# frozen_string_literal: true

module Jobs
  class SparklocBillingCheckCanceledSubscriptions < ::Jobs::Scheduled
    every 1.hour
    CREEM_SYNC_GRACE_PERIOD = 30.minutes

    def execute(_args)
      return unless SiteSetting.sparkloc_creem_enabled

      group = Group.find_by(name: SiteSetting.sparkloc_creem_group_name)
      unless group
        Rails.logger.error("[Creem] scheduled job: group '#{SiteSetting.sparkloc_creem_group_name}' does not exist")
        return
      end

      DiscourseSparklocBilling::SubscriptionStore.all_rows.each do |row|
        begin
          record = DiscourseSparklocBilling::SubscriptionStore.parse(row.value)
          next if record.blank? || record["current_period_end"].blank?

          username = row.key.sub("creem_subscription::", "")
          user = User.find_by(username: username)
          period_end = parse_time(record["current_period_end"])
          next if period_end.nil?

          if expired_canceled_subscription?(record, period_end) || expired_manual_subscription?(record, period_end)
            expire_record(username, record, user, group)
            next
          end

          next unless should_sync_creem_subscription?(record, period_end)

          sync_creem_subscription(username, record, user, group)
        rescue => e
          Rails.logger.error("[Creem] scheduled job failed for #{row.key}: #{e.message}")
        end
      end
    end

    private

    def expired_canceled_subscription?(record, period_end)
      record["status"] == "canceled" && period_end <= Time.current
    end

    def expired_manual_subscription?(record, period_end)
      record["status"] == "active" && record["source"] == "manual" && period_end <= Time.current
    end

    def should_sync_creem_subscription?(record, period_end)
      return false if record["source"] == "manual"
      return false if record["creem_subscription_id"].blank?
      return false if %w[expired refunded paused].include?(record["status"])

      period_end <= Time.current - CREEM_SYNC_GRACE_PERIOD
    end

    def sync_creem_subscription(username, record, user, group)
      sub_id = record["creem_subscription_id"]
      resp = DiscourseSparklocBilling::CreemClient.fetch_subscription(sub_id)
      unless resp.is_a?(Net::HTTPSuccess)
        Rails.logger.error("[Creem] scheduled job: failed to fetch subscription #{sub_id}: #{resp.code} #{resp.body}")
        return
      end

      payload = DiscourseSparklocBilling::CreemClient.parse_json(resp)
      unless payload
        Rails.logger.error("[Creem] scheduled job: invalid subscription payload for #{sub_id}")
        return
      end

      synced = record.merge(DiscourseSparklocBilling::CreemClient.extract_subscription_attrs(payload))
      new_period_end = parse_time(synced["current_period_end"])
      status = synced["status"]

      if subscription_still_active?(status, new_period_end)
        DiscourseSparklocBilling::SubscriptionStore.save(username, synced)
        group.add(user) if user && !group.users.include?(user)
        Rails.logger.info("[Creem] scheduled job: synced #{username}, status=#{status}, period_end=#{synced["current_period_end"]}")
        return
      end

      cancel_creem_subscription_immediately(sub_id)
      synced["status"] = terminal_status_for(status)
      synced["canceled_at"] ||= Time.current.iso8601
      DiscourseSparklocBilling::SubscriptionStore.save(username, synced)

      if user
        group.remove(user)
        Rails.logger.info("[Creem] scheduled job: #{username} was not renewed in time, subscription removed immediately")
      end
    end

    def cancel_creem_subscription_immediately(subscription_id)
      resp = DiscourseSparklocBilling::CreemClient.cancel_subscription(subscription_id, mode: "immediate")
      return if resp.is_a?(Net::HTTPSuccess)

      Rails.logger.error("[Creem] scheduled job: immediate cancel failed for #{subscription_id}: #{resp.code} #{resp.body}")
    rescue => e
      Rails.logger.error("[Creem] scheduled job: immediate cancel errored for #{subscription_id}: #{e.message}")
    end

    def subscription_still_active?(status, period_end)
      return false if period_end.nil?

      %w[active trialing scheduled_cancel].include?(status) && period_end > Time.current
    end

    def terminal_status_for(status)
      return "expired" if status.blank?
      return "expired" if %w[active trialing scheduled_cancel canceled past_due unpaid].include?(status)

      status
    end

    def expire_record(username, record, user, group)
      group.remove(user) if user
      Rails.logger.info("[Creem] scheduled job: #{username} expired and was removed from the group") if user

      record["status"] = "expired"
      DiscourseSparklocBilling::SubscriptionStore.save(username, record)
    end

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value)
    rescue => _
      begin
        Time.parse(value)
      rescue => _
        nil
      end
    end
  end
end
