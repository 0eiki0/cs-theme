import { service } from "@ember/service";
import calendarFeed, { normalizeCalendarUrl } from "./calendar-feed";

// Punkt "Kalender" in der Seitenleiste (Community-Bereich).
//
// Discourse prüft shouldDisplay nur beim Aufbau der Seitenleiste, die
// Kalender-Rolle kommt aber erst danach. Deshalb ist der Link für alle
// angemeldeten Nutzer (aus calendar_groups) vorhanden und wird per CSS erst
// eingeblendet, wenn der Kalender Zugriff bestätigt hat (body.cs-has-calendar).
// Der Klick wird im Initializer abgefangen und öffnet den Kalender im Forum.

export default function createCalendarSectionLink(BaseSectionLink) {
  return class CalendarSectionLink extends BaseSectionLink {
    @service currentUser;

    get name() {
      return "cs-calendar";
    }

    get shouldDisplay() {
      return !!this.currentUser;
    }

    get text() {
      return settings.calendar_sidebar_text || "Kalender";
    }

    get title() {
      return this.text;
    }

    // Echte Adresse statt einer Forum-Route: So markiert Discourse den Punkt
    // nicht als aktiv (vorher: zusammen mit "Themen"), und Strg-/Mittelklick
    // öffnet den Kalender direkt in einem neuen Tab. Ein normaler Klick wird
    // im Initializer abgefangen und öffnet das Fenster im Forum.
    get href() {
      return (
        calendarFeed.pageUrl ||
        `${normalizeCalendarUrl(settings.calendar_url) || ""}/`
      );
    }

    get defaultPrefixValue() {
      return "calendar-days";
    }
  };
}
