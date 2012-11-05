# Capistrano Unicorn

Capistrano plugin that integrates Unicorn tasks into capistrano deployment script.

## Installation

```
gem install capistrano-unicorn
```

## Usage

Add the gem to your ```Gemfile```:

```ruby
group :development do
  gem 'capistrano-unicorn', :require => false
end
```

Add unicorn plugin into your deploy.rb file.

**NOTE:** Should be placed after all hooks

```ruby
require 'capistrano-unicorn'
```

This should add a unicorn server start task after ```deploy:restart```.

Unicorn configuration file should be placed under ```config/unicorn/YOUR_ENV.rb``` -
see [```examples/rails3.rb```](https://github.com/sosedoff/capistrano-unicorn/blob/master/examples/rails3.rb) for an example.

To test if it works type:

```
cap unicorn:start
cap unicorn:stop
cap unicorn:reload
```

**NOTE:** This plugin uses bundler.

## Configuration options

- ```unicorn_env``` - Set unicorn environment. Default to ```rails_env``` variable.
- ```unicorn_pid``` - Set unicorn PID file path. Default to ```current_path/tmp/pids/unicorn.pid```
- ```unicorn_bin``` - Set unicorn executable file. Default to ```unicorn```.

## Unicorn Tasks

To get a list of all capistrano tasks, run `cap -T`:

```
cap unicorn:add_worker                # Add a new worker
cap unicorn:remove_worker             # Remove amount of workers
cap unicorn:reload                    # Reload Unicorn
cap unicorn:restart                   # Restart Unicorn
cap unicorn:shutdown                  # Immediately shutdown Unicorn
cap unicorn:start                     # Start Unicorn master process
cap unicorn:stop                      # Stop Unicorn
```

## License

Copyright (c) 2011-2012 Dan Sosedoff.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
