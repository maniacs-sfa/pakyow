# frozen_string_literal: true

require "pakyow/support/deep_dup"

module Pakyow
  module Support
    module Configurable
      # @api private
      class Setting
        using DeepDup

        def initialize(default:, configurable:, &block)
          @default, @block, @configurable = default, block, configurable
        end

        def initialize_copy(_)
          @default = @default.deep_dup
          super
        end

        def freeze
          value
          super
        end

        def set(value)
          @value = value
        end

        def value
          if instance_variable_defined?(:@value)
            @value
          else
            @value = if @block
              @configurable.instance_eval(&@block)
            else
              @default
            end
          end
        end

        def update_configurable(configurable)
          @configurable = configurable
        end
      end
    end
  end
end
