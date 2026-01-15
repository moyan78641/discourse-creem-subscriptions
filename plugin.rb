# frozen_string_literal: true

# name: discourse-creem-subscriptions
# about: Creem payment integration for Discourse subscriptions
# version: 1.0.0
# authors: Sparkloc
# url: https://github.com/sparkloc/discourse-creem-subscriptions
# required_version: 2.7.0

enabled_site_setting :creem_enabled

register_asset "stylesheets/creem.scss"

after_initialize do
  module ::CreemSubscriptions
    PLUGIN_NAME = "discourse-creem-subscriptions"

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace CreemSubscriptions
    end
  end

  require_relative "lib/creem_subscriptions/creem_api"
  require_relative "lib/creem_subscriptions/webhook_handler"
  require_relative "app/controllers/creem_subscriptions/webhooks_controller"
  require_relative "app/controllers/creem_subscriptions/checkout_controller"

  CreemSubscriptions::Engine.routes.draw do
    post "/webhooks" => "webhooks#handle"
    post "/api/checkout" => "checkout#api_checkout"
    get "/api/subscriptions" => "checkout#subscriptions"
  end

  Discourse::Application.routes.append do
    mount ::CreemSubscriptions::Engine, at: "/creem"
  end

  # Add user custom field for subscription status
  User.register_custom_field_type("creem_subscription_id", :string)
  User.register_custom_field_type("creem_customer_id", :string)
  User.register_custom_field_type("creem_subscription_status", :string)
  User.register_custom_field_type("creem_subscription_end_date", :string)

  add_to_serializer(:current_user, :creem_subscription_status) do
    object.custom_fields["creem_subscription_status"]
  end

  add_to_serializer(:current_user, :creem_subscription_end_date) do
    object.custom_fields["creem_subscription_end_date"]
  end
end
