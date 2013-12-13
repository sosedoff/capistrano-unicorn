module CapistranoUnicorn
  class Config
    def self.load(config)
      config.instance_eval do
        # Environments
        _cset(:unicorn_env)                { fetch(:rails_env, 'production' ) }
        _cset(:unicorn_rack_env) do
          # Following recommendations from http://unicorn.bogomips.org/unicorn_1.html
          fetch(:rails_env) == 'development' ? 'development' : 'deployment'
        end

        # Execution
        _cset(:unicorn_user)               { nil }
        _cset(:unicorn_bundle)             { fetch(:bundle_cmd, "bundle") }
        _cset(:unicorn_bin)                { "unicorn" }
        _cset(:unicorn_options)            { '' }
        _cset(:unicorn_restart_sleep_time) { 2 }

        # Relative paths
        _cset(:app_subdir)                 { '' }
        _cset(:unicorn_config_rel_path)    { "config" }
        _cset(:unicorn_config_filename)    { "unicorn.rb" }
        _cset(:unicorn_config_rel_file_path) \
          { unicorn_config_rel_path + '/' + unicorn_config_filename }
        _cset(:unicorn_config_stage_rel_file_path) \
          { [ unicorn_config_rel_path, 'unicorn',
              "#{unicorn_env}.rb" ].join('/') }

          # Absolute paths
          # If you find the following confusing, try running 'cap unicorn:show_vars' -
          # it might help :-)
          _cset(:app_path)                   { current_path + app_subdir }
          _cset(:bundle_gemfile)             { app_path + '/Gemfile' }
          _cset(:unicorn_config_path)        { app_path + '/' + unicorn_config_rel_path }
          _cset(:unicorn_config_file_path)   { app_path + '/' + unicorn_config_rel_file_path }
          _cset(:unicorn_config_stage_file_path) \
            { app_path + '/' + unicorn_config_stage_rel_file_path }
          _cset(:unicorn_default_pid)        { app_path + "/tmp/pids/unicorn.pid" }
          _cset(:unicorn_pid) { extract_pid_file || unicorn_default_pid }
      end
    end
  end
end
