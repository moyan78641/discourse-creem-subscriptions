# frozen_string_literal: true

CreemSubscriptions::Engine.routes.draw do
  # API endpoints (mounted at /creem-api)
  post "/checkout" => "checkout#create"
  get "/subscription" => "checkout#subscription"
  
  # Webhook
  post "/webhooks" => "webhooks#create"
end
