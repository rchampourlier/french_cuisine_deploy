Capistrano::Configuration.instance.load do
  
  # From http://henriksjokvist.net/archive/2012/2/deploying-with-rbenv-and-capistrano/
  # We want Bundler to handle our gems and we want it to package everything locally with the app.
  # The --binstubs flag means any gem executables will be added to <app>/bin and the
  # --shebang ruby-local-exec option makes sure we'll use the ruby version defined in the
  # .rbenv-version in the app root. Note that he --shebang flag requires Bundler 1.1.

  if using_rbenv
    set :bundle_flags, "--deployment --quiet --binstubs --shebang ruby-local-exec"
    set :default_environment, {
      'PATH' => "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
    }
  end
  
end