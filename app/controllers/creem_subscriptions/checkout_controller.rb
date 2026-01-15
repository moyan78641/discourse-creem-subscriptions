# frozen_string_literal: true

module CreemSubscriptions
  class CheckoutController < ::ApplicationController
    requires_plugin CreemSubscriptions::PLUGIN_NAME
    
    before_action :ensure_logged_in
    skip_before_action :check_xhr, only: [:create]

    def create
      product_id = SiteSetting.creem_product_id
      
      if product_id.blank?
        return render json: { error: "Product ID not configured" }, status: 400
      end

      base_url = Discourse.base_url
      
      begin
        result = CreemApi.create_checkout(
          product_id: product_id,
          customer_email: current_user.email,
          success_url: "#{base_url}/creem/success?session_id={checkout_id}",
          cancel_url: "#{base_url}/creem/cancel",
          metadata: {
            discourse_user_id: current_user.id.to_s,
            discourse_username: current_user.username
          }
        )

        checkout_url = result["checkout_url"] || result["url"]
        
        if checkout_url
          render json: { checkout_url: checkout_url }
        else
          Rails.logger.error("[Creem] Checkout failed: #{result}")
          render json: { error: "Failed to create checkout" }, status: 500
        end
      rescue => e
        Rails.logger.error("[Creem] Error: #{e.message}")
        render json: { error: e.message }, status: 500
      end
    end

    def subscription
      render json: {
        status: current_user.custom_fields["creem_subscription_status"] || "none",
        end_date: current_user.custom_fields["creem_subscription_end_date"],
        subscription_id: current_user.custom_fields["creem_subscription_id"]
      }
    end
  end
end
