module FrenchCuisineDeploy; end

$:.unshift File.expand_path("..", __FILE__)
require 'capistrano'
require 'capistrano/cli'
require 'helpers'
require 'bundler/capistrano'

Dir[File.expand_path('../recipes/**/*.rb', __FILE__)].each { |f| require f }