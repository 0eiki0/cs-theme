import { tracked } from "@glimmer/tracking";
import { withScheme } from "./calendar-scheme";

// Termine aus dem Kalender (cs-cal) für Banner und Box "Nächste Termine".
//
// Das Forum lädt dafür die unsichtbare Seite <calendar_url>/embed in einem
// versteckten iframe. Der Kalender meldet den Nutzer dort still über das
// Forum an (DiscourseConnect) und schickt per postMessage nur die Termine,
// die dieser Nutzer laut seinen Gruppen sehen darf.

const MAX_EVENTS = 50;

function isValidEvent(ev) {
  return (
    ev &&
    typeof ev === "object" &&
    typeof ev.title === "string" &&
    typeof ev.start === "string" &&
    Number.isFinite(ev.startMs) &&
    Number.isFinite(ev.endMs)
  );
}

function cleanEvent(ev) {
  return {
    id: String(ev.id),
    title: ev.title,
    category: typeof ev.category === "string" ? ev.category : "Sonstiges",
    description: typeof ev.description === "string" ? ev.description : "",
    allDay: !!ev.allDay,
    start: ev.start,
    end: typeof ev.end === "string" ? ev.end : ev.start,
    startMs: ev.startMs,
    endMs: ev.endMs,
  };
}

class CalendarFeed {
  @tracked role = null;
  @tracked events = [];
  @tracked loaded = false;
  // Wird jede Minute aktualisiert, damit Banner/Box ohne Neuladen weiterlaufen
  @tracked now = Date.now();

  started = false;
  origin = null;
  baseUrl = null;
  // Wird im Initializer gesetzt (braucht den Modal-Service)
  openHandler = null;

  /** URL des Kalenders ohne / am Ende, oder null wenn ungültig */
  static normalizeUrl(url) {
    try {
      const parsed = new URL(String(url || "").trim());
      if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
        return null;
      }
      return parsed.href.replace(/\/+$/, "");
    } catch {
      return null;
    }
  }

  start(url) {
    const baseUrl = CalendarFeed.normalizeUrl(url);
    if (this.started || !baseUrl) {
      return;
    }
    this.started = true;
    this.baseUrl = baseUrl;
    this.origin = new URL(baseUrl).origin;

    window.addEventListener("message", this.onMessage);

    const iframe = document.createElement("iframe");
    iframe.src = `${baseUrl}/embed`;
    iframe.title = "Kalender";
    iframe.className = "cs-cal-feed";
    iframe.tabIndex = -1;
    iframe.setAttribute("aria-hidden", "true");
    document.body.appendChild(iframe);

    setInterval(() => (this.now = Date.now()), 60 * 1000);
  }

  onMessage = (event) => {
    if (event.origin !== this.origin) {
      return;
    }
    const data = event.data;
    if (!data || data.version !== 1 || data.type !== "cscal:events") {
      return;
    }
    this.role = data.role === "team" || data.role === "buddy" ? data.role : null;
    this.events = Array.isArray(data.events)
      ? data.events.filter(isValidEvent).slice(0, MAX_EVENTS).map(cleanEvent)
      : [];
    this.loaded = true;
    this.now = Date.now();
    // Blendet u. a. den Seitenleisten-Punkt "Kalender" ein
    document.body.classList.toggle("cs-has-calendar", this.role !== null);
  };

  /** Kalender-Seite passend zur Rolle; vor der ersten Antwort die Startseite (leitet selbst weiter) */
  get pageUrl() {
    if (!this.baseUrl) {
      return null;
    }
    // Mit ?scheme=…, damit der Kalender hell/dunkel wie das Forum ist
    if (this.role === "team") {
      return withScheme(`${this.baseUrl}/team`);
    }
    if (this.role === "buddy") {
      return withScheme(`${this.baseUrl}/buddy`);
    }
    return withScheme(`${this.baseUrl}/`);
  }

  /** Kalender im Forum öffnen (großes Fenster) */
  open() {
    this.openHandler?.();
  }

  /** Eigener Link aus den Einstellungen (z. B. Forum-Thema) oder null */
  get customLink() {
    const custom =
      this.role === "team"
        ? settings.calendar_team_link
        : settings.calendar_buddy_link;
    return custom && custom.trim() ? custom.trim() : null;
  }
}

const calendarFeed = new CalendarFeed();
export default calendarFeed;

export function normalizeCalendarUrl(url) {
  return CalendarFeed.normalizeUrl(url);
}
