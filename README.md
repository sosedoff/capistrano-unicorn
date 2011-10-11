# Capistrano Unicorn

Capistrano plugin that integrates Unicorn tasks into deployment script.

## Installation

```
gem install capistrano-unicorn
```

## Usage

Add the gem to your ```Gemfile```:

```ruby
group :development do
  gem 'capistrano-unicorn'
end
```

Add unicorn plugin into your deploy.rb file.

**NOTE:** Should be placed after all hooks

```ruby
require 'capistrano-unicorn'
```

Place configuration file into ```config/unicorn/YOUR_ENV.rb```

To test if it works type:

```
cap unicorn:start
cap unicorn:stop
cap unicorn:reload
```

## Configuration options

- unicorn_env &mdash; Set unicorn environment. Default to "rails_env" variable.
- unicorn_pid &mdash; Set unicorn PID file path. Default to "current_path/tmp/pids/unicorn.pid"

## License

Copyright © 2011 Dan Sosedoff.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.