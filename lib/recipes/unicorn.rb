Capistrano::Configuration.instance.load do

  # Unicorn setup
  
  # The wrapped bin to start unicorn. This is necessary because we're using rvm.
  _cset :unicorn_binary,      "unicorn_rails"

  _cset :unicorn_config,      "#{config_path}/unicorn.rb"
  _cset :unicorn_pid,         "#{pids_path}/unicorn.pid"      # Defines where the unicorn pid will live.
  _cset :unicorn_socket,      "#{sockets_path}/unicorn.sock"

  _cset :unicorn_workers,     4 unless exists?(:unicorn_workers)

  # Workers timeout in the amount of seconds below, when the master kills it and
  # forks another one.
  _cset :unicorn_workers_timeout, 30 unless exists?(:unicorn_workers_timeout)

  # Workers are started with this user/group
  # By default we get the user/group set in capistrano.
  set(:unicorn_user) { user }   unless exists?(:unicorn_user)
  set(:unicorn_group) { group } unless exists?(:unicorn_group)

  # The unicorn template to be parsed by erb. You must copy this file to your app's vendor directory
  # (vendor/unicorn_template.rb.erb). Capistrano will search it locally, so you don't need to track it
  # in git. However, it may be helpful to have in there so anybody can use it to deploy.
  _cset :unicorn_template,                File.join(templates_path, "unicorn.rb.erb")
  _cset :unicorn_startup_script_template, File.join(templates_path, "unicorn_startup_script.erb")
  _cset :startup_script_prefix,           "/etc/init.d"
  _cset :startup_script_name,             "unicorn_#{application}"
  _cset :startup_script_path,             "#{startup_script_prefix}/#{startup_script_name}"
  _cset :unicorn_runlevels,               "2 3 4 5"
  _cset :unicorn_stoplevels,              "0 1 6"
  _cset :unicorn_startorder,              "21"
  _cset :unicorn_killorder,               "19"

  # The monit config template for the unicorn process. Expected in /vendor/monit_unicorn.conf.erb
  _cset :monit_unicorn_template,          File.join(templates_path, "monit_unicorn.conf.erb")
  _cset :monit_conf_prefix,               "/etc/monit/conf.d"
  _cset :monit_unicorn_conf_name,         "unicorn_#{application}.conf"
  _cset :monit_unicorn_conf,              "#{monit_conf_prefix}/#{monit_unicorn_conf_name}"

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
      generate_config(unicorn_startup_script_template, "#{shared_path}/#{startup_script_name}")
      sudo "mv #{shared_path}/#{startup_script_name} #{startup_script_path}"
      sudo "chown root:root #{startup_script_path}"
      sudo "chmod 0755 #{startup_script_path}"

      # Position the script for loading at server's boot.
      sudo "update-rc.d #{startup_script_name} start #{unicorn_startorder} #{unicorn_runlevels} . stop #{unicorn_killorder} #{unicorn_stoplevels} ."

      # Adds the monit config file for this process.
      generate_config(monit_unicorn_template, "#{shared_path}/#{monit_unicorn_conf_name}")
      sudo "mv #{shared_path}/#{monit_unicorn_conf_name} #{monit_unicorn_conf}"
      sudo "chown root:root #{monit_unicorn_conf}"
      sudo "chmod 0644 #{monit_unicorn_conf}"
    end
  end

end