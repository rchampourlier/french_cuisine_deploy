Capistrano::Configuration.instance.load do

  namespace :db do
    namespace :pg do
    
      def set_db_credentials
        _aset :pg_db_name
        _aset :pg_db_user
        _aset :pg_db_password
      end

      def deny_in_production
        if stage == "production"
          puts "Can't push to production"
          abort
        end
      end

      _cset :local_pg_dump, 'fc_pg_dump'
      unset :local_pg_dump unless FileTest.exist?(local_pg_dump)
      _cset :remote_pg_dump, "/tmp/fc_pg_dump"

      task :pull, :roles => :db do
        set_db_credentials

        set :pg_temp_dump, "/tmp/#{local_pg_dump}"
        run "PGPASSWORD='#{pg_db_password}' pg_dump -U #{pg_db_user} #{pg_db_name} > #{pg_temp_dump}"
        get pg_temp_dump, local_pg_dump
        run "rm #{pg_temp_dump}"
      end
      
      task :drop, :roles => :db, :on_error => :continue do
        deny_in_production
        set_db_credentials

        run "PGPASSWORD='#{pg_db_password}' dropdb -U #{pg_db_user} #{pg_db_name}"
      end
      
      task :create, :roles => :db do
        deny_in_production
        set_db_credentials

        run "PGPASSWORD='#{pg_db_password}' createdb -U #{pg_db_user} -T template0 -O #{pg_db_user} -E UTF8 #{pg_db_name}"
      end
      
      task :load_from_dump, :roles => :db do
        deny_in_production
        set_db_credentials

        run "PGPASSWORD='#{pg_db_password}' psql -U #{pg_db_user} #{pg_db_name} < #{remote_pg_dump}"
      end
      
      task :restore, :roles => :db do
        deny_in_production

        _aset :local_pg_dump
        upload local_pg_dump, remote_pg_dump
        drop
        create
        load_from_dump
      end

      task :push, :roles => :db, :on_error => :continue do
        deny_in_production
        
        _aset :local_pg_dump
        answer = Capistrano::CLI.ui.ask("Are you sure? This will replace your #{stage} PostgreSQL DB by the local dump (#{local_pg_dump}) (yes/no)") do |q|
          q.default = "no"
          q.validate = %r%(yes|no)%
        end
        abort unless answer == "yes"

        restore
      end
    end
  end
end