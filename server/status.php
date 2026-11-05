<?php
/**
 * CS Theme – Status-Endpunkt für das Discourse-Server-Banner
 *
 * Liefert Online-Status, Spielerzahl und Spielernamen als JSON.
 * Fragt euren Minecraft-Server direkt per Server-List-Ping ab
 * (über status.class.php), ohne externe APIs.
 *
 * Einrichtung:
 *   1. Diese Datei neben eure status.class.php legen.
 *   2. Unten HOST/PORT und ALLOWED_ORIGIN anpassen.
 *   3. Die URL dieser Datei im Theme unter "status_url" eintragen.
 */

// ---------------- Konfiguration ----------------
const MC_HOST        = 'brokko.cubeside.de';
const MC_PORT        = 25565;
// Domain eures Forums (für CORS). '*' erlaubt jede Seite – die Daten sind öffentlich.
const ALLOWED_ORIGIN = '*';
// Wie lange (Sekunden) ein Ergebnis zwischengespeichert wird.
const CACHE_SECONDS  = 30;
// ------------------------------------------------

ini_set('display_errors', '0');
set_time_limit(10);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: ' . ALLOWED_ORIGIN);
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Accept');
header('Cache-Control: public, max-age=' . CACHE_SECONDS);
header('X-Content-Type-Options: nosniff');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$cacheFile = sys_get_temp_dir() . '/cs-theme-status-' . md5(MC_HOST . ':' . MC_PORT) . '.json';

/**
 * Fragt den Server ab und baut die Antwort zusammen.
 */
function cs_fetch_status(): array
{
    require_once __DIR__ . '/status.class.php';

    $response = @MinecraftServerStatus::query(MC_HOST, MC_PORT);
    if (!$response) {
        return ['online' => false, 'players' => ['online' => 0, 'max' => 0, 'list' => []]];
    }

    $names = [];
    if (is_array($response['playerlist'])) {
        foreach ($response['playerlist'] as $player) {
            // Platzhalter-Einträge (z. B. eigene Texte in der Spielerliste) überspringen
            if (isset($player->id) && $player->id === '00000000-0000-0000-0000-000000000000') {
                continue;
            }
            $name = isset($player->name) ? (string) $player->name : '';
            $name = trim(preg_replace('/\x{00A7}./u', '', $name)); // Farbcodes entfernen
            if ($name !== '' && mb_strlen($name) <= 32) {
                $names[$name] = true;
            }
        }
    }
    $names = array_keys($names);
    natcasesort($names);

    return [
        'online'  => true,
        'players' => [
            'online' => (int) $response['players'],
            'max'    => (int) $response['max_players'],
            'list'   => array_values($names),
        ],
    ];
}

// Frischen Cache direkt ausliefern
if (is_file($cacheFile) && time() - filemtime($cacheFile) < CACHE_SECONDS) {
    readfile($cacheFile);
    exit;
}

// Nur ein Request aktualisiert den Cache, alle anderen bekommen den alten Stand
$lock = fopen($cacheFile . '.lock', 'c');
if ($lock && flock($lock, LOCK_EX | LOCK_NB)) {
    $data = cs_fetch_status();
    $data['updated'] = time();
    $json = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    file_put_contents($cacheFile . '.tmp', $json);
    rename($cacheFile . '.tmp', $cacheFile);
    flock($lock, LOCK_UN);
    fclose($lock);
    echo $json;
    exit;
}

if (is_file($cacheFile)) {
    readfile($cacheFile);
} else {
    http_response_code(503);
    echo json_encode(['online' => false, 'players' => ['online' => 0, 'max' => 0, 'list' => []]]);
}
