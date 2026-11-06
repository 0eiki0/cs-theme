import { apiInitializer } from "discourse/lib/api";
import ServerBanner from "../components/server-banner";
import OnlineUsers from "../components/online-users";
import TeamOnline from "../components/team-online";
import startTeamHeartbeat from "../lib/team-heartbeat";

export default apiInitializer((api) => {
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
