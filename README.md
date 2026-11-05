# CS Theme – Discourse-Theme für Minecraft-Communities

Ein modernes, schlichtes Theme für Discourse mit dezentem Minecraft-Touch.

## Features

- **Zwei Farbschemata:** „CS Hell“ und „CS Dunkel“ mit grasgrünem Akzent
- **Server-Banner** auf der Startseite und in den Themenlisten
  - Server-IP mit **Ein-Klick-Kopieren**
  - **Live-Status & Spielerzahl** über euren eigenen Status-Endpunkt (keine Fremd-API)
  - **Köpfe aller Online-Spieler** (über [mineskin.eu](https://mineskin.eu))
  - Optionale Buttons zu **Discord** und **Regeln**
  - Dezente **Pixel-Kante** in Gras-Block-Optik (abschaltbar)
- Glasiger, schlanker Header, ruhige Themenliste, abgerundete Karten
- Einheitliche Eckenradien (einstellbar), sanfte Hover-Effekte, Fokus-Ringe
- Mobil optimiert, respektiert `prefers-reduced-motion`

## Installation

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
| `show_player_heads` | Köpfe der Online-Spieler ein/aus |
| `max_player_heads` | Max. Anzahl Köpfe (0 = alle), Rest als „+X“ |
| `player_head_url` | Bildquelle, `{name}` = Spielername |
| `player_link_url` | Ziel beim Klick auf einen Kopf, `{name}` = Spielername (leer = nicht klickbar) |
| `discord_url` | Link zum Discord (leer = ausgeblendet) |
| `rules_url` | Link zu den Regeln (leer = ausgeblendet) |
| `corner_radius` | Eckenradius in px (0–24) |
| `pixel_accent` | Gras-Block-Kante unter dem Banner |

## Empfehlungen

- Unter *Admin → Einstellungen → Schriftart* als Grundschrift **Inter** wählen – passt perfekt zum Theme.
- Ein Logo mit transparentem Hintergrund (SVG oder PNG, ca. 40 px hoch) wirkt im Header am besten.

## Status-Endpunkt einrichten (Spielerzahl & Köpfe)

Status, Spielerzahl und Spielernamen fragt das Theme bei eurem **eigenen Webserver** ab –
es wird keine fremde API benutzt. Nur die Kopf-Bilder kommen von mineskin.eu.

1. `server/status.php` aus diesem Repo auf euren Webserver laden, **in denselben Ordner wie
   eure `status.class.php`**.
2. Oben in der `status.php` anpassen:
   - `MC_HOST` / `MC_PORT` – welcher Server abgefragt wird (Standard: `brokko.cubeside.de`)
   - `ALLOWED_ORIGIN` – optional die Forum-Adresse, z. B. `https://forum.cubeside.de`
   - `CACHE_SECONDS` – wie lange ein Ergebnis zwischengespeichert wird (Standard: 30 s)
3. Im Browser prüfen, ob die Datei JSON liefert, z. B.:
   `{"online":true,"players":{"online":55,"max":100,"list":["Alex","Eiki"]},"updated":…}`
4. Die URL im Theme unter **`status_url`** eintragen. Die Seite muss über **https** erreichbar sein.

Der Endpunkt speichert das Ergebnis zwischen, damit nicht jeder Forenbesuch den
Minecraft-Server anpingt. Spielerzahl und Namen kommen aus derselben Abfrage und passen
deshalb immer zusammen.
