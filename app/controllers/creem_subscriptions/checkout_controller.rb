# frozen_string_literal: true

module CreemSubscriptions
  class CheckoutController < ::ApplicationController
    before_action :ensure_logged_in, except: [:success, :cancel]

    def create
      product_id = params[:product_id] || SiteSetting.creem_product_id
      
      if product_id.blank?
        return render json: { error: "Product ID not configured" }, status: 400
      end

      base_url = Discourse.base_url
      success_url = "#{base_url}#{SiteSetting.creem_success_url}?session_id={checkout_id}"
      cancel_url = "#{base_url}#{SiteSetting.creem_cancel_url}"

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

        if result["checkout_url"] || result["url"]
          checkout_url = result["checkout_url"] || result["url"]
          redirect_to checkout_url, allow_other_host: true
        else
          Rails.logger.error("[Creem] Checkout creation failed: #{result}")
          render json: { error: "Failed to create checkout", details: result }, status: 500
        end
      rescue => e
        Rails.logger.error("[Creem] Checkout error: #{e.message}")
        render json: { error: e.message }, status: 500
      end
    end

    def success
      @session_id = params[:session_id]
      render html: success_html.html_safe, layout: false
    end

    def cancel
      render html: cancel_html.html_safe, layout: false
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

    private

    def success_html
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>支付成功</title>
          <meta charset="utf-8">
          <style>
            body { font-family: system-ui, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f5; }
            .container { text-align: center; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .icon { font-size: 64px; margin-bottom: 20px; }
            h1 { color: #22c55e; margin-bottom: 10px; }
            p { color: #666; margin-bottom: 20px; }
            a { display: inline-block; background: #B794F6; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; }
            a:hover { background: #A78BFA; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="icon">✅</div>
            <h1>支付成功！</h1>
            <p>感谢您的订阅，您的会员权限已激活。</p>
            <a href="/">返回首页</a>
          </div>
        </body>
        </html>
      HTML
    end

    def cancel_html
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>支付取消</title>
          <meta charset="utf-8">
          <style>
            body { font-family: system-ui, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f5; }
            .container { text-align: center; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .icon { font-size: 64px; margin-bottom: 20px; }
            h1 { color: #666; margin-bottom: 10px; }
            p { color: #666; margin-bottom: 20px; }
            a { display: inline-block; background: #B794F6; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; }
            a:hover { background: #A78BFA; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="icon">❌</div>
            <h1>支付已取消</h1>
            <p>您已取消支付，如有疑问请联系客服。</p>
            <a href="/">返回首页</a>
          </div>
        </body>
        </html>
      HTML
    end
  end
end
