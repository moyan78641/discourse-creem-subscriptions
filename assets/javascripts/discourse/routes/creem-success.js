import Route from "@ember/routing/route";

export default class CreemSuccessRoute extends Route {
  model() {
    const params = new URLSearchParams(window.location.search);
    return {
      sessionId: params.get("session_id"),
      success: true
    };
  }
}
