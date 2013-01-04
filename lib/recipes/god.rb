Capistrano::Configuration.instance.load do

  _cset :god_dir,           "/home/deployer/God"
  _cset :god_confs_prefix,  "#{god_dir}/conf"
  _cset :god_master_conf,   "#{god_dir}/main.god"
  
  # The god config template for the thin process
  _cset :god_thin_template,      File.join(templates_path, "thin.god.erb")
  _cset :god_thin_conf_filename, "#{application}_thin.god"
  _cset :god_thin_conf_file,     File.join(config_path, god_thin_conf_filename)
  _cset :god_thin_conf_symlink,  File.join(god_confs_prefix, god_thin_conf_filename)
  
  # The god config template for the delayed_job process
  _cset :god_delayed_job_template,      File.join(templates_path, "delayed_job.god.erb")
  _cset :god_delayed_job_conf_filename, "#{application}_delayed_job.god"
  _cset :god_delayed_job_conf_file,     File.join(config_path, god_delayed_job_conf_filename)
  _cset :god_delayed_job_conf_symlink,  File.join(god_confs_prefix, god_delayed_job_conf_filename)
  
  namespace :god do
    
    task :start_monitoring, :roles => :app do
      rbenv_sudo "god monitor #{application}"
    end
    
    task :stop_monitoring, :roles => :app do
      rbenv_sudo "god unmonitor #{application}"
    end
    
    task :restart_monitoring, :roles => :app do
      stop_monitoring
      start_monitoring
    end
    
    task :reload, :roles => :app do
      stop_monitoring
      rbenv_sudo "god load #{god_master_conf}"
      start_monitoring if is_using_god 
    end
    
    task :setup, :roles => :app do
      # Nothing specific to god itself to setup
    end

    task :clean_setup, :roles => :app do
      # Nothing specific to god itself to clean
    end
    
    desc <<-EOF
    Setup god monitoring for app server thin
    EOF
    task :setup_app_server_thin, :roles => :app do
      generate_config(god_thin_template, god_thin_conf_file)
      
      # Symlinks it to god's confs dir
      run "unlink #{god_thin_conf_symlink}; true"
      run "ln -s #{god_thin_conf_file} #{god_thin_conf_symlink}"
    end
  
    desc <<-EOF
    Clean setup god monitoring for app server thin
    EOF
    task :clean_setup_app_server_thin, :roles => :app do
      run "unlink #{god_thin_conf_symlink}; true"
      # forcing continue, even if unlink fails (generally because no link)

      run "rm -f #{god_thin_conf_file}"
    end
    
    desc <<-EOF
    Setup god monitoring for background processor delayed_job
    EOF
    task :setup_background_processor_delayed_job, :roles => :app do
      generate_config(god_delayed_job_template, god_delayed_job_conf_file)

      # Symlinks it to god's confs dir
      run "unlink #{god_delayed_job_conf_symlink}; true"
      run "ln -s #{god_delayed_job_conf_file} #{god_delayed_job_conf_symlink}"
    end
  
    desc <<-EOF
    Clean setup god monitoring for background processor delayed_job
    EOF
    task :clean_setup_background_processor_delayed_job, :roles => :app do
      run "unlink #{god_delayed_job_conf_symlink}; true"
      # forcing continue, even if unlink fails (generally because no link)
      
      run "rm -f #{god_delayed_job_conf_file}"
    end
  end
  
  # HOOKS
  after 'thin:clean_setup',         "god:clean_setup_app_server_thin"
  after 'delayed_job:clean_setup',  "god:clean_setup_background_processor_delayed_job"
  if is_using_god
    after 'thin:setup',             "god:setup_app_server_thin"
    after 'delayed_job:setup',      "god:setup_background_processor_delayed_job"
  end
end