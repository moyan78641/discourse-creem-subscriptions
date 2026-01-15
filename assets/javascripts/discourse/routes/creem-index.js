import Route from "@ember/routing/route";
import { service } from "@ember/service";

export default class CreemIndexRoute extends Route {
  @service router;

  beforeModel() {
    // Redirect to checkout by default
    this.router.transitionTo("creem.checkout");
  }
}
