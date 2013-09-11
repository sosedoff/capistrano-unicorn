module CapistranoUnicorn
  module Utility

    def local_unicorn_config
      File.exist?(unicorn_config_rel_file_path) ?
          unicorn_config_rel_file_path
        : unicorn_config_stage_rel_file_path
    end

    def extract_pid_file
      tmp = Tempfile.new('unicorn.rb')
      begin
        conf = local_unicorn_config
        tmp.write <<-EOF.gsub(/^ */, '')
          config_file = "#{conf}"

          # stub working_directory to avoid chdir failure since this will
          # run client-side:
          def working_directory(path); end

          instance_eval(File.read(config_file), config_file) if config_file
          puts set[:pid]
          exit 0
        EOF
        tmp.close
        extracted_pid = `unicorn -c "#{tmp.path}"`
        $?.success? ? extracted_pid.rstrip : nil
      rescue StandardError => e
        return nil
      ensure
        tmp.close
        tmp.unlink
      end
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
      %Q%
        if [ -e "#{unicorn_config_file_path}" ]; then
          UNICORN_CONFIG_PATH=#{unicorn_config_file_path};
        else
          if [ -e "#{unicorn_config_stage_file_path}" ]; then
            UNICORN_CONFIG_PATH=#{unicorn_config_stage_file_path};
          else
            echo "Config file for "#{unicorn_env}" environment was not found at either "#{unicorn_config_file_path}" or "#{unicorn_config_stage_file_path}"";
            exit 1;
          fi;
        fi;

        if [ -e "#{unicorn_pid}" ]; then
          if #{try_unicorn_user} kill -0 `cat #{unicorn_pid}` > /dev/null 2>&1; then
            echo "Unicorn is already running!";
            exit 0;
          fi;

          #{try_unicorn_user} rm #{unicorn_pid};
        fi;

        echo "Starting Unicorn...";
        cd #{app_path} && #{try_unicorn_user} RAILS_ENV=#{rails_env} BUNDLE_GEMFILE=#{bundle_gemfile} #{unicorn_bundle} exec #{unicorn_bin} -c $UNICORN_CONFIG_PATH -E #{unicorn_rack_env} -D #{unicorn_options};
      %
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
      defer{ fetch(:unicorn_roles, :app) }
    end

  end
end
