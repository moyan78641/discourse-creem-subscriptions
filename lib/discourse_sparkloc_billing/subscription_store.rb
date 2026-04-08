# frozen_string_literal: true

module ::DiscourseSparklocBilling
  module SubscriptionStore
    module_function

    def key_for(username)
      "creem_subscription::#{username}"
    end

    def load(username)
      raw = PluginStore.get(DiscourseSparklocBilling::STORE_NAMESPACE, key_for(username))
      parse(raw)
    end

    def save(username, attrs)
      key = key_for(username)
      record = load(username) || {}
      record.merge!(attrs)
      record["updated_at"] = Time.current.iso8601
      record["created_at"] ||= Time.current.iso8601
      PluginStore.set(DiscourseSparklocBilling::STORE_NAMESPACE, key, record.to_json)
      record
    end

    def all_rows
      PluginStoreRow.where(plugin_name: DiscourseSparklocBilling::STORE_NAMESPACE)
                    .where("key LIKE ?", "creem_subscription::%")
    end

    def parse(raw)
      return nil if raw.nil?
      return raw if raw.is_a?(Hash)

      JSON.parse(raw)
    rescue JSON::ParserError
      nil
    end
  end
end
