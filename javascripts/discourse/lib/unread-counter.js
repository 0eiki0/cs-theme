import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

// Zähler für "Ungelesene Beiträge" im Modus "alle" (Discourse-Liste /unseen).
//
// Aktualisiert sich von selbst:
// - sofort beim Laden der Seite
// - live, sobald Discourse neue Beiträge meldet (MessageBus /latest, /new)
//   oder sich der Lesestand ändert (z. B. Thema gelesen)
// - beim Zurückkehren in den Tab bzw. ins Fenster
// - nach jedem Seitenwechsel im Forum
// - und zur Sicherheit alle 30 Sekunden, solange der Tab sichtbar ist

const POLL_MS = 30 * 1000;
// Mehrere Meldungen kurz hintereinander zu einer Abfrage zusammenfassen
const CHANGE_DELAY_MS = 1200;
// Nicht öfter als alle 3 Sekunden abfragen (außer bei echten Neuigkeiten)
const MIN_GAP_MS = 3 * 1000;

class UnreadCounter {
  @tracked count = 0;
  @tracked hasMore = false;

  started = false;
  loading = null;
  again = false;
  lastLoad = 0;
  changeTimer = null;

  start({ messageBus, topicTrackingState, router }) {
    if (this.started) {
      return;
    }
    this.started = true;

    this.refresh(true);

    setInterval(() => {
      if (document.visibilityState === "visible") {
        this.refresh();
      }
    }, POLL_MS);

    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState === "visible") {
        this.refresh();
      }
    });
    window.addEventListener("focus", () => this.refresh());
    window.addEventListener("online", () => this.refresh(true));

    // Live-Meldungen von Discourse
    topicTrackingState?.onStateChange?.(() => this.scheduleRefresh());
    ["/latest", "/new"].forEach((channel) => {
      try {
        messageBus?.subscribe(channel, () => this.scheduleRefresh());
      } catch {
        // MessageBus nicht verfügbar – dann eben per Abfrage
      }
    });

    router?.on?.("routeDidChange", () => this.scheduleRefresh(400));
  }

  scheduleRefresh(delay = CHANGE_DELAY_MS) {
    clearTimeout(this.changeTimer);
    this.changeTimer = setTimeout(() => this.refresh(true), delay);
  }

  async refresh(force = false) {
    if (this.loading) {
      // Läuft gerade – danach noch einmal, damit nichts verloren geht
      this.again ||= force;
      return this.loading;
    }
    if (!force && Date.now() - this.lastLoad < MIN_GAP_MS) {
      return;
    }
    this.lastLoad = Date.now();

    this.loading = ajax("/unseen.json")
      .then((result) => {
        const list = result?.topic_list;
        this.count = list?.topics?.length || 0;
        this.hasMore = !!list?.more_topics_url;
      })
      .catch(() => {
        // Beim nächsten Anlass erneut versuchen
      })
      .finally(() => {
        this.loading = null;
        if (this.again) {
          this.again = false;
          this.refresh(true);
        }
      });
    return this.loading;
  }
}

const unreadCounter = new UnreadCounter();
export default unreadCounter;
