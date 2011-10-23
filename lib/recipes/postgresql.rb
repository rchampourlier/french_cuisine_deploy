Capistrano::Configuration.instance.load do

  # PostgreSQL
  namespace :postgresql do
    
    desc "Setups PostgreSQL database for new application"
    task :prerequisites, :roles => :db do
      puts "### Connect on server as 'deployer' user and run:"
      puts "### sudo -s -u postgres (you will be requested your 'deployer' password)"
      puts "### createuser -SDR #{application} (you will be requested your 'postgres' db user password)"
      puts "### psql -d template1 -c \"alter user #{application} with password 'choose_a_password'\""
      puts "### createdb -O #{application} -E UTF8 #{application}_production (you will be requested your 'postgres' db user password)"
    end
    
  end
  
end