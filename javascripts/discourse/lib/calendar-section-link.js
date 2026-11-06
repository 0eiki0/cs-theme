import { service } from "@ember/service";

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

    // Ziel nur für den Fall, dass der Klick nicht abgefangen wird
    get route() {
      return "discovery.latest";
    }

    get defaultPrefixValue() {
      return "calendar-days";
    }
  };
}
