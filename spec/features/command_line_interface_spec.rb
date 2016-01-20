require "spec_helper"

RSpec.shared_examples "help information" do |command|
  it "prints help information" do
    output = `#{command}`

    expect(output).to match(/Usage|Commands/)
  end
end

RSpec.describe "command line interface" do
  describe "help" do
    it_behaves_like "help information", "bin/pakyow --help"
    it_behaves_like "help information", "bin/pakyow -h"

    %w(console new server).each do |command|
      describe "#{command} help" do
        it_behaves_like "help information", "bin/pakyow help #{command}"
      end
    end
  end
end