# frozen_string_literal: true

module CreemSubscriptions
  class WebhookHandler
    def self.handle(event_type, data)
      Rails.logger.info("[Creem] Webhook: #{event_type}")
      
      case event_type
      when "checkout.completed", "subscription.active"
        handle_subscription_active(data)
      when "subscription.paid"
        handle_subscription_paid(data)
      when "subscription.canceled", "subscription.expired"
        handle_subscription_ended(data)
      else
        Rails.logger.info("[Creem] Unhandled event: #{event_type}")
      end
    end

    def self.handle_subscription_active(data)
      email = data.dig("customer", "email") || data["customer_email"]
      subscription_id = data.dig("subscription", "id") || data["id"]
      customer_id = data.dig("customer", "id")
      
      return unless email.present?
      
      user = User.find_by_email(email)
      return unless user

      user.custom_fields["creem_subscription_id"] = subscription_id
      user.custom_fields["creem_customer_id"] = customer_id
      user.custom_fields["creem_subscription_status"] = "active"
      user.save_custom_fields

      add_to_group(user)
      Rails.logger.info("[Creem] Activated subscription for #{user.username}")
    end

    def self.handle_subscription_paid(data)
      subscription_id = data["id"]
      end_date = data["current_period_end"]
      
      user = find_user_by_subscription(subscription_id)
      return unless user

      user.custom_fields["creem_subscription_status"] = "active"
      user.custom_fields["creem_subscription_end_date"] = end_date
      user.save_custom_fields

      add_to_group(user)
      Rails.logger.info("[Creem] Renewed subscription for #{user.username}")
    end

    def self.handle_subscription_ended(data)
      subscription_id = data["id"]
      
      user = find_user_by_subscription(subscription_id)
      return unless user

      user.custom_fields["creem_subscription_status"] = "canceled"
      user.save_custom_fields

      remove_from_group(user)
      Rails.logger.info("[Creem] Ended subscription for #{user.username}")
    end

    def self.find_user_by_subscription(subscription_id)
      UserCustomField.where(name: "creem_subscription_id", value: subscription_id).first&.user
    end

    def self.add_to_group(user)
      group = Group.find_by(id: SiteSetting.creem_subscription_group)
      group&.add(user) unless group&.users&.include?(user)
    end

    def self.remove_from_group(user)
      group = Group.find_by(id: SiteSetting.creem_subscription_group)
      group&.remove(user) if group&.users&.include?(user)
    end
  end
end
