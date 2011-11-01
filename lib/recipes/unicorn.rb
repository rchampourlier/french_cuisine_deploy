Capistrano::Configuration.instance.load do

  # Unicorn setup
  
  # The wrapped bin to start unicorn. This is necessary because we're using rvm.
  _cset :unicorn_binary,      "unicorn_rails"

  _cset :unicorn_config,      "#{config_path}/unicorn.rb"
  _cset :unicorn_pid,         "#{pids_path}/unicorn.pid"      # Defines where the unicorn pid will live.
  _cset :unicorn_socket,      "#{sockets_path}/unicorn.sock"

  _cset :unicorn_workers,         workers

  # Workers timeout in the amount of seconds below, when the master kills it and
  # forks another one.
  _cset :unicorn_workers_timeout, workers_timeout

  # Workers are started with this user/group
  # By default we get the user/group set in capistrano.
  set(:unicorn_user) { user }   unless exists?(:unicorn_user)
  set(:unicorn_group) { group } unless exists?(:unicorn_group)

  # The unicorn template to be parsed by erb. You must copy this file to your app's vendor directory
  # (vendor/unicorn_template.rb.erb). Capistrano will search it locally, so you don't need to track it
  # in git. However, it may be helpful to have in there so anybody can use it to deploy.
  _cset :unicorn_template,                File.join(templates_path, "unicorn.rb.erb")
  _cset :unicorn_startup_script_template, File.join(templates_path, "unicorn_startup_script.erb")
  _cset :unicorn_startup_script_name,     "unicorn_#{application}"
  _cset :unicorn_startup_script_path,     "#{startup_script_prefix}/#{unicorn_startup_script_name}"
  _cset :unicorn_runlevels,               "2 3 4 5"
  _cset :unicorn_stoplevels,              "0 1 6"
  _cset :unicorn_startorder,              "21"
  _cset :unicorn_killorder,               "19"

  if process_monitorer == :monit
    # The monit config template for the unicorn process. Expected in /vendor/monit_unicorn.conf.erb
    _cset :unicorn_monit_template,          File.join(templates_path, "monit_unicorn.conf.erb")
    _cset :unicorn_monit_conf_prefix,       monit_conf_prefix
    _cset :unicorn_monit_conf_name,         "monit_unicorn_#{application}.conf"
    _cset :unicorn_monit_conf_path,         "#{unicorn_monit_conf_prefix}/#{unicorn_monit_conf_name}"
  end

  # Unicorn deployment tasks
  namespace :unicorn do
    desc "Starts unicorn directly"
    task :start, :roles => :app do
      run "cd #{current_path} && bundle exec #{unicorn_binary} -c #{unicorn_config} -E #{rails_env} -D"
    end

    desc "Stops unicorn directly"
    task :stop, :roles => :app do
      run "#{try_sudo} kill `cat #{unicorn_pid}`"
    end

    desc "Restarts unicorn directly"
    task :restart, :roles => :app do
      run "#{try_sudo} kill -s USR2 `cat #{unicorn_pid}`"
    end

    desc "Gracefully stops unicorn directly"
    task :graceful_stop, :roles => :app, :except => {:no_release => true} do
      run "#{try_sudo} kill -s QUIT `cat #{unicorn_pid}`"
    end

    desc <<-EOF
    Create the unicorn configuration file from the template and \
    uploads the result to #{unicorn_config}, to be loaded by whoever is booting \
    up the unicorn.
    EOF
    task :setup, :roles => :app , :except => { :no_release => true } do
      generate_config(unicorn_template, unicorn_config)

      # Generate the startup script and move it to the init.d dir (or any other directory specified
      # by :startup_script_prefix). Also set the correct rights.
      generate_config(unicorn_startup_script_template, "#{shared_path}/#{unicorn_startup_script_name}")
      sudo "mv #{shared_path}/#{unicorn_startup_script_name} #{unicorn_startup_script_path}"
      sudo "chown root:root #{unicorn_startup_script_path}"
      sudo "chmod 0755 #{unicorn_startup_script_path}"

      # Position the script for loading at server's boot.
      sudo "update-rc.d #{unicorn_startup_script_name} start #{unicorn_startorder} #{unicorn_runlevels} . stop #{unicorn_killorder} #{unicorn_stoplevels} ."

      if process_monitorer == :monit
        # Adds the monit config file for this process.
        generate_config(unicorn_monit_template, "#{shared_path}/#{unicorn_monit_conf_name}")
        sudo "mv #{shared_path}/#{unicorn_monit_conf_name} #{unicorn_monit_conf_path}"
        sudo "chown root:root #{unicorn_monit_conf_path}"
        sudo "chmod 0644 #{unicorn_monit_conf_path}"
      end
    end
    
    desc <<-EOF
    Clean the Unicorn setup files: Unicorn's config, startup script, process monitorer conf file.
    EOF
    task :setup_clean, :roles => :app do
      
      # Remove the startup script
      sudo "rm #{unicorn_startup_script_path}"
      
      # Un-position from startup services
      sudo "update-rc.d #{unicorn_startup_script_name} remove"
      
      if process_monitorer == :monit
        # Remove the monit conf file if needed
        sudo "rm #{unicorn_monit_conf_path}"
      end
      
    end # task :setup_clean
    
  end

end