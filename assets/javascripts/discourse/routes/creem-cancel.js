import Route from "@ember/routing/route";

export default class CreemCancelRoute extends Route {
  model() {
    return { canceled: true };
  }
}
