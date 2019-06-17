# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Exposures
        extend Support::Extension

        apply_extension do
          unless ancestors.include?(Plugin)
            # Copy exposures from the plugin renderer.
            #
            after "load.plugins" do
              plugs.each do |plug|
                plug.isolated(:Renderer).__expose_fns.each do |fn|
                  isolated(:Renderer).send(:expose) do |connection|
                    fn.call(connection, plug)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
