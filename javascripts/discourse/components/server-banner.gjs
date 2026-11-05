import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

const STATUS_CACHE_MS = 60 * 1000;
let statusCache = null;

export default class ServerBanner extends Component {
  @service router;

  @tracked copied = false;
  @tracked status = statusCache?.data ?? null;

  constructor() {
    super(...arguments);
    if (settings.show_player_count && settings.server_ip) {
      this.loadStatus();
    }
  }

  get shouldShow() {
    const route = this.router.currentRouteName || "";
    return route.startsWith("discovery.");
  }

  get serverName() {
    return settings.server_name;
  }

  get tagline() {
    return settings.banner_tagline;
  }

  get serverIp() {
    return settings.server_ip;
  }

  get discordUrl() {
    return settings.discord_url;
  }

  get rulesUrl() {
    return settings.rules_url;
  }

  get showStatus() {
    return settings.show_player_count && this.status;
  }

  get isOnline() {
    return !!this.status?.online;
  }

  get statusLabel() {
    if (!this.isOnline) {
      return i18n(themePrefix("banner.offline"));
    }
    const players = this.status.players;
    if (players && typeof players.online === "number") {
      return i18n(themePrefix("banner.players"), {
        count: players.online,
        max: players.max ?? "?",
      });
    }
    return i18n(themePrefix("banner.online"));
  }

  get allPlayers() {
    const list = this.status?.players?.list;
    if (!this.isOnline || !Array.isArray(list)) {
      return [];
    }
    return list
      .map((p) => (typeof p === "string" ? p : p?.name))
      .filter((name) => name && /^[A-Za-z0-9_.]{1,16}$/.test(name))
      .sort((a, b) => a.localeCompare(b));
  }

  get showHeads() {
    return settings.show_player_heads && this.allPlayers.length > 0;
  }

  get visiblePlayers() {
    const max = settings.max_player_heads || 0;
    const players = max > 0 ? this.allPlayers.slice(0, max) : this.allPlayers;
    return players.map((name) => ({
      name,
      url: settings.player_head_url.replace(
        "{name}",
        encodeURIComponent(name)
      ),
    }));
  }

  get hiddenPlayerCount() {
    return this.allPlayers.length - this.visiblePlayers.length;
  }

  get copyLabel() {
    return this.copied
      ? i18n(themePrefix("banner.copied"))
      : i18n(themePrefix("banner.copy_ip"));
  }

  get discordLabel() {
    return i18n(themePrefix("banner.discord"));
  }

  get rulesLabel() {
    return i18n(themePrefix("banner.rules"));
  }

  async loadStatus() {
    if (statusCache && Date.now() - statusCache.time < STATUS_CACHE_MS) {
      this.status = statusCache.data;
      return;
    }
    try {
      const response = await fetch(
        `https://api.mcsrvstat.us/3/${encodeURIComponent(settings.server_ip)}`
      );
      if (!response.ok) {
        return;
      }
      const data = await response.json();
      statusCache = { time: Date.now(), data };
      if (!this.isDestroying && !this.isDestroyed) {
        this.status = data;
      }
    } catch {
      // Status ist optional – bei Fehlern einfach ausblenden.
    }
  }

  @action
  async copyIp() {
    try {
      await navigator.clipboard.writeText(this.serverIp);
    } catch {
      const input = document.createElement("textarea");
      input.value = this.serverIp;
      document.body.appendChild(input);
      input.select();
      document.execCommand("copy");
      input.remove();
    }
    this.copied = true;
    setTimeout(() => {
      if (!this.isDestroying && !this.isDestroyed) {
        this.copied = false;
      }
    }, 2000);
  }

  <template>
    {{#if this.shouldShow}}
      <section class="cs-banner">
        <div class="cs-banner__inner">
          <div class="cs-banner__text">
            <h1 class="cs-banner__title">{{this.serverName}}</h1>
            {{#if this.tagline}}
              <p class="cs-banner__tagline">{{this.tagline}}</p>
            {{/if}}
          </div>

          <div class="cs-banner__actions">
            {{#if this.serverIp}}
              <button
                type="button"
                class="cs-ip {{if this.copied '--copied'}}"
                title={{this.copyLabel}}
                {{on "click" this.copyIp}}
              >
                {{#if this.showStatus}}
                  <span
                    class="cs-ip__dot {{if this.isOnline '--online' '--offline'}}"
                  ></span>
                {{/if}}
                <span class="cs-ip__address">{{this.serverIp}}</span>
                <span class="cs-ip__action">
                  {{icon (if this.copied "check" "copy")}}
                  <span class="cs-ip__label">{{this.copyLabel}}</span>
                </span>
              </button>
            {{/if}}

            {{#if this.discordUrl}}
              <a
                class="btn cs-banner__btn"
                href={{this.discordUrl}}
                target="_blank"
                rel="noopener noreferrer"
              >{{icon "fab-discord"}}<span>{{this.discordLabel}}</span></a>
            {{/if}}

            {{#if this.rulesUrl}}
              <a class="btn cs-banner__btn" href={{this.rulesUrl}}>
                {{icon "book"}}<span>{{this.rulesLabel}}</span>
              </a>
            {{/if}}
          </div>

          {{#if this.showStatus}}
            <p class="cs-banner__status">{{this.statusLabel}}</p>
          {{/if}}

          {{#if this.showHeads}}
            <ul class="cs-heads">
              {{#each this.visiblePlayers as |player|}}
                <li class="cs-heads__item" title={{player.name}}>
                  <img
                    class="cs-heads__img"
                    src={{player.url}}
                    alt={{player.name}}
                    width="32"
                    height="32"
                    loading="lazy"
                  />
                </li>
              {{/each}}
              {{#if this.hiddenPlayerCount}}
                <li class="cs-heads__more">+{{this.hiddenPlayerCount}}</li>
              {{/if}}
            </ul>
          {{/if}}
        </div>
      </section>
    {{/if}}
  </template>
}
