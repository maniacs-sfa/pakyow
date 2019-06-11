# frozen_string_literal: true

require "pakyow/support/aargv"
require "pakyow/support/core_refinements/string/normalization"

module Pakyow
  module Routing
    # A {Controller} endpoint.
    #
    class Route
      using Support::Refinements::String::Normalization

      attr_reader :path, :method, :name, :collapsed_path

      # @api private
      attr_accessor :pipeline

      def initialize(path_or_matcher, name:, method:, &block)
        @name, @method, @block = name, method, block

        if path_or_matcher.is_a?(String)
          @path = String.normalize_path(path_or_matcher.to_s)
          @collapsed_path = String.normalize_path(collapse_path(@path))
          @matcher = create_matcher_from_path(@path)
        else
          @path, @collapsed_path = ""
          @matcher = path_or_matcher
        end
      end

      def match(path_to_match)
        @matcher.match(path_to_match)
      end

      def call(context)
        context.instance_exec(&@block) if @block
      end

      def build_path(path_to_self, **params)
        working_path = String.normalize_path(File.join(path_to_self.to_s, @path))

        params.each do |key, value|
          working_path.sub!(":#{key}", value.to_s)
        end

        working_path.sub!("/#", "#")
        working_path
      end

      private

      def collapse_path(path)
        path.split("/").keep_if { |part|
          part[0] != ":"
        }.join("/")
      end

      def create_matcher_from_path(path)
        converted_path = String.normalize_path(path.split("/").map { |segment|
          if segment.include?(":")
            "(?<#{segment[(segment.index(":") + 1)..-1]}>(\\w|[-~:@!$\\'\\(\\)\\*\\+,;])+)"
          else
            segment
          end
        }.join("/"))

        Regexp.new("^#{converted_path}$")
      end

      class EndpointBuilder
        attr_reader :params

        def initialize(route:, path:)
          @route, @path = route, path
          @params = String.normalize_path(File.join(@path.to_s, @route.path)).split("/").select { |segment|
            segment.start_with?(":")
          }.map { |segment|
            segment[1..-1].to_sym
          }
        end

        def call(params)
          @route.build_path(@path, params)
        end
      end
    end
  end
end
