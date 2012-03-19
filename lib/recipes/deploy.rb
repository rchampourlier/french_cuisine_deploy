# Overriding deploy:start, deploy:stop, deploy:restart standard Capistrano
# tasks is a requirement of Capistrano.
#
# Code from https://github.com/ricodigo/ricodigo-french_cuisine/blob/master/lib/recipes/deploy.rb
# Edited by romain@softr.li

Capistrano::Configuration.instance.load do
  set :shared_children, %w(public/system log tmp/pids)

  namespace :deploy do
    
    desc "|french_cuisine| Interactive walkthrough for complete first deployment"
    task :first do
      
      deploy.prerequisites
      answer = Capistrano::CLI.ui.ask("Continue? (yes/no)") do |q|
        q.default = "yes"
        q.validate = %r%(yes|no)%
      end
      abort unless answer == "yes" 
      
      deploy.setup
      deploy.cold
    end
    
    desc "|french_cuisine| Displays application deployment prerequisites"
    task :prerequisites do
      rvm.prerequisites
      eval "#{database}.prerequisites"
    end
    
    desc "|french_cuisine| Destroys everything"
    task :seppuku, :roles => :app, :except => { :no_release => true } do
      run "rm -rf #{current_path}; rm -rf #{shared_path}"
    end

    # Invoked during initial deployment
    desc "|french_cuisine| Starts application server"
    task :start, :roles => :app, :except => {:no_release => true} do
      app.start
    end
  
    desc "|french_cuisine| Stops application server"
    task :stop, :roles => :app, :except => {:no_release => true} do
      app.stop
    end
    
    desc "|french_cuisine| Reloads application server"
    task :reload, :roles => :app, :except => {:no_release => true} do
      eval "#{app_server}.reload"
    end
    
    desc "|french_cuisine| Gracefully stops application server"
    task :graceful_stop, :roles => :app, :except => {:no_release => true} do
      eval "#{app_server}.graceful_stop"
    end
    
    # Invoked after each deployment afterwards
    desc "|french_cuisine| Restarts application server"
    task :restart do
      stop
      start
    end
  end
  
end
