export default {
  resource: "creem",
  path: "/creem",
  map() {
    this.route("checkout");
    this.route("success");
    this.route("cancel");
  },
};
