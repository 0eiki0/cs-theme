// Externe Seiten (z. B. das Webinterface), die sich wie der Kalender als
// großes Fenster im Forum öffnen. Eingetragen in der Theme-Einstellung
// "embedded_pages", erreichbar über die Seitenleiste und/oder die Kopfzeile.

const POSITIONS = ["seitenleiste", "kopfzeile", "beides"];

function normalizeUrl(value) {
  const url = typeof value === "string" ? value.trim() : "";
  if (/^https?:\/\//i.test(url)) {
    return url;
  }
  if (/^[a-z0-9-]+(\.[a-z0-9-]+)+([/?#].*)?$/i.test(url)) {
    return `https://${url}`;
  }
  return null;
}

/** Alle gültig eingetragenen Seiten */
export function embeddedPages() {
  const raw = Array.isArray(settings.embedded_pages)
    ? settings.embedded_pages
    : [];
  return raw
    .map((page, index) => ({
      key: `cs-page-${index}`,
      label: (page?.label || "").trim(),
      url: normalizeUrl(page?.url),
      icon:
        (typeof page?.icon === "string" && page.icon.trim()) ||
        "up-right-from-square",
      position: POSITIONS.includes(page?.position)
        ? page.position
        : "seitenleiste",
      newTab: page?.open_in === "neuer_tab",
      groups: page?.groups,
    }))
    .filter((page) => page.label && page.url);
}

/**
 * Leer = alle Angemeldeten. Automatische Gruppen: 0 = jeder,
 * 4 = Gäste, 5 = angemeldete Benutzer.
 * Hinweis: Das blendet nur den Button aus. Die Seite selbst muss ihren
 * Zugang weiterhin selbst schützen.
 */
export function canSeePage(page, user) {
  const ids = [].concat(page.groups ?? []).map((id) => parseInt(id, 10));
  if (ids.length === 0 || ids.includes(0)) {
    return !!user;
  }
  if (!user) {
    return ids.includes(4);
  }
  if (ids.includes(5)) {
    return true;
  }
  const memberOf = new Set((user.groups || []).map((g) => g.id));
  return ids.some((id) => memberOf.has(id));
}

export function inSidebar(page) {
  return page.position === "seitenleiste" || page.position === "beides";
}

export function inHeader(page) {
  return page.position === "kopfzeile" || page.position === "beides";
}

// Wird im Initializer gesetzt (braucht den Modal-Service)
let openHandler = null;

export function setPageOpener(handler) {
  openHandler = handler;
}

/** Seite im Forum-Fenster oder in einem neuen Tab öffnen */
export function openPage(page) {
  if (page.newTab || !openHandler) {
    window.open(page.url, "_blank", "noopener");
    return;
  }
  openHandler(page);
}
