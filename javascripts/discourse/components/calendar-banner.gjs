import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import calendarFeed from "../lib/calendar-feed";
import { categorySlug, formatStartsWhen } from "../lib/calendar-format";

// Hinweis-Banner X Stunden vor Beginn eines Termins. Weggeklickte Termine
// bleiben in diesem Browser ausgeblendet. Wird ein Termin verschoben,
// erscheint der Hinweis erneut.

const STORAGE_KEY = "cs_calendar_dismissed";
const MAX_ITEMS = 3;

function loadDismissed() {
  try {
    const data = JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}");
    return data && typeof data === "object" ? data : {};
  } catch {
    return {};
  }
}

function saveDismissed(data) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  } catch {
    // z. B. privater Modus – dann eben nur bis zum Neuladen ausgeblendet
  }
}

function dismissKey(ev) {
  return `${ev.id}@${ev.start}`;
}

function allowedCategories() {
  return String(settings.calendar_banner_categories || "")
    .split("|")
    .map((c) => c.trim())
    .filter(Boolean);
}

export default class CalendarBanner extends Component {
  @tracked dismissed = loadDismissed();

  get items() {
    const now = calendarFeed.now;
    const leadMs = Math.max(1, settings.calendar_banner_hours || 24) * 3600 * 1000;
    const categories = allowedCategories();

    return calendarFeed.events
      .filter(
        (ev) =>
          ev.startMs > now &&
          ev.startMs - now <= leadMs &&
          (categories.length === 0 || categories.includes(ev.category)) &&
          !this.dismissed[dismissKey(ev)]
      )
      .slice(0, MAX_ITEMS)
      .map((ev) => ({
        key: dismissKey(ev),
        title: ev.title,
        category: ev.category,
        slug: categorySlug(ev.category),
        when: formatStartsWhen(ev, now),
        startMs: ev.startMs,
      }));
  }

  // Eigener Link aus den Einstellungen, sonst der Kalender selbst
  get link() {
    return calendarFeed.customLink || calendarFeed.pageUrl;
  }

  // Ohne eigenen Link öffnet ein Klick den Kalender im Forum.
  // Strg-/Cmd-Klick öffnet ihn wie gewohnt in einem neuen Tab.
  @action
  openCalendar(event) {
    if (calendarFeed.customLink || event.ctrlKey || event.metaKey || event.shiftKey) {
      return;
    }
    event.preventDefault();
    calendarFeed.open();
  }

  get label() {
    return i18n(themePrefix("calendar.banner_label"));
  }

  get closeLabel() {
    return i18n(themePrefix("calendar.dismiss"));
  }

  get startsLabel() {
    return i18n(themePrefix("calendar.starts"));
  }

  @action
  dismiss(item) {
    const now = Date.now();
    const data = { ...this.dismissed, [item.key]: item.startMs };
    // Abgelaufene Einträge aufräumen
    for (const [key, startMs] of Object.entries(data)) {
      if (typeof startMs !== "number" || startMs < now - 86400000) {
        delete data[key];
      }
    }
    saveDismissed(data);
    this.dismissed = data;
  }

  <template>
    {{#if this.items.length}}
      <div class="cs-cal-banner" role="status" aria-label={{this.label}}>
        {{#each this.items key="key" as |item|}}
          <div class="cs-cal-banner__item --{{item.slug}}">
            <span class="cs-cal-banner__icon">{{icon "calendar-days"}}</span>
            <p class="cs-cal-banner__text">
              <span class="cs-cal-banner__label">{{this.label}}</span>
              {{#if this.link}}
                <a
                  class="cs-cal-banner__title"
                  href={{this.link}}
                  {{on "click" this.openCalendar}}
                >{{item.title}}</a>
              {{else}}
                <strong class="cs-cal-banner__title">{{item.title}}</strong>
              {{/if}}
              <span class="cs-cal-tag --{{item.slug}}">{{item.category}}</span>
              <span class="cs-cal-banner__when">{{this.startsLabel}}
                {{item.when}}</span>
            </p>
            <button
              type="button"
              class="btn-transparent cs-cal-banner__close"
              title={{this.closeLabel}}
              aria-label={{this.closeLabel}}
              {{on "click" (fn this.dismiss item)}}
            >{{icon "xmark"}}</button>
          </div>
        {{/each}}
      </div>
    {{/if}}
  </template>
}
