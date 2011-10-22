# Code from https://github.com/ricodigo/ricodigo-french_cuisine/blob/master/lib/recipes/deploy.rb
# Edited by romain@softr.li

Capistrano::Configuration.instance.load do
  set :shared_children, %w(system log pids config)

  namespace :deploy do
    desc "|french_cuisine| Destroys everything"
    task :seppuku, :roles => :app, :except => { :no_release => true } do
      run "rm -rf #{current_path}; rm -rf #{shared_path}"
    end

    # Invoked during initial deployment
    desc "start"
    task :start, :roles => :app, :except => {:no_release => true} do
      unicorn.start
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
  end
  
end
