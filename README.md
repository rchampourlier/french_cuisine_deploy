# French Cuisine, Capistrano Recipes

Capistrano recipes useful for deployment, including:

* One-in-all deployment for a Rails app:
** Supported configuration:
*** Ubuntu 10.04 LTS server (may work on other servers, but adapted with this one in mind),
*** served through a nginx proxy (standard distrib installation),
*** PostgreSQL database (for now),
*** monit process monitoring (may be disabled, only monitor supported for now),
*** Unicorn Rails application server (only one supported for now).
** What does the script do:
*** setup the app's directories (shared, config, log, sockets...),
*** deploy the app with standard Capistrano recipe,
*** integrates RVM and Bundler,
*** setups Unicorn (generates an appropriate unicorn.rb file),
*** setups Nginx (generates an appropriate host configuration file),
*** setups Monit (generates an appropriate configuration file).

## History

This is just another set of Capistrano Recipes derived from the certainly excellent Weficient's one.
Wanting to learn how to write Capistrano recipes from scratch, I did not fork nor copy the original
recipes, rather made my own (starting in a single 'deploy.rb' file) to transform it to a gem to make
it simpler to use, and to share.

## Included Tasks

TO BE UPDATED

How to use:

First deployment (cold):
* cap deploy:first -> sugar syntax for running the following tasks:
** cap deploy:prerequisites -> displays the manual operations to run before deploying the first time
** cap deploy:setup
** cap deploy:cold

Next deployments:
* cap deploy

Other tasks:

RVM:
* cap rvm:prerequisites

Web server:
* cap nginx:setup
* cap nginx:start
* cap nginx:stop
* cap nginx:restart
* cap nginx:clean_setup: remove nginx setup files
* cap nginx:setup_recreate: clean then setup

Application servers:
* cap unicorn:start
* cap unicorn:stop
* cap unicorn:restart
* cap unicorn:setup
* cap thin:start
* cap thin:stop
* cap thin:restart
* cap thin:setup

Database:
* Database servers setup:
** cap postgresl:prerequisites
* Database synchronization:
Ongoing implementation for PostgreSQL and MongoDB using dump/restore commands.

SSH:
* cap ssh:open_tunnel
* cap ssh:close_tunnel

## Use cases

* Changing your application server from :unicorn to :thin:
** change the 'app_server' value in your 'deploy.rb' file
** run 'cap maintenance:on'
** run 'cap app:change_server'
** run 'cap maintenance:off'


## Todo

* If using RVM, should create the gemset if it does not exist, and even install the ruby if it is not
yet installed.
* Better management of monit. It should begin watching over the unicorn instance once it has been started
by the script, or it may start it itself. It should stop watching when we want to stop the process too.
* Tasks for log rotation.
* Task to reset the application's gemset (nice when removed some gems).
* Add tasks for dumping and loading from dump PostgreSQL databases (local and remote). Would be nice way
to sync production, staging and dev when we work with the same database system.

## Installation

TO BE UPDATED

Easy as pie...

Install this gem:

  sudo gem install ricodigo-capistrano-recipes

To setup the initial Capistrano deploy file, go to your Rails app folder via command line and enter:

  capify .

## Configuration

Inside the newly created config/deploy.rb, add:

  require 'capistrano/ext/multistage' # only require if you've installed Cap ext gem

  # This one should go at the end of your deploy.rb
  require 'ricodigo_capistrano_recipes'

### rbenv

rbenv is not used in place of RVM for ruby management. It's more lightweight, and less
head-banging-prone when trying to deal with startup scripts or managers (ie. god).

:rbenv is set as the default ruby_manager
You can disable it by setting ruby_manager to :rvm instead, or to :none if you don't use
a Ruby manager (which would not be advised by more expert-people-than-me).

NB: RVM is not supported anymore (I don't use it anymore, and I prefer removing obsolete parts that may not work. Please check the repo's history if you need RVM parts.)

### Nginx

If you're using nginx as your web server, set :web_server to :nginx and deploy:setup will
generate the appropriate configuration file for it based on your other variables, such as
:application_uses_ssl, etc.

### Unicorn

If you're running Unicorn (http://unicorn.bogomips.org/) be sure to add this line instead:

  set :server, :unicorn

==Copyrights

Original source: Copyright (c) 2009-2011 Webficient LLC, Phil Misiowiec. See LICENSE for details.
Modified by: ricodigo (https://github.com/ricodigo)
Our copyright: Copyright (c) 2011 softr.li, Romain Champourlier.