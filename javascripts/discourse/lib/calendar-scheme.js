// Hell/Dunkel des Forums an den Kalender weitergeben.
//
// Discourse kennt mehrere Wege zum dunklen Modus (Farbschema des Nutzers,
// automatischer Wechsel nach System, Umschalter). Am zuverlässigsten ist es,
// die tatsächlich verwendete Hintergrundfarbe (--secondary) auszuwerten.

function parseColor(value) {
  const v = String(value || "").trim();
  let m = /^#([0-9a-f]{3})$/i.exec(v);
  if (m) {
    return m[1].split("").map((c) => parseInt(c + c, 16));
  }
  m = /^#([0-9a-f]{6})/i.exec(v);
  if (m) {
    return [0, 2, 4].map((i) => parseInt(m[1].slice(i, i + 2), 16));
  }
  m = /rgba?\(\s*(\d+)[\s,]+(\d+)[\s,]+(\d+)/i.exec(v);
  if (m) {
    return [m[1], m[2], m[3]].map(Number);
  }
  return null;
}

export function currentScheme() {
  const styles = getComputedStyle(document.documentElement);
  const rgb =
    parseColor(styles.getPropertyValue("--secondary")) ||
    parseColor(getComputedStyle(document.body).backgroundColor);
  if (!rgb) {
    return window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  }
  const [r, g, b] = rgb;
  const luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
  return luminance < 0.5 ? "dark" : "light";
}

/** Hängt ?scheme=light|dark an eine Kalender-Adresse an */
export function withScheme(url) {
  try {
    const parsed = new URL(url, window.location.href);
    parsed.searchParams.set("scheme", currentScheme());
    return parsed.href;
  } catch {
    return url;
  }
}

/**
 * Beobachtet Wechsel zwischen hell und dunkel und meldet sie allen
 * Kalender-iframes (die sich dann ohne Neuladen umfärben).
 */
export function watchScheme(origin) {
  let last = currentScheme();

  const check = () => {
    const scheme = currentScheme();
    if (scheme === last) {
      return;
    }
    last = scheme;
    document
      .querySelectorAll("iframe.cs-cal-frame, iframe.cs-cal-modal__frame")
      .forEach((iframe) => {
        iframe.contentWindow?.postMessage({ type: "cscal:scheme", scheme }, origin);
      });
  };

  // Etwas Verzögerung: Discourse tauscht beim Umschalten Stylesheets aus
  let timer = null;
  const schedule = () => {
    clearTimeout(timer);
    timer = setTimeout(check, 150);
  };

  window
    .matchMedia("(prefers-color-scheme: dark)")
    .addEventListener("change", schedule);
  new MutationObserver(schedule).observe(document.documentElement, {
    attributes: true,
  });
  new MutationObserver(schedule).observe(document.head, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["media", "href", "disabled"],
  });
}
