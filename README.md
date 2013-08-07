# Capistrano Unicorn

Capistrano plugin that integrates Unicorn tasks into capistrano deployment script.

## Installation

Install library from rubygems:

```
gem install capistrano-unicorn
```

## Usage

### Setup

Add the library to your `Gemfile`:

```ruby
group :development do
  gem 'capistrano-unicorn', :require => false
end
```

And load it into your deployment script `config/deploy.rb`:

```ruby
require 'capistrano-unicorn'
```

Add unicorn setup task hook:

```ruby
after 'deploy:setup', 'unicorn:setup'   # Needed if you've configured Unicorn to use a UNIX Socket file.
```

Add unicorn restart task hook:

```ruby
after 'deploy:restart', 'unicorn:reload' # app IS NOT preloaded
after 'deploy:restart', 'unicorn:restart'  # app preloaded
```

Add unicorn shared sockets hook:

```ruby
after 'deploy:finalize_update', 'unicorn:link_socket_dir' # Needed if you've configured Unicorn to use a UNIX Socket file
```

Create a new configuration file `config/unicorn.rb` or `config/unicorn/STAGE.rb`, where stage is your deployment environment.

Example config - [examples/rails3.rb](https://github.com/sosedoff/capistrano-unicorn/blob/master/examples/rails3.rb). Please refer to unicorn documentation for more examples and configuration options.

### Test

First, make sure you're running the latest release:

```
cap deploy
```

Then you can test each individual task:

```
cap unicorn:start
cap unicorn:stop
cap unicorn:reload
```

## Configuration

You can modify any of the following options in your `deploy.rb` config.

- `unicorn_env`               - Set unicorn environment. Default to `rails_env` variable.
- `unicorn_pid`               - Set unicorn PID file path. Default to `current_path/tmp/pids/unicorn.pid`
- `unicorn_bin`               - Set unicorn executable file. Default to `unicorn`.
- `unicorn_bundle`            - Set bundler command for unicorn. Default to `bundle`.
- `unicorn_user`              - Launch unicorn master as the specified user. Default to `user` variable.
- `unicorn_roles`             - Define which roles to perform unicorn recpies on. Default to `:app`.
- `unicorn_config_path`       - Set the directory where unicorn config files reside. Default to `current_path/config`.
- `unicorn_config_filename`   - Set the filename of the unicorn config file. Not used in multistage installations. Default to `unicorn.rb`.
- `unicorn_shared_socket_dir` - Set the shared socket path where the unicorn sockets should live. Default to `shared_path/sockets`. 

### Multistage

If you are using capistrano multistage, please refer to [Using capistrano unicorn with multistage environment](https://github.com/sosedoff/capistrano-unicorn/wiki/Using-capistrano-unicorn-with-multistage-environment).

## Available Tasks

To get a list of all capistrano tasks, run `cap -T`:

```
cap unicorn:add_worker                # Add a new worker
cap unicorn:remove_worker             # Remove amount of workers
cap unicorn:reload                    # Reload Unicorn
cap unicorn:restart                   # Restart Unicorn
cap unicorn:shutdown                  # Immediately shutdown Unicorn
cap unicorn:start                     # Start Unicorn master process
cap unicorn:stop                      # Stop Unicorn
cap unicorn:setup                     # Setup the project (i.e. create the shared sockets directory)
cap unicorn:link_socket_dir           # Link the shared sockets directory to tmp/sockets
```

## License

See LICENSE file for details.
