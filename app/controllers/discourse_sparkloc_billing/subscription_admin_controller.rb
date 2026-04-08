# frozen_string_literal: true

module ::DiscourseSparklocBilling
  class SubscriptionAdminController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    before_action :ensure_logged_in
    before_action :ensure_admin

    def index
      subs = SubscriptionStore.all_rows.filter_map do |row|
        username = row.key.sub("creem_subscription::", "")
        data = SubscriptionStore.parse(row.value)
        next if data.blank? || data["status"] == "none"

        user = User.find_by(username: username)
        {
          username: username,
          user_id: user&.id,
          status: data["status"],
          source: data["source"] || "creem",
          current_period_end: data["current_period_end"],
          created_at: data["created_at"],
          updated_at: data["updated_at"],
        }
      rescue
        nil
      end

      render json: { subscriptions: subs }
    end

    def create
      username = params[:username]
      months = (params[:months] || 1).to_i
      return render json: { error: "请填写用户名" }, status: 400 if username.blank?
      return render json: { error: "月数必须大于 0" }, status: 400 if months <= 0

      user = User.find_by(username: username)
      return render json: { error: "用户不存在" }, status: 404 unless user

      record = SubscriptionStore.load(username) || {}
      period_end = if record["status"] == "active" && record["current_period_end"].present?
                     Time.parse(record["current_period_end"])
                   else
                     Time.current
                   end
      new_period_end = period_end + months.months

      SubscriptionStore.save(
        username,
        {
          "status" => "active",
          "source" => "manual",
          "current_period_end" => new_period_end.iso8601,
          "manual_by" => current_user.username,
        },
      )

      group = Group.find_by(name: SiteSetting.sparkloc_creem_group_name)
      group&.add(user) unless group&.users&.include?(user)

      render json: { success: true, username: username, period_end: new_period_end.iso8601 }
    end

    def renew
      username = params[:username]
      months = (params[:months] || 1).to_i
      return render json: { error: "请填写用户名" }, status: 400 if username.blank?

      user = User.find_by(username: username)
      return render json: { error: "用户不存在" }, status: 404 unless user

      record = SubscriptionStore.load(username)
      return render json: { error: "该用户没有订阅记录" }, status: 404 if record.nil?

      period_end = if record["current_period_end"].present?
                     [Time.parse(record["current_period_end"]), Time.current].max
                   else
                     Time.current
                   end
      new_period_end = period_end + months.months

      SubscriptionStore.save(
        username,
        {
          "status" => "active",
          "current_period_end" => new_period_end.iso8601,
          "manual_by" => current_user.username,
        },
      )

      group = Group.find_by(name: SiteSetting.sparkloc_creem_group_name)
      group&.add(user) unless group&.users&.include?(user)

      render json: { success: true, username: username, period_end: new_period_end.iso8601 }
    end

    def cancel
      username = params[:username]
      return render json: { error: "请填写用户名" }, status: 400 if username.blank?

      user = User.find_by(username: username)
      return render json: { error: "用户不存在" }, status: 404 unless user

      record = SubscriptionStore.load(username)
      return render json: { error: "该用户没有订阅记录" }, status: 404 if record.nil?

      SubscriptionStore.save(
        username,
        {
          "status" => "canceled",
          "canceled_at" => Time.current.iso8601,
          "manual_by" => current_user.username,
        },
      )

      group = Group.find_by(name: SiteSetting.sparkloc_creem_group_name)
      group&.remove(user)

      render json: { success: true }
    end

    private

    def ensure_admin
      raise Discourse::InvalidAccess unless current_user&.admin?
    end
  end
end
