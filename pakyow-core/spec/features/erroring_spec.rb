RSpec.describe "handling errors when calling the environment" do
  context "low-level error occurs" do
    before do
      Pakyow.action do |connection|
        fail "something went wrong"
      end
    end

    include_context "app"

    it "responds with the expected status" do
      expect(call("/")[0]).to eq(500)
    end

    it "responds with the expected headers" do
      expect(call("/")[1]).to eq({})
    end

    it "responds with the expected body" do
      expect(call("/")[2]).to eq("500 Low-Level Server Error")
    end
  end

  context "error occurs during dispatch" do
    include_context "app"

    let :app_def do
      Proc.new do
        action do |connection|
          fail "something went wrong"
        end
      end
    end

    let :allow_request_failures do
      true
    end

    it "sets the error on the connection" do
      expect_any_instance_of(Pakyow::Connection).to receive(:error=) do |_, error|
        expect(error.message).to eq("something went wrong")
      end

      call("/")
    end

    it "logs the error with the connection logger" do
      logger_double = instance_double(Pakyow::Logger, prologue: nil, epilogue: nil)
      allow_any_instance_of(Pakyow::Connection).to receive(:logger).and_return(logger_double)
      expect(logger_double).to receive(:houston) do |error|
        expect(error.message).to eq("something went wrong")
      end

      call("/")
    end

    it "responds with the expected status" do
      expect(call("/")[0]).to eq(500)
    end

    it "responds with the expected body" do
      expect(call("/")[2]).to eq("500 Server Error")
    end

    context "app implements `controller_for_connection`" do
      let :app_def do
        Proc.new do
          action do |connection|
            fail "something went wrong"
          end
        end
      end

      let :app_init do
        local = self
        Proc.new do
          @local = local
          def controller_for_connection(connection)
            @local.controller.new(connection)
          end
        end
      end

      let :controller do
        Class.new do
          def initialize(connection)
            @connection = connection
          end

          def handle_error(error)
            @connection.body = StringIO.new("handled: #{error}")
            @connection.halt
          end
        end
      end

      it "lets the controller handle the error" do
        expect(call("/")[2]).to eq("handled: something went wrong")
      end
    end
  end
end
