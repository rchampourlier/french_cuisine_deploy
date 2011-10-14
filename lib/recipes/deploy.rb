# Code from https://github.com/ricodigo/ricodigo-french_cuisine/blob/master/lib/recipes/deploy.rb
# Edited by romain@softr.li

Capistrano::Configuration.instance.load do
  set :shared_children, %w(system log pids config)

  namespace :deploy do
    desc "|french_cuisine| Destroys everything"
    task :seppuku, :roles => :app, :except => { :no_release => true } do
      run "rm -rf #{current_path}; rm -rf #{shared_path}"
    end

    desc "|french_cuisine| Create shared dirs"
    task :setup_dirs, :roles => :app, :except => { :no_release => true } do
      commands = shared_dirs.map do |path|
        "mkdir -p #{shared_path}/#{path}"
      end
      run commands.join(" && ")
    end

    desc "|french_cuisine| Remote run for rake db:seed"
    task :migrate, :roles => :app, :except => { :no_release => true } do
      run "cd #{current_path}; bundle exec rake RAILS_ENV=#{rails_env} db:seed"
    end

    desc "|french_cuisine| [Obsolete] Nothing to cleanup when using reset --hard on git"
    task :cleanup, :roles => :app, :except => { :no_release => true } do
      #nothing to cleanup, we're not working with 'releases'
      puts "Nothing to cleanup, yay!"
    end

    # Invoked during initial deployment
    desc "start"
    task :start, :roles => :app, :except => {:no_release => true} do
      unicorn.start
      nginx.restart # reload seems not to be sufficient to get new host confs
    end
  
    desc "stop"
    task :stop, :roles => :app, :except => {:no_release => true} do
      unicorn.stop
    end
    
    desc "reload"
    task :reload, :roles => :app, :except => {:no_release => true} do
      unicorn.reload
    end
    
    desc "graceful stop"
    task :graceful_stop, :roles => :app, :except => {:no_release => true} do
      unicorn.graceful_stop
    end
    
    # Invoked after each deployment afterwards
    desc "restart"
    task :restart do
      stop
      start
    end

    namespace :rollback do
      desc "|french_cuisine| Rollback , :except => { :no_release => true }a single commit."
      task :default, :roles => :app, :except => { :no_release => true } do
        set :branch, "HEAD^"
        deploy.default
      end
    end
  end
  
end
