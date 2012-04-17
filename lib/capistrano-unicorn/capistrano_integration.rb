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

        # Returns the current process id as an integer.
        #
        # Returns 0 if the pidfile doesn't exist or is empty
        def get_pid(pid_file)
          capture("cat '#{pid_file}' 2> /dev/null || :").to_i
        end

        # Set unicorn vars
        #
        _cset(:unicorn_pid, "#{fetch(:current_path)}/tmp/pids/unicorn.pid")
        _cset(:app_env, (fetch(:rails_env) rescue 'production'))
        _cset(:unicorn_env, (fetch(:app_env)))
        _cset(:unicorn_bin, "unicorn")

        namespace :unicorn do
          desc 'Start Unicorn'
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
            if remote_file_exists?(unicorn_pid)
              if remote_process_exists?(unicorn_pid)
                logger.important("Stopping...", "Unicorn")
                run "#{try_sudo} kill `cat #{unicorn_pid}`"
              else
                run "rm #{unicorn_pid}"
                logger.important("Unicorn is not running.", "Unicorn")
              end
            else
              logger.important("No PIDs found. Check if unicorn is running.", "Unicorn")
            end
          end

          desc 'Unicorn graceful shutdown'
          task :graceful_stop, :roles => :app, :except => {:no_release => true} do
            if remote_file_exists?(unicorn_pid)
              if remote_process_exists?(unicorn_pid)
                logger.important("Stopping...", "Unicorn")
                run "#{try_sudo} kill -s QUIT `cat #{unicorn_pid}`"
              else
                run "rm #{unicorn_pid}"
                logger.important("Unicorn is not running.", "Unicorn")
              end
            else
              logger.important("No PIDs found. Check if unicorn is running.", "Unicorn")
            end
          end

          desc 'Reload Unicorn'
          task :reload, :roles => :app, :except => {:no_release => true} do
            old_pid = get_pid(unicorn_pid)
            new_pid = 0
            if old_pid == 0
              logger.important("No PIDs found. Starting Unicorn server...", "Unicorn")
              config_path = "#{current_path}/config/unicorn/#{unicorn_env}.rb"
              if remote_file_exists?(config_path)
                run "cd #{current_path} && BUNDLE_GEMFILE=#{current_path}/Gemfile bundle exec #{unicorn_bin} -c #{config_path} -E #{app_env} -D"
              else
                logger.important("Config file for \"#{unicorn_env}\" environment was not found at \"#{config_path}\"", "Unicorn")
              end
            else
              begin
                logger.important("Shutting down old Unicorn, PID: #{old_pid}", "Unicorn")

                # Start a new master
                run "#{try_sudo} kill -s USR2 #{old_pid}"

                # Wait for new pid to appear for a while...
                countdown = 60
                while new_pid == 0 or new_pid == old_pid
                  new_pid = get_pid(unicorn_pid)
                  sleep(0.5)
                  countdown -= 1
                  raise Capistrano::Error.new("Failed to start new Unicorn...timedout") if countdown == 0
                end

                logger.important("New Unicorn started, PID: #{new_pid}", "Unicorn")

                # Switch to new master and kill the old master
                run "#{try_sudo} kill -s WINCH #{old_pid} ; #{try_sudo} kill -s QUIT #{old_pid}"
              rescue
                # Restore the old master
                logger.important("Failed to start new Unicorn, reverting to old", "Unicorn")
                run "#{try_sudo} kill -s HUP #{old_pid} ; #{try_sudo} kill -s QUIT #{new_pid}" unless new_pid == 0

                raise
              end
            end
          end

          task :restart => :reload
        end

        after "deploy:restart", "unicorn:reload"
      end
    end
  end
end

if Capistrano::Configuration.instance
  CapistranoUnicorn::CapistranoIntegration.load_into(Capistrano::Configuration.instance)
end
