# Code from https://github.com/ricodigo/ricodigo-capistrano-recipes/blob/master/lib/recipes/application.rb
# Modified by romain@softr.li

module FrenchCuisineDeploy
  class App
    def self.supported_servers
      [:unicorn, :thin] 
    end
  end
end

Capistrano::Configuration.instance.load do
  
  # User settings
  _aset :user
  _aset :group
  _aset :password
  _cset :use_sudo, false

  # System settings
  _cset :startup_script_prefix, '/etc/init.d'

  # Server settings
  _cset :app_server, :thin
  _cset :web_server, :nginx
  _cset :runner, user
  _cset :application_port, 80

  _cset :application_uses_ssl, true
  _cset :application_port_ssl, 443

  # Database settings
  _cset :database, :postgresql
  
  # Monitoring settings
  _cset :process_monitor, :none

  # Background process
  _cset :background_processor, :none  # :none or :delayed_job

  # SCM settings
  _cset :scm,           :git
  _aset :repository
  _cset :branch,        'master'
  _cset :deploy_to,     "/home/#{user}/rails/#{application}"
  _cset :deploy_via,    :checkout
  _cset :keep_releases, 3
  _cset :run_method,    :run
  _cset :git_enable_submodules, true
  _cset :git_shallow_clone, 1
  _cset :rails_env, 'production'

  if is_using_git
    # Git settings for Capistrano
    default_run_options[:pty] = true
    ssh_options[:forward_agent] = true
  end

  # RVM settings
  _cset :ruby_manager, :rbenv

  if is_using_rvm
    $:.unshift(File.expand_path('./lib', ENV['rvm_path']))  # Add RVM's lib directory to the load path.
    require "rvm/capistrano"                                # Load RVM's capistrano plugin.

    # Sets the rvm to a specific version (or whatever env you want it to run in)
    _aset :rvm_ruby_string
  end

  # Options necessary to make Ubuntu’s SSH happy
  ssh_options[:paranoid]    = false
  default_run_options[:pty] = true
  
  # Shared paths
  _cset :shared_path,           File.join(deploy_to, "shared")
  _cset :shared_dirs,           %w(config log pids sockets system)
  shared_dirs.each do |shared_dir|
    eval "_cset :#{shared_dir}_path, File.join(shared_path, '#{shared_dir}')"
  end
  
  namespace :app do
    
    task :setup_shared_dirs, :roles => :app do
      # Check shared dirs exist or create them.
      shared_dirs.each do |shared_dir|
        shared_dir_path = eval "#{shared_dir}_path"
        run "mkdir -p #{shared_dir_path}"
      end
    end
    
    task :web_server_setup, :roles => :app do
      eval "#{web_server}.setup"
      eval "#{web_server}.reload"
    end
    
    task :clean_web_server_setup, :roles => :app do
      eval "#{web_server}.clean_setup"
      eval "#{web_server}.reload"
    end
    
    task :reset_web_server_setup, :roles => :app do
    end
    
    task :setup, :roles => :app do
      eval "#{app_server}.setup"
      eval "#{background_processor}.setup" if is_using_background_processor
      eval "#{process_monitor}.setup" if is_using_process_monitor
    end
    
    task :clean_setup, :roles => :app do
      eval "#{app_server}.clean_setup"
      eval "#{background_processor}.clean_setup" if is_using_background_processor
      eval "#{process_monitor}.clean_setup" if is_using_process_monitor
    end
    
    task :reset_setup, :roles => :app do
      clean_setup
      setup
    end
    
    task :change_server, :roles => :app do
      possible_servers = FrenchCuisineDeploy::App.supported_servers - [app_server]
      prompt = "Which application server is currently running? (#{possible_servers.join ", "})"
      server = Capistrano::CLI.ui.ask(prompt) do |q|
        q.validate = %r%(#{possible_servers.join("|")})%
      end
      logger = Capistrano::Logger.new
      logger.important "Changing app server from #{server} to #{app_server}"
      
      current_server = app_server
      
      # Temporary change app_server to old one to perform the cleaning operations
      set :app_server, server.to_sym
      clean_setup
      stop
      
      # Restore the current app_server, do the setup and start it.
      set :app_server, current_server
      setup
      start
    end
    
    # Called by deploy:start
    task :start, :roles => :app do
      eval "#{app_server}.start"
      eval "#{background_processor}.start" if is_using_background_processor
      eval "#{process_monitor}.start_monitoring" if is_using_process_monitor
    end
    
    # Called by deploy:stop
    task :stop, :roles => :app do
      eval "#{process_monitor}.stop_monitoring" if is_using_process_monitor
      eval "#{background_processor}.stop" if is_using_background_processor
      eval "#{app_server}.stop"
    end
    
    # Called by deploy:restart
    task :restart, :roles => :app do
      eval "#{app_server}.restart"
      eval "#{background_processor}.restart" if is_using_background_processor
    end
    
  end
end