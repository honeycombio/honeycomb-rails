Gem::Specification.new do |gem|
  gem.name = 'honeycomb-rails'
  gem.version = '0.0.1'

  gem.summary = 'TOSUMMARISE'
  gem.description = <<-DESC
TODESCRIBE
  DESC

  gem.authors = ['Sam Stokes', 'Christine Yen']
  gem.email = %w(sam@honeycomb.io)
  gem.homepage = 'https://github.com/honeycombio/honeycomb-rails'
  gem.license = 'MIT'


  gem.add_dependency 'libhoney', '>= 1.3.2'
  gem.add_dependency 'rails', '>= 3.0.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'yard'
  # override the version requirement just for development: we want the testing
  gem.add_development_dependency 'libhoney', '>= 1.4.0'


  gem.required_ruby_version = '>= 2.0.0'


  gem.files = Dir[*%w(
      lib/**/*
      README*)] & %x{git ls-files -z}.split("\0")
end
