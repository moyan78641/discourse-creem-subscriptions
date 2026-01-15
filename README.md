# Discourse Creem Subscriptions

Creem payment integration for Discourse subscriptions.

## Installation

Add to your `app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/sparkloc/discourse-creem-subscriptions.git
```

Then rebuild: `./launcher rebuild app`

## Configuration

1. Go to Admin > Settings > Plugins
2. Enable `creem enabled`
3. Set `creem api key` (from Creem Dashboard > Developers)
4. Set `creem product id` (your subscription product ID)
5. Set `creem subscription group` (group to add subscribers to)
6. Set `creem webhook secret` (optional, for webhook verification)

## Webhook Setup

Configure webhook in Creem Dashboard:
- URL: `https://your-site.com/creem/webhooks`
- Events: `checkout.completed`, `subscription.active`, `subscription.paid`, `subscription.canceled`, `subscription.expired`

## Usage

Direct users to `/creem/checkout` to start the subscription flow.

## Routes

- `/creem` - Main page
- `/creem/checkout` - Start checkout (redirects to Creem)
- `/creem/success` - Payment success page
- `/creem/cancel` - Payment cancelled page
- `/creem/webhooks` - Webhook endpoint (POST)
- `/creem/api/checkout` - Checkout API (POST)

## Test Mode

Enable `creem test mode` to use `test-api.creem.io` for testing.
