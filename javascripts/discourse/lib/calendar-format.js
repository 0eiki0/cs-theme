import { i18n } from "discourse-i18n";

// Datumsanzeige für Termine. Termine werden in deutscher Zeit (Europe/Berlin)
// gespeichert und auch so angezeigt.

const TIME_ZONE = "Europe/Berlin";

const dayKeyFmt = new Intl.DateTimeFormat("en-CA", {
  timeZone: TIME_ZONE,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
});

function locale() {
  return document.documentElement.lang || "de";
}

function dayKey(ms) {
  return dayKeyFmt.format(new Date(ms)); // YYYY-MM-DD
}

/** Ganze Kalendertage zwischen zwei Zeitpunkten (in Berliner Zeit) */
function dayDiff(fromMs, toMs) {
  const a = Date.parse(dayKey(fromMs) + "T00:00:00Z");
  const b = Date.parse(dayKey(toMs) + "T00:00:00Z");
  return Math.round((b - a) / 86400000);
}

export function formatTime(ms) {
  return new Intl.DateTimeFormat(locale(), {
    timeZone: TIME_ZONE,
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(ms));
}

export function formatDate(ms, { weekday = true } = {}) {
  return new Intl.DateTimeFormat(locale(), {
    timeZone: TIME_ZONE,
    weekday: weekday ? "short" : undefined,
    day: "2-digit",
    month: "2-digit",
  }).format(new Date(ms));
}

/** Tag und Monat für das Datums-Kästchen in der Box */
export function dateBadge(ms) {
  const date = new Date(ms);
  return {
    day: new Intl.DateTimeFormat(locale(), { timeZone: TIME_ZONE, day: "numeric" }).format(date),
    month: new Intl.DateTimeFormat(locale(), { timeZone: TIME_ZONE, month: "short" })
      .format(date)
      .replace(".", ""),
  };
}

/** "heute", "morgen" oder "am Sa., 08.11." */
function relativeDay(ms, now) {
  const diff = dayDiff(now, ms);
  if (diff === 0) {
    return i18n(themePrefix("calendar.today"));
  }
  if (diff === 1) {
    return i18n(themePrefix("calendar.tomorrow"));
  }
  return i18n(themePrefix("calendar.on_date"), { date: formatDate(ms) });
}

/** Für das Banner: "morgen um 18:00 Uhr" / "heute" (ganztägig) */
export function formatStartsWhen(ev, now) {
  const day = relativeDay(ev.startMs, now);
  if (ev.allDay) {
    return day;
  }
  return i18n(themePrefix("calendar.day_at_time"), {
    day,
    time: formatTime(ev.startMs),
  });
}

/** Für die Box: Zeitraum in Kurzform */
export function formatRange(ev) {
  // Ende um 0:00 Uhr zählt noch zum Vortag (z. B. 23:00 – 0:00)
  const sameDay = dayKey(ev.startMs) === dayKey(Math.max(ev.startMs, ev.endMs - 1));
  if (ev.allDay) {
    return sameDay
      ? i18n(themePrefix("calendar.all_day"))
      : i18n(themePrefix("calendar.until"), {
          date: formatDate(ev.endMs, { weekday: false }),
        });
  }
  if (sameDay) {
    return `${formatTime(ev.startMs)} – ${formatTime(ev.endMs)}`;
  }
  return i18n(themePrefix("calendar.time_until"), {
    time: formatTime(ev.startMs),
    date: formatDate(ev.endMs, { weekday: false }),
  });
}

/** CSS-taugliche Kennung der Kategorie (für die Farbe) */
export function categorySlug(category) {
  return String(category || "sonstiges")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-");
}
