lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH << lib unless $LOAD_PATH.include?(lib)
require 'honeycomb-rails/version'

Gem::Specification.new do |gem|
  gem.name = HoneycombRails::GEM_NAME
  gem.version = HoneycombRails::VERSION

  gem.summary = 'Easily instrument your Rails apps with Honeycomb'
  gem.description = <<-DESC
    Get fine-grained visibility into the behavior and performance of your
    Rails web app. This gem instruments your app to send events to Honeycomb
    (https://honeycomb.io) each time it processes an HTTP request or makes a
  database query.
  DESC

  gem.authors = ['Sam Stokes', 'Christine Yen']
  gem.email = %w(sam@honeycomb.io)
  gem.homepage = 'https://github.com/honeycombio/honeycomb-rails'
  gem.license = 'MIT'


  gem.add_dependency 'libhoney', '>= 1.8.1'
  gem.add_dependency 'rails', '>= 3.0.0'

  gem.add_development_dependency 'bump'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rspec-rails'
  gem.add_development_dependency 'yard'


  gem.required_ruby_version = '>= 2.0.0'


  gem.files = Dir[*%w(
      lib/**/*
      README*)] & %x{git ls-files -z}.split("\0")
end
