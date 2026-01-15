# frozen_string_literal: true

module CreemSubscriptions
  class CreemApi
    def self.base_url
      SiteSetting.creem_test_mode ? "https://test-api.creem.io" : "https://api.creem.io"
    end

    def self.api_key
      SiteSetting.creem_api_key
    end

    def self.headers
      {
        "Authorization" => "Bearer #{api_key}",
        "Content-Type" => "application/json"
      }
    end

    def self.create_checkout(product_id:, customer_email:, success_url:, cancel_url:, metadata: {})
      url = "#{base_url}/v1/checkouts"
      
      payload = {
        product_id: product_id,
        customer_email: customer_email,
        success_url: success_url,
        cancel_url: cancel_url,
        metadata: metadata
      }

      response = Excon.post(url, headers: headers, body: payload.to_json)
      JSON.parse(response.body)
    end

    def self.get_subscription(subscription_id)
      url = "#{base_url}/v1/subscriptions/#{subscription_id}"
      response = Excon.get(url, headers: headers)
      JSON.parse(response.body)
    end

    def self.verify_webhook_signature(payload, signature)
      secret = SiteSetting.creem_webhook_secret
      return true if secret.blank? # Skip verification if no secret configured
      
      expected = OpenSSL::HMAC.hexdigest("sha256", secret, payload)
      ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
    end
  end
end
