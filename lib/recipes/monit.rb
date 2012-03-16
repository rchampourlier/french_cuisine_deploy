Capistrano::Configuration.instance.load do

  _cset :monit_conf_prefix, "/etc/monit/conf.d"
  
  if is_using_monit
    if is_using_thin
      # The monit config template for the thin process.
      _cset :thin_monit_template,          File.join(templates_path, "monit_thin.conf.erb")
      _cset :thin_monit_conf_name,         "monit_thin_#{application}.conf"
      _cset :thin_monit_conf,              "#{monit_conf_prefix}/#{thin_monit_conf_name}"

    elsif is_using_unicorn
      # The monit config template for the unicorn process. Expected in /vendor/monit_unicorn.conf.erb
      _cset :unicorn_monit_template,          File.join(templates_path, "monit_unicorn.conf.erb")
      _cset :unicorn_monit_conf_prefix,       monit_conf_prefix
      _cset :unicorn_monit_conf_name,         "monit_unicorn_#{application}.conf"
      _cset :unicorn_monit_conf_path,         "#{unicorn_monit_conf_prefix}/#{unicorn_monit_conf_name}"
    end
  end
  
  task :setup, :roles => :app , :except => { :no_release => true } do
    if is_using_thin
      # Adds the monit config file for thin
      generate_config(monit_thin_template, "#{shared_path}/#{thin_monit_conf_name}")
      sudo "mv #{shared_path}/#{thin_monit_conf_name} #{thin_monit_conf}"
      sudo "chown root:root #{thin_monit_conf}"
      sudo "chmod 0644 #{thin_monit_conf}"
    end
  end
  
  task :clean_setup, :roles => :app , :except => { :no_release => true } do
    if is_using_thin
      # Remove the monit conf file if needed
      sudo "rm #{thin_monit_conf_path}"
    end
  end
end