Capistrano::Configuration.instance.load do
  
  # From http://henriksjokvist.net/archive/2012/2/deploying-with-rbenv-and-capistrano/
  # We want Bundler to handle our gems and we want it to package everything locally with the app.
  # The --binstubs flag means any gem executables will be added to <app>/bin and the
  # --shebang ruby-local-exec option makes sure we'll use the ruby version defined in the
  # .rbenv-version in the app root. Note that he --shebang flag requires Bundler 1.1.

  if is_using_rbenv
    set :bundle_flags, "--deployment --quiet --binstubs --shebang ruby-local-exec"

    case fetch(:rbenv_install)
    when :user
      _cset :rbenv_shims_path, "/home/#{user}/.rbenv/shims"
      _cset :rbenv_bin_path, "/home/#{user}/.rbenv/bin"
    else # :system or else
      _cset :rbenv_shims_path, '/opt/rbenv/shims'
      _cset :rbenv_bin_path, '/opt/rbenv/bin'
    end
    set :rbenv_path, "#{rbenv_shims_path}:#{rbenv_bin_path}"

    existing_environment = fetch(:default_environment) || {}
    existing_path = existing_environment['PATH'] || '$PATH'
    set :default_environment, existing_environment.merge('PATH' => "#{rbenv_path}:#{existing_path}")
  end
end