# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      # Loads default pipeline actions based on included frameworks.
      #
      module Pipeline
        extend Support::Extension

        apply_extension do
          # We set the priority very low here in case initialize hooks in other frameworks define
          # state that should be loaded into the pipeline (e.g. controllers).
          #
          after "initialize", "initialize.pipeline", priority: -10 do
            load_pipeline_defaults(@__pipeline)
          end
        end

        private

        def load_pipeline_defaults(pipeline)
          if self.class.includes_framework?(:assets)
            pipeline.action(Actions::Assets::Public, self)
            pipeline.action(Actions::Assets::Process)
          end

          if self.class.includes_framework?(:realtime) && Pakyow.config.realtime.server && !is_a?(Plugin)
            pipeline.action(Actions::Realtime::Upgrader)
          end

          if self.class.includes_framework?(:routing) && !Pakyow.env?(:prototype)
            state(:controller).each do |controller|
              pipeline.action(controller, self)
            end
          end

          if instance_variable_defined?(:@plugs)
            @plugs.each do |plug_instance|
              pipeline.action(plug_instance)
            end
          end

          if self.class.includes_framework?(:presenter)
            pipeline.action(Actions::Presenter::AutoRender)
          end

          if self.class.includes_framework?(:routing) && !Pakyow.env?(:prototype) && !is_a?(Plugin)
            pipeline.action(Actions::Routing::RespondMissing)
          end
        end
      end
    end
  end
end
