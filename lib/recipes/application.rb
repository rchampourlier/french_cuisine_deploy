# Romain Champourlier © softr.li
# Inspired from many gist, recipes on github, tutorials... essentially:
# - https://gist.github.com/548927
# - http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/
# - https://github.com/ricodigo/ricodigo-capistrano-recipes
#
# This is ONGOING WORK
#
# MIT License http://www.opensource.org/licenses/mit-license.php
#
# - Intended for Ubuntu 10.04.3
# - Deploy Rails app to be served by an unicorn instance, reverse-proxied by a nginx server
# - Automatically:
#     - generates unicorn.rb conf file,
#     - generates nginx host-file and symlinks it to sites-available and sites-enabled,
#     - generates a startup script to run the unicorn instance when the server is booted,
#     - adds the service to the expected runlevels.
#     - adds a config file to monitor the unicorn instance in monit.
#
# TODO
# - use CLI for passwords
# - write a remove task

# Code from https://github.com/ricodigo/ricodigo-capistrano-recipes/blob/master/lib/recipes/application.rb
Capistrano::Configuration.instance.load do
  
  # User settings
  _aset :user
  _aset :group

  # Server settings
  _cset :app_server, :unicorn
  _cset :web_server, :nginx
  _cset :runner, user
  _cset :application_port, 80

  _cset :application_uses_ssl, true
  _cset :application_port_ssl, 443

  # Database settings
  _cset :database, :postgresql

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

  # Git settings for capistrano
  default_run_options[:pty] = true
  ssh_options[:forward_agent] = true

  # RVM settings
  _cset :using_rvm, true

  if using_rvm
    $:.unshift(File.expand_path('./lib', ENV['rvm_path']))  # Add RVM's lib directory to the load path.
    require "rvm/capistrano"                                # Load RVM's capistrano plugin.

    # Sets the rvm to a specific version (or whatever env you want it to run in)
    _aset :rvm_ruby_string
  end

  # Daemons settings
  # The unix socket that unicorn will be attached to.
  _cset :sockets_path, { File.join(shared_path, "sockets", "#{application}.sock") }

  # Just to be safe, put the pid somewhere that survives deploys. shared/pids is
  # a good choice as any.
  _cset(:pids_path) { File.join(shared_path, "pids") }

  _cset :process_monitorer, :none

  # Application settings
  _cset :shared_dirs, %w(config uploads backup bundle tmp sockets pids log system) unless exists?(:shared_dirs)

  # Options necessary to make Ubuntu’s SSH happy
  ssh_options[:paranoid]    = false
  default_run_options[:pty] = true
  
  # Shared paths
  _cset :shared_path,           "#{deploy_to}/shared"
  _cset :configs_path,          "#{shared_path}/configs"
  _cset :logs_path,             "#{shared_path}/log"

  namespace :app do
    task :setup, :roles => :app do
      commands = shared_dirs.map do |path|
        "if [ ! -d '#{path}' ]; then mkdir -p #{path}; fi;"
      end
      run "cd #{shared_path}; #{commands.join(' ')}"
    end
  end
end

namespace :deploy do

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
end

def parse_config(file)
  puts File.expand_path(File.dirname(__FILE__))
  require 'erb' # render not available in Capistrano 2
  template = File.read(file) # read it
  return ERB.new(template).result(binding) # parse it
end

# Generates a configuration file parsing through ERB
# Fetches local file and uploads it to remote_file
# Make sure your user has the right permissions.
def generate_config(local_file, remote_file)
  temp_file = '/tmp/' + File.basename(local_file)
  buffer    = parse_config(local_file)
  File.open(temp_file, 'w+') { |f| f << buffer }
  upload temp_file, remote_file, :via => :scp
  `rm #{temp_file}`
end