import { apiInitializer } from "discourse/lib/api";
import ServerBanner from "../components/server-banner";
import TeamOnline from "../components/team-online";

export default apiInitializer((api) => {
  if (settings.show_banner) {
    api.renderInOutlet("above-main-container", ServerBanner);
  }

  if (settings.show_team_online) {
    // Steht im Discourse-Layout direkt vor der Themenliste und wird per CSS
    // als Spalte rechts daneben angeordnet.
    api.renderInOutlet("before-list-area", TeamOnline);
  }
});
