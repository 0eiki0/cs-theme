import { tracked } from "@glimmer/tracking";
import { withScheme } from "./calendar-scheme";

// Termine aus dem Kalender (cs-cal) für Banner und Box "Nächste Termine".
//
// Das Forum lädt dafür die unsichtbare Seite <calendar_url>/embed in einem
// versteckten iframe. Der Kalender meldet den Nutzer dort still über das
// Forum an (DiscourseConnect) und schickt per postMessage nur die Termine,
// die dieser Nutzer laut seinen Gruppen sehen darf.

const MAX_EVENTS = 50;
// So lange auf eine Antwort der Kalender-Seite warten (inkl. stillem Login)
const WATCHDOG_MS = 20 * 1000;
const RETRY_DELAYS_MS = [15 * 1000, 60 * 1000, 5 * 60 * 1000, 10 * 60 * 1000];
// Daten gelten nach dieser Zeit als veraltet (z. B. nach Standby)
const STALE_MS = 5 * 60 * 1000;

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
  frame = null;
  roleKey = null;
  failures = 0;
  lastLoad = 0;
  lastUpdate = 0;
  retryTimer = null;
  watchdog = null;
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

  start(url, username) {
    const baseUrl = CalendarFeed.normalizeUrl(url);
    if (this.started || !baseUrl) {
      return;
    }
    this.started = true;
    this.baseUrl = baseUrl;
    this.origin = new URL(baseUrl).origin;
    this.roleKey = `cs_calendar_role_${username || ""}`;

    // Zuletzt bekannte Rolle sofort anwenden, damit der Punkt "Kalender"
    // nicht erst nach dem Laden erscheint (wird gleich danach geprüft).
    try {
      const cachedRole = localStorage.getItem(this.roleKey);
      if (cachedRole === "team" || cachedRole === "buddy") {
        this.applyRole(cachedRole);
      }
    } catch {
      // localStorage gesperrt
    }

    window.addEventListener("message", this.onMessage);
    document.addEventListener("visibilitychange", this.onVisible);
    window.addEventListener("online", () => this.reload());

    this.reload();
    setInterval(() => (this.now = Date.now()), 60 * 1000);
  }

  /** Lädt die unsichtbare Kalender-Seite (neu) */
  reload() {
    clearTimeout(this.retryTimer);
    clearTimeout(this.watchdog);
    this.frame?.remove();

    const iframe = document.createElement("iframe");
    // Zeitstempel verhindert, dass ein Browser eine alte Antwort wiederverwendet
    iframe.src = `${this.baseUrl}/embed?t=${Date.now()}`;
    iframe.title = "Kalender";
    iframe.className = "cs-cal-feed";
    iframe.tabIndex = -1;
    iframe.setAttribute("aria-hidden", "true");
    document.body.appendChild(iframe);
    this.frame = iframe;
    this.lastLoad = Date.now();

    // Keine Antwort (z. B. Netzwerk weg, Server neu gestartet) -> erneut versuchen
    this.watchdog = setTimeout(() => this.retryLater(), WATCHDOG_MS);
  }

  /** Erneuter Versuch mit wachsendem Abstand: 15 s, 1 min, 5 min, dann alle 10 min */
  retryLater() {
    clearTimeout(this.retryTimer);
    const delay = RETRY_DELAYS_MS[Math.min(this.failures, RETRY_DELAYS_MS.length - 1)];
    this.failures++;
    this.retryTimer = setTimeout(() => this.reload(), delay);
  }

  // Zurück im Tab (z. B. morgens nach dem Standby): veraltete Daten auffrischen
  onVisible = () => {
    if (
      document.visibilityState === "visible" &&
      Date.now() - (this.lastUpdate || 0) > STALE_MS
    ) {
      this.reload();
    }
  };

  applyRole(role) {
    this.role = role;
    // Blendet u. a. den Seitenleisten-Punkt "Kalender" ein
    document.body.classList.toggle("cs-has-calendar", role !== null);
  }

  onMessage = (event) => {
    if (event.origin !== this.origin) {
      return;
    }
    const data = event.data;
    if (!data || data.version !== 1) {
      return;
    }
    if (data.type === "cscal:error") {
      clearTimeout(this.watchdog);
      this.retryLater();
      return;
    }
    if (data.type !== "cscal:events") {
      return;
    }
    clearTimeout(this.watchdog);

    const role = data.role === "team" || data.role === "buddy" ? data.role : null;

    // Ohne Rolle, aber nicht wegen fehlender Rechte (Login hakte, Sitzung
    // abgelaufen, Cookie blockiert): bisherigen Stand behalten, später erneut.
    if (!role && data.reason && data.reason !== "no_access") {
      this.loaded = true;
      this.retryLater();
      return;
    }

    this.failures = 0;
    this.lastUpdate = Date.now();
    this.applyRole(role);
    this.events = Array.isArray(data.events)
      ? data.events.filter(isValidEvent).slice(0, MAX_EVENTS).map(cleanEvent)
      : [];
    this.loaded = true;
    this.now = Date.now();

    try {
      if (role) {
        localStorage.setItem(this.roleKey, role);
      } else {
        localStorage.removeItem(this.roleKey);
      }
    } catch {
      // egal
    }
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
