import { apiInitializer } from "discourse/lib/api";
import ServerBanner from "../components/server-banner";
import OnlineUsers from "../components/online-users";
import TeamOnline from "../components/team-online";
import startTeamHeartbeat from "../lib/team-heartbeat";

export default apiInitializer((api) => {
  if (settings.show_online_users) {
    // Direkt unter dem Seiteninhalt (innerhalb des Hauptbereichs, damit die
    // Box im Layout mit Seitenleiste richtig sitzt). Erscheint wie die
    // Fußleiste erst, wenn das Ende einer Seite erreicht ist.
    api.renderInOutlet("main-outlet-bottom", OnlineUsers);
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
