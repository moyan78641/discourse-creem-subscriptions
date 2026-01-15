import RouteTemplate from "ember-route-template";

export default RouteTemplate(
  <template>
    <div class="creem-page">
      {{#if @controller.model.error}}
        <div class="creem-error">
          <div class="creem-icon">❌</div>
          <h1>支付发起失败</h1>
          <p>{{@controller.model.error}}</p>
          <a href="/" class="btn btn-primary">返回首页</a>
        </div>
      {{else}}
        <div class="creem-loading">
          <div class="spinner"></div>
          <p>正在跳转到支付页面...</p>
        </div>
      {{/if}}
    </div>
  </template>
);
