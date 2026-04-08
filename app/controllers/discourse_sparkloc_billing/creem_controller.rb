# frozen_string_literal: true

module ::DiscourseSparklocBilling
  class CreemController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    before_action :ensure_logged_in

    def create_checkout
      record = SubscriptionStore.load(current_user.username)
      if record && %w[active trialing].include?(record["status"])
        return render json: { error: "您已有有效订阅" }, status: 422
      end

      body = {
        product_id: SiteSetting.sparkloc_creem_product_id,
        success_url: "#{Discourse.base_url}/u/#{current_user.username}/billing/subscriptions",
        customer: { email: current_user.email },
        metadata: { discourse_username: current_user.username },
      }

      resp = CreemClient.create_checkout(body)

      if resp.is_a?(Net::HTTPSuccess)
        data = CreemClient.parse_json(resp) || {}
        render json: { checkout_url: data["checkout_url"] || data["url"] }
      else
        Rails.logger.error("[Creem] create checkout failed: #{resp.code} #{resp.body}")
        render json: { error: "创建支付会话失败" }, status: 502
      end
    rescue => e
      Rails.logger.error("[Creem] create checkout errored: #{e.message}")
      render json: { error: "支付服务暂时不可用" }, status: 502
    end

    def subscription_status
      record = SubscriptionStore.load(current_user.username)
      if record
        render json: {
          status: record["status"],
          creem_subscription_id: record["creem_subscription_id"],
          current_period_end: record["current_period_end"],
          canceled_at: record["canceled_at"],
        }
      else
        render json: { status: "none" }
      end
    end

    def cancel_subscription
      record = SubscriptionStore.load(current_user.username)
      unless record && record["creem_subscription_id"].present?
        return render json: { error: "没有可取消的订阅" }, status: 422
      end

      unless %w[active trialing].include?(record["status"])
        return render json: { error: "当前订阅状态无法取消" }, status: 422
      end

      resp = CreemClient.cancel_subscription(record["creem_subscription_id"], mode: "scheduled")

      if resp.is_a?(Net::HTTPSuccess)
        render json: { success: true }
      else
        Rails.logger.error("[Creem] cancel subscription failed: #{resp.code} #{resp.body}")
        render json: { error: "取消订阅失败，请稍后重试" }, status: 502
      end
    rescue => e
      Rails.logger.error("[Creem] cancel subscription errored: #{e.message}")
      render json: { error: "服务暂时不可用" }, status: 502
    end

    def billing_portal
      record = SubscriptionStore.load(current_user.username)
      unless record && record["creem_customer_id"].present?
        return render json: { error: "没有可管理的订阅" }, status: 422
      end

      resp = CreemClient.billing_portal(record["creem_customer_id"])

      if resp.is_a?(Net::HTTPSuccess)
        data = CreemClient.parse_json(resp) || {}
        render json: { url: data["customer_portal_link"] }
      else
        Rails.logger.error("[Creem] billing portal failed: #{resp.code} #{resp.body}")
        render json: { error: "无法打开账单管理页面" }, status: 502
      end
    rescue => e
      Rails.logger.error("[Creem] billing portal errored: #{e.message}")
      render json: { error: "服务暂时不可用" }, status: 502
    end
  end
end
