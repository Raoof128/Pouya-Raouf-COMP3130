#!/usr/bin/env dart

/// Pulls the building registry from Supabase `app_config` and writes
/// the normalised JSON to `assets/data/buildings.json`.
///
/// Usage:
///   dart run tools/sync_buildings.dart                   # reads .env
///   dart run tools/sync_buildings.dart --url=... --key=...
///
/// Environment (read from `.env` when flags are omitted):
///   SUPABASE_URL       — project URL
///   SUPABASE_ANON_KEY  — public anon key (RLS-enforced)
library;

import 'dart:convert';
import 'dart:io';

const _assetPath = 'assets/data/buildings.json';
const _configTable = 'app_config';
const _configKey = 'building_registry';

void main(List<String> args) async {
  final flags = _parseFlags(args);
  final env = _loadEnv();

  final url = flags['url'] ?? env['SUPABASE_URL'] ?? env['DEV_SUPABASE_URL'];
  final key =
      flags['key'] ?? env['SUPABASE_ANON_KEY'] ?? env['DEV_SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || key == null || key.isEmpty) {
    stderr.writeln(
      'Missing SUPABASE_URL / SUPABASE_ANON_KEY.\n'
      'Either pass --url and --key, or populate .env.',
    );
    exit(1);
  }

  final endpoint = Uri.parse(
    '$url/rest/v1/$_configTable?key=eq.$_configKey&select=value',
  );

  stdout.writeln('Fetching building registry from $url …');

  final client = HttpClient();
  try {
    final request = await client.getUrl(endpoint);
    request.headers.set('apikey', key);
    request.headers.set('Accept', 'application/json');

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 400) {
      stderr.writeln('Supabase returned ${response.statusCode}: $body');
      exit(1);
    }

    final rows = jsonDecode(body) as List<dynamic>;
    if (rows.isEmpty || rows.first['value'] == null) {
      stderr.writeln('No building_registry row found in app_config.');
      exit(1);
    }

    final buildings = rows.first['value'] as List<dynamic>;
    const encoder = JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(buildings);

    File(_assetPath).writeAsStringSync('$formatted\n');
    stdout.writeln('Wrote ${buildings.length} buildings → $_assetPath');
  } finally {
    client.close();
  }
}

Map<String, String> _parseFlags(List<String> args) {
  final flags = <String, String>{};
  for (final arg in args) {
    if (arg.startsWith('--')) {
      final parts = arg.substring(2).split('=');
      if (parts.length == 2) {
        flags[parts[0]] = parts[1];
      }
    }
  }
  return flags;
}

Map<String, String> _loadEnv() {
  final envFile = File('.env');
  if (!envFile.existsSync()) return {};
  final map = <String, String>{};
  for (final line in envFile.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx < 1) continue;
    map[trimmed.substring(0, idx)] = trimmed.substring(idx + 1);
  }
  return map;
}
