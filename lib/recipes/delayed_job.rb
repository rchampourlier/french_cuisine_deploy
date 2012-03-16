# Recipes included and modified from
# https://github.com/collectiveidea/delayed_job/blob/master/lib/delayed/recipes.rb
#
# REFERENCES
#   - Useful documentation on script/delayed_job:
#     https://github.com/collectiveidea/delayed_job/wiki/Delayed-job-command-details

Capistrano::Configuration.instance.load do
  
  _cset :background_workers, 2
  
  namespace :delayed_job do
    
    def rails_env
      fetch(:rails_env, false) ? "RAILS_ENV=#{fetch(:rails_env)}" : ''
    end

    def args
      fetch(:delayed_job_args, "")
    end

    def roles
      fetch(:delayed_job_server_role, :app)
    end

    desc "Stop the delayed_job process"
    task :stop, :roles => lambda { roles } do
      #run "cd #{current_path};#{rails_env} bundle exec script/delayed_job -n #{background_workers} stop"
      run "cd #{current_path};#{rails_env} bundle exec script/delayed_job -n #{background_workers} --pid-dir=#{pids_path} stop"
    end

    desc "Start the delayed_job process"
    task :start, :roles => lambda { roles } do
      run "cd #{current_path};#{rails_env} bundle exec script/delayed_job -n #{background_workers} --pid-dir=#{pids_path} start #{args}"
      #run "cd #{current_path};#{rails_env} bundle exec script/delayed_job -n #{background_workers} start"
    end

    desc "Restart the delayed_job process"
    task :restart, :roles => lambda { roles } do
      run "cd #{current_path};#{rails_env} bundle exec script/delayed_job -n #{background_workers} --pid-dir=#{pids_path} restart #{args}"
    end

    task :setup, :roles => :app , :except => { :no_release => true } do
      unless process_monitor_manages_background_processor
        # TODO
        # Should have a setup to load background processor at startup
        # Upstart or SystemV scripts.
      end
    end
  
    task :clean_setup, :roles => :app , :except => { :no_release => true } do
      # Nothing to do, wasn't setup
    end
  
  end

end