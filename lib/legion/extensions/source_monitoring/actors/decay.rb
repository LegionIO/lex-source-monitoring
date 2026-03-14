# frozen_string_literal: true

module Legion
  module Extensions
    module SourceMonitoring
      module Actors
        class Decay < Legion::Extensions::Actors::Every
          INTERVAL = 60

          def run
            Runners::SourceMonitoring.instance_method(:update_source_monitoring).bind_call(runner_instance)
          end
        end
      end
    end
  end
end
