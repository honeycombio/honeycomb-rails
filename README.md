# honeycomb-rails [![Build Status](https://travis-ci.org/honeycombio/honeycomb-rails.svg?branch=master)](https://travis-ci.org/honeycombio/honeycomb-rails) [![Gem Version](https://badge.fury.io/rb/honeycomb-rails.svg)](https://badge.fury.io/rb/honeycomb-rails)

**DEPRECATION NOTICE**: This gem is deprecated, please use [honeycomb-beeline](https://github.com/honeycombio/beeline-ruby) instead.

Ruby gem for sending events from your Rails application to [Honeycomb](https://www.honeycomb.io), a service for debugging your software in production.

Requires Ruby 2.2 or greater and Rails 3 or greater.

- [Usage and Examples](https://docs.honeycomb.io/thinking-about-observability/getting-started-with/rails/)
- [API Reference](https://www.rubydoc.info/gems/honeycomb-rails)

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
