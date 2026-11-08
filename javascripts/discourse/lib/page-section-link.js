import { service } from "@ember/service";
import { canSeePage } from "./embedded-pages";

// Seitenleisten-Punkt für eine eingetragene Seite (embedded_pages).
// Der Klick wird im Initializer abgefangen und öffnet das Fenster.

export default function createPageSectionLink(page) {
  return (BaseSectionLink) =>
    class PageSectionLink extends BaseSectionLink {
      @service currentUser;

      get name() {
        return page.key;
      }

      get shouldDisplay() {
        return canSeePage(page, this.currentUser);
      }

      get text() {
        return page.label;
      }

      get title() {
        return page.label;
      }

      // Ziel nur für den Fall, dass der Klick nicht abgefangen wird
      get route() {
        return "discovery.latest";
      }

      get defaultPrefixValue() {
        return page.icon;
      }
    };
}
