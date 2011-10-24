Capistrano::Configuration.instance.load do

  # RVM gemset
  namespace :rvm do
    
    desc "Setups RVM gemset for new application"
    task :prerequisites, :roles => :app do
      puts "### Connect on server as '#{user}' user and run:"
      puts "### rvm use #{(rvm_ruby_string.match(%r%^.*@%).to_s)[0..-2]}"
      puts "### rvm gemset create #{(rvm_ruby_string.match(%r%^.*@%).post_match)}"
    end
    
    desc 'Trust rvmrc file'
    task :trust_rvmrc do
      run "rvm rvmrc trust #{current_release}"
      run "rvm rmcrc trust #{current_path}"
      # We have to trust both, if we want to use both when performing actions with Capistrano.
    end
  end
  
end