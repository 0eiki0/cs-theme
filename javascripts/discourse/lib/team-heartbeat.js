import { ajax } from "discourse/lib/ajax";

// Discourse aktualisiert "zuletzt gesehen" nur bei Anfragen mit dem Header
// "Discourse-Present: true". Den setzt Discourse selbst nur, solange der
// Nutzer aktiv ist (Maus/Tastatur in der letzten Minute, Tab sichtbar).
// Teammitglieder schicken deshalb ein Lebenszeichen, solange ihr Tab offen
// ist – so bleiben sie in der Box "Team Online", auch wenn sie nichts tun.

let started = false;

function teamGroupIds() {
  const sections = Array.isArray(settings.team_sections)
    ? settings.team_sections
    : [];
  return new Set(
    sections
      .map((section) => parseInt([].concat(section?.group ?? [])[0], 10))
      .filter((id) => !isNaN(id))
  );
}

function isTeamMember(user) {
  const ids = teamGroupIds();
  return (user?.groups || []).some((group) => ids.has(group.id));
}

// Halbe Online-Schwelle, mindestens 60 s (Discourse zählt höchstens einmal
// pro Minute), höchstens 2 Minuten.
function intervalMs() {
  const thresholdSeconds = Math.max(1, settings.team_online_minutes || 5) * 60;
  return Math.min(Math.max(thresholdSeconds / 2, 60), 120) * 1000;
}

async function ping() {
  try {
    await ajax("/session/current.json", {
      headers: { "Discourse-Present": "true" },
    });
  } catch {
    // z. B. abgemeldet oder offline – beim nächsten Mal erneut versuchen
  }
}

export default function startTeamHeartbeat(currentUser) {
  if (started || !currentUser || !isTeamMember(currentUser)) {
    return;
  }
  started = true;
  setInterval(ping, intervalMs());
}
