# frozen_string_literal: true

require "pakyow/support/definable"
require "pakyow/support/deep_freeze"
require "pakyow/support/class_state"
require "pakyow/support/inspectable"
require "pakyow/support/hookable"
require "pakyow/support/configurable"
require "pakyow/support/pipeline"

require "pakyow/behavior/config"
require "pakyow/behavior/sessions"
require "pakyow/behavior/endpoints"
require "pakyow/behavior/pipeline"
require "pakyow/behavior/frameworks"
require "pakyow/behavior/aspects"
require "pakyow/behavior/helpers"
require "pakyow/behavior/rescuing"
require "pakyow/behavior/restarting"
require "pakyow/behavior/isolating"
require "pakyow/behavior/initializers"
require "pakyow/behavior/plugins"
require "pakyow/behavior/operations"

require "pakyow/connection"

module Pakyow
  # Pakyow's main application object. Can be defined directly or subclassed to
  # create multiple application objects, each containing its own state. These
  # applications can then be mounted as an endpoint within the environment.
  #
  #   Pakyow::App.define do
  #     # state shared between all apps goes here
  #   end
  #
  #   class API < Pakyow::App
  #     # state for this app goes here
  #   end
  #
  #   Pakyow.configure do
  #     mount API, at: "/api"
  #   end
  #
  # = Pipeline
  #
  # Requests are received by {App#call}, creating a {Connection} object that
  # provides an interface to the underlying request state. The connection is
  # pushed through a pipeline. Each pipeline action can modify the connection
  # and then either 1) allow the connection to hit the next action 2) halt
  # pipeline execution completely.
  #
  # Once the connection exits the pipeline a response is returned. If an action
  # halted, the connection is finalized and returned, otherwise app assumes
  # that the connection was unhandled and returns a canned 404 response.
  #
  # App also catches any unhandled errors that occur in the pipeline by simply
  # logging the error and returning a canned 500 response.
  #
  # @see Support::Pipeline
  #
  # = Configuration
  #
  # App objects can be configured.
  #
  #   Pakyow::App.configure do
  #     config.name = "my-app"
  #   end
  #
  # It's possible to configure for certain environments.
  #
  #   Pakyow::App.configure :development do
  #     config.name = "my-dev-app"
  #   end
  #
  # The +app+ config namespace can be extended with your own custom options.
  #
  #   Pakyow::App.configure do
  #     config.foo = "bar"
  #   end
  #
  # @see Support::Configurable
  #
  # = Hooks
  #
  # Hooks can be defined for the following events:
  #
  #   - initialize
  #   - configure
  #   - load
  #   - finalize
  #   - boot
  #   - rescue
  #   - shutdown
  #
  # Here's how to log a message after initialize:
  #
  #   Pakyow::App.after "initialize" do
  #     logger.info "initialized #{self}"
  #   end
  #
  # @see Support::Hookable
  #
  class App
    require "pakyow/app/connection"

    class << self
      def inherited(subclass)
        super

        # Creates a connection subclass that other frameworks can safely extend.
        #
        subclass.isolate Connection
      end
    end

    # Environment the app is booted in, e.g. +:development+.
    #
    attr_reader :environment

    # App mount path.
    #
    attr_reader :mount_path

    include Support::Inspectable
    inspectable :@environment

    include Support::Hookable
    events :initialize, :configure, :load, :finalize, :boot, :rescue, :shutdown

    include Support::Configurable
    include Support::Definable
    include Support::Pipeline

    include Behavior::Config
    include Behavior::Sessions
    include Behavior::Endpoints
    include Behavior::Pipeline
    include Behavior::Frameworks
    include Behavior::Aspects
    include Behavior::Helpers
    include Behavior::Rescuing
    include Behavior::Restarting
    include Behavior::Isolating
    include Behavior::Initializers
    include Behavior::Plugins
    include Behavior::Operations

    def initialize(environment, mount_path: "/", &block)
      super()

      @environment, @mount_path, @rescued = environment, mount_path, false

      performing :initialize do
        performing :configure do
          configure!(environment)
        end

        performing :load do
          $LOAD_PATH.unshift(config.lib)
        end

        config.version = Support::PathVersion.build(config.src)

        # Call the Pakyow::Definable initializer.
        #
        # This ensures that any state registered in the passed block
        # has the proper priority against instance and global state.
        #
        defined!(&block)
      end
    rescue ScriptError, StandardError => error
      rescue!(error)
    end

    # Called by the environment after it boots the app.
    #
    def booted
      unless rescued?
        call_hooks :after, :boot
      end
    rescue ScriptError, StandardError => error
      rescue!(error)
    end

    # Calls the app pipeline with a connection created from the rack env.
    #
    def call(connection)
      app_connection = isolated(:Connection).new(self, connection)
      super(app_connection)
    rescue => error
      if respond_to?(:controller_for_connection)
        controller_for_connection(app_connection).handle_error(error)
      else
        raise error
      end
    end

    def shutdown
      performing :shutdown do; end
    end

    def _dump(_)
      Marshal.dump(
        {
          name: config.name
        }
      )
    end

    def self._load(state)
      Pakyow.app(Marshal.load(state)[:name])
    end

    # @api private
    def perform(app_connection)
      @__pipeline.call(app_connection)
    end
  end
end
