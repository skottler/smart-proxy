source 'http://rubygems.org'

gem 'sinatra'
gem 'json'


Dir["#{File.dirname(__FILE__)}/bundler.d/*.rb"].each do |bundle|
  self.instance_eval(Bundler.read_file(bundle))
end
