# frozen_string_literal: true

require "pakyow/assets/asset"

module Pakyow
  module Assets
    module Types
      class Scss < Asset
        class << self
          def load
            require "sass"
          rescue LoadError
            Pakyow.logger.error <<~ERROR
              Pakyow found a *.scss file, but couldn't find sass. Please add this to your Gemfile:

                gem "sass"
            ERROR
          end
        end

        extension :scss
        emits :css

        def initialize(local_path:, config:, **kwargs)
          @options = {
            syntax: :scss,
            cache: false,
            load_paths: [
              File.dirname(local_path),
              config.frontend_assets_path
            ]
          }

          super
        end

        def process(content)
          ::Sass::Engine.new(content, @options).render
        rescue ::Sass::SyntaxError => e
          Pakyow.logger.error "[scss] syntax error: #{e}"
        end

        def dependencies
          ::Sass::Engine.for_file(@local_path, @options).dependencies.map { |dependency|
            dependency.options[:filename]
          }
        end
      end
    end
  end
end