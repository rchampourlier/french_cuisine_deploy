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

  _cset :thin_conf_template,              File.join(templates_path, "thin.yml.erb")
  
  # Used to build thin startup scripts.
  _cset :thin_startup_script_template,    File.join(templates_path, "thin_startup_script.erb")
  _cset :thin_startup_script_name,        "thin_#{application}"
  _cset :thin_startup_script_path,        "#{startup_script_prefix}/#{thin_startup_script_name}"
  _cset :thin_runlevels,                  "2 3 4 5"
  _cset :thin_stoplevels,                 "0 1 6"
  _cset :thin_startorder,                 "21"
  _cset :thin_killorder,                  "19"
  
  # Thin deployment tasks
  namespace :thin do
    desc "Starts thin directly"
    task :start, :roles => :app do
      run "cd #{current_path} && bundle exec #{thin_binary} -C #{thin_config} start"
    end

    desc "Stops thin directly"
    task :stop, :roles => :app, :on_error => :continue do
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

      unless process_monitor_manages_app_server
        # Generate the startup script and move it to the init.d dir (or any other directory specified
        # by :startup_script_prefix). Also set the correct rights.
        generate_config(thin_startup_script_template, "#{shared_path}/#{thin_startup_script_name}")
        sudo "mv #{shared_path}/#{thin_startup_script_name} #{thin_startup_script_path}"
        sudo "chown root:root #{thin_startup_script_path}"
        sudo "chmod 0755 #{thin_startup_script_path}"

        # Position the script for loading at server's boot.
        sudo "update-rc.d #{thin_startup_script_name} start #{thin_startorder} #{thin_runlevels} . stop #{thin_killorder} #{thin_stoplevels} ."
      end
    end
    
    
    desc <<-EOF
    Clean the setup files: config, startup script, process monitor conf file.
    EOF
    task :clean_setup, :roles => :app do
      
      # Remove the startup script
      sudo "rm -f #{thin_startup_script_path}"
      
      # Un-position from startup services
      sudo "update-rc.d #{thin_startup_script_name} remove"
    end # task :clean_setup
    
  end

end