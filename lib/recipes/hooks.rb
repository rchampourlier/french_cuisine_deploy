# Common hooks for all scenarios.
Capistrano::Configuration.instance.load do
  
  after 'deploy:setup' do
    bundler.setup
    app.setup_shared_dirs
  end
end