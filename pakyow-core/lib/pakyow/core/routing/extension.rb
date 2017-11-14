require "forwardable"

module Pakyow
  module Routing
    # Makes it possible to define router extensions. For example:
    #
    #   module FooRoutes
    #     include Pakyow::Routing::Extension
    #
    #     get "/foo" do
    #       # this route will be defined on any router extended with FooRoutes
    #     end
    #   end
    #
    #   Pakyow::App.router do
    #     extend FooRoutes
    #   end
    #
    # See {Extension::Resource} for a more complex example.
    #
    # @api public
    module Extension
      # @api private
      def self.extended(base)
        base.instance_variable_set(:@__extension, Pakyow::Router(nil))
        base.extend(ClassMethods)
      end

      # Methods available to the extension.
      #
      # @api public
      module ClassMethods
        extend Forwardable

        # @!method get
        #   @see Router.get
        # @!method post
        #   @see Router.post
        # @!method put
        #   @see Router.put
        # @!method patch
        #   @see Router.patch
        # @!method delete
        #   @see Router.delete
        # @!method default
        #   @see Router.default
        # @!method group
        #   @see Router.group
        # @!method namespace
        #   @see Router.namespace
        # @!method template
        #   @see Router.template
        def_delegators :@__extension, *[:default, :group, :namespace, :template].concat(Router::SUPPORTED_HTTP_METHODS)

        # @api private
        def included(base)
          if base.ancestors.include?(Router)
            base.merge(@__extension)
          else
            raise StandardError, "Expected `#{base}' to be a subclass of `Pakyow::Router'"
          end
        end
      end
    end
  end
end