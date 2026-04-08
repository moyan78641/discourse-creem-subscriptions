# frozen_string_literal: true

# name: discourse-creem-subscriptions
# about: Creem subscription billing for Discourse with legacy Sparkloc data compatibility
# version: 0.1.0
# authors: Sparkloc
# url: https://sparkloc.com

module ::DiscourseSparklocBilling
  PLUGIN_NAME = "discourse-creem-subscriptions"
  STORE_NAMESPACE = "discourse-sparkloc-plugin"
end

require_relative "lib/discourse_sparkloc_billing/engine"
require_relative "lib/discourse_sparkloc_billing/creem_client"
require_relative "lib/discourse_sparkloc_billing/subscription_store"

register_asset "stylesheets/common/sparkloc-billing.scss"

after_initialize do
  register_svg_icon "credit-card"
  register_svg_icon "book"
  register_svg_icon "external-link-alt"
end
