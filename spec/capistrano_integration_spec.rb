require "spec_helper"

describe CapistranoUnicorn::CapistranoIntegration, "loaded into a configuration" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)
    CapistranoUnicorn::CapistranoIntegration.load_into(@configuration)

    @configuration.stub(:_cset)
  end

  share_examples_for "a task" do |task_name|
    after do
      #Execute the task after the test to trigger the before_task hook
      @configuration.find_and_execute_task(task_name)
    end
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
    end
  end


  describe "task" do
    describe 'unicorn:start' do
      before do
        @configuration.stub(:start_unicorn)
      end

      it_should_behave_like "a task", 'unicorn:start'

      it "should run start_unicorn" do
        @configuration.should_receive(:start_unicorn).and_return("start_unicorn")
        @configuration.find_and_execute_task('unicorn:start')
        @configuration.should have_run("start_unicorn")
      end
    end

    describe 'unicorn:stop' do
      before do
        @configuration.stub(:kill_unicorn)
      end

      it_should_behave_like "a task", 'unicorn:stop'

      it "should run kill_unicorn" do
        @configuration.should_receive(:kill_unicorn).with('QUIT').and_return("kill_unicorn")
        @configuration.find_and_execute_task('unicorn:stop')
        @configuration.should have_run("kill_unicorn")
      end
    end
  end
end