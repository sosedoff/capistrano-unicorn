require "spec_helper"

describe CapistranoUnicorn::CapistranoIntegration, "loaded into a configuration" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)
    CapistranoUnicorn::CapistranoIntegration.load_into(@configuration)
  end

  context "testing variables" do
    before do
      # define _cset etc. from capistrano
      @configuration.load 'deploy'

      # capistrano-unicorn variables are set during a 'before'
      # callback, so in order to be able to test the result, we need
      # to ensure the callback is triggered.
      @configuration.trigger :before
    end

    describe "app paths" do
      cur_path = '/path/to/myapp'

      before do
        @configuration.set(:current_path, cur_path)
      end

      shared_examples_for "an app in path" do |app_path|
        let(:shell) { :` } # ` } work around confused emacs ruby-mode

        specify "app_path should default to #{app_path}" do
          @configuration.fetch(:app_path).should == app_path
        end

        it "should default to a sensible pid file when auto-detection failed" do
          @configuration.should_receive(shell).with(/unicorn -c /).and_return('') do |cmd|
            $?.should_receive(:success?).and_return(false)
          end
          @configuration.logger.stub(:important)
          @configuration.fetch(:unicorn_pid).should == app_path + "/tmp/pids/unicorn.pid"
        end

        shared_examples "auto-detect pid file from unicorn config" do
          |pid_file, primary_exists, config_file|
          which_config = primary_exists ? 'primary' : 'stage'
          it "should auto-detect pid file from #{which_config} unicorn config" do
            # Tempfile.new in Ruby 1.9.2 will call File.exist?
            allow(File).to receive(:exist?).with(/tmp/)

            File.should_receive(:exist?).with('config/unicorn.rb').and_return(primary_exists)
            tmpfile = nil
            @configuration.should_receive(shell).with(/unicorn -c /) do |cmd|
              (cmd =~ /^unicorn -c "(.+)"$/).should be_true
              tmpfile = $~[1]
              tmpfile.should include("tmp")
              File.read(tmpfile).should include(%!config_file = "#{config_file}"!)
              $?.should_receive(:success?).and_return(true)
              pid_file
            end
            @configuration.fetch(:unicorn_pid).should == pid_file
          end
        end

        include_examples "auto-detect pid file from unicorn config", \
          '/path/to/pid/from/config/file', true, "config/unicorn.rb"

        include_examples "auto-detect pid file from unicorn config", \
          '/path/to/pid/from/stage/config/file', false, "config/unicorn/production.rb"

        specify "Gemfile should default correctly" do
          @configuration.fetch(:bundle_gemfile).should == app_path + "/Gemfile"
        end

        specify "config/ directory should default correctly" do
          @configuration.fetch(:unicorn_config_path).should == app_path + "/config"
        end

        specify "config file should default correctly" do
          @configuration.fetch(:unicorn_config_file_path).should == app_path + "/config/unicorn.rb"
        end

        specify "per-stage config file should default correctly" do
          @configuration.fetch(:unicorn_config_stage_file_path).should == app_path + "/config/unicorn/production.rb"
        end

        specify "per-stage config file should be set correctly for different environment" do
          @configuration.set(:rails_env, 'staging')
          @configuration.fetch(:unicorn_config_stage_file_path).should == app_path + "/config/unicorn/staging.rb"
        end
      end

      context "app in current_path" do
        it_should_behave_like "an app in path", cur_path
      end

      context "app in a subdirectory" do
        subdir = 'mysubdir'

        before do
          @configuration.set(:app_subdir, '/' + subdir)
        end

        it_should_behave_like "an app in path", cur_path + '/' + subdir
      end
    end

    describe "unicorn_env" do
      it "should default to value of rails_env if set" do
        @configuration.set(:rails_env, 'staging')
        @configuration.fetch(:unicorn_env).should == \
          @configuration.fetch(:rails_env)
      end

      it "should default to production if rails_env not set" do
        @configuration.fetch(:unicorn_env).should == 'production'
      end
    end

    describe "unicorn_rack_env" do
      it "should default to deployment if rails_env not set" do
        @configuration.fetch(:unicorn_rack_env).should == 'deployment'
      end

      it "should default to development if rails_env set to development" do
        @configuration.set(:rails_env, 'development')
        @configuration.fetch(:unicorn_rack_env).should == 'development'
      end

      it "should default to deployment if rails_env set to anything else" do
        @configuration.set(:rails_env, 'staging')
        @configuration.fetch(:unicorn_rack_env).should == 'deployment'
      end
    end
  end

  shared_examples_for "a task" do |task_name|
    it "sets attributes in before_task hook" do
      # Environments
      @configuration.should_receive(:_cset).with(:unicorn_env)
      @configuration.should_receive(:_cset).with(:unicorn_rack_env)

      # Execution
      @configuration.should_receive(:_cset).with(:unicorn_user)
      @configuration.should_receive(:_cset).with(:unicorn_bundle)
      @configuration.should_receive(:_cset).with(:unicorn_bin)
      @configuration.should_receive(:_cset).with(:unicorn_options)
      @configuration.should_receive(:_cset).with(:unicorn_restart_sleep_time)

      # Relative paths
      @configuration.should_receive(:_cset).with(:app_subdir)
      @configuration.should_receive(:_cset).with(:unicorn_config_rel_path)
      @configuration.should_receive(:_cset).with(:unicorn_config_filename)
      @configuration.should_receive(:_cset).with(:unicorn_config_rel_file_path)
      @configuration.should_receive(:_cset).with(:unicorn_config_stage_rel_file_path)

      # Absolute paths
      @configuration.should_receive(:_cset).with(:app_path)
      @configuration.should_receive(:_cset).with(:unicorn_pid)
      @configuration.should_receive(:_cset).with(:bundle_gemfile)
      @configuration.should_receive(:_cset).with(:unicorn_config_path)
      @configuration.should_receive(:_cset).with(:unicorn_config_file_path)
      @configuration.should_receive(:_cset).with(:unicorn_config_stage_file_path)

      @configuration.find_and_execute_task(task_name)
    end
  end

  describe "task" do
    describe 'unicorn:start' do
      before do
        @configuration.stub(:start_unicorn)
        @configuration.stub(:_cset)
      end

      it_behaves_like "a task", 'unicorn:start'

      it "runs start_unicorn command" do
        @configuration.should_receive(:start_unicorn).and_return("start unicorn command")
        @configuration.find_and_execute_task('unicorn:start')
        @configuration.should have_run("start unicorn command")
      end
    end

    describe 'unicorn:stop' do
      before do
        @configuration.stub(:kill_unicorn)
        @configuration.stub(:_cset)
      end

      it_behaves_like "a task", 'unicorn:stop'

      it "runs kill_unicorn command" do
        @configuration.should_receive(:kill_unicorn).with('QUIT').and_return("kill unicorn command")
        @configuration.find_and_execute_task('unicorn:stop')
        @configuration.should have_run("kill unicorn command")
      end
    end
  end

  describe "#kill_unicorn" do
    before do
      @configuration.stub(:unicorn_pid).and_return(999)
      @configuration.stub(:unicorn_user).and_return("deploy_user")
    end

    it "generates the kill unicorn command" do
      @configuration.kill_unicorn('QUIT').should match /-u deploy_user kill -s QUIT `cat 999`;/
    end
  end
end
