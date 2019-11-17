require "smoke_helper"

RSpec.describe "starting up a newly generated project", smoke: true do
  before do
    boot do
      # TODO: Enable this once externals are fetched in the background.
      #
      # expect(@boot_time).to be < 10
    end
  end

  context "development environment" do
    let :environment do
      :development
    end

    it "responds to a request" do
      response = HTTP.get("http://localhost:#{port}")

      # It'll 404 because of the default view missing message. This is fine.
      #
      expect(response.status).to eq(404)
    end
  end

  context "production environment" do
    let :environment do
      :production
    end

    let :envars do
      {
        "SECRET" => "sekret",
        "DATABASE_URL" => "sqlite://database/production.db"
      }
    end

    it "responds to a request" do
      response = HTTP.get("http://localhost:#{port}")

      # It'll 404 because of the default view missing message. This is fine.
      #
      expect(response.status).to eq(404)
    end
  end
end
