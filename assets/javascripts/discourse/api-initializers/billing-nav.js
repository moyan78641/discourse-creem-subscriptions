import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.0", (api) => {
  const currentUser = api.getCurrentUser();
  if (!currentUser) {
    return;
  }

  api.addQuickAccessProfileItem({
    icon: "credit-card",
    href: `/u/${currentUser.username}/billing/subscriptions`,
    content: "账单",
    className: "billing-link",
  });
});
