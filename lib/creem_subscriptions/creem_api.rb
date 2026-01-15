# frozen_string_literal: true

module CreemSubscriptions
  class CreemApi
    def self.base_url
      if SiteSetting.creem_test_mode
        "https://test-api.creem.io"
      else
        "https://api.creem.io"
      end
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

    # Create a checkout session
    def self.create_checkout(product_id:, customer_email:, success_url:, cancel_url:, metadata: {})
      url = "#{base_url}/v1/checkouts"
      
      payload = {
        product_id: product_id,
        customer_email: customer_email,
        success_url: success_url,
        cancel_url: cancel_url,
        metadata: metadata
      }

      response = Excon.post(
        url,
        headers: headers,
        body: payload.to_json
      )

      JSON.parse(response.body)
    end

    # Get subscription details
    def self.get_subscription(subscription_id)
      url = "#{base_url}/v1/subscriptions/#{subscription_id}"
      
      response = Excon.get(url, headers: headers)
      JSON.parse(response.body)
    end

    # Cancel subscription
    def self.cancel_subscription(subscription_id)
      url = "#{base_url}/v1/subscriptions/#{subscription_id}/cancel"
      
      response = Excon.post(url, headers: headers)
      JSON.parse(response.body)
    end

    # Verify webhook signature
    def self.verify_webhook_signature(payload, signature)
      secret = SiteSetting.creem_webhook_secret
      return false if secret.blank?

      expected_signature = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        secret,
        payload
      )

      ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
    end
  end
end
