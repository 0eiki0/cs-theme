import { apiInitializer } from "discourse/lib/api";
import ServerBanner from "../components/server-banner";
import OnlineUsers from "../components/online-users";
import TeamOnline from "../components/team-online";
import startTeamHeartbeat from "../lib/team-heartbeat";
import setupGuestPopup from "../lib/guest-popup";
import createUnreadSectionLink from "../lib/unread-section-link";

export default apiInitializer((api) => {
  if (settings.show_guest_popup) {
    setupGuestPopup(api);
  }

  if (settings.sidebar_unread_link) {
    api.addCommunitySectionLink(createUnreadSectionLink);
  }

  // In der Liste "Ungesehen" ist jedes Thema ungelesen. Discourse liefert für
  // nicht verfolgte Themen aber keine Anzahl ungelesener Beiträge mit – per
  // Body-Klasse werden dort deshalb alle Themen hervorgehoben.
  const router = api.container.lookup("service:router");
  router.on("routeDidChange", () => {
    const route = router.currentRouteName || "";
    document.body.classList.toggle(
      "cs-route-unseen",
      route.startsWith("discovery.unseen")
    );
  });

  if (settings.show_online_users) {
    // In der Seitenleiste unter den Kategorien
    api.renderInOutlet("after-sidebar-sections", OnlineUsers);
  }

  if (settings.show_banner) {
    api.renderInOutlet("above-main-container", ServerBanner);
  }

  if (settings.show_team_online) {
    // Steht im Discourse-Layout direkt vor der Themenliste und wird per CSS
    // als Spalte rechts daneben angeordnet.
    api.renderInOutlet("before-list-area", TeamOnline);

    if (settings.team_online_keep_alive) {
      startTeamHeartbeat(api.getCurrentUser());
    }
  }
});
