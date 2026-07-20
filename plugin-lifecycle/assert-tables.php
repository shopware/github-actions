<?php declare(strict_types=1);

/**
 * Asserts that a set of database tables is present or absent.
 *
 * Usage: php assert-tables.php <present|absent> [table ...]
 *
 * The database connection is read from the DATABASE_URL environment variable,
 * which Shopware exposes in CI. With no tables given the script is a no-op, so
 * plugins that own no tables can call the action without configuring anything.
 */

$mode = $argv[1] ?? '';
if (!in_array($mode, ['present', 'absent'], true)) {
    fwrite(STDERR, "Usage: assert-tables.php <present|absent> [table ...]\n");
    exit(2);
}

$tables = array_slice($argv, 2);
if ($tables === []) {
    exit(0);
}

$url = (string) getenv('DATABASE_URL');
if ($url === '') {
    fwrite(STDERR, "::error::DATABASE_URL is not set\n");
    exit(2);
}

$parts = parse_url($url);
if ($parts === false || !isset($parts['host'], $parts['path'])) {
    fwrite(STDERR, "::error::Could not parse DATABASE_URL\n");
    exit(2);
}

$pdo = new PDO(
    sprintf('mysql:host=%s;port=%d;dbname=%s', $parts['host'], $parts['port'] ?? 3306, ltrim($parts['path'], '/')),
    $parts['user'] ?? 'root',
    isset($parts['pass']) ? urldecode($parts['pass']) : ''
);

$failed = false;
foreach ($tables as $table) {
    $exists = $pdo->query('SHOW TABLES LIKE ' . $pdo->quote($table))->fetch() !== false;

    if ($mode === 'absent' && $exists) {
        fwrite(STDERR, "::error::Table $table still exists after uninstall\n");
        $failed = true;
    }

    if ($mode === 'present' && !$exists) {
        fwrite(STDERR, "::error::Table $table was not recreated after reinstall\n");
        $failed = true;
    }
}

if ($failed) {
    exit(1);
}

echo $mode === 'absent'
    ? "All configured tables removed after uninstall\n"
    : "All configured tables present after reinstall\n";
