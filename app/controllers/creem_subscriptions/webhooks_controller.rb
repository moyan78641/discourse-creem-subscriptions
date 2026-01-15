# frozen_string_literal: true

module CreemSubscriptions
  class WebhooksController < ::ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :redirect_to_login_if_required

    def handle
      payload = request.raw_post
      signature = request.headers["creem-signature"]

      # Verify signature
      unless CreemApi.verify_webhook_signature(payload, signature)
        Rails.logger.warn("[Creem] Invalid webhook signature")
        return render json: { error: "Invalid signature" }, status: 401
      end

      begin
        event = JSON.parse(payload)
        event_type = event["eventType"] || event["event_type"] || event["type"]
        data = event["data"] || event

        Rails.logger.info("[Creem] Received webhook: #{event_type}")

        WebhookHandler.handle(event_type, data)

        render json: { received: true }, status: 200
      rescue JSON::ParserError => e
        Rails.logger.error("[Creem] JSON parse error: #{e.message}")
        render json: { error: "Invalid JSON" }, status: 400
      rescue => e
        Rails.logger.error("[Creem] Webhook error: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        render json: { error: "Internal error" }, status: 500
      end
    end
  end
end
