# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "french_cuisine_deploy"
  s.version = "0.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["romain@softr.li"]
  s.date = "2011-10-23"
  s.description = "Rails app deployment recipes for Capistrano"
  s.email = "romain@softr.li"
  s.extra_rdoc_files = [
    "LICENSE",
    "README"
  ]
  s.files = [
    ".project",
    ".rvmrc",
    ".rvmrc.10.14.2011-12:10:24",
    "LICENSE",
    "README",
    "Rakefile",
    "VERSION",
    "example_deploy.rb",
    "french_cuisine_deploy.gemspec",
    "generators/monit_unicorn.conf.erb",
    "generators/nginx_host_file.ltd.erb",
    "generators/thin.yml.erb",
    "generators/thin_startup_script.erb",
    "generators/unicorn.rb.erb",
    "generators/unicorn_startup_script.erb",
    "lib/french_cuisine_deploy.rb",
    "lib/helpers.rb",
    "lib/recipes/application.rb",
    "lib/recipes/bundler.rb",
    "lib/recipes/deploy.rb",
    "lib/recipes/hooks.rb",
    "lib/recipes/monit.rb",
    "lib/recipes/nginx.rb",
    "lib/recipes/postgresql.rb",
    "lib/recipes/rvm.rb",
    "lib/recipes/thin.rb",
    "lib/recipes/unicorn.rb",
    "pkg/french_cuisine_deploy-0.0.1.gem"
  ]
  s.homepage = "http://github.com/rchampourlier/french_cuisine_deploy"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "Rails app deployment recipes for Capistrano"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

