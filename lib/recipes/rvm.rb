Capistrano::Configuration.instance.load do

  # RVM gemset
  namespace :rvm do
    
    desc "Setups RVM gemset for new application"
    task :prerequisites, :roles => :app do
      puts "### Connect on server as '#{user}' user and run:"
      puts "### rvm use #{(rvm_ruby_string.match(%r%^.*@%).to_s)[0..-2]}"
      puts "### rvm gemset create #{(rvm_ruby_string.match(%r%^.*@%).post_match)}"
    end
    
    desc 'Set /etc/rvmrc parameter to trust all projects\' rvmrc files'
    task :setup do
      # If the file /etc/rvmrc contains rvm_trust_rvmrc_flag=0, replace it with rvm_trust_rvmrc_flag=1
      run "sudo sed -e 's/rvm_trust_rvmrc_flag=0/rvm_trust_rvmrc_flag=1/g' /etc/rvmrc > /tmp/etc_rvmrc && sudo mv /tmp/etc_rvmrc /etc/rvmrc"
      # If the file does not contain rvm_trust_rvmrc_flag=, adds it.
      run "! sudo cat /etc/rvmrc | grep "rvm_trust_rvmrc_flag=" && echo "rvm_trust_rvmrc_flag=1" | sudo tee -a /etc/rvmrc"
      # We have to trust both, if we want to use both when performing actions with Capistrano.
    end
  end
  
end