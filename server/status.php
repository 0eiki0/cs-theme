<?php
/**
 * CS Theme – Status-Endpunkt für das Discourse-Server-Banner
 *
 * Liefert Online-Status, Spielerzahl und Spielernamen als JSON.
 * Fragt euren Minecraft-Server direkt per Server-List-Ping ab –
 * ohne externe APIs und ohne zusätzliche Dateien.
 *
 * Einrichtung:
 *   1. Datei auf euren Webserver hochladen (PHP 7.4+).
 *   2. Unten MC_HOST / MC_PORT und ggf. ALLOWED_ORIGIN anpassen.
 *   3. Die URL dieser Datei im Theme unter "status_url" eintragen.
 */

// ---------------- Konfiguration ----------------
const MC_HOST        = 'brokko.cubeside.de';
const MC_PORT        = 25565;
// Domain eures Forums (für CORS). '*' erlaubt jede Seite – die Daten sind öffentlich.
const ALLOWED_ORIGIN = '*';
// Wie lange (Sekunden) ein Ergebnis zwischengespeichert wird.
// Nicht größer als "refresh_interval" im Theme wählen.
const CACHE_SECONDS  = 30;
// Schlägt eine Abfrage fehl, wird so lange (Sekunden) der letzte gute Stand
// ausgeliefert, bevor der Server als offline gilt.
const STALE_SECONDS  = 300;
// Zeitlimit (Sekunden) für Verbindung und Antwort.
const TIMEOUT        = 3;
// ------------------------------------------------

ini_set('display_errors', '0');

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: ' . ALLOWED_ORIGIN);
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Accept');
header('Cache-Control: no-cache');
header('X-Content-Type-Options: nosniff');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ---------------- Minecraft Server-List-Ping ----------------

function mc_varint(int $value): string
{
    $value &= 0xFFFFFFFF;
    $out = '';
    do {
        $byte = $value & 0x7F;
        $value >>= 7;
        if ($value !== 0) {
            $byte |= 0x80;
        }
        $out .= chr($byte);
    } while ($value !== 0);
    return $out;
}

function mc_read_exact($fp, int $length): ?string
{
    $data = '';
    while (strlen($data) < $length) {
        $chunk = fread($fp, $length - strlen($data));
        if ($chunk === false || $chunk === '') {
            $meta = stream_get_meta_data($fp);
            if ($meta['timed_out'] || feof($fp)) {
                return null;
            }
            continue;
        }
        $data .= $chunk;
    }
    return $data;
}

function mc_read_varint($fp): ?int
{
    $value = 0;
    for ($i = 0; $i < 5; $i++) {
        $byte = mc_read_exact($fp, 1);
        if ($byte === null) {
            return null;
        }
        $byte = ord($byte);
        $value |= ($byte & 0x7F) << (7 * $i);
        if (($byte & 0x80) === 0) {
            return $value;
        }
    }
    return null; // VarInt zu lang
}

function mc_varint_from_string(string $data, int &$offset): ?int
{
    $value = 0;
    for ($i = 0; $i < 5; $i++) {
        if (!isset($data[$offset])) {
            return null;
        }
        $byte = ord($data[$offset++]);
        $value |= ($byte & 0x7F) << (7 * $i);
        if (($byte & 0x80) === 0) {
            return $value;
        }
    }
    return null;
}

/**
 * Fragt den Server ab. Gibt das dekodierte Status-JSON zurück
 * oder null, wenn die Abfrage fehlschlägt oder unvollständig ist.
 */
