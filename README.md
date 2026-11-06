# CS Theme – Discourse-Theme für Minecraft-Communities

Ein modernes, schlichtes Theme für Discourse mit dezentem Minecraft-Touch.

## Features

- **Zwei Farbschemata:** „CS Hell“ und „CS Dunkel“ mit grasgrünem Akzent
- **Server-Banner** auf der Startseite und in den Themenlisten
  - Server-IP mit **Ein-Klick-Kopieren**
  - **Live-Status & Spielerzahl** über euren eigenen Status-Endpunkt (keine Fremd-API)
  - **Köpfe aller Online-Spieler** (über [mineskin.eu](https://mineskin.eu))
  - **Frei konfigurierbare Buttons** (Discord, Regeln, Shop …) mit Icon-Auswahl
  - Dezente **Pixel-Kante** in Gras-Block-Optik (abschaltbar)
- **Team Online:** Box rechts neben der Themenliste mit allen Teammitgliedern, die gerade im Forum aktiv sind
- Glasiger, schlanker Header, ruhige Themenliste, abgerundete Karten
- Einheitliche Eckenradien (einstellbar), sanfte Hover-Effekte, Fokus-Ringe
- Mobil optimiert, respektiert `prefers-reduced-motion`

## Installation

Voraussetzung: **Discourse 2026.8.0 oder neuer** (wegen der Icon-Auswahl in den Einstellungen).


1. Discourse-Admin → **Darstellung → Themes → Installieren → Aus Git-Repository**
2. URL eingeben: `https://github.com/0eiki0/cs-theme` (bei privatem Repo einen Deploy-Key hinterlegen)
3. Theme als **Standard** setzen und das Farbschema **„CS Hell“** oder **„CS Dunkel“** wählen.
   Für automatischen Hell/Dunkel-Wechsel: in den Benutzereinstellungen bzw. unter
   *Darstellung → Farben* „CS Dunkel“ als Dark-Mode-Schema festlegen.

## Einstellungen

| Einstellung | Beschreibung |
|---|---|
| `server_name` | Name im Banner |
| `banner_tagline` | Untertitel im Banner |
| `server_ip` | Server-Adresse zum Kopieren |
| `show_banner` | Banner ein/aus |
| `status_url` | URL eurer `status.php` (siehe unten) |
| `show_player_count` | Live-Status & Spielerzahl ein/aus |
| `refresh_interval` | Automatische Aktualisierung von Spielerzahl & Köpfen in Sekunden (0 = aus) |
| `show_player_heads` | Köpfe der Online-Spieler ein/aus |
| `max_player_heads` | Max. Anzahl Köpfe (0 = alle), Rest als „+X“ |
| `player_head_url` | Bildquelle, `{name}` = Spielername |
| `player_link_url` | Ziel beim Klick auf einen Kopf, `{name}` = Spielername (leer = nicht klickbar) |
| `banner_buttons` | Alle Buttons im Banner (siehe unten) |
| `show_team_online` | Box „Team Online“ ein/aus |
| `team_online_title` | Überschrift der Box |
| `team_sections` | Gruppen in der Box, per Drag & Drop sortierbar, optional mit eigener Überschrift |
| `team_online_minutes` | Als online gilt, wer in den letzten X Minuten aktiv war (Standard 5) |
| `team_online_keep_alive` | Teammitglieder bleiben in der Box, solange ihr Forum-Tab offen ist |
| `team_online_mobile` | Box auch mobil anzeigen |
| `show_online_users` | Box „Gerade online“ über der Fußleiste |
| `online_users_title` | Überschrift der Box |
| `online_users_minutes` | Als online gilt, wer in den letzten X Minuten aktiv war |
| `online_users_max` | Maximale Anzahl Avatare, Rest als „+X“ |
| `show_guest_popup` | Willkommens-Popup für nicht angemeldete Besucher |
| `guest_popup_title` / `guest_popup_text` | Überschrift und Text des Popups |
| `guest_popup_migration_text` | Hinweis für Nutzer aus dem alten Forum mit Button „Neues Passwort anfordern“ (leer = aus) |
| `guest_popup_delay_seconds` | Verzögerung in Sekunden |
| `guest_popup_repeat_days` | Nach dem Schließen erst nach X Tagen wieder anzeigen |
| `sidebar_unread_link` | Punkt „Ungelesene Beiträge“ ganz oben in der Seitenleiste, sobald es Neues gibt |
| `sidebar_unread_link_text` | Beschriftung dieses Punkts |
| `highlight_unread` | Neues hervorheben: ungelesene Themen, ungelesene Beiträge („Neu“), ungelesene Benachrichtigungen und Zähler am Avatar |
| `corner_radius` | Eckenradius in px (0–24) |
| `pixel_accent` | Gras-Block-Kante unter dem Banner |

## Buttons im Banner

Alle Buttons neben der Server-IP werden unter **`banner_buttons`** im Editor angelegt –
es gibt keine fest eingebauten. Buttons lassen sich hinzufügen, per Drag & Drop sortieren
und löschen.

| Feld | Beschreibung |
|---|---|
| Beschriftung | Text auf dem Button, z. B. „Discord“ |
| Link | `https://…`, ein Forenpfad wie `/t/regeln/12` oder einfach `shop.example.de` |
| Icon | Optional – Icon-Auswahl mit Vorschau und Suche über alle Font-Awesome-Icons inkl. Marken-Logos (Discord, YouTube, TeamSpeak …). Wird automatisch geladen. |
| Stil | `standard` (grau) oder `hervorgehoben` (grün) |
| In neuem Tab öffnen | für externe Links empfohlen |

**Beispiel:** Discord → Link `https://discord.gg/…`, Icon „discord“, neuer Tab ✓ ·
Regeln → Link `/t/regeln/12`, Icon „book“.

## Team Online

Die Box zeigt Mitglieder der unter `team_sections` eingetragenen Gruppen, die in den letzten
`team_online_minutes` Minuten im Forum aktiv waren – mit Avatar, Name und Titel. Ein Klick
öffnet die Benutzerkarte. Die Box aktualisiert sich jede Minute.

- In jeder gewählten Gruppe muss unter *Gruppe → Verwalten → Interaktion* „Wer kann
  Mitglieder sehen“ auf **Jeder** stehen, sonst wird die Gruppe übersprungen.
- Reihenfolge der Gruppen per Drag & Drop im Editor. Wer in mehreren Gruppen ist, erscheint nur in der obersten.
- Als Abschnittstitel wird die eingetragene **Überschrift** verwendet, sonst der **Vollständige Name** der Gruppe.
- Mit `team_online_keep_alive` schickt der Browser von Teammitgliedern alle 1–2 Minuten ein
  Lebenszeichen, solange das Forum offen ist. Wer nur den Tab offen hat, bleibt also in der Liste;
  nach dem Schließen verschwindet er nach `team_online_minutes`.
- Mitglieder, die in ihrem Profil „Profil und Präsenz verbergen“ aktiviert haben, erscheinen nicht.
- Auf Bildschirmen unter 1200 px steht die Box über der Themenliste.

## Gerade online

In der Seitenleiste unter den Kategorien zeigt eine Box alle Nutzer, die in den letzten `online_users_minutes`
Minuten im Forum aktiv waren, als Avatare (Klick öffnet die Benutzerkarte). Die Daten
kommen aus der automatischen Gruppe „Vertrauensstufe 0“ (`trust_level_0`, ID 10), in der alle Nutzer sind.

- Nur für **angemeldete** Nutzer sichtbar (Gäste dürfen die Liste nicht abrufen).
- Nutzer mit „Profil und Präsenz verbergen“ erscheinen nicht.
- Es werden höchstens die 200 zuletzt aktiven Nutzer geprüft; sind alle online, steht „200+“.

## Empfehlungen

- Unter *Admin → Einstellungen → Schriftart* als Grundschrift **Inter** wählen – passt perfekt zum Theme.
- Ein Logo mit transparentem Hintergrund (SVG oder PNG, ca. 40 px hoch) wirkt im Header am besten.

## Status-Endpunkt einrichten (Spielerzahl & Köpfe)

Status, Spielerzahl und Spielernamen fragt das Theme bei eurem **eigenen Webserver** ab –
es wird keine fremde API benutzt. Nur die Kopf-Bilder kommen von mineskin.eu.

1. `server/status.php` aus diesem Repo auf euren Webserver laden (PHP 7.4+). Weitere Dateien
   wie eine `status.class.php` werden nicht benötigt.
2. Oben in der `status.php` anpassen:
   - `MC_HOST` / `MC_PORT` – welcher Server abgefragt wird (Standard: `brokko.cubeside.de`)
   - `ALLOWED_ORIGIN` – optional die Forum-Adresse, z. B. `https://forum.cubeside.de`
   - `CACHE_SECONDS` – wie lange ein Ergebnis zwischengespeichert wird (Standard: 30 s)
   - `STALE_SECONDS` – wie lange bei Fehlern der letzte gute Stand weiter angezeigt wird (Standard: 5 min)
   - `TIMEOUT` – Zeitlimit für die Abfrage (Standard: 3 s)
3. Im Browser prüfen, ob die Datei JSON liefert, z. B.:
   `{"online":true,"players":{"online":55,"max":100,"list":["Alex","Eiki"]},"updated":…}`
4. Die URL im Theme unter **`status_url`** eintragen. Die Seite muss über **https** erreichbar sein.

Der Endpunkt speichert das Ergebnis zwischen, damit nicht jeder Forenbesuch den
Minecraft-Server anpingt. `CACHE_SECONDS` in der `status.php` sollte nicht größer sein als
`refresh_interval` im Theme, sonst kommen bei der automatischen Aktualisierung alte Daten. Spielerzahl und Namen kommen aus derselben Abfrage und passen
deshalb immer zusammen.
