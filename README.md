# Discourse Creem Subscriptions

Creem 支付集成插件，为 Discourse 提供订阅付费功能。

## 功能

- 集成 Creem 支付平台
- 支持订阅制付费
- 自动管理用户群组权限
- 支持测试模式
- Webhook 自动处理订阅状态

## 安装

1. 编辑 `containers/app.yml`，在 hooks 部分添加：

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/你的用户名/discourse-creem-subscriptions.git
```

2. 重建容器：

```bash
./launcher rebuild app
```

## 配置

在 Discourse 后台 **管理 → 设置** 搜索 `creem`：

| 设置项 | 说明 |
|-------|------|
| creem_enabled | 启用插件 |
| creem_test_mode | 测试模式（使用 test-api.creem.io） |
| creem_api_key | Creem API 密钥 |
| creem_webhook_secret | Webhook 签名密钥 |
| creem_subscription_group | 订阅用户加入的群组名 |
| creem_product_id | Creem 产品 ID |

## Creem 配置

1. 在 Creem Dashboard 创建产品
2. 复制产品 ID 填入 `creem_product_id`
3. 在 Developers 页面获取 API Key
4. 配置 Webhook URL：`https://你的域名/creem/webhooks`
5. 复制 Webhook Secret 填入 `creem_webhook_secret`

## 使用

### 订阅链接

用户访问以下链接即可发起订阅：

```
https://你的域名/creem/checkout/产品ID
```

或使用默认产品：

```
https://你的域名/creem/checkout
```

### 查询订阅状态

```
GET /creem/subscriptions
```

返回当前用户的订阅状态。

## Webhook 事件

插件自动处理以下事件：

- `checkout.completed` - 支付完成
- `subscription.paid` - 订阅续费
- `subscription.active` - 订阅激活
- `subscription.canceled` - 订阅取消
- `subscription.expired` - 订阅过期

## 测试

1. 开启 `creem_test_mode`
2. 使用 Creem 测试 API Key
3. 使用测试卡号：`4242 4242 4242 4242`

## License

MIT
