import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import unreadCounter from "./unread-counter";

// Seitenleisten-Link "Ungelesene Beiträge" ganz oben im Community-Bereich.
//
// Zwei Modi (Einstellung sidebar_unread_mode):
// - "alle": wie in klassischen Foren – alle Themen mit Beiträgen, die man noch
//   nicht gelesen hat, egal ob man das Thema verfolgt oder je geöffnet hat.
//   Nutzt die Discourse-Liste /unseen; der Zähler aktualisiert sich live
//   (siehe unread-counter.js, wird im Initializer gestartet).
// - "verfolgt": Discourse-Standard – neue Themen plus ungelesene Antworten in
//   verfolgten/beobachteten Themen (Zähler live aus topicTrackingState).
//
// Discourse prüft shouldDisplay nur beim Aufbau der Seitenleiste. Damit der
// Link sofort erscheint/verschwindet, ist er für angemeldete Nutzer immer
// vorhanden und wird per CSS ausgeblendet, solange er keinen Zähler hat
// (siehe common.scss, data-list-item-name="cs-unread").

function allMode() {
  return settings.sidebar_unread_mode !== "verfolgt";
}

export default function createUnreadSectionLink(BaseSectionLink) {
  return class UnreadSectionLink extends BaseSectionLink {
    @service currentUser;
    @service topicTrackingState;

    @tracked totalUnread = 0;
    @tracked totalNew = 0;

    constructor() {
      super(...arguments);
      if (!allMode()) {
        this.refreshCounts();
      }
    }

    teardown() {
      // Der Zähler läuft unabhängig vom Link weiter (unread-counter.js)
    }

    get name() {
      return "cs-unread";
    }

    get shouldDisplay() {
      return !!this.currentUser;
    }

    get text() {
      return settings.sidebar_unread_link_text || "Ungelesene Beiträge";
    }

    get title() {
      return this.text;
    }

    // Leer = Link ausgeblendet (CSS)
    get badgeText() {
      if (allMode()) {
        if (unreadCounter.count <= 0) {
          return undefined;
        }
        return unreadCounter.hasMore
          ? `${unreadCounter.count}+`
          : String(unreadCounter.count);
      }
      const total = this.totalUnread + this.totalNew;
      return total > 0 ? String(total) : undefined;
    }

    get route() {
      if (allMode()) {
        return "discovery.unseen";
      }
      // Mit "neuer Neu-Ansicht" zeigt /new neue Themen und ungelesene
      // Antworten zusammen. Sonst: zuerst ungelesene Antworten, dann neue.
      if (this.currentUser?.unified_new_enabled) {
        return "discovery.new";
      }
      return this.totalUnread > 0 ? "discovery.unread" : "discovery.new";
    }

    get defaultPrefixValue() {
      return "bell";
    }

    onTopicTrackingStateChange() {
      if (allMode()) {
        unreadCounter.scheduleRefresh();
      } else {
        this.refreshCounts();
      }
    }

    refreshCounts() {
      this.totalUnread = this.topicTrackingState.countUnread();
      this.totalNew = this.topicTrackingState.countNew();
    }
  };
}
