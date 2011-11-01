# Manage application's maintenance state.
# 
# Tasks:
#  - cap maintenance:on
#  - cap maintenance:off
#
# Generate the maintenance.html file and copy it to the server. Matches web server
# configuration so that it will automatically redirect all requests to the maintenance
# page.
#
# To provide a custom maintenance.html template (ERB), set the 'maintenance_template_path'
# variable to the template's local file's path.
Capistrano::Configuration.instance.load do

  # Maintenance page
  _cset :shared_system_path,        File.join(shared_path, 'system')
  _cset :maintenance_page_path,     File.join(shared_system_path, 'maintenance.html')
  _cset :maintenance_template_path, File.join(templates_path, "maintenance.html.erb")

  namespace :maintenance do

    task :on, :roles => :app do
      on_rollback do
        run "rm -f #{maintenance_page_path}"
      end
      generate_config(maintenance_template_path, maintenance_page_path)
      run "chmod 0644 #{maintenance_page_path}"
    end
    
    task :off, :roles => :app do
      on_rollback { maintenance:on }
      run "rm -f #{maintenance_page_path}"
    end
    
  end # namespace :maintenance
  
end