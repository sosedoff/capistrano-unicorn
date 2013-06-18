require 'capistrano'
require 'capistrano/version'

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
      'unicorn:remove_worker'
    ]

    def self.load_into(capistrano_config)
      capistrano_config.load do
        before(CapistranoIntegration::TASKS) do
          _cset(:app_env)                    { (fetch(:rails_env) rescue 'production') }
          _cset(:unicorn_pid)                { "#{fetch(:current_path)}/tmp/pids/unicorn.pid" }
          _cset(:unicorn_env)                { fetch(:app_env) }
          _cset(:unicorn_bin)                { "unicorn" }
          _cset(:unicorn_bundle)             { fetch(:bundle_cmd) rescue 'bundle' }
          _cset(:unicorn_restart_sleep_time) { 2 }
          _cset(:unicorn_user)               { nil }
          _cset(:unicorn_config_path)        { "#{fetch(:current_path)}/config" }
          _cset(:unicorn_config_filename)    { "unicorn.rb" }
        end

        # Check if a remote process exists using its pid file
        #
        def remote_process_exists?(pid_file)
          "[ -e #{pid_file} ] && #{try_unicorn_user} kill -0 `cat #{pid_file}` > /dev/null 2>&1"
        end

        # Stale Unicorn process pid file
        #
        def old_unicorn_pid
          "#{unicorn_pid}.oldbin"
        end

        # Command to check if Unicorn is running
        #
        def unicorn_is_running?
          remote_process_exists?(unicorn_pid)
        end

        # Command to check if stale Unicorn is running
        #
        def old_unicorn_is_running?
          remote_process_exists?(old_unicorn_pid)
        end

        # Get unicorn master process PID (using the shell)
        #
        def get_unicorn_pid(pid_file=unicorn_pid)
          "`cat #{pid_file}`"
        end

        # Get unicorn master (old) process PID
        #
        def get_old_unicorn_pid
          get_unicorn_pid(old_unicorn_pid)
        end

        # Send a signal to a unicorn master processes
        #
        def unicorn_send_signal(signal, pid=get_unicorn_pid)
          "#{try_unicorn_user} kill -s #{signal} #{pid}"
        end

        # Run a command as the :unicorn_user user if :unicorn_user is a string.
        # Otherwise run as default (:user) user.
        #
        def try_unicorn_user
          "#{sudo :as => unicorn_user.to_s}" if unicorn_user.kind_of?(String)
        end

        # Kill Unicorns in multiple ways O_O
        #
        def kill_unicorn(signal)
          script = <<-END
            if #{unicorn_is_running?}; then
              echo "Stopping Unicorn...";
              #{unicorn_send_signal(signal)};
            else
              echo "Unicorn is not running.";
            fi;
          END

          script
        end

        # Start the Unicorn server
        #
        def start_unicorn
          primary_config_path = "#{unicorn_config_path}/#{unicorn_config_filename}"
          secondary_config_path = "#{unicorn_config_path}/unicorn/#{unicorn_env}.rb"

          script = <<-END
            if [ -e #{primary_config_path} ]; then
              UNICORN_CONFIG_PATH=#{primary_config_path};
            else
              if [ -e #{secondary_config_path} ]; then
                UNICORN_CONFIG_PATH=#{secondary_config_path};
              else
                echo "Config file for \"#{unicorn_env}\" environment was not found at either \"#{primary_config_path}\" or \"#{secondary_config_path}\"";
                exit 1;
              fi;
            fi;

            if [ -e #{unicorn_pid} ]; then
              if #{try_unicorn_user} kill -0 `cat #{unicorn_pid}` > /dev/null 2>&1; then
                echo "Unicorn is already running!";
                exit 0;
              fi;

              #{try_unicorn_user} rm #{unicorn_pid};
            fi;

            echo "Starting Unicorn...";
            cd #{current_path} && #{try_unicorn_user} BUNDLE_GEMFILE=#{current_path}/Gemfile #{unicorn_bundle} exec #{unicorn_bin} -c $UNICORN_CONFIG_PATH -E #{app_env} -D;
          END

          script
        end

        def duplicate_unicorn
          script = <<-END
            if #{unicorn_is_running?}; then
              echo "Duplicating Unicorn...";
              #{unicorn_send_signal('USR2')};
            else
              #{start_unicorn}
            fi;
          END

          script
        end

        def unicorn_roles
          fetch(:unicorn_roles, :app)
        end

        #
        # Unicorn cap tasks
        #
        namespace :unicorn do
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
