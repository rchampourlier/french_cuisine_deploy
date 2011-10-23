Capistrano::Configuration.instance.load do
  
  # nginx _csetup
  _cset :host_confs_prefix,  "/etc/nginx"
  _cset :app_port,          80
  _cset :app_uses_ssl,      false
  _cset :app_port_ssl,      443
  
  # The nginx template to be parsed by erb. You must copy this file to your app's vendor directory
  # (vendor/nginx_template.rb.erb). Capistrano will search it locally, so you don't need to track it
  # in git. However, it may be helpful to have in there so anybody can use it to deploy.
  _cset :nginx_template,    File.join(templates_path, "nginx_host_file.ltd.erb")
  _cset :nginx_host_config, "#{config_path}/#{application}.tld"
  
  # Nginx tasks are not *nix agnostic, they assume you're using Debian/Ubuntu.
  # Override them as needed.
  namespace :nginx do
    
    desc "Parses and uploads nginx configuration for this app"
    task :setup, :roles => :web , :except => { :no_release => true } do
      _aset :domain_names
      generate_config(nginx_template, nginx_host_config)
      sudo "ln -sf #{nginx_host_config} #{host_confs_prefix}/sites-available/"
      sudo "ln -sf #{nginx_host_config} #{host_confs_prefix}/sites-enabled/"
      nginx.restart # reload seems not to be sufficient to get new host confs
    end
  
    desc "Parses config file and outputs it to STDOUT (internal task)"
    task :parse, :roles => :web , :except => { :no_release => true } do
      puts parse_config(nginx_template)
    end
  
    desc "Reload nginx. Send the HUP signal to have nginx reload its configuration"
    task :reload, :roles => :web , :except => { :no_release => true } do
      sudo "service nginx reload"
    end
  
    desc "Restart nginx"
    task :restart, :roles => :web , :except => { :no_release => true } do
      sudo "service nginx restart"
    end
  
    desc "Stop nginx"
    task :stop, :roles => :web , :except => { :no_release => true } do
      sudo "service nginx stop"
    end
  
    desc "Start nginx"
    task :start, :roles => :web , :except => { :no_release => true } do
      sudo "service nginx start"
    end
  
    desc "Show nginx status"
    task :status, :roles => :web , :except => { :no_release => true } do
      sudo "service nginx status"
    end
  end
  
end
