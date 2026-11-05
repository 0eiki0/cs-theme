// Stellt banner_buttons von der alten Icon-Auswahlliste (+ custom_icon)
// auf den Discourse-Icon-Picker um.
export default function migrate(settings) {
  if (!settings.has("banner_buttons")) {
    return settings;
  }

  let buttons = settings.get("banner_buttons");
  if (typeof buttons === "string") {
    try {
      buttons = JSON.parse(buttons);
    } catch {
      return settings;
    }
  }
  if (!Array.isArray(buttons)) {
    return settings;
  }

  const migrated = buttons.map((button) => {
    const result = { ...button };
    const custom = (result.custom_icon || "").trim();
    delete result.custom_icon;

    if (custom) {
      result.icon = custom;
    } else if (!result.icon || result.icon === "keins") {
      delete result.icon;
    }
    return result;
  });

  settings.set("banner_buttons", migrated);
  return settings;
}
