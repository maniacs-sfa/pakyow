require "pakyow/plugin"

RSpec.describe "booting plugins" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      action :test
      def test(connection)
        connection.body = StringIO.new((@value || :did_not_boot).to_s)
        connection.halt
      end
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable, at: "/"
    end
  end

  let :autorun do
    false
  end

  context "plugin implements boot" do
    before do
      TestPlugin.class_eval do
        def boot
          @value = :booted
        end
      end

      setup_and_run
    end

    it "calls boot" do
      expect(call("/")[0]).to eq(200)
      expect(call("/")[2]).to eq("booted")
    end
  end

  context "plugin does not implement boot" do
    before do
      if TestPlugin.method_defined?(:boot)
        TestPlugin.remove_method(:boot)
      end

      setup_and_run
    end

    it "calls boot" do
      expect(call("/")[0]).to eq(200)
      expect(call("/")[2]).to eq("did_not_boot")
    end
  end
end
