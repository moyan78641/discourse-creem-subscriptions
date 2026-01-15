# frozen_string_literal: true

module ::CreemSubscriptions
  class Engine < ::Rails::Engine
    engine_name "discourse-creem-subscriptions"
    isolate_namespace CreemSubscriptions
  end
end
