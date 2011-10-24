Capistrano::Configuration.instance.load do

  # RVM gemset
  namespace :rvm do
    
    desc "Setups RVM gemset for new application"
    task :prerequisites, :roles => :app do
      puts "### Connect on server as '#{user}' user and run:"
      puts "### rvm use #{(rvm_ruby_string.match(%r%^.*@%).to_s)[0..-2]}"
      puts "### rvm gemset create #{(rvm_ruby_string.match(%r%^.*@%).post_match)}"
    end
    
  end
  
end