require "pakyow/verifier"

RSpec.describe Pakyow::Verifier do
  let :result do
    verifier.call(values)
  end

  before do
    result
  end

  describe "sanitization" do
    let :verifier do
      described_class.new do
        required :foo
        optional :bar
      end
    end

    let :values do
      {
        foo: "foo",
        bar: "bar",
        baz: "baz"
      }
    end

    it "does not remove required values" do
      expect(values[:foo]).to eq("foo")
    end

    it "does not remove optional values" do
      expect(values[:bar]).to eq("bar")
    end

    it "removes values that are neither required nor optional" do
      expect(values).not_to include(:baz)
    end
  end

  describe "normalization" do
    let :verifier do
      described_class.new do
        required :foo, :datetime
      end
    end

    let :values do
      {
        foo: "2019-06-14 09:15:39 -0700"
      }
    end

    context "type is defined for a key" do
      it "typecasts the value" do
        expect(values[:foo]).to be_instance_of(Time)
      end

      it "represents the correct value" do
        expect(values[:foo].to_s).to eq("2019-06-14 09:15:39 -0700")
      end
    end
  end

  describe "verification" do
    let :verifier do
      described_class.new do
        required :foo
        optional :bar
      end
    end

    context "required value is not passed" do
      let :values do
        {
          bar: "bar"
        }
      end

      it "fails" do
        expect(result.verified?).to be(false)
      end
    end

    context "required value is passed as nil" do
      let :values do
        {
          foo: nil,
          bar: "bar"
        }
      end

      it "fails" do
        expect(result.verified?).to be(false)
      end
    end

    context "required value is passed as empty" do
      let :values do
        {
          foo: "",
          bar: "bar"
        }
      end

      it "succeeds" do
        expect(result.verified?).to be(true)
      end
    end

    context "optional value is not passed" do
      let :values do
        {
          foo: "foo"
        }
      end

      it "succeeds" do
        expect(result.verified?).to be(true)
      end
    end

    context "all values are passed" do
      let :values do
        {
          foo: "foo",
          bar: "bar"
        }
      end

      it "succeeds" do
        expect(result.verified?).to be(true)
      end
    end
  end

  describe "validation" do
    let :verifier do
      described_class.new do
        optional :foo do
          validate do |value|
            value.include?("foo")
          end

          validate do |value|
            value.include?("bar")
          end
        end
      end
    end

    context "value does not pass any validations" do
      let :values do
        {
          foo: "baz",
        }
      end

      it "fails" do
        expect(result.verified?).to be(false)
      end
    end

    context "value passes one validation but not another" do
      let :values do
        {
          foo: "foo",
        }
      end

      it "fails" do
        expect(result.verified?).to be(false)
      end
    end

    context "value passes all validations" do
      let :values do
        {
          foo: "foobar",
        }
      end

      it "succeeds" do
        expect(result.verified?).to be(true)
      end
    end
  end

  describe "messages" do
    context "verificaton failed" do
      let :verifier do
        described_class.new do
          required :foo
          required :bar
        end
      end

      let :values do
        {
          foo: "foo"
        }
      end

      it "includes a verification message for the failed key" do
        expect(result.messages[:bar]).to eq(["is required"])
      end

      it "does not include a message for values that succeeded" do
        expect(result.messages).not_to include(:foo)
      end

      context "custom message is provided" do
        let :verifier do
          described_class.new do
            required :foo, message: "custom"
          end
        end

        let :values do
          {}
        end

        it "uses the custom message" do
          expect(result.messages[:foo]).to eq(["custom"])
        end
      end
    end

    context "validation failed" do
      let :verifier do
        described_class.new do
          optional :foo do
            validate :presence
          end

          optional :bar do
            validate :presence
          end
        end
      end

      let :values do
        {
          foo: "",
          bar: "bar"
        }
      end

      it "includes a validation message for the failed key" do
        expect(result.messages[:foo]).to eq(["cannot be blank"])
      end

      it "does not include a message for values that succeeded" do
        expect(result.messages).not_to include(:bar)
      end

      context "custom message is provided" do
        let :verifier do
          described_class.new do
            optional :foo do
              validate :presence, message: "custom"
            end
          end
        end

        let :values do
          {
            foo: ""
          }
        end

        it "uses the custom message" do
          expect(result.messages[:foo]).to eq(["custom"])
        end
      end
    end

    context "verification and validation succeeded" do
      let :verifier do
        described_class.new do
          required :foo do
            validate :presence
          end
        end
      end

      let :values do
        {
          foo: "foo"
        }
      end

      it "returns an empty hash" do
        expect(result.messages).to eq({})
      end
    end
  end
end
