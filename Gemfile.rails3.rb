source 'https://rubygems.org'

gemspec

# pull in newer libhoney just for testing, since we need TestClient#reset
gem 'libhoney', '>= 1.5.1'

gem 'rails', '< 4'
