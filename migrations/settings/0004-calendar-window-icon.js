// Ergänzt das Icon für "In neuem Tab öffnen" im Kalender-Fenster, falls
// svg_icons bereits angepasst wurde und der neue Standardwert deshalb nicht greift.
export default function migrate(settings) {
  if (!settings.has("svg_icons")) {
    return settings;
  }
  const icons = String(settings.get("svg_icons") || "")
    .split("|")
    .map((icon) => icon.trim())
    .filter(Boolean);
  if (!icons.includes("up-right-from-square")) {
    icons.push("up-right-from-square");
  }
  settings.set("svg_icons", icons.join("|"));
  return settings;
}
