// Converts web app JSON translation files to Flutter ARB format.
//
// Usage:  dart tools/convert_i18n.dart
//
// Reads from: ../mq-navigation/locales/<lang>/translations.json
// Writes to:  lib/app/l10n/app_<lang>.arb

import 'dart:convert';
import 'dart:io';

const webLocalesDir = '../mq-navigation/locales';
const arbOutputDir = 'lib/app/l10n';

/// Keys to include in the ARB files (core UI keys).
/// Building-specific keys (building_*_name, building_*_desc) are excluded
/// from ARB files — they are loaded from Supabase at runtime.
final excludePatterns = [
  RegExp(r'^building_\w+_name$'),
  RegExp(r'^building_\w+_desc$'),
];

bool shouldExclude(String key) {
  return excludePatterns.any((p) => p.hasMatch(key));
}

/// Convert {{variable}} (Handlebars) to {variable} (ICU/ARB format).
String convertInterpolation(String value) {
  return value.replaceAllMapped(
    RegExp(r'\{\{(\w+)\}\}'),
    (m) => '{${m.group(1)}}',
  );
}

/// Dart reserved keywords that cannot be used as ARB identifiers.
const dartReservedWords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

/// Sanitise a JSON key to be a valid Dart identifier for ARB.
String sanitiseKey(String key) {
  // Replace dots, hyphens, spaces with camelCase
  var sanitised = key.replaceAllMapped(
    RegExp(r'[.\-\s]+(\w)'),
    (m) => m.group(1)!.toUpperCase(),
  );
  // Ensure starts with lowercase letter
  if (sanitised.isNotEmpty && sanitised[0] == sanitised[0].toUpperCase()) {
    sanitised = sanitised[0].toLowerCase() + sanitised.substring(1);
  }
  // Remove any remaining invalid characters
  sanitised = sanitised.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
  // Prefix Dart reserved words with 'k' to make them valid identifiers
  if (dartReservedWords.contains(sanitised)) {
    sanitised = 'k${sanitised[0].toUpperCase()}${sanitised.substring(1)}';
  }
  return sanitised;
}

void main() async {
  final localesDir = Directory(webLocalesDir);
  if (!localesDir.existsSync()) {
    stderr.writeln('Error: Web locales directory not found at $webLocalesDir');
    stderr.writeln('Make sure the web app is at ../mq-navigation/');
    exit(1);
  }

  final outputDir = Directory(arbOutputDir);
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // Read template (English) to establish key order
  final enFile = File('$webLocalesDir/en/translations.json');
  if (!enFile.existsSync()) {
    stderr.writeln('Error: English translations not found');
    exit(1);
  }
  final enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final templateKeys = enJson.keys
      .where((k) => !shouldExclude(k))
      .map(sanitiseKey)
      .toList();

  stdout.writeln(
    'Template has ${templateKeys.length} keys (excluding building keys)',
  );

  var convertedCount = 0;

  for (final entity in localesDir.listSync()) {
    if (entity is! Directory) continue;
    final langCode = entity.path.split('/').last;
    if (langCode.startsWith('.')) continue;

    final translationsFile = File('${entity.path}/translations.json');
    if (!translationsFile.existsSync()) {
      stderr.writeln('  Skipping $langCode: no translations.json');
      continue;
    }

    try {
      final json =
          jsonDecode(translationsFile.readAsStringSync())
              as Map<String, dynamic>;

      // Build ARB map
      final arb = <String, dynamic>{'@@locale': langCode};

      for (final entry in json.entries) {
        if (shouldExclude(entry.key)) continue;
        final arbKey = sanitiseKey(entry.key);
        if (arbKey.isEmpty) continue;
        final value = entry.value;
        arb[arbKey] = value is String ? convertInterpolation(value) : value;
      }

      // Write ARB file
      final arbFile = File('$arbOutputDir/app_$langCode.arb');
      const encoder = JsonEncoder.withIndent('  ');
      arbFile.writeAsStringSync('${encoder.convert(arb)}\n');

      convertedCount++;
      stdout.writeln('  Converted $langCode (${arb.length - 1} keys)');
    } catch (e) {
      stderr.writeln('  Error converting $langCode: $e');
    }
  }

  stdout.writeln(
    '\nDone! Converted $convertedCount locale(s) to $arbOutputDir/',
  );
  stdout.writeln('Run "flutter gen-l10n" to regenerate localisation classes.');
}
