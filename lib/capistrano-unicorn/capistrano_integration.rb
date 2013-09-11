require 'tempfile'

require 'capistrano'
require 'capistrano/version'

require 'capistrano-unicorn/config'
require 'capistrano-unicorn/utility'

module CapistranoUnicorn
  class CapistranoIntegration
    TASKS = [
      'unicorn:start',
      'unicorn:stop',
      'unicorn:restart',
      'unicorn:duplicate',
      'unicorn:reload',
      'unicorn:shutdown',
      'unicorn:add_worker',
      'unicorn:remove_worker',
      'unicorn:show_vars',
    ]

    def self.load_into(capistrano_config)
      capistrano_config.load do

        before(CapistranoIntegration::TASKS) do
          Config.load(self)
        end

        extend Utility

        #
        # Unicorn cap tasks
        #
        namespace :unicorn do
          desc 'Debug Unicorn variables'
          task :show_vars, :roles => :app do
            puts <<-EOF.gsub(/^ +/, '')

              # Environments
              rails_env          "#{rails_env}"
              unicorn_env        "#{unicorn_env}"
              unicorn_rack_env   "#{unicorn_rack_env}"

              # Execution
              unicorn_user       #{unicorn_user.inspect}
              unicorn_bundle     "#{unicorn_bundle}"
              unicorn_bin        "#{unicorn_bin}"
              unicorn_options    "#{unicorn_options}"
              unicorn_restart_sleep_time  #{unicorn_restart_sleep_time}

              # Relative paths
              app_subdir                         "#{app_subdir}"
              unicorn_config_rel_path            "#{unicorn_config_rel_path}"
              unicorn_config_filename            "#{unicorn_config_filename}"
              unicorn_config_rel_file_path       "#{unicorn_config_rel_file_path}"
              unicorn_config_stage_rel_file_path "#{unicorn_config_stage_rel_file_path}"

              # Absolute paths
              app_path                  "#{app_path}"
              unicorn_pid               "#{unicorn_pid}"
              bundle_gemfile            "#{bundle_gemfile}"
              unicorn_config_path       "#{unicorn_config_path}"
              unicorn_config_file_path  "#{unicorn_config_file_path}"
              unicorn_config_stage_file_path
              ->                        "#{unicorn_config_stage_file_path}"
            EOF
          end

          desc 'Start Unicorn master process'
          task :start, :roles => unicorn_roles, :except => {:no_release => true} do
            run start_unicorn
          end

          desc 'Stop Unicorn'
          task :stop, :roles => unicorn_roles, :except => {:no_release => true} do
            run kill_unicorn('QUIT')
          end

          desc 'Immediately shutdown Unicorn'
          task :shutdown, :roles => unicorn_roles, :except => {:no_release => true} do
            run kill_unicorn('TERM')
          end

          desc 'Restart Unicorn'
          task :restart, :roles => unicorn_roles, :except => {:no_release => true} do
            run <<-END
              #{duplicate_unicorn}

              sleep #{unicorn_restart_sleep_time}; # in order to wait for the (old) pidfile to show up

              if #{old_unicorn_is_running?}; then
                #{unicorn_send_signal('QUIT', get_old_unicorn_pid)};
              fi;
            END
          end

          desc 'Duplicate Unicorn'
          task :duplicate, :roles => unicorn_roles, :except => {:no_release => true} do
            run duplicate_unicorn()
          end

          desc 'Reload Unicorn'
          task :reload, :roles => unicorn_roles, :except => {:no_release => true} do
            run <<-END
              if #{unicorn_is_running?}; then
                echo "Reloading Unicorn...";
                #{unicorn_send_signal('HUP')};
              else
                #{start_unicorn}
              fi;
            END
          end

          desc 'Add a new worker'
          task :add_worker, :roles => unicorn_roles, :except => {:no_release => true} do
            run <<-END
              if #{unicorn_is_running?}; then
                echo "Adding a new Unicorn worker...";
                #{unicorn_send_signal('TTIN')};
              else
                echo "Unicorn is not running.";
              fi;
            END
          end

          desc 'Remove amount of workers'
          task :remove_worker, :roles => unicorn_roles, :except => {:no_release => true} do
            run <<-END
              if #{unicorn_is_running?}; then
                echo "Removing a Unicorn worker...";
                #{unicorn_send_signal('TTOU')};
              else
                echo "Unicorn is not running.";
              fi;
            END
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  CapistranoUnicorn::CapistranoIntegration.load_into(Capistrano::Configuration.instance)
end
