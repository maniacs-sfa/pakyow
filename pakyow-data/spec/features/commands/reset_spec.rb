require "pakyow/cli"

RSpec.describe "cli: db:reset" do
  include_context "app"
  include_context "command"

  let(:precompiler_instance) {
    double(:precompiler).as_null_object
  }

  let(:command) {
    "db:reset"
  }

  describe "help" do
    it "is helpful" do
      expect(run_command(command, help: true, project: true)).to eq("\e[34;1mReset a database\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow db:reset\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env                \e[33mThe environment to run this command under\e[0m\n      --adapter=adapter        \e[33mThe database adapter (default: sql)\e[0m\n  -c, --connection=connection  \e[33mThe database connection (default: default)\e[0m\n")
    end
  end

  describe "running" do
    let(:adapter) {
      :test_adapter
    }

    let(:connection) {
      :test_connection
    }

    it "calls db:drop with the adapter and connection" do
      run_command(command, adapter: adapter, connection: connection, project: true, loaded: -> (cli) {
        allow(cli).to receive(:call).and_call_original
        stub_command(Pakyow::Commands::Db::Drop)
        stub_command(Pakyow::Commands::Db::Bootstrap)
      }) do |cli|
        expect(cli).to have_received(:call).with(
          "db:drop", adapter: :test_adapter, connection: :test_connection
        )
      end
    end

    it "calls db:bootstrap with the adapter and connection" do
      run_command(command, adapter: adapter, connection: connection, project: true, loaded: -> (cli) {
        allow(cli).to receive(:call).and_call_original
        stub_command(Pakyow::Commands::Db::Drop)
        stub_command(Pakyow::Commands::Db::Bootstrap)
      }) do |cli|
        expect(cli).to have_received(:call).with(
          "db:bootstrap", adapter: :test_adapter, connection: :test_connection
        )
      end
    end
  end
end
