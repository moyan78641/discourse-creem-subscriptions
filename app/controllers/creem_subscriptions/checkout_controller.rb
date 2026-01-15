# frozen_string_literal: true

module CreemSubscriptions
  class CheckoutController < ::ApplicationController
    before_action :ensure_logged_in, only: [:api_checkout, :subscriptions]
    skip_before_action :check_xhr, raise: false
    skip_before_action :preload_json, raise: false
    skip_before_action :redirect_to_login_if_required, only: [:success, :cancel], raise: false

    # API endpoint for frontend to get checkout URL
    def api_checkout
      product_id = params[:product_id] || SiteSetting.creem_product_id
      
      if product_id.blank?
        return render json: { error: "产品 ID 未配置" }, status: 400
      end

      base_url = Discourse.base_url
      success_url = "#{base_url}/creem/success?session_id={checkout_id}"
      cancel_url = "#{base_url}/creem/cancel"

      begin
        result = CreemApi.create_checkout(
          product_id: product_id,
          customer_email: current_user.email,
          success_url: success_url,
          cancel_url: cancel_url,
          metadata: {
            discourse_user_id: current_user.id.to_s,
            discourse_username: current_user.username
          }
        )

        checkout_url = result["checkout_url"] || result["url"]
        
        if checkout_url
          render json: { checkout_url: checkout_url }
        else
          Rails.logger.error("[Creem] Checkout creation failed: #{result}")
          render json: { error: "创建支付失败", details: result }, status: 500
        end
      rescue => e
        Rails.logger.error("[Creem] Checkout error: #{e.message}")
        render json: { error: e.message }, status: 500
      end
    end

    def subscriptions
      subscription_status = current_user.custom_fields["creem_subscription_status"]
      subscription_end_date = current_user.custom_fields["creem_subscription_end_date"]
      subscription_id = current_user.custom_fields["creem_subscription_id"]

      render json: {
        status: subscription_status || "none",
        end_date: subscription_end_date,
        subscription_id: subscription_id
      }
    end
  end
end
