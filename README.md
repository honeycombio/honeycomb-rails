# honeycomb-rails [![Build Status](https://travis-ci.org/honeycombio/honeycomb-rails.svg?branch=master)](https://travis-ci.org/honeycombio/honeycomb-rails) [![Gem Version](https://badge.fury.io/rb/honeycomb-rails.svg)](https://badge.fury.io/rb/honeycomb-rails)

Easily instrument your Rails apps with [Honeycomb](https://honeycomb.io).

Requires Ruby 2.2+ and Rails 3+.  Sign up for a [Honeycomb trial](https://ui.honeycomb.io/signup) to obtain an API key before starting.

## Getting started

Add the following to your Gemfile:

```ruby
gem 'honeycomb-rails'
```

Then create a file in your application repo called `config/initializers/honeycomb.rb` with the following contents:

```ruby
HoneycombRails.configure do |conf|
  conf.writekey = 'your honeycomb API key here'
  conf.dataset = 'your app name'
  conf.db_dataset = 'your app name-activerecord'
end
```

Now check out our [guide](https://honeycomb.io/docs/guides/rails/) to see what kind of visibility you can get from your app.

## Configuration

See [docs](http://www.rubydoc.info/gems/honeycomb-rails/HoneycombRails/Config) for available config options.

## Documentation

See [rubydoc](http://www.rubydoc.info/gems/honeycomb-rails/) for gem documentation.

## Contributions

Features, bug fixes and other changes are gladly accepted. Please
open issues or a pull request with your change. Remember to add your name to the
CONTRIBUTORS file!

All contributions will be released under the Apache License 2.0.

### Releasing a new version

Travis will automatically upload tagged releases to Rubygems. To release a new
version, run
```
rake bump:patch[tag]   # Or rake bump:minor[tag], etc.
git push --follow-tags
```
