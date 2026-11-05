import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import avatar from "discourse/helpers/bound-avatar-template";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

const REFRESH_MS = 60 * 1000;
let teamCache = null;

// team_sections: [{ group: [id], title: "…" }, …] in der eingestellten
// Reihenfolge. IDs werden über site.groups in Gruppennamen aufgelöst.
function configuredGroups(site) {
  const available = site.groups || [];
  const sections = Array.isArray(settings.team_sections)
    ? settings.team_sections
    : [];

  return sections
    .map((section) => {
      const id = parseInt([].concat(section?.group ?? [])[0], 10);
      const group = available.find((g) => g.id === id);
      if (!group) {
        return null;
      }
      const title = (section.title || "").trim();
      return {
        name: group.name,
        title: title || group.full_name || group.name,
      };
    })
    .filter(Boolean);
}

async function loadGroupMembers(name) {
  try {
    const result = await ajax(
      `/groups/${encodeURIComponent(name)}/members.json`,
      { data: { order: "last_seen_at", limit: 50 } }
    );
    return result?.members || [];
  } catch {
    // Gruppe nicht sichtbar oder nicht vorhanden → überspringen
    return [];
  }
}

async function loadTeam(site) {
  const configured = configuredGroups(site);
  const cutoff =
    Date.now() - Math.max(1, settings.team_online_minutes || 5) * 60 * 1000;
  const seen = new Set();

  const groups = await Promise.all(
    configured.map(async (group) => ({
      ...group,
      members: await loadGroupMembers(group.name),
    }))
  );

  // Jede Person nur einmal anzeigen – in der ersten passenden Gruppe
  return groups
    .map((group) => ({
      name: group.name,
      title: group.title,
      members: group.members
        .filter((m) => {
          const lastSeen = m.last_seen_at ? Date.parse(m.last_seen_at) : 0;
          if (lastSeen < cutoff || seen.has(m.id)) {
            return false;
          }
          seen.add(m.id);
          return true;
        })
        .map((m) => ({
          id: m.id,
          username: m.username,
          displayName: m.name || m.username,
          avatarTemplate: m.avatar_template,
          title: m.title,
          url: `/u/${encodeURIComponent(m.username_lower || m.username)}`,
        }))
        .sort((a, b) => a.displayName.localeCompare(b.displayName)),
    }))
    .filter((group) => group.members.length > 0);
}

export default class TeamOnline extends Component {
  @service router;
  @service site;

  @tracked groups = teamCache?.groups ?? null;
  timer = null;

  constructor() {
    super(...arguments);
    this.refresh();
    this.timer = setInterval(this.refresh, REFRESH_MS);
    document.addEventListener("visibilitychange", this.refresh);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    clearInterval(this.timer);
    document.removeEventListener("visibilitychange", this.refresh);
  }

  get shouldShow() {
    if (this.site.mobileView && !settings.team_online_mobile) {
      return false;
    }
    const route = this.router.currentRouteName || "";
    return (
      route.startsWith("discovery.") && configuredGroups(this.site).length > 0
    );
  }

  get title() {
    return settings.team_online_title;
  }

  get isEmpty() {
    return this.groups && this.groups.length === 0;
  }

  get onlineCount() {
    return (this.groups || []).reduce((sum, g) => sum + g.members.length, 0);
  }

  get emptyLabel() {
    return i18n(themePrefix("team_online.nobody"));
  }

  @action
  async refresh() {
    if (document.visibilityState !== "visible" || !this.shouldShow) {
      return;
    }
    if (teamCache && Date.now() - teamCache.time < REFRESH_MS - 1000) {
      this.groups = teamCache.groups;
      return;
    }
    const groups = await loadTeam(this.site);
    teamCache = { time: Date.now(), groups };
    if (!this.isDestroying && !this.isDestroyed) {
      this.groups = groups;
    }
  }

  <template>
    {{#if this.shouldShow}}
      <aside class="cs-team" aria-label={{this.title}}>
        <h2 class="cs-team__title">
          <span class="cs-team__dot"></span>
          {{this.title}}
          {{#if this.groups}}
            <span class="cs-team__count">{{this.onlineCount}}</span>
          {{/if}}
        </h2>

        {{#if this.isEmpty}}
          <p class="cs-team__empty">{{this.emptyLabel}}</p>
        {{/if}}

        {{#each this.groups key="name" as |group|}}
          <section class="cs-team__group">
            <h3 class="cs-team__group-title">{{group.title}}</h3>
            <ul class="cs-team__list">
              {{#each group.members key="id" as |member|}}
                <li class="cs-team__member">
                  <a
                    class="cs-team__link"
                    href={{member.url}}
                    data-user-card={{member.username}}
                  >
                    <span class="cs-team__avatar">
                      {{avatar member.avatarTemplate "medium"}}
                    </span>
                    <span class="cs-team__names">
                      <span
                        class="cs-team__name"
                      >{{member.displayName}}</span>
                      {{#if member.title}}
                        <span class="cs-team__role">{{member.title}}</span>
                      {{/if}}
                    </span>
                  </a>
                </li>
              {{/each}}
            </ul>
          </section>
        {{/each}}
      </aside>
    {{/if}}
  </template>
}
