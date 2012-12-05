Capistrano::Configuration.instance.load do

  namespace :db do
    namespace :mongo do
    
      def set_db_credentials
        _aset :mongo_db_name
      end

      def deny_in_production
        if stage == "production"
          puts "Can't push to production"
          abort
        end
      end

      _cset :local_mongo_dumps_dir, 'fc_pg_dump'
      unset :local_mongo_dumps_dir unless FileTest.exist?(local_mongo_dumps_dir)
      _cset :remote_mongo_dump, "/tmp/fc_mongo_dump.bson"

      task :drop, :roles => :db do
        deny_in_production
        set_db_credentials

        run "mongo #{mongo_db_name} --eval 'db.dropDatabase()'"
      end

      task :load_from_dump, :roles => :db do
        deny_in_production
        set_db_credentials

        _cset :remote_mongo_dump, '/tmp/french_cuisine_deploy_mongo_dump.bson'
        run "mongorestore -d #{mongo_db_name} #{remote_mongo_dump}"
      end

      task :restore, :roles => :db do
        deny_in_production
        set_db_credentials

        _aset :local_mongo_dumps_dir
        Dir[File.join(local_mongo_dumps_dir, '*.bson')].each do |local_dump|
          _cset :remote_mongo_dump, '/tmp/french_cuisine_deploy_mongo_dump.bson'
          upload local_dump, remote_mongo_dump
          drop
          load_from_dump
          run "rm #{remote_mongo_dump}"
        end
      end

      task :push, :roles => :db, :on_error => :continue do
        deny_in_production

        set :local_mongo_dumps_dir, 'french_cuisine_deploy_mongo_dumps'
        unset :local_mongo_dumps_dir unless FileTest.exist?(local_mongo_dumps_dir)
        _aset :local_mongo_dumps_dir

        answer = Capistrano::CLI.ui.ask("Are you sure? This will replace your #{stage} MongoDB by the BSON dumps in #{local_mongo_dumps_dir} (yes/no)") do |q|
          q.default = "no"
          q.validate = %r%(yes|no)%
        end
        abort unless answer == "yes"

        restore
      end
    end
  end
end