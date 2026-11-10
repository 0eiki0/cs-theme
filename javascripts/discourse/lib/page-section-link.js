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

      // Echte Adresse statt einer Forum-Route (siehe calendar-section-link.js)
      get href() {
        return page.url;
      }

      get defaultPrefixValue() {
        return page.icon;
      }
    };
}
