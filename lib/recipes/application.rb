# Code from https://github.com/ricodigo/ricodigo-capistrano-recipes/blob/master/lib/recipes/application.rb
# Modified by romain@softr.li

Capistrano::Configuration.instance.load do
  
  # User settings
  _aset :user
  _aset :group
  _aset :password
  _cset :use_sudo, false

  # Server settings
  _cset :app_server, :unicorn
  _cset :web_server, :nginx
  _cset :runner, user
  _cset :application_port, 80

  _cset :application_uses_ssl, true
  _cset :application_port_ssl, 443

  # Database settings
  _cset :database, :postgresql
  
  # Monitoring settings
  _cset :process_monitorer, :none

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
  _cset :using_rvm, true

  if using_rvm
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
  _cset :shared_dirs,           %w(config log pids sockets)
  shared_dirs.each do |shared_dir|
    eval "_cset :#{shared_dir}_path, File.join(shared_path, '#{shared_dir}')"
  end

  namespace :app do
    
    task :setup, :roles => :app do
      # Check shared dirs exist or create them.
      shared_dirs.each do |shared_dir|
        shared_dir_path = eval "#{shared_dir}_path"
        run "mkdir -p #{shared_dir_path}"
      end
    end
    
  end
end