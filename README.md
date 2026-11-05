# CS Theme – Discourse-Theme für Minecraft-Communities

Ein modernes, schlichtes Theme für Discourse mit dezentem Minecraft-Touch.

## Features

- **Zwei Farbschemata:** „CS Hell“ und „CS Dunkel“ mit grasgrünem Akzent
- **Server-Banner** auf der Startseite und in den Themenlisten
  - Server-IP mit **Ein-Klick-Kopieren**
  - **Live-Status & Spielerzahl** (über [mcsrvstat.us](https://mcsrvstat.us))
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
| `show_player_count` | Live-Status & Spielerzahl ein/aus |
| `show_player_heads` | Köpfe der Online-Spieler ein/aus |
| `max_player_heads` | Max. Anzahl Köpfe (0 = alle), Rest als „+X“ |
| `player_head_url` | Bildquelle, `{name}` = Spielername |
| `discord_url` | Link zum Discord (leer = ausgeblendet) |
| `rules_url` | Link zu den Regeln (leer = ausgeblendet) |
| `corner_radius` | Eckenradius in px (0–24) |
| `pixel_accent` | Gras-Block-Kante unter dem Banner |

## Empfehlungen

- Unter *Admin → Einstellungen → Schriftart* als Grundschrift **Inter** wählen – passt perfekt zum Theme.
- Ein Logo mit transparentem Hintergrund (SVG oder PNG, ca. 40 px hoch) wirkt im Header am besten.

## Spielerköpfe – Voraussetzung

Die Namen der Online-Spieler kommen von mcsrvstat.us. Damit die **vollständige** Liste
verfügbar ist, muss auf eurem Server Query aktiviert sein (`server.properties`):

```
enable-query=true
query.port=25565
```

Ohne Query liefert Minecraft nur eine Stichprobe von max. 12 Spielern. Bei Proxys
(BungeeCord/Velocity) Query in der Proxy-Konfiguration aktivieren. Die Daten werden
von mcsrvstat.us einige Minuten zwischengespeichert.
