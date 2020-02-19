require "pakyow/cli"

RSpec.describe "cli: db:drop" do
  include_context "app"
  include_context "command"

  let(:precompiler_instance) {
    double(:precompiler).as_null_object
  }

  let(:command) {
    "db:drop"
  }

  describe "help" do
    it "is helpful" do
      expect(run_command(command, help: true, project: true)).to eq("\e[34;1mDrop a database\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow db:drop\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env                \e[33mThe environment to run this command under\e[0m\n      --adapter=adapter        \e[33mThe database adapter (default: sql)\e[0m\n  -c, --connection=connection  \e[33mThe database connection (default: default)\e[0m\n")
    end
  end

  describe "running" do
    let(:migrator) {
      instance_double(Pakyow::Data::Migrator, drop!: nil, disconnect!: nil)
    }

    let(:adapter) {
      :test_adapter
    }

    let(:connection) {
      :test_connection
    }

    before do
      allow(Pakyow::Data::Migrator).to receive(:connect_global).and_return(migrator)
    end

    it "connects globally with the given adapter and connection" do
      expect(Pakyow::Data::Migrator).to receive(:connect_global).with(
        adapter: adapter, connection: connection
      ).and_return(migrator)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "drops the database" do
      expect(migrator).to receive(:drop!)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "disconnects" do
      expect(migrator).to receive(:disconnect!)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    context "database connection exists" do
      before do
        allow(Pakyow).to receive(:connection).with(adapter, connection).and_return(connection)
      end

      let(:connection) {
        instance_double(Pakyow::Data::Connection)
      }

      it "disconnects" do
        expect(connection).to receive(:disconnect)

        run_command(command, adapter: adapter, connection: connection, project: true)
      end
    end
  end
end