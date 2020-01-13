require "pakyow/support/deprecatable"

RSpec.describe "deprecating a method" do
  before do
    allow(Pakyow::Support::Deprecator.global).to receive(:deprecated)
  end

  context "method is an instance method" do
    let!(:deprecatable) {
      Class.new {
        extend Pakyow::Support::Deprecatable

        attr_reader :args, :kwargs, :block

        def foo(*args, **kwargs, &block)
          @args, @kwargs, @block = args, kwargs, block
        end

        deprecate :foo
      }.tap do |deprecatable|
        stub_const "DeprecatableClass", deprecatable
      end
    }

    it "does not report the deprecation immediately" do
      expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
    end

    context "class is initialized" do
      let!(:instance) {
        deprecatable.new
      }

      it "does not report the deprecation" do
        expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
      end

      context "method is called" do
        before do
          instance.foo(:foo, :bar, baz: :qux) do
            :test
          end
        end

        it "reports the deprecation" do
          expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(instance, :foo, solution: "do not use")
        end

        it "calls the original method" do
          expect(instance.args).to eq([:foo, :bar])
          expect(instance.kwargs).to eq(baz: :qux)
          expect(instance.block.call).to eq(:test)
        end
      end
    end
  end

  context "method is a class method" do
    let!(:deprecatable) {
      Class.new {
        class << self
          extend Pakyow::Support::Deprecatable

          attr_reader :args, :kwargs, :block

          def foo(*args, **kwargs, &block)
            @args, @kwargs, @block = args, kwargs, block
          end

          deprecate :foo
        end
      }.tap do |deprecatable|
        stub_const "DeprecatableClass", deprecatable
      end
    }

    it "does not report the deprecation immediately" do
      expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
    end

    context "method is called" do
      before do
        deprecatable.foo(:foo, :bar, baz: :qux) do
          :test
        end
      end

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, :foo, solution: "do not use")
      end

      it "calls the original initializer" do
        expect(deprecatable.args).to eq([:foo, :bar])
        expect(deprecatable.kwargs).to eq(baz: :qux)
        expect(deprecatable.block.call).to eq(:test)
      end
    end
  end

  context "method is a mixin" do
    let!(:deprecatable) {
      Module.new {
        attr_reader :args, :kwargs, :block

        def foo(*args, **kwargs, &block)
          @args, @kwargs, @block = args, kwargs, block
        end

        extend Pakyow::Support::Deprecatable
        deprecate :foo
      }.tap do |deprecatable|
        stub_const "DeprecatableModule", deprecatable
      end
    }

    it "does not report the deprecation immediately" do
      expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
    end

    context "method is called" do
      before do
        instance.foo(:foo, :bar, baz: :qux) do
          :test
        end
      end

      let(:instance) {
        Class.new {
          include DeprecatableModule
        }.new
      }

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, :foo, solution: "do not use")
      end

      it "calls the original initializer" do
        expect(instance.args).to eq([:foo, :bar])
        expect(instance.kwargs).to eq(baz: :qux)
        expect(instance.block.call).to eq(:test)
      end
    end
  end

  context "method is a module function" do
    let!(:deprecatable) {
      Module.new {
        def foo(*args, **kwargs, &block)
          @args, @kwargs, @block = args, kwargs, block
        end
        module_function :foo

        class << self
          attr_reader :args, :kwargs, :block

          extend Pakyow::Support::Deprecatable
          deprecate :foo
        end
      }.tap do |deprecatable|
        stub_const "DeprecatableModule", deprecatable
      end
    }

    it "does not report the deprecation immediately" do
      expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
    end

    context "method is called" do
      before do
        deprecatable.foo(:foo, :bar, baz: :qux) do
          :test
        end
      end

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, :foo, solution: "do not use")
      end

      it "calls the original initializer" do
        expect(deprecatable.args).to eq([:foo, :bar])
        expect(deprecatable.kwargs).to eq(baz: :qux)
        expect(deprecatable.block.call).to eq(:test)
      end
    end
  end

  context "method is not found" do
    it "raises an error" do
      expect {
        Class.new do
          extend Pakyow::Support::Deprecatable

          deprecate :foo
        end
      }.to raise_error(RuntimeError) do |error|
        expect(error.message).to eq("could not find method `foo' to deprecate")
      end
    end
  end

  context "class is named after method is deprecated" do
    let!(:deprecatable) {
      Class.new {
        extend Pakyow::Support::Deprecatable

        def foo; end
        deprecate :foo
      }.tap do |deprecatable|
        stub_const "DeprecatableClass", deprecatable
      end
    }

    let(:instance) {
      deprecatable.new
    }

    it "reports the correct name" do
      expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(DeprecatableClass, :foo, solution: "do not use")

      instance.foo
    end
  end
end
