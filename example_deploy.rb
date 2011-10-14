# Romain Champourlier © softr.li
# Inspired from many gist, recipes on github, tutorials... essentially:
# - https://gist.github.com/548927
# - http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/
# - https://github.com/ricodigo/ricodigo-capistrano-recipes
#
# ONGOING WORK
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
# - write a remove task# ESSENTIALS

# ESSENTIALS

set :application,       'application'                                               # default: 'application'

set :user,              'username'                                                  # required
set :group,             'groupname'                                                 # required
set :deploy_to,         "/home/#{user}/rails/#{application}"

set :domain_name,       'server'                                            # required


role :app,              'server'
role :web,              'server'
role :db,               'server', :primary => true


# REPOSITORY SETUP

set :scm,               :git          # possible values: [:git]                       default: git
set :repository,        ''                                                          # required
set :branch,            'branch'                                                    # default: 'master'


# SERVER ENVIRONMENT

set :web_server,        :nginx        # possible values: [:nginx]                     default: :nginx
set :app_server,        :unicorn      # possible values: [:unicorn]                   default: :unicorn
set :database,          :postgresql   # possible values: [:postgresql]                default: :postgresql
set :process_monitorer, :monit        # possible values: [:none, :monit]              default: :none

set :sockets_path,      File.join(shared_path, "sockets", "#{application}.sock")    # default: File.join(shared_path, "sockets", "#{application}.sock")
set :pids_path,         File.join(shared_path, "pids")                              # default: File.join(shared_path, "pids")


# WEB SERVER CONFIGURATION

set :host_confs_prefix, "/etc/nginx"                                                # default: /etc/nginx for nginx


# RAILS ENVIRONMENT

set :rails_env,         'production'                                                # default: 'production'

set :using_rvm,         true          # possible values: [true, false]                default: true
set :rvm_ruby_string,   "ruby-1.9.2-p290/#{application}"                            # required if using rvm


# APP SERVER CONFIGURATION

# UNICORN
# Number of workers (Rule of thumb is 1 per CPU)
# Just be aware that every worker needs to cache all classes and thus eat some
# of your RAM.
set :unicorn_workers,         2           # default: 4
set :unicorn_workers_timeout, 30          # default: 30

require 'capistrano/french_cuisine'
