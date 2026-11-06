import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import avatar from "discourse/helpers/bound-avatar-template";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

const REFRESH_MS = 60 * 1000;
// Automatische Gruppe, in der alle Nutzer sind. Angemeldete Nutzer dürfen
// ihre Mitgliederliste (inkl. "zuletzt gesehen") abrufen.
const ALL_USERS_GROUP = "trust_level_0";
const FETCH_LIMIT = 200;
let cache = null;

async function loadOnlineUsers() {
  const cutoff =
    Date.now() - Math.max(1, settings.online_users_minutes || 5) * 60 * 1000;
  try {
    const result = await ajax(`/groups/${ALL_USERS_GROUP}/members.json`, {
      data: { order: "last_seen_at", limit: FETCH_LIMIT },
    });
    const members = result?.members || [];
    const online = members.filter(
      (m) => m.last_seen_at && Date.parse(m.last_seen_at) >= cutoff
    );
    return {
      users: online.map((m) => ({
        id: m.id,
        username: m.username,
        avatarTemplate: m.avatar_template,
        url: `/u/${encodeURIComponent(m.username_lower || m.username)}`,
      })),
      // Alle abgerufenen Mitglieder waren online → es könnten noch mehr sein
      capped: online.length >= FETCH_LIMIT,
    };
  } catch {
    return null;
  }
}

export default class OnlineUsers extends Component {
  @service currentUser;

  @tracked data = cache?.data ?? null;
  timer = null;

  constructor() {
    super(...arguments);
    if (this.currentUser) {
      this.refresh();
      this.timer = setInterval(this.refresh, REFRESH_MS);
      document.addEventListener("visibilitychange", this.refresh);
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    clearInterval(this.timer);
    document.removeEventListener("visibilitychange", this.refresh);
  }

  get shouldShow() {
    return !!this.currentUser && !!this.data && this.args.outletArgs?.showFooter;
  }

  get visibleUsers() {
    const max = settings.online_users_max || 0;
    const users = this.data?.users || [];
    return max > 0 ? users.slice(0, max) : users;
  }

  get hiddenCount() {
    return (this.data?.users.length || 0) - this.visibleUsers.length;
  }

  get countLabel() {
    const count = this.data?.users.length || 0;
    return i18n(themePrefix("online_users.count"), {
      count: this.data?.capped ? `${count}+` : count,
    });
  }

  get title() {
    return settings.online_users_title;
  }

  @action
  async refresh() {
    if (document.visibilityState !== "visible") {
      return;
    }
    if (cache && Date.now() - cache.time < REFRESH_MS - 1000) {
      this.data = cache.data;
      return;
    }
    const data = await loadOnlineUsers();
    if (!data) {
      return;
    }
    cache = { time: Date.now(), data };
    if (!this.isDestroying && !this.isDestroyed) {
      this.data = data;
    }
  }

  <template>
    {{#if this.shouldShow}}
      <section class="cs-online wrap" aria-label={{this.title}}>
        <div class="cs-online__header">
          <h2 class="cs-online__title">
            <span class="cs-online__dot"></span>
            {{this.title}}
          </h2>
          <span class="cs-online__count">{{this.countLabel}}</span>
        </div>

        <ul class="cs-online__list">
          {{#each this.visibleUsers key="id" as |user|}}
            <li class="cs-online__user">
              <a
                href={{user.url}}
                data-user-card={{user.username}}
                title={{user.username}}
              >{{avatar user.avatarTemplate "medium"}}</a>
            </li>
          {{/each}}
          {{#if this.hiddenCount}}
            <li class="cs-online__more">+{{this.hiddenCount}}</li>
          {{/if}}
        </ul>
      </section>
    {{/if}}
  </template>
}
