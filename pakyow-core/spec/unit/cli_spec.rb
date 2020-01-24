require "pakyow/cli"
require "pakyow/task"

RSpec.describe Pakyow::CLI do
  describe "requiring config/environment.rb" do
    before do
      allow_any_instance_of(Pakyow::CLI).to receive(:load_tasks)
      allow_any_instance_of(Pakyow::CLI).to receive(:output_help)
      allow_any_instance_of(Pakyow::CLI).to receive(:output_error)
    end

    context "within the project folder" do
      before do
        allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
      end

      it "loads the environment" do
        expect(Pakyow).to receive(:load)

        Pakyow::CLI.new
      end
    end

    context "outside of a project folder" do
      before do
        allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(false)
      end

      it "does not load the environment" do
        expect(Pakyow).not_to receive(:load)

        Pakyow::CLI.new
      end
    end
  end

  describe "presenting commands based on context" do
    before do
      allow_any_instance_of(Pakyow::CLI).to receive(:output_help)
      allow_any_instance_of(Pakyow::CLI).to receive(:output_error)
      allow_any_instance_of(Pakyow::CLI).to receive(:load_tasks)

      allow(Pakyow).to receive(:tasks) do
        [].tap do |tasks|
          tasks << Pakyow::Task.new(description: "global", global: true)
          tasks << Pakyow::Task.new(description: "local", global: false)
        end
      end
    end

    let :tasks do
      Pakyow::CLI.new.send(:tasks)
    end

    context "within the project folder" do
      before do
        allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
      end

      it "only includes project commands" do
        expect(tasks.length).to be(1)
        expect(tasks[0].description).to eq("local")
      end
    end

    context "outside of a project folder" do
      before do
        allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(false)
      end

      it "only includes global commands" do
        expect(tasks.length).to be(1)
        expect(tasks[0].description).to eq("global")
      end
    end
  end

  describe "failing tasks" do
    before do
      allow_any_instance_of(Pakyow::CLI).to receive(:load_tasks)
      allow_any_instance_of(Pakyow::CLI).to receive(:output_help)
      allow_any_instance_of(Pakyow::CLI).to receive(:output_error)
    end

    context "stdout is a tty" do
      before do
        allow($stdout).to receive(:isatty).and_return(true)
      end

      it "does not raise the error" do
        expect_any_instance_of(Pakyow::CLI).to receive(:parse_global_options).and_raise(RuntimeError)

        expect {
          Pakyow::CLI.new([])
        }.to_not raise_error
      end
    end

    context "stdout is not a tty" do
      before do
        allow($stdout).to receive(:isatty).and_return(false)
      end

      it "raises the error" do
        expect_any_instance_of(Pakyow::CLI).to receive(:parse_global_options).and_raise(RuntimeError)

        expect {
          Pakyow::CLI.new([])
        }.to raise_error(RuntimeError)
      end
    end
  end

  describe "exit codes" do
    before do
      allow_any_instance_of(Pakyow::CLI).to receive(:load_tasks)
      allow_any_instance_of(Pakyow::CLI).to receive(:output_help)
      allow_any_instance_of(Pakyow::CLI).to receive(:output_error)
    end

    context "command succeeds" do
      it "indicates success" do
        expect(::Process).not_to receive(:exit)
        Pakyow::CLI.new([])
      end
    end

    context "command fails" do
      before do
        expect_any_instance_of(Pakyow::CLI).to receive(:parse_global_options).and_raise(RuntimeError)
      end

      it "indicates failure" do
        expect(::Process).to receive(:exit).with(0)
        Pakyow::CLI.new([])
      end
    end
  end

  describe "calling the task" do
    before do
      allow_any_instance_of(Pakyow::CLI).to receive(:output_help)
      allow_any_instance_of(Pakyow::CLI).to receive(:output_error)
      allow_any_instance_of(Pakyow::CLI).to receive(:load_tasks)

      allow(Pakyow).to receive(:tasks) do
        [].tap do |tasks|
          tasks << task.new
        end
      end
    end

    let :task do
      Class.new do
        def name
          "test"
        end

        def global?
          true
        end

        def app?
          false
        end

        def call(*args)
        end
      end
    end

    let :tasks do
      Pakyow::CLI.new.send(:tasks)
    end

    it "retains the argument order" do
      expect_any_instance_of(task).to receive(:call) do |_, _, args|
        expect(args).to eq(["foo_value", "-b", "bar_value", "--qux", "qux_value"])
      end

      Pakyow::CLI.new(["test", "foo_value", "-b", "bar_value", "--qux", "qux_value"])
    end
  end
end
