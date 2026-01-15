import Route from "@ember/routing/route";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";

export default class CreemCheckoutRoute extends Route {
  @service router;

  beforeModel() {
    if (!this.currentUser) {
      this.router.transitionTo("login");
    }
  }

  async model() {
    try {
      const result = await ajax("/creem-api/checkout", { type: "POST" });
      if (result.checkout_url) {
        window.location.href = result.checkout_url;
        return { redirecting: true };
      }
      return { error: "No checkout URL returned" };
    } catch (e) {
      return { error: e.jqXHR?.responseJSON?.error || "Failed to create checkout" };
    }
  }
}
