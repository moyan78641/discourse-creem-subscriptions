# frozen_string_literal: true

# name: discourse-creem-subscriptions
# about: Creem payment integration for Discourse subscriptions
# version: 1.0.0
# authors: Sparkloc
# url: https://github.com/sparkloc/discourse-creem-subscriptions
# required_version: 2.7.0

enabled_site_setting :creem_enabled

register_asset "stylesheets/creem.scss"

module ::CreemSubscriptions
  PLUGIN_NAME = "discourse-creem-subscriptions"
end

require_relative "lib/creem_subscriptions/engine"

after_initialize do
  require_relative "lib/creem_subscriptions/creem_api"
  require_relative "lib/creem_subscriptions/webhook_handler"

  # Mount Engine for API and webhook routes
  Discourse::Application.routes.append { mount ::CreemSubscriptions::Engine, at: "/creem" }

  # User custom fields
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
