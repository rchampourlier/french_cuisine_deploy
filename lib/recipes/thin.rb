Capistrano::Configuration.instance.load do

  # Thin setup
  
  # The wrapped bin to start thin. This is necessary because we're using rvm.
  _cset :thin_binary,         "thin"

  _cset :thin_config,         "#{config_path}/thin.yml"
  _cset :thin_pid,            "#{pids_path}/thin.pid"      # Defines where the thin pid will live.
  _cset :thin_socket,         "#{sockets_path}/thin.sock"
  _cset :thin_log,            "#{log_path}/thin.log"
  
  _cset :thin_workers,            workers

  # Workers timeout in the amount of seconds below, when the master kills it and
  # forks another one.
  _cset :thin_workers_timeout,     workers_timeout

  # Workers are started with this user/group
  # By default we get the user/group set in capistrano.
  _cset(:thin_user)           { user }
  _cset(:thin_group)          { group }

  # The thin template to be parsed by erb. You must copy this file to your app's vendor directory
  # (vendor/thin_template.rb.erb). Capistrano will search it locally, so you don't need to track it
  # in git. However, it may be helpful to have in there so anybody can use it to deploy.
  _cset :thin_conf_template,              File.join(templates_path, "thin.yml.erb")
  _cset :thin_startup_script_template,    File.join(templates_path, "thin_startup_script.erb")
  _cset :thin_startup_script_name,        "thin_#{application}"
  _cset :thin_startup_script_path,        "#{startup_script_prefix}/#{thin_startup_script_name}"
  _cset :thin_runlevels,                  "2 3 4 5"
  _cset :thin_stoplevels,                 "0 1 6"
  _cset :thin_startorder,                 "21"
  _cset :thin_killorder,                  "19"

  if process_monitorer == :monit
    # The monit config template for the thin process. Expected in /vendor/monit_thin.conf.erb
    _cset :thin_monit_template,          File.join(templates_path, "monit_thin.conf.erb")
    _cset :thin_monit_conf_name,         "monit_thin_#{application}.conf"
    _cset :thin_monit_conf,              "#{monit_conf_prefix}/#{thin_monit_conf_name}"
  end

  # Thin deployment tasks
  namespace :thin do
    desc "Starts thin through service"
    task :start, :roles => :app do
      #sudo "service #{thin_startup_script_name} start"
      run "cd #{current_path} && bundle exec #{thin_binary} -C #{thin_config} start"
    end

    desc "Stops thin directly"
    task :stop, :roles => :app do
     #sudo "service #{thin_startup_script_name} stop"
     run "cd #{current_path} && bundle exec #{thin_binary} -C #{thin_config} stop"
    end

    desc "Restarts thin directly"
    task :restart, :roles => :app do
      run "cd #{current_path} && bundle exec #{thin_binary} -C #{thin_config} restart"
    end

    desc <<-EOF
    Create the thin configuration file from the template and \
    uploads the result to #{thin_config}, to be loaded by whoever is booting \
    up the thin.
    EOF
    task :setup, :roles => :app , :except => { :no_release => true } do
      generate_config(thin_conf_template, thin_config)

      # Generate the startup script and move it to the init.d dir (or any other directory specified
      # by :startup_script_prefix). Also set the correct rights.
      generate_config(thin_startup_script_template, "#{shared_path}/#{thin_startup_script_name}")
      sudo "mv #{shared_path}/#{thin_startup_script_name} #{thin_startup_script_path}"
      sudo "chown root:root #{thin_startup_script_path}"
      sudo "chmod 0755 #{thin_startup_script_path}"

      # Position the script for loading at server's boot.
      sudo "update-rc.d #{thin_startup_script_name} start #{thin_startorder} #{thin_runlevels} . stop #{thin_killorder} #{thin_stoplevels} ."

      if process_monitorer == :monit
        # Adds the monit config file for this process.
        generate_config(monit_thin_template, "#{shared_path}/#{thin_monit_conf_name}")
        sudo "mv #{shared_path}/#{thin_monit_conf_name} #{thin_monit_conf}"
        sudo "chown root:root #{thin_monit_conf}"
        sudo "chmod 0644 #{thin_monit_conf}"
      end
    end # task :setup
    
    
    desc <<-EOF
    Clean the setup files: config, startup script, process monitorer conf file.
    EOF
    task :setup_clean, :roles => :app do
      
      # Remove the startup script
      sudo "rm #{thin_startup_script_path}"
      
      # Un-position from startup services
      sudo "update-rc.d #{thin_startup_script_name} remove"
      
      if process_monitorer == :monit
        # Remove the monit conf file if needed
        sudo "rm #{thin_monit_conf_path}"
      end
      
    end # task :setup_clean
    
  end

end