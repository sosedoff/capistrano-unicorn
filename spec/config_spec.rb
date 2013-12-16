require 'spec_helper'
describe CapistranoUnicorn::Config, "loaded into a configuration" do
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
          @configuration.should_receive(:capture).and_return('unset')
          @configuration.logger.stub(:important)
          @configuration.fetch(:unicorn_pid).should == app_path + "/tmp/pids/unicorn.pid"
        end

        shared_examples "auto-detect pid file from unicorn config" do |pid_file|
          it "should auto-detect pid file from unicorn config" do
            @configuration.should_receive(:capture).and_return(pid_file)
            @configuration.fetch(:unicorn_pid).should == File.expand_path(pid_file, app_path)
          end
        end

        include_examples "auto-detect pid file from unicorn config", \
          '/path/to/pid/from/config/file'

        include_examples "auto-detect pid file from unicorn config", \
          'relative/path/to/pid'

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
end
