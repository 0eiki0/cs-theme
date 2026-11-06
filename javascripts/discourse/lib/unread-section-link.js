import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";

// Seitenleisten-Link "Ungelesene Beiträge" ganz oben im Community-Bereich.
//
// Zwei Modi (Einstellung sidebar_unread_mode):
// - "alle": wie in klassischen Foren – alle Themen mit Beiträgen, die man noch
//   nicht gelesen hat, egal ob man das Thema verfolgt oder je geöffnet hat.
//   Nutzt die Discourse-Liste /unseen; der Zähler wird regelmäßig abgefragt.
// - "verfolgt": Discourse-Standard – neue Themen plus ungelesene Antworten in
//   verfolgten/beobachteten Themen (Zähler live aus topicTrackingState).
//
// Discourse prüft shouldDisplay nur beim Aufbau der Seitenleiste. Damit der
// Link sofort erscheint/verschwindet, ist er für angemeldete Nutzer immer
// vorhanden und wird per CSS ausgeblendet, solange er keinen Zähler hat
// (siehe common.scss, data-list-item-name="cs-unread").

const POLL_MS = 60 * 1000;
const CHANGE_DEBOUNCE_MS = 5 * 1000;

function allMode() {
  return settings.sidebar_unread_mode !== "verfolgt";
}

export default function createUnreadSectionLink(BaseSectionLink) {
  return class UnreadSectionLink extends BaseSectionLink {
    @service currentUser;
    @service topicTrackingState;

    @tracked totalUnread = 0;
    @tracked totalNew = 0;
    @tracked unseenCount = 0;
    @tracked unseenHasMore = false;

    pollTimer = null;
    debounceTimer = null;

    constructor() {
      super(...arguments);
      if (!this.currentUser) {
        return;
      }
      if (allMode()) {
        this.loadUnseen();
        this.pollTimer = setInterval(() => {
          if (document.visibilityState === "visible") {
            this.loadUnseen();
          }
        }, POLL_MS);
      } else {
        this.refreshCounts();
      }
    }

    teardown() {
      clearInterval(this.pollTimer);
      clearTimeout(this.debounceTimer);
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
        if (this.unseenCount <= 0) {
          return undefined;
        }
        return this.unseenHasMore ? `${this.unseenCount}+` : String(this.unseenCount);
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
      if (!allMode()) {
        this.refreshCounts();
        return;
      }
      // Neue Beiträge oder gelesene Themen → Zähler zeitnah neu abfragen
      clearTimeout(this.debounceTimer);
      this.debounceTimer = setTimeout(() => this.loadUnseen(), CHANGE_DEBOUNCE_MS);
    }

    refreshCounts() {
      this.totalUnread = this.topicTrackingState.countUnread();
      this.totalNew = this.topicTrackingState.countNew();
    }

    async loadUnseen() {
      try {
        const result = await ajax("/unseen.json");
        const list = result?.topic_list;
        this.unseenCount = list?.topics?.length || 0;
        this.unseenHasMore = !!list?.more_topics_url;
      } catch {
        // Zähler ist optional – beim nächsten Mal erneut versuchen
      }
    }
  };
}
