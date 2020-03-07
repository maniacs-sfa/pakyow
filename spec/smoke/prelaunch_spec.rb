require "smoke_helper"

require_relative "./shared/migrate"
require_relative "./shared/precompile"

RSpec.describe "prelaunching the environment", smoke: true do
  include_examples "migrate"
  include_examples "precompile" do
    let :envars do
      {
        "SECRET" => "sekret",
        "DATABASE_URL" => "sqlite://database/production.db"
      }
    end
  end

  before do
    cli_run "prelaunch -e production"
  end
end
