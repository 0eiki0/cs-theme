import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

const MIN_REFRESH_SECONDS = 10;
let statusCache = null;
let pendingRequest = null;

function statusUrl() {
  return (settings.status_url || "").trim();
}

// Aktualisierungsintervall in ms (0 = keine automatische Aktualisierung)
function refreshMs() {
  const seconds = parseInt(settings.refresh_interval, 10) || 0;
  return seconds > 0 ? Math.max(seconds, MIN_REFRESH_SECONDS) * 1000 : 0;
}

// Wie alt zwischengespeicherte Daten höchstens sein dürfen
function maxAgeMs() {
  const interval = refreshMs();
  return interval > 0 ? interval - 1000 : 30 * 1000;
}

function fetchStatus() {
  if (statusCache && Date.now() - statusCache.time < maxAgeMs()) {
    return Promise.resolve(statusCache.data);
  }
  pendingRequest ??= requestStatus().finally(() => (pendingRequest = null));
  return pendingRequest;
}

// Prüft, ob eine Antwort vollständig ist. "Online" ohne gültige
// Spielerzahl oder mit 0 Plätzen deutet auf eine abgebrochene Abfrage hin.
function isPlausible(data) {
  if (!data || typeof data !== "object") {
    return false;
  }
  if (!data.online) {
    return true;
  }
  const players = data.players;
  return (
    !!players &&
    typeof players.online === "number" &&
    typeof players.max === "number" &&
    players.max > 0
  );
}

async function requestStatus() {
  try {
    const response = await fetch(statusUrl(), {
      credentials: "omit",
      cache: "no-cache",
      headers: { Accept: "application/json" },
    });
    if (!response.ok) {
      return statusCache?.data ?? null;
    }
    const data = await response.json();
    if (!isPlausible(data)) {
      // Kaputte Antwort (z. B. "online, aber 0 / 0") → alten Stand behalten
      return statusCache?.data ?? null;
    }
    statusCache = { time: Date.now(), data };
    return data;
  } catch {
    // Status ist optional – bei Fehlern einfach ausblenden.
    return statusCache?.data ?? null;
  }
}

