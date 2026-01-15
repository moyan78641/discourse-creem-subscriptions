# frozen_string_literal: true

module CreemSubscriptions
  class WebhookHandler
    def self.handle(event_type, data)
      case event_type
      when "checkout.completed"
        handle_checkout_completed(data)
      when "subscription.paid"
        handle_subscription_paid(data)
      when "subscription.active"
        handle_subscription_active(data)
      when "subscription.canceled"
        handle_subscription_canceled(data)
      when "subscription.expired"
        handle_subscription_expired(data)
      else
        Rails.logger.info("[Creem] Unhandled event type: #{event_type}")
      end
    end

    def self.handle_checkout_completed(data)
      Rails.logger.info("[Creem] Checkout completed: #{data}")
      
      customer_email = data.dig("customer", "email")
      subscription_id = data.dig("subscription", "id")
      customer_id = data.dig("customer", "id")
      
      return unless customer_email.present?

      user = User.find_by_email(customer_email)
      return unless user

      user.custom_fields["creem_subscription_id"] = subscription_id
      user.custom_fields["creem_customer_id"] = customer_id
      user.custom_fields["creem_subscription_status"] = "active"
      user.save_custom_fields

      add_user_to_subscription_group(user)
      
      Rails.logger.info("[Creem] User #{user.username} subscription activated")
    end

    def self.handle_subscription_paid(data)
      Rails.logger.info("[Creem] Subscription paid: #{data}")
      
      subscription_id = data["id"]
      customer_email = data.dig("customer", "email")
      current_period_end = data["current_period_end"]

      user = find_user_by_subscription_or_email(subscription_id, customer_email)
      return unless user

      user.custom_fields["creem_subscription_status"] = "active"
      user.custom_fields["creem_subscription_end_date"] = current_period_end
      user.save_custom_fields

      add_user_to_subscription_group(user)
      
      Rails.logger.info("[Creem] User #{user.username} subscription renewed")
    end

    def self.handle_subscription_active(data)
      Rails.logger.info("[Creem] Subscription active: #{data}")
      
      subscription_id = data["id"]
      customer_email = data.dig("customer", "email")

      user = find_user_by_subscription_or_email(subscription_id, customer_email)
      return unless user

      user.custom_fields["creem_subscription_id"] = subscription_id
      user.custom_fields["creem_subscription_status"] = "active"
      user.save_custom_fields

      add_user_to_subscription_group(user)
    end

    def self.handle_subscription_canceled(data)
      Rails.logger.info("[Creem] Subscription canceled: #{data}")
      
      subscription_id = data["id"]
      
      user = find_user_by_subscription(subscription_id)
      return unless user

      user.custom_fields["creem_subscription_status"] = "canceled"
      user.save_custom_fields

      remove_user_from_subscription_group(user)
      
      Rails.logger.info("[Creem] User #{user.username} subscription canceled")
    end

    def self.handle_subscription_expired(data)
      Rails.logger.info("[Creem] Subscription expired: #{data}")
      
      subscription_id = data["id"]
      
      user = find_user_by_subscription(subscription_id)
      return unless user

      user.custom_fields["creem_subscription_status"] = "expired"
      user.save_custom_fields

      remove_user_from_subscription_group(user)
      
      Rails.logger.info("[Creem] User #{user.username} subscription expired")
    end

    def self.find_user_by_subscription(subscription_id)
      UserCustomField.where(name: "creem_subscription_id", value: subscription_id).first&.user
    end

    def self.find_user_by_subscription_or_email(subscription_id, email)
      user = find_user_by_subscription(subscription_id)
      user ||= User.find_by_email(email) if email.present?
      user
    end

    def self.add_user_to_subscription_group(user)
      group_id = SiteSetting.creem_subscription_group
      return if group_id.blank? || group_id.to_i == 0

      group = Group.find_by(id: group_id)
      return unless group

      unless group.users.include?(user)
        group.add(user)
        Rails.logger.info("[Creem] Added user #{user.username} to group #{group.name}")
      end
    end

    def self.remove_user_from_subscription_group(user)
      group_id = SiteSetting.creem_subscription_group
      return if group_id.blank? || group_id.to_i == 0

      group = Group.find_by(id: group_id)
      return unless group

      if group.users.include?(user)
        group.remove(user)
        Rails.logger.info("[Creem] Removed user #{user.username} from group #{group.name}")
      end
    end
  end
end
