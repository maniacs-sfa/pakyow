# frozen_string_literal: true

module Pakyow
  module Support
    # Makes it easier to define extensions.
    #
    # @example
    #
    #   module SomeExtension
    #     extend Pakyow::Support::Extension
    #
    #     # only allows the extension to be used on descendants of `SomeBaseClass`
    #     restrict_extension SomeBaseClass
    #
    #     # includes the module unless it is already present
    #     dependency SomeBehavior
    #
    #     apply_extension do
    #       # anything here is evaluated on the object including the extension
    #     end
    #
    #     class_methods do
    #       # class methods can be defined here
    #     end
    #
    #     prepend_methods do
    #       # instance methods you wish to prepend can be defined here
    #     end
    #
    #     # define instance-level methods as usual
    #   end
    #
    #   class SomeClass < SomeBaseClass
    #     include SomeExtension
    #   end
    #
    module Extension
      def restrict_extension(type)
        @__extension_restriction = type
      end

      def apply_extension(&block)
        @__extension_block = block
      end

      def class_methods(&block)
        @__extension_extend_module = Module.new(&block)
      end

      def prepend_methods(&block)
        @__extension_prepend_module = Module.new(&block)
      end

      def included(base)
        enforce_restrictions(base)
        mixin_extension_dependencies(base)
        mixin_extension_modules(base)
        include_extensions(base)
      end

      # Register a dependency to be included into classes that include the extension. If the
      # dependency is already present, it will not be included a second time.
      #
      def include_dependency(dependency)
        extension_dependencies << {
          method: :include, object: dependency
        }
      end

      # Register a dependency to be extended into classes that include the extension. If the
      # dependency is already present, it will not be extended a second time.
      #
      def extend_dependency(dependency)
        extension_dependencies << {
          method: :extend, object: dependency
        }
      end

      private

      def enforce_restrictions(base)
        if instance_variable_defined?(:@__extension_restriction) && !base.ancestors.include?(@__extension_restriction)
          raise StandardError, "expected `#{base}' to be `#{@__extension_restriction}'"
        end
      end

      def mixin_extension_modules(base)
        if instance_variable_defined?(:@__extension_extend_module)
          base.extend @__extension_extend_module
        end

        if instance_variable_defined?(:@__extension_prepend_module)
          base.prepend @__extension_prepend_module
        end
      end

      def include_extensions(base)
        if instance_variable_defined?(:@__extension_block)
          base.instance_exec(&@__extension_block)
        end
      end

      def extension_dependencies
        @__extension_dependencies ||= []
      end

      def mixin_extension_dependencies(base)
        extension_dependencies.each do |dependency|
          case dependency[:method]
          when :include
            unless base.ancestors.include?(dependency[:object])
              base.include(dependency[:object])
            end
          when :extend
            unless base.singleton_class.ancestors.include?(dependency[:object])
              base.extend(dependency[:object])
            end
          end
        end
      end
    end
  end
end
