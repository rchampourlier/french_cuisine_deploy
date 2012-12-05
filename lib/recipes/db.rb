Capistrano::Configuration.instance.load do

  # PostgreSQL
  namespace :db do
    
    task :pull, :roles => :db do
      _aset :remote_db_name
      _aset :remote_db_user
      _aset :remote_db_password
      _cset :dump_file_name, "french_cuisine_deploy_db_dump"
      set :remote_temp_dump, "/tmp/#{dump_file_name}"
      run "PGPASSWORD='#{remote_db_password}' pg_dump -U #{remote_db_user} #{remote_db_name} > #{remote_temp_dump}"
      get remote_temp_dump, dump_file_name
      run "rm #{remote_temp_dump}"
    end
    
    task :drop, :roles => :db, :on_error => :continue do
      _aset :remote_db_name
      _aset :remote_db_user
      _aset :remote_db_password
      run "PGPASSWORD='#{remote_db_password}' dropdb -U #{remote_db_user} #{remote_db_name}"
    end
    
    task :create, :roles => :db do
      _aset :remote_db_name
      _aset :remote_db_user
      _aset :remote_db_password
      run "PGPASSWORD='#{remote_db_password}' createdb -U #{remote_db_user} -T template0 -O #{remote_db_user} -E UTF8 #{remote_db_name}"
    end
    
    task :load_from_dump, :roles => :db do
      _aset :remote_db_name
      _aset :remote_db_user
      _aset :remote_db_password
      _cset :dump_file, "/tmp/french_cuisine_deploy_db_dump"
      run "PGPASSWORD='#{remote_db_password}' psql -U #{remote_db_user} #{remote_db_name} < #{dump_file}"
    end
    
    task :push, :roles => :db, :on_error => :continue do
      if stage == "production"
        puts "Can't push to production"
        abort
      else
        # TODO should obfuscate the password
        _aset :remote_db_name
        _aset :remote_db_user
        _aset :remote_db_password
        set :local_dump_file, 'french_cuisine_deploy_db_dump'
        unset :local_dump_file unless FileTest.exist?(local_dump_file)
        _aset :local_dump_file
        _cset :dump_file, "/tmp/french_cuisine_deploy_db_dump"
        answer = Capistrano::CLI.ui.ask("Are you sure? This will replace your #{stage} database by the local dump (#{local_dump_file}) (yes/no)") do |q|
          q.default = "no"
          q.validate = %r%(yes|no)%
        end
        abort unless answer == "yes"
        upload local_dump_file, dump_file
        drop
        create
        load_from_dump
        run "rm #{dump_file}"
      end
    end
  end
  
end