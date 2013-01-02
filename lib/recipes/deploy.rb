# Overriding deploy:start, deploy:stop, deploy:restart standard Capistrano
# tasks is a requirement of Capistrano.
#
# Author: Romain Champourlier <romain@softr.li>
#
# Original inspiration from:
# https://github.com/ricodigo/ricodigo-french_cuisine/blob/master/lib/recipes/deploy.rb

Capistrano::Configuration.instance.load do
  set :shared_children, %w(public/system log tmp/pids)

  namespace :deploy do
    
    desc <<-EOF
    Prepares deployment
    This tasks automates the process of finalizing the commit to be deployed,
    checkout the correct branches, merges the appropriate one and pushed to 
    origin.
    When used in 'staging' stage, it will ask for a branch to merge, merge it,
    perform assets precompilation, commit and push to remote origin.
    When used in 'production' stage, it will automatically checkout the 'master'
    branch, merge the 'staging' one and push to remote origin. Assets precompilation
    is expected to be done during preparation for staging, so it won't be repeated here.
    EOF
    task :prepare do
      
      # Checking out stage's branch
      run_locally "git checkout #{branch}"

      if stage == :staging
      
        # Merging a branch into staging
        message = "Which branch should be used for this deployment? It will be merged within #{branch} (use 'none' if no merging is necessary, 'abort' to abort)"
        merged_branch = Capistrano::CLI.ui.ask(message) do |q|
          q.default = "dev"
        end
        abort if merged_branch == 'abort'
        run_locally "git merge #{merged_branch}" unless merged_branch == 'none'
      
        # Ask for assets precompiling
        message = "Should assets be precompiled (through rake assets:precompile)? If yes, it will then commit and push to origin (yn). Empty answer will abort."
        precompile = Capistrano::CLI.ui.ask(message)
        abort if (precompile.downcase =~ %r%[yn]%).nil?

        if precompile.downcase == 'y'
          # Precompiling and committing assets
          run_locally "bundle exec rake assets:precompile"
          run_locally "git add public/assets"
          run_locally "git commit -m 'Precompiled assets for deployment'"
        end
      
      elsif stage == :production
        message = "Continue? This will merge the 'staging' branch and push to 'origin'. (Yn)"
        continue = Capistrano::CLI.ui.ask(message) do |q|
          q.default = 'Y'
        end
        abort if continue.downcase != 'y'
        run_locally "git merge staging"
      end
      
      # Pushing to origin
      run_locally "git push origin"
    end
    
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