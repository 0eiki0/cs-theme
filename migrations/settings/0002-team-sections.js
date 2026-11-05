// Überträgt die alte Gruppenauswahl (team_groups, z. B. "41|42|3")
// in die sortierbare Liste team_sections.
export default function migrate(settings) {
  if (!settings.has("team_groups")) {
    return settings;
  }

  const sections = String(settings.get("team_groups") || "")
    .split("|")
    .map((value) => value.trim())
    .filter((value) => /^\d+$/.test(value))
    .map((value) => ({ group: [parseInt(value, 10)] }));

  settings.set("team_sections", sections);
  settings.delete("team_groups");
  return settings;
}
