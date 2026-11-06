import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import calendarFeed from "../lib/calendar-feed";
import {
  categorySlug,
  dateBadge,
  formatRange,
} from "../lib/calendar-format";

// Box "Nächste Termine" rechts neben der Themenliste (über "Team Online").

export default class UpcomingEvents extends Component {
  @service router;
  @service site;

  get shouldShow() {
    if (this.site.mobileView && !settings.upcoming_events_mobile) {
      return false;
    }
    const route = this.router.currentRouteName || "";
    return (
      route.startsWith("discovery.") &&
      calendarFeed.loaded &&
      calendarFeed.role !== null
    );
  }

  get items() {
    const now = calendarFeed.now;
    const count = Math.max(1, settings.upcoming_events_count || 3);
    const includeRunning = settings.upcoming_events_include_running;

    return calendarFeed.events
      .filter((ev) => ev.endMs >= now && (includeRunning || ev.startMs > now))
      .slice(0, count)
      .map((ev) => ({
        key: `${ev.id}@${ev.start}`,
        title: ev.title,
        category: ev.category,
        slug: categorySlug(ev.category),
        badge: dateBadge(ev.startMs),
        range: formatRange(ev),
        running: ev.startMs <= now,
        tooltip: ev.description ? `${ev.title}\n${ev.description}` : ev.title,
      }));
  }

  get title() {
    return settings.upcoming_events_title;
  }

  get runningLabel() {
    return i18n(themePrefix("calendar.running"));
  }

  get emptyLabel() {
    return i18n(themePrefix("calendar.none"));
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

  <template>
    {{#if this.shouldShow}}
      <aside class="cs-events" aria-label={{this.title}}>
        <h2 class="cs-events__title">
          {{icon "calendar-days"}}
          {{#if this.link}}
            <a
              href={{this.link}}
              {{on "click" this.openCalendar}}
            >{{this.title}}</a>
          {{else}}
            {{this.title}}
          {{/if}}
        </h2>

        {{#if this.items.length}}
          <ul class="cs-events__list">
            {{#each this.items key="key" as |item|}}
              <li class="cs-events__item">
                <a
                  class="cs-events__link"
                  href={{this.link}}
                  title={{item.tooltip}}
                  {{on "click" this.openCalendar}}
                >
                  <span class="cs-events__date --{{item.slug}}">
                    <span class="cs-events__day">{{item.badge.day}}</span>
                    <span class="cs-events__month">{{item.badge.month}}</span>
                  </span>
                  <span class="cs-events__info">
                    <span class="cs-events__name">{{item.title}}</span>
                    <span class="cs-events__meta">
                      {{#if item.running}}
                        <span class="cs-events__running">{{this.runningLabel}}</span>
                      {{/if}}
                      {{item.range}}
                    </span>
                  </span>
                </a>
              </li>
            {{/each}}
          </ul>
        {{else}}
          <p class="cs-events__empty">{{this.emptyLabel}}</p>
        {{/if}}
      </aside>
    {{/if}}
  </template>
}
