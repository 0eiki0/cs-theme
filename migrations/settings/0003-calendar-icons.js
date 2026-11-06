// Ergänzt die Icons für den Kalender (Banner, "Nächste Termine"), falls
// svg_icons bereits angepasst wurde und der neue Standardwert deshalb nicht greift.
export default function migrate(settings) {
  if (!settings.has("svg_icons")) {
    return settings;
  }
  const icons = String(settings.get("svg_icons") || "")
    .split("|")
    .map((icon) => icon.trim())
    .filter(Boolean);
  for (const icon of ["calendar-days", "xmark"]) {
    if (!icons.includes(icon)) {
      icons.push(icon);
    }
  }
  settings.set("svg_icons", icons.join("|"));
  return settings;
}
