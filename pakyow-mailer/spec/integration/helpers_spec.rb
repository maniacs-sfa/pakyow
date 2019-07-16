RSpec.describe "mailer helpers" do
  include_context "app"

  it "registers Mailer::Helpers as an active helper" do
    expect(app.helpers(:active)).to include(Pakyow::App::Helpers::Mailer)
  end
end
