module FrenchCuisineDeploy
end

$:.unshift File.expand_path("..", __FILE__)
require 'capistrano'
require 'capistrano/cli'
require 'helpers'
require 'bundler/capistrano'

Dir.glob(File.join(File.dirname(__FILE__), '/recipes/*.rb')).sort.each { |f| load f }