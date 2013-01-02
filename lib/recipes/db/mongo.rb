Capistrano::Configuration.instance.load do

  namespace :db do
    namespace :mongo do
    
      def set_db_credentials
        _aset :mongo_db_name
      end

      task :drop, :roles => :db do
        deny_in_production
        set_db_credentials

        run "mongo #{mongo_db_name} --eval 'db.dropDatabase()'"
      end

      task :restore, :roles => :db do
        deny_in_production
        set_db_credentials

        ask_for_file_unless_set :local_mongo_dumps_dir, :with_prompt => "Local directory of MongoDB dumps?"
        local_mongo_dumps_archive = "#{local_mongo_dumps_dir}.tar.gz"
        remote_mongo_dumps_archive = "/tmp/french_cuisine_mongo_dumps.tar.gz"

        local_mongo_dumps_dir_name = local_mongo_dumps_dir.split('/').last
        run_locally "cd #{local_mongo_dumps_dir}/..; tar zcf #{local_mongo_dumps_archive} #{local_mongo_dumps_dir_name}"
        upload local_mongo_dumps_archive, remote_mongo_dumps_archive

        drop

        run "tar zxf #{remote_mongo_dumps_archive} -C /tmp"
        Dir[File.join(local_mongo_dumps_dir, '*.bson')].each do |dump_file|
          dump_file_name = File.basename(dump_file)
          run "mongorestore -d #{mongo_db_name} /tmp/#{local_mongo_dumps_dir_name}/#{dump_file_name}"
        end

        run "rm #{remote_mongo_dumps_archive}"
        run "rm -Rf /tmp/#{local_mongo_dumps_dir_name}"
        run_locally "rm #{local_mongo_dumps_archive}"
      end

      task :push, :roles => :db, :on_error => :continue do
        deny_in_production

        ask_for_file "Local directory of MongoDB dumps?", :local_mongo_dumps_dir, :unless_exists => 'french_cuisine_deploy_mongo_dumps'
        ask "Are you sure? This will replace your #{stage} MongoDB by the BSON dumps in #{local_mongo_dumps_dir} (yes/no)", false
        restore
      end
    end
  end
end