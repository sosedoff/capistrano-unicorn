# Capistrano Unicorn

Capistrano plugin that integrates Unicorn tasks into capistrano deployment script.

**Developers:** Please consider contributing your forked changes, or opening an
issue if there is no existing relevant one. There are a lot of forks--we'd love
to reabsorb some of the issues/solutions the community has encountered.

[![Build Status](https://travis-ci.org/sosedoff/capistrano-unicorn.png?branch=master)](https://travis-ci.org/sosedoff/capistrano-unicorn)
[![Gem Version](https://badge.fury.io/rb/capistrano-unicorn.png)](http://badge.fury.io/rb/capistrano-unicorn)
[![Code Climate](https://codeclimate.com/github/sosedoff/capistrano-unicorn.png)](https://codeclimate.com/github/sosedoff/capistrano-unicorn)

## Usage

If you are upgrading from a previous version, please see the [NEWS file](NEWS.md).

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

Add unicorn restart task hook:

```ruby
after 'deploy:restart', 'unicorn:reload'    # app IS NOT preloaded
after 'deploy:restart', 'unicorn:restart'   # app preloaded
after 'deploy:restart', 'unicorn:duplicate' # before_fork hook implemented (zero downtime deployments)
```

Create a new configuration file `config/unicorn.rb` or `config/unicorn/STAGE.rb`, 
where stage is your deployment environment.

Example config - [examples/rails3.rb](https://github.com/sosedoff/capistrano-unicorn/blob/master/examples/rails3.rb). 
Please refer to Unicorn documentation for more examples and configuration options.

### Deploy

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

You can modify any of the following Capistrano variables in your `deploy.rb` config.
You can use the `unicorn:show_vars` task to check that the values you have specified
are set correctly.

### Environment parameters

- `unicorn_env`             - Set basename of unicorn config `.rb` file to be used loaded from `unicorn_config_path`. Defaults to `rails_env` variable if set, otherwise `production`.
- `unicorn_rack_env`        - Set the value which will be passed to unicorn via [the `-E` parameter as the Rack environment](http://unicorn.bogomips.org/unicorn_1.html). Valid values are `development`, `deployment`, and `none`. Defaults to `development` if `rails_env` is `development`, otherwise `deployment`.

### Execution parameters

- `unicorn_user`            - Launch unicorn master as the specified user via `sudo`. Defaults to `nil`, which means no use of `sudo`, i.e. run as the user defined by the `user` variable.
- `unicorn_roles`           - Define which roles to perform unicorn recipes on. Defaults to `:app`.
- `unicorn_bundle`          - Set bundler command for unicorn. Defaults to `bundle`.
- `unicorn_bin`             - Set unicorn executable file. Defaults to `unicorn`.
- `unicorn_options`         - Set any additional options to be passed to unicorn on startup.
- `unicorn_restart_sleep_time` - Number of seconds to wait for (old) pidfile to show up when restarting unicorn. Defaults to 2.

### Relative path parameters

- `app_subdir`              - If your app lives in a subdirectory 'rails' (say) of your repository, set this to `/rails` (the leading slash is required).
- `unicorn_config_rel_path` - Set the directory path (relative to `app_path` - see below) where unicorn config files reside. Defaults to `config`.
- `unicorn_config_filename` - Set the filename of the unicorn config file loaded from `unicorn_config_path`. Should not be present in multistage installations. Defaults to `unicorn.rb`.

### Absolute path parameters

- `app_path`                - Set path to app root. Defaults to `current_path + app_subdir`.
- `unicorn_pid`             - Set unicorn PID file path. By default, attempts to auto-detect from unicorn config file. On failure, falls back to value in `unicorn_default_pid`
- `unicorn_default_pid`     - See above. Defaults to `#{current_path}/tmp/pids/unicorn.pid`
- `bundle_gemfile`          - Set path to Gemfile. Defaults to `#{app_path}/Gemfile`
- `unicorn_config_path`     - Set the directory where unicorn config files reside. Defaults to `#{current_path}/config`.

### Zero Downtime Deployment Options

* `unicorn:restart`: :-1: This can sort of support it with a configurable timeout, which may not be reliable.
* `unicorn:reload`: :question: Can anyone testify to its zero-downtime support?
* `unicorn:duplicate`: :+1: If you install the Unicorn `before_fork` hook, then yes! See: https://github.com/sosedoff/capistrano-unicorn/issues/40#issuecomment-16011353

## Available Tasks

To get a list of all capistrano tasks, run `cap -T`:

```
cap unicorn:add_worker                # Add a new worker
cap unicorn:remove_worker             # Remove amount of workers
cap unicorn:reload                    # Reload Unicorn
cap unicorn:restart                   # Restart Unicorn
cap unicorn:show_vars                 # Debug Unicorn variables
cap unicorn:shutdown                  # Immediately shutdown Unicorn
cap unicorn:start                     # Start Unicorn master process
cap unicorn:stop                      # Stop Unicorn
```

## Tests

To execute test suite run:

```
bundle exec rake test
```

### Multistage

The issue here is that capistrano loads default configuration and then
executes your staging task and overrides previously defined
variables. The default environment before executing your stage task is
set to `:production`, so it will use a wrong environment unless you
take steps to ensure that `:rails_env` and `:unicorn_env` are
set correctly.

Let's say you have a scenario involving two deployment stages: staging
and production.  You’ll need to add `config/deploy/staging.rb` and
`config/deploy/production.rb` files.  However, it makes sense to
adhere to DRY and avoid duplicating lines between the two files.  So
it would be nicer to keep common settings in `config/deploy.rb`, and
only put stuff in each staging definition file which is really
specific to that staging environment.  Fortunately this can be done
using the [lazy evaluation form of `set`](https://github.com/capistrano/capistrano/wiki/2.x-DSL-Configuration-Variables-Set).

So `config/deploy.rb` file would contain something like:

```ruby
set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

set(:unicorn_env) { rails_env }

role(:web) { domain }
role(:app) { domain }
role(:db, :primary => true) { domain }

set(:deploy_to)    { "/home/#{user}/#{application}/#{fetch :rails_env}" }
set(:current_path) { File.join(deploy_to, current_dir) }
```

Then `config/deploy/production.rb` would contain something like:

```ruby
set :domain,      "app.mydomain.com"
set :rails_env,   "production"
```

and `config/deploy/staging.rb` would only need to contain something like:

```ruby
set :domain,      "app.staging.mydomain.com"
set :rails_env,   "staging"
```

Nice and clean!

## License

See LICENSE file for details.
