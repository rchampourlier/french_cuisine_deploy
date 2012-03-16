Capistrano::Configuration.instance.load do
  
  # From http://henriksjokvist.net/archive/2012/2/deploying-with-rbenv-and-capistrano/
  # We want Bundler to handle our gems and we want it to package everything locally with the app.
  # The --binstubs flag means any gem executables will be added to <app>/bin and the
  # --shebang ruby-local-exec option makes sure we'll use the ruby version defined in the
  # .rbenv-version in the app root. Note that he --shebang flag requires Bundler 1.1.

  # This is a hack which runs a uselss command in a sudo to make Capistrano
  # request the password. Since sudo retains the password for some time, thus
  # allowing to run rbenv sudo without needing to enter the password again.
  def rbenv_sudo command
    sudo "echo"
    run "rbenv sudo #{command}"
  end
  
  if is_using_rbenv
    set :bundle_flags, "--deployment --quiet --binstubs --shebang ruby-local-exec"
    set :default_environment, {
      'PATH' => "/home/deployer/.rbenv/shims:/home/deployer/.rbenv/bin:$PATH"
    }
  end
  
end