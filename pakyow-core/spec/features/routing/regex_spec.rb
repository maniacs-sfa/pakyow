RSpec.describe "routing with regex matchers" do
  include_context "testable app"

  context "when route is defined with a regex" do
    let :app_definition do
      -> {
        router do
          get(/.*/) do
            send "regex"
          end
        end
      }
    end

    it "still matches the route" do
      expect(call("/foo")[2].body.read).to eq("regex")
    end

    context "when regex contains named captures" do
      it "makes the captures available as params"
    end
  end

  context "when a namespace is defined with a regex" do
    it "is matched"
  end

  context "when a router is defined with a regex" do
    let :app_definition do
      -> {
        router(/foo/) do
          default do
            send "foo"
          end
        end
      }
    end

    it "is matched" do
      expect(call("/foo")[2].body.first).to eq("foo")
    end
  end
end
