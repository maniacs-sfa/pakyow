# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

module Pakyow
  module Actions
    # Normalizes request uris, issuing a 301 redirect to the normalized uri.
    #
    class Normalizer
      using Support::Refinements::String::Normalization

      def call(connection)
        if strict_www? && require_www? && !www?(connection) && !subdomain?(connection)
          redirect!(connection, File.join(add_www(connection), connection.fullpath))
        elsif strict_www? && !require_www? && www?(connection)
          redirect!(connection, File.join(remove_www(connection), connection.fullpath))
        elsif strict_path? && slash?(connection)
          redirect!(connection, String.normalize_path(connection.fullpath))
        end
      end

      private

      def redirect!(connection, location)
        connection.status = 301
        connection.set_header("Location", location)
        connection.halt
      end

      def add_www(connection)
        "www.#{connection.authority}"
      end

      def remove_www(connection)
        connection.authority.split(".", 2)[1]
      end

      def slash?(connection)
        double_slash?(connection) || tail_slash?(connection)
      end

      def double_slash?(connection)
        connection.path.include?("//")
      end

      TAIL_SLASH_REGEX = /(.)+(\/)+$/

      def tail_slash?(connection)
        !(TAIL_SLASH_REGEX =~ connection.path).nil?
      end

      def subdomain?(connection)
        connection.host.count(".") > 1
      end

      def www?(connection)
        connection.subdomain == "www"
      end

      def strict_path?
        Pakyow.config.normalizer.strict_path == true
      end

      def strict_www?
        Pakyow.config.normalizer.strict_www == true
      end

      def require_www?
        Pakyow.config.normalizer.require_www == true
      end
    end
  end
end
