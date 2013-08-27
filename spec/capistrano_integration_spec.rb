require "spec_helper"

describe CapistranoUnicorn::CapistranoIntegration, "loaded into a configuration" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)
    CapistranoUnicorn::CapistranoIntegration.load_into(@configuration)

    @configuration.stub(:_cset)
  end

  shared_examples_for "a task" do |task_name|
    it "sets attributes in before_task hook" do
      @configuration.should_receive(:_cset).with(:app_env)
      @configuration.should_receive(:_cset).with(:unicorn_pid)
      @configuration.should_receive(:_cset).with(:unicorn_env)
      @configuration.should_receive(:_cset).with(:unicorn_bin)
      @configuration.should_receive(:_cset).with(:unicorn_bundle)
      @configuration.should_receive(:_cset).with(:unicorn_restart_sleep_time)
      @configuration.should_receive(:_cset).with(:unicorn_user)
      @configuration.should_receive(:_cset).with(:unicorn_config_path)
      @configuration.should_receive(:_cset).with(:unicorn_config_filename)

      @configuration.find_and_execute_task(task_name)
    end
  end

  describe "task" do
    describe 'unicorn:start' do
      before do
        @configuration.stub(:start_unicorn)
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