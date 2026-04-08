# frozen_string_literal: true

DiscourseSparklocBilling::Engine.routes.draw do
  post "/webhooks/creem" => "creem_webhook#handle"
  post "/creem/checkout" => "creem#create_checkout"
  get "/creem/subscription" => "creem#subscription_status"
  post "/creem/cancel" => "creem#cancel_subscription"
  post "/creem/billing-portal" => "creem#billing_portal"

  get "/admin/subscriptions" => "subscription_admin#index"
  post "/admin/subscriptions" => "subscription_admin#create"
  put "/admin/subscriptions/renew" => "subscription_admin#renew"
  delete "/admin/subscriptions" => "subscription_admin#cancel"
end

Discourse::Application.routes.draw do
  mount ::DiscourseSparklocBilling::Engine, at: "/sparkloc"

  get "/subscription-admin" => "list#latest", constraints: ->(req) { !req.path.end_with?(".json") }
  get "/u/:username/billing" => "users#show"
  get "/u/:username/billing/subscriptions" => "users#show"
end
