# frozen_string_literal: true

module ::DiscourseSparklocBilling
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseSparklocBilling
  end
end
