require_relative "../shared"

RSpec.describe "handling prerun and postrun work" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      definitions
      allow(Pakyow).to receive(:houston)
      run_container(timeout: 0.1)
    end

    let(:container_options) {
      { restartable: false }
    }

    let(:definitions) {
      local = self

      container.service :foo, restartable: false do
        define_singleton_method :prerun do |options|
          options[:metadata] = {
            preran: true
          }
        end

        define_singleton_method :postrun do |options|
          options[:metadata][:postran] = true

          local.write_to_parent(Marshal.dump(options[:metadata]))
        end

        define_method :perform do
          # noop
        end
      end
    }

    it "calls prerun on each service with options" do
      expect(Marshal.load(result)[:preran]).to be(true)
    end

    it "calls postrun on each service with options" do
      expect(Marshal.load(result)[:postran]).to be(true)
    end

    context "prerun fails for a service" do
      let(:definitions) {
        local = self

        container.service :foo, restartable: false do
          define_singleton_method :prerun do |options|
            fail
          end

          define_singleton_method :postrun do |options|
            options[:metadata] = {
              postran_foo: true
            }

            local.write_to_parent(Marshal.dump(options[:metadata]))
          end

          define_method :perform do
            # noop
          end
        end

        container.service :bar, restartable: false do
          define_singleton_method :prerun do |options|
            options[:metadata] = {
              preran_bar: true
            }
          end

          define_singleton_method :postrun do |options|
            options[:metadata][:postran_bar] = true

            local.write_to_parent(Marshal.dump(options[:metadata]))
          end

          define_method :perform do
            # noop
          end
        end
      }

      it "does not call postrun for that service" do
        expect(Marshal.load(result)[:postran_foo]).to be(nil)
      end

      it "calls postrun for services that did prerun" do
        expect(Marshal.load(result)[:preran_bar]).to be(true)
        expect(Marshal.load(result)[:postran_bar]).to be(true)
      end

      it "reports the error" do
        expect(Pakyow).to have_received(:houston)
      end
    end

    context "post fails for a service" do
      let(:definitions) {
        local = self

        container.service :foo, restartable: false do
          define_singleton_method :postrun do |options|
            fail
          end

          define_method :perform do
            # noop
          end
        end

        container.service :bar, restartable: false do
          define_singleton_method :postrun do |options|
            options[:metadata] = {
              postran_bar: true
            }

            local.write_to_parent(Marshal.dump(options[:metadata]))
          end

          define_method :perform do
            # noop
          end
        end
      }

      it "calls postrun for other services" do
        expect(Marshal.load(result)[:postran_bar]).to be(true)
      end

      it "reports the error" do
        expect(Pakyow).to have_received(:houston)
      end
    end
  end

  context "forked container" do
    let(:run_options) {
      { strategy: :forked }
    }

    include_examples :examples
  end

  context "threaded container" do
    let(:run_options) {
      { strategy: :threaded }
    }

    include_examples :examples
  end

  context "hybrid container" do
    let(:run_options) {
      { strategy: :hybrid }
    }

    include_examples :examples
  end
end

RSpec.describe "handling prerun and postrun work in nested services" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      definitions
      allow(Pakyow).to receive(:houston)
      run_container(timeout: 0.1)
    end

    let(:container_options) {
      { restartable: false }
    }

    let(:definitions) {
      local = self

      container.service :foo, restartable: false do
        define_singleton_method :prerun do |options|
          options[:metadata] = {
            preran_foo: true
          }
        end

        define_singleton_method :postrun do |options|
          options[:metadata][:postran_foo] = true

          local.write_to_parent(Marshal.dump(options[:metadata]))
        end

        define_method :perform do
          local.run_container(local.container2, timeout: 0.1, parent: self)
        end
      end

      container2.service :bar, restartable: false do
        define_singleton_method :prerun do |options|
          options[:metadata][:preran_bar] = true
        end

        define_singleton_method :postrun do |options|
          options[:metadata][:postran_bar] = true

          local.write_to_parent(Marshal.dump(options[:metadata]))
        end

        define_method :perform do
          # noop
        end
      end
    }

    let(:container2) {
      Pakyow::Runnable::Container.make(:test2)
    }

    it "only calls prerun and postrun for toplevel services" do
      expect(Marshal.load(result)[:preran_foo]).to be(true)
      expect(Marshal.load(result)[:postran_foo]).to be(true)
      expect(Marshal.load(result)[:preran_bar]).to be(nil)
      expect(Marshal.load(result)[:postran_bar]).to be(nil)
    end
  end

  context "forked container" do
    let(:run_options) {
      { strategy: :forked }
    }

    include_examples :examples
  end

  context "threaded container" do
    let(:run_options) {
      { strategy: :threaded }
    }

    include_examples :examples
  end

  context "hybrid container" do
    let(:run_options) {
      { strategy: :hybrid }
    }

    include_examples :examples
  end
end
