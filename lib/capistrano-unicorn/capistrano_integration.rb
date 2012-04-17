require 'capistrano'
require 'capistrano/version'

module CapistranoUnicorn
  class CapistranoIntegration
    def self.load_into(capistrano_config)
      capistrano_config.load do
        # Check if remote file exists
        #
        def remote_file_exists?(full_path)
          'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
        end
        
        # Check if process is running
        #
        def remote_process_exists?(pid_file)
          capture("ps -p $(cat #{pid_file}) ; true").strip.split("\n").size == 2
        end

        # Get unicorn master process PID
        #
        def unicorn_get_pid
          if remote_file_exists?(unicorn_pid) && remote_process_exists?(unicorn_pid)
            capture("cat #{unicorn_pid}")
          end
        end

        # Send a signal to unicorn master process
        #
        def unicorn_send_signal(pid, signal)
          run "#{try_sudo} kill -s #{signal} #{pid}"
        end

        #
        # Set unicorn vars
        #
        _cset(:unicorn_pid, "#{fetch(:current_path)}/tmp/pids/unicorn.pid")
        _cset(:app_env,     (fetch(:rails_env) rescue 'production'))
        _cset(:unicorn_env, (fetch(:app_env)))
        _cset(:unicorn_bin, "unicorn")

        #
        # Unicorn rake tasks
        #
        namespace :unicorn do
          desc 'Start Unicorn master process'
          task :start, :roles => :app, :except => {:no_release => true} do
            if remote_file_exists?(unicorn_pid)
              if process_exists?(unicorn_pid)
                logger.important("Unicorn is already running!", "Unicorn")
                next
              else
                run "rm #{unicorn_pid}"
              end
            end

            config_path = "#{current_path}/config/unicorn/#{unicorn_env}.rb"
            if remote_file_exists?(config_path)
              logger.important("Starting...", "Unicorn")
              run "cd #{current_path} && BUNDLE_GEMFILE=#{current_path}/Gemfile bundle exec #{unicorn_bin} -c #{config_path} -E #{app_env} -D"
            else
              logger.important("Config file for \"#{unicorn_env}\" environment was not found at \"#{config_path}\"", "Unicorn")
            end
          end

          desc 'Stop Unicorn'
          task :stop, :roles => :app, :except => {:no_release => true} do
            pid = unicorn_get_pid
            unless pid.nil?
              logger.important("Stopping...", "Unicorn")
              unicorn_send_signal(pid, "QUIT")
            else
              logger.important("Unicorn is not running.", "Unicorn")
            end
          end

          desc 'Immediately shutdown Unicorn'
          task :shutdown, :roles => :app, :except => {:no_release => true} do
            pid = unicorn_get_pid
            unless pid.nil?
              logger.important("Stopping...", "Unicorn")
              unicorn_send_signal(pid, "TERM")
            else
              logger.important("Unicorn is not running.", "Unicorn")
            end
          end

          desc 'Reload Unicorn'
          task :reload, :roles => :app, :except => {:no_release => true} do
            pid = unicorn_get_pid
            unless pid.nil?
              logger.important("Reloading...", "Unicorn")
              unicorn_send_signal(pid, 'USR2')
            else
              unicorn.start
            end
          end
        end

        after "deploy:restart", "unicorn:reload"
      end
    end
  end
end

if Capistrano::Configuration.instance
  CapistranoUnicorn::CapistranoIntegration.load_into(Capistrano::Configuration.instance)
end