function mc_ping(string $host, int $port, int $timeout): ?array
{
    $fp = @stream_socket_client("tcp://{$host}:{$port}", $errno, $errstr, $timeout);
    if (!$fp) {
        return null;
    }
    stream_set_timeout($fp, $timeout);

    try {
        // Handshake: Paket 0x00, Protokoll, Host, Port, nächster Status = 1
        $handshake = "\x00"
            . mc_varint(-1)
            . mc_varint(strlen($host)) . $host
            . pack('n', $port)
            . mc_varint(1);
        fwrite($fp, mc_varint(strlen($handshake)) . $handshake);
        // Status-Anfrage: Paket 0x00 ohne Inhalt
        fwrite($fp, "\x01\x00");

        $length = mc_read_varint($fp);
        if ($length === null || $length < 3 || $length > 2 * 1024 * 1024) {
            return null;
        }
        $packet = mc_read_exact($fp, $length);
        if ($packet === null) {
            return null;
        }

        $offset = 0;
        if (mc_varint_from_string($packet, $offset) !== 0) {
            return null; // falsche Paket-ID
        }
        $jsonLength = mc_varint_from_string($packet, $offset);
        if ($jsonLength === null || $offset + $jsonLength > strlen($packet)) {
            return null;
        }
        $data = json_decode(substr($packet, $offset, $jsonLength), true);
        if (!is_array($data) || !isset($data['players']['online'], $data['players']['max'])) {
            return null;
        }
        return $data;
    } finally {
        fclose($fp);
    }
}

// ---------------- Antwort bauen ----------------

function cs_build_status(array $data): array
{
    $names = [];
    foreach ($data['players']['sample'] ?? [] as $player) {
        // Platzhalter-Einträge (eigene Texte in der Spielerliste) überspringen
        if (($player['id'] ?? '') === '00000000-0000-0000-0000-000000000000') {
            continue;
        }
        $name = trim(preg_replace('/\x{00A7}./u', '', (string) ($player['name'] ?? '')));
        if ($name !== '' && mb_strlen($name) <= 32) {
            $names[$name] = true;
        }
    }
    $names = array_keys($names);
    natcasesort($names);

    return [
        'online'  => true,
        'players' => [
            'online' => (int) $data['players']['online'],
            'max'    => (int) $data['players']['max'],
            'list'   => array_values($names),
        ],
    ];
}

function cs_offline(): array
{
    return ['online' => false, 'players' => ['online' => 0, 'max' => 0, 'list' => []]];
}

function cs_write_cache(string $file, array $payload): void
{
    file_put_contents($file . '.tmp', json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
    rename($file . '.tmp', $file);
}

function cs_read_cache(string $file): ?array
{
    if (!is_file($file)) {
        return null;
    }
    $cache = json_decode((string) file_get_contents($file), true);
    return is_array($cache) && isset($cache['checked'], $cache['status']) ? $cache : null;
}

function cs_output(array $status, int $updated): void
{
    $status['updated'] = $updated;
    echo json_encode($status, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

// Cache-Aufbau: checked = letzte Abfrage, good = letzter erfolgreicher Stand
$cacheFile = sys_get_temp_dir() . '/cs-theme-status-' . md5(MC_HOST . ':' . MC_PORT) . '.json';
$cache = cs_read_cache($cacheFile);

// Frischer Cache → direkt ausliefern
if ($cache && time() - $cache['checked'] < CACHE_SECONDS) {
    cs_output($cache['status'], $cache['good'] ?? $cache['checked']);
    exit;
}

// Nur ein Request fragt den Server ab, alle anderen bekommen den letzten Stand
$lock = fopen($cacheFile . '.lock', 'c');
if (!$lock || !flock($lock, LOCK_EX | LOCK_NB)) {
    if ($cache) {
        cs_output($cache['status'], $cache['good'] ?? $cache['checked']);
    } else {
        http_response_code(503);
        cs_output(cs_offline(), time());
    }
    exit;
}

$now = time();
$data = mc_ping(MC_HOST, MC_PORT, TIMEOUT) ?? mc_ping(MC_HOST, MC_PORT, TIMEOUT); // 1 Wiederholung

if ($data !== null) {
    $status = cs_build_status($data);
    $cache = ['checked' => $now, 'good' => $now, 'status' => $status];
} elseif ($cache && isset($cache['good']) && $now - $cache['good'] < STALE_SECONDS) {
    // Abfrage fehlgeschlagen → letzten guten Stand weiter ausliefern
    $cache['checked'] = $now;
} else {
    $cache = ['checked' => $now, 'status' => cs_offline()];
}

cs_write_cache($cacheFile, $cache);
flock($lock, LOCK_UN);
fclose($lock);

cs_output($cache['status'], $cache['good'] ?? $now);
