# TASKS
# nginx.setup
# nginx.clean_setup
# nginx.reload
# nginx.restart
# nginx.start
# nginx.stop
# nginx.status
Capistrano::Configuration.instance.load do
  
  # nginx _csetup
  _cset :host_confs_prefix,  "/etc/nginx"
  _cset :app_port,          80
  _cset :app_uses_ssl,      false
  _cset :app_port_ssl,      443
  
  # The nginx template to be parsed by erb. By default, the recipe will use the
  # generators/nginx_host_file.ltd.erb default file. You can configure most of it
  # through deployment variables, however you can also copy the template in your
  # project's directory and set the :nginx_template variable to your own template's
  # path, so that it can be used to configure your nginx server.
  # This is particularly useful when you need project-specific configuration (such
  # as specific assets routing, SSL configuration, etc.)
  _cset :nginx_template,          File.join(templates_path, "nginx_host_file.ltd.erb")
  _cset :nginx_host_config_name,  "#{application}.tld"
  _cset :nginx_host_config,       "#{config_path}/#{nginx_host_config_name}"
  
  # Nginx tasks are not *nix agnostic, they assume you're using Debian/Ubuntu.
  # Override them as needed.
  namespace :nginx do
    
    desc <<-EOF
    Regenerates the nginx configuration file for the app, uploads it and
    reload nginx so that it takes the new configuration.
    EOF
    task :reload_setup, :roles => :web do
      _aset :server_name
      generate_config(nginx_template, nginx_host_config)
      reload
    end
    
    desc "Parses and uploads nginx configuration for this app"
    task :setup, :roles => :web , :except => { :no_release => true } do
      _aset :server_name
      generate_config(nginx_template, nginx_host_config)
      sudo "ln -sf #{nginx_host_config} #{host_confs_prefix}/sites-available/"
      sudo "ln -sf #{nginx_host_config} #{host_confs_prefix}/sites-enabled/"
    end
    
    desc "Remove the nginx configuration file for this app"
    task :clean_setup, :roles => :web do
      sudo "rm -f #{host_confs_prefix}/sites-available/#{nginx_host_config_name}"
      sudo "rm -f #{host_confs_prefix}/sites-enabled/#{nginx_host_config_name}"
      run "rm -f #{nginx_host_config}"
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
