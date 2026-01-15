import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class CreemCheckoutRoute extends Route {
  async model() {
    try {
      const result = await ajax("/creem/api/checkout", { type: "POST" });
      if (result.checkout_url) {
        window.location.href = result.checkout_url;
      }
      return result;
    } catch (e) {
      return { error: e.jqXHR?.responseJSON?.error || "发起支付失败" };
    }
  }
}
