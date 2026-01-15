export default function () {
  this.route("creem", { path: "/creem" }, function () {
    this.route("checkout");
    this.route("success");
    this.route("cancel");
  });
}