// Erlaubt https://…, http://…, Forenpfade (/t/…) und nackte Domains (shop.de).
// Alles andere (z. B. javascript:) wird verworfen.
function normalizeUrl(value) {
  const url = typeof value === "string" ? value.trim() : "";
  if (/^https?:\/\//i.test(url) || /^\/(?!\/)/.test(url)) {
    return url;
  }
  if (/^[a-z0-9-]+(\.[a-z0-9-]+)+([/?#].*)?$/i.test(url)) {
    return `https://${url}`;
  }
  return null;
}

export default class ServerBanner extends Component {
  @service router;
  @service currentUser;

  @tracked copied = false;
  @tracked status = statusCache?.data ?? null;

  refreshTimer = null;

  constructor() {
    super(...arguments);
    if (
      statusUrl() &&
      (settings.show_player_count || settings.show_player_heads)
    ) {
      this.loadStatus();
      this.startAutoRefresh();
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    clearInterval(this.refreshTimer);
    document.removeEventListener("visibilitychange", this.onVisibilityChange);
  }

  startAutoRefresh() {
    const interval = refreshMs();
    if (!interval) {
      return;
    }
    this.refreshTimer = setInterval(this.refresh, interval);
    document.addEventListener("visibilitychange", this.onVisibilityChange);
  }

  // Nur aktualisieren, wenn der Tab sichtbar ist und das Banner angezeigt wird
  @action
  refresh() {
    if (document.visibilityState === "visible" && this.shouldShow) {
      this.loadStatus();
    }
  }

  // Beim Zurückkehren in den Tab sofort aktualisieren (falls Daten veraltet)
  @action
  onVisibilityChange() {
    this.refresh();
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

  get customButtons() {
    return (settings.banner_buttons || [])
      .map((b) => ({
        label: b?.label,
        url: normalizeUrl(b?.url),
        icon: typeof b?.icon === "string" ? b.icon.trim() : "",
        primary: b?.style === "hervorgehoben",
        newTab: !!b?.new_tab,
        groups: b?.groups,
      }))
      .filter((b) => b.label && b.url && this.canSee(b.groups));
  }

  // Leer = für alle sichtbar. Automatische Gruppen ohne echte Mitgliedschaft:
  // 0 = jeder, 4 = anonyme Benutzer (Gäste), 5 = angemeldete Benutzer.
  // Hinweis: Das blendet den Button nur aus – der Link selbst ist nicht geschützt.
  canSee(groups) {
    const ids = [].concat(groups ?? []).map((id) => parseInt(id, 10));
    if (ids.length === 0 || ids.includes(0)) {
      return true;
    }
    const user = this.currentUser;
    if (!user) {
      return ids.includes(4);
    }
    if (ids.includes(5)) {
      return true;
    }
    const memberOf = new Set((user.groups || []).map((g) => g.id));
    return ids.some((id) => memberOf.has(id));
  }

  get showStatus() {
    return settings.show_player_count && !!this.status;
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
    const list = this.isOnline && this.status.players?.list;
    if (!Array.isArray(list)) {
      return [];
    }
    const names = list
      .map((p) => (typeof p === "string" ? p : p?.name))
      .map((name) =>
        // Farbcodes (§a, §l …) entfernen, z. B. bei Proxys mit eigener Liste
        String(name ?? "")
          .replace(/\u00a7./g, "")
          .trim()
      )
      // Java-Namen (3–16 Zeichen) sowie Bedrock-/Geyser-Namen mit Präfix
      // (z. B. ".Name" oder "*Name", auch mit Leerzeichen) zulassen
      .filter((name) => name.length > 0 && name.length <= 32);
    return [...new Set(names)].sort((a, b) =>
      a.localeCompare(b, undefined, { sensitivity: "base" })
    );
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
      link: settings.player_link_url
        ? settings.player_link_url.replace("{name}", encodeURIComponent(name))
        : null,
    }));
  }

  get hiddenPlayerCount() {
    // Nur Spieler zählen, deren Namen bekannt sind, aber wegen
    // max_player_heads nicht angezeigt werden (keine Vanish-Spieler).
    return this.allPlayers.length - this.visiblePlayers.length;
  }

  get hiddenPlayerTitle() {
    return i18n(themePrefix("banner.more_players"), {
      count: this.hiddenPlayerCount,
    });
  }

  get copyLabel() {
    return this.copied
      ? i18n(themePrefix("banner.copied"))
      : i18n(themePrefix("banner.copy_ip"));
  }

  async loadStatus() {
    const data = await fetchStatus();
    if (data && !this.isDestroying && !this.isDestroyed) {
      this.status = data;
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

            {{#each this.customButtons as |button|}}
              <a
                class="btn cs-banner__btn {{if button.primary '--primary'}}"
                href={{button.url}}
                target={{if button.newTab "_blank"}}
                rel={{if button.newTab "noopener noreferrer"}}
              >
                {{#if button.icon}}{{icon button.icon}}{{/if}}<span
                >{{button.label}}</span>
              </a>
            {{/each}}
          </div>

          {{#if this.showStatus}}
            <p class="cs-banner__status">{{this.statusLabel}}</p>
          {{/if}}

          {{#if this.showHeads}}
            <ul class="cs-heads">
              {{#each this.visiblePlayers key="name" as |player|}}
                <li class="cs-heads__item" title={{player.name}}>
                  {{#if player.link}}
                    <a
                      class="cs-heads__link"
                      href={{player.link}}
                      target="_blank"
                      rel="noopener noreferrer"
                      aria-label={{player.name}}
                    >
                      <img
                        class="cs-heads__img"
                        src={{player.url}}
                        alt={{player.name}}
                        width="32"
                        height="32"
                        loading="lazy"
                      />
                    </a>
                  {{else}}
                    <img
                      class="cs-heads__img"
                      src={{player.url}}
                      alt={{player.name}}
                      width="32"
                      height="32"
                      loading="lazy"
                    />
                  {{/if}}
                </li>
              {{/each}}
              {{#if this.hiddenPlayerCount}}
                <li class="cs-heads__more" title={{this.hiddenPlayerTitle}}>+{{this.hiddenPlayerCount}}</li>
              {{/if}}
            </ul>
          {{/if}}
        </div>
      </section>
    {{/if}}
  </template>
}
