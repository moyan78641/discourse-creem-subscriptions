# frozen_string_literal: true

CreemSubscriptions::Engine.routes.draw do
  # API endpoints
  post "/api/checkout" => "checkout#create"
  get "/api/subscription" => "checkout#subscription"
  
  # Webhook
  post "/webhooks" => "webhooks#create"
  
  # Frontend routes - return empty JSON, Discourse will serve HTML for browser requests
  get "/" => "creem#index"
  get "/checkout" => "creem#index"
  get "/success" => "creem#index"
  get "/cancel" => "creem#index"
end
