import Route from "@ember/routing/route";

export default class CreemSuccessRoute extends Route {
  model(params) {
    const sessionId = new URLSearchParams(window.location.search).get("session_id");
    return { 
      sessionId: sessionId,
      valid: !!sessionId 
    };
  }
}
