# Taps recipes
#
# 
# Requirements:
#  - You must have the 'taps' gem in your Gemfile for the production and development groups.
#
# Limitations:
#  - Only works for a single server
#  - Due to the taps gem, during the time the synchronization is performed, a process is running
#    on the server machine and it contains the database user and password in clear. Be sure no
#    one can list the running processes, and they do not get logged to prevent database password
#    leakage.
#
# TODO
#  - Manage several servers.

require 'rubygems'
begin
  gem 'taps', '>= 0.3.23', '< 0.4.0'
  require 'taps/operation'
rescue LoadError
  puts "Install the Taps gem to use db commands. On most systems this will be:\nsudo gem install taps"
  exit
end

module FrenchCuisineDeploy::DB
  extend self
  
  def taps_remote_url
    "http://tmpuser:tmppass@localhost:5000"
  end
  
  # A quick start for a Taps client.
  def taps_client_transfer(method, local_database_url, remote_url)
    logger = Capistrano::Logger.new
    logger.important "taps_client_transfer #{method}, #{local_database_url}, #{remote_url}"
    
    Taps::Operation.factory(method, local_database_url, remote_url, {}).run
  end
  
  # Generates the server command used to start a Taps server
  #
  # ==== Parameters
  # * <tt>:remote_database_url, :login, :password</tt> - See #run.
  # * <tt>:port</tt> - The +port+ the Taps server is on. If given and different from 5000, appends <tt>--port=[port]</tt> to command.
  def server_command(options={})
    current_path = options[:current_path]
    database = options[:remote_database]

    "cd #{current_path} && bundle exec taps server #{database} tmpuser tmppass"
  end
  
  # The meat of the operation. Runs operations after setting up the Taps server.
  # 
  # 1. Runs the <tt>taps</tt> taps command to start the Taps server (assuming Sinatra is running on Thin)
  # 2. Wait until the server is ready 
  # 3. Execute block on Taps client
  # 4. Close the connection(s) and bid farewell.
  #
  # ==== Parameters
  # * <tt>:remote_database_url</tt> - Refers to local database url in the options for the Taps server command (see Taps Options).
  # * <tt>:login</tt> - The login for +host+. Usually what's in <tt>set :user, "the user"</tt> in <tt>deploy.rb</tt>
  # * <tt>:password</tt> - The temporary password for the Taps server.
  # * <tt>:port</tt> - The +port+ the Taps server is on. If not given, defaults to 5000
  # * <tt>:local_database_url</tt> - Refers to the local database url in the options for Taps client commands (see Taps Options).
  #
  # ==== Taps Options
  #
  # <tt>taps</tt>
  #   server <local_database_url> <login> <password> [--port=N]        Start a taps database import/export server
  #   pull <local_database_url> <remote_url> [--chunksize=N]           Pull a database from a taps server
  #   push <local_database_url> <remote_url> [--chunksize=N]           Push a database to a taps server
  #
  # ==== Examples
  #
  #   task :push do
  #     login = fetch(:user)
  #     password = Time.now.to_s
  #     FrenchCuisineDeploy.DB.run(self, { :login => login, :password => password, :remote_database_url => "sqlite://test_production", :local_database_url => "sqlite://test_development" }) do |client|
  #       client.cmd_send
  #     end
  #   end
  def run(method, instance, options = {})
    logger = Capistrano::Logger.new
    
    remote_database_url, login, password, port, local_database_url = options[:remote_database_url], options[:login], options[:password], options[:port], options[:local_database_url]
    data_so_far = ""
    instance.run FrenchCuisineDeploy::DB.server_command(options) do |channel, stream, data|
      data_so_far << data
      logger.important data_so_far
      if data_so_far.include? ">> Listening on 0.0.0.0:5000, CTRL+C to stop"
        remote_url = FrenchCuisineDeploy::DB.taps_remote_url
        sleep 5
        FrenchCuisineDeploy::DB.taps_client_transfer(method, local_database_url, remote_url)
  
        data_so_far = ""
        channel.close
        channel[:status] = 0
      end
    end
  end
  
end

Capistrano::Configuration.instance.load do

  # Taps tools
  namespace :db do
    
    desc "Pull or push the remote database to the local current environment's database"
    task :perform_sync, :roles => :app do
      
      _aset :sync_method, :pull
      
      logger = Capistrano::Logger.new

      # Setup SSH tunnel to carry the taps' connection data.
      set :ssh_target_server, roles[:app].servers.first.to_s
      set :ssh_local_port, 5000
      set :ssh_target_port, 5000
      ssh.open_tunnel
      
      # Start taps on the app server
      
      # TODO replace with autodetection of databases through database.yml file
      
      # Local database
      _aset :local_database, 'sqlite'
      _aset :local_database_name, 'db/development.sqlite3'
      _aset :local_database_user, 'none'
      _aset :local_database_password, 'none'
      
      # Remote database
      # Using 'database' as database connector representative
      _aset :remote_database_name
      _aset :remote_database_user
      _aset :remote_database_password
      
      if database == :postgresql
        remote_database_url = "postgres://#{remote_database_user}:#{remote_database_password}@localhost/#{remote_database_name}"
      else
        logger.important "#{database} databases not supported yet."
        abort
      end
      
      if local_database == 'sqlite'
        local_database_url = "sqlite://#{local_database_name}"
      else
        logger.important "#{local_database} databases not supported yet."
      end
      
      # Run the taps operation:
      #  1. starts taps server
      #  2. perform the pull operation
      #  3. closes the channel, thus stopping the taps server
      options = {:current_path => current_path, :remote_database => remote_database_url, :local_database_url => local_database_url}
      FrenchCuisineDeploy::DB.run(sync_method.to_sym, self, options)
      
      ssh.close_tunnel
    end
    
    task :pull do
      answer = Capistrano::CLI.ui.ask("Are you sure? This will replace your local database (#{local_database_name}) by the remote one. (yes/no)") do |q|
        q.default = "no"
        q.validate = %r%(yes|no)%
      end
      abort unless answer == "yes"
      
      set :sync_method, :pull
      db.perform_sync
    end
    
    desc "Pushes the current environment's database to the remote production database"
    task :push do
      answer = Capistrano::CLI.ui.ask("Are you sure? This will replace your remote database by the local one (#{local_database_name}) (yes/no)") do |q|
        q.default = "no"
        q.validate = %r%(yes|no)%
      end
      abort unless answer == "yes"
      
      set :sync_method, :push
      db.perform_sync
    end
  end
  
end