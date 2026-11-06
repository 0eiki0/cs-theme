import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";

// Seitenleisten-Link "Ungelesene Beiträge" ganz oben im Community-Bereich.
//
// Discourse prüft shouldDisplay nur beim Aufbau der Seitenleiste. Damit der
// Link sofort erscheint/verschwindet, ist er für angemeldete Nutzer immer
// vorhanden und wird per CSS ausgeblendet, solange er keinen Zähler hat
// (siehe common.scss, data-list-item-name="cs-unread").
export default function createUnreadSectionLink(BaseSectionLink) {
  return class UnreadSectionLink extends BaseSectionLink {
    @service currentUser;
    @service topicTrackingState;

    @tracked totalUnread = 0;
    @tracked totalNew = 0;

    constructor() {
      super(...arguments);
      this.refreshCounts();
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

    get total() {
      return this.totalUnread + this.totalNew;
    }

    // Leer = Link ausgeblendet (CSS)
    get badgeText() {
      return this.total > 0 ? String(this.total) : undefined;
    }

    // Mit "neuer Neu-Ansicht" zeigt /new neue Themen und ungelesene Antworten
    // zusammen. Sonst: zuerst ungelesene Antworten, dann neue Themen.
    get route() {
      if (this.currentUser?.unified_new_enabled) {
        return "discovery.new";
      }
      return this.totalUnread > 0 ? "discovery.unread" : "discovery.new";
    }

    get defaultPrefixValue() {
      return "bell";
    }

    onTopicTrackingStateChange() {
      this.refreshCounts();
    }

    refreshCounts() {
      if (!this.currentUser) {
        return;
      }
      this.totalUnread = this.topicTrackingState.countUnread();
      this.totalNew = this.topicTrackingState.countNew();
    }
  };
}
