if defined?(Rails)
  require 'honeycomb-rails/railtie'
else
  raise LoadError, 'honeycomb-rails requires Rails (maybe you meant libhoney?)'
end
