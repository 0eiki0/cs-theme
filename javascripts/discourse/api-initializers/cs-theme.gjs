import { apiInitializer } from "discourse/lib/api";
import ServerBanner from "../components/server-banner";

export default apiInitializer((api) => {
  if (!settings.show_banner) {
    return;
  }

  api.renderInOutlet("above-main-container", ServerBanner);
});
