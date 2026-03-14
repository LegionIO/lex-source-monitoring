# frozen_string_literal: true

require 'legion/extensions/source_monitoring/version'
require 'legion/extensions/source_monitoring/helpers/constants'
require 'legion/extensions/source_monitoring/helpers/source_record'
require 'legion/extensions/source_monitoring/helpers/source_tracker'
require 'legion/extensions/source_monitoring/runners/source_monitoring'
require 'legion/extensions/source_monitoring/client'

module Legion
  module Extensions
    module SourceMonitoring
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core)
    end
  end
end
