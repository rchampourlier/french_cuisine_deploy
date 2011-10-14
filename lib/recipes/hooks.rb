# Common hooks for all scenarios.
Capistrano::Configuration.instance.load do
  after 'deploy:setup' do
    app.setup
    bundler.setup
    eval "#{app_server}.setup"
    eval "#{web_server}.setup"
  end
end