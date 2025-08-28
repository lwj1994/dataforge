#!/usr/bin/env dart

import 'dart:io';

/// Version management tool
/// Used to uniformly update version numbers of main package and annotation package
class VersionManager {
  static const String versionFile = 'version.yaml';

  /// Read version configuration
  Map<String, dynamic> readVersionConfig() {
    final file = File(versionFile);
    if (!file.existsSync()) {
      throw Exception('Version configuration file $versionFile does not exist');
    }

    final content = file.readAsStringSync();
    return parseYaml(content);
  }

  /// Simple YAML parser (supports basic format only)
  Map<String, dynamic> parseYaml(String content) {
    final result = <String, dynamic>{};
    final lines = content.split('\n');

    String? currentSection;
    Map<String, dynamic>? currentMap;
    String? currentSubSection;
    Map<String, dynamic>? currentSubMap;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final indent = line.length - line.trimLeft().length;

      if (trimmed.endsWith(':') && !trimmed.contains(' ')) {
        if (indent == 0) {
          // Top-level section
          currentSection = trimmed.substring(0, trimmed.length - 1);
          currentMap = <String, dynamic>{};
          result[currentSection] = currentMap;
          currentSubSection = null;
          currentSubMap = null;
        } else if (indent == 2 && currentMap != null) {
          // Second-level section
          currentSubSection = trimmed.substring(0, trimmed.length - 1);
          currentSubMap = <String, dynamic>{};
          currentMap[currentSubSection] = currentSubMap;
        }
      } else if (trimmed.contains(': ')) {
        // key-value pair
        final parts = trimmed.split(': ');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(': ').trim().replaceAll('"', '');

          if (currentSubMap != null) {
            currentSubMap[key] = value;
          } else if (currentMap != null) {
            currentMap[key] = value;
          } else {
            result[key] = value;
          }
        }
      }
    }

    return result;
  }

  /// Update version number in pubspec.yaml file
  void updatePubspecVersion(String pubspecPath, String newVersion) {
    final file = File(pubspecPath);
    if (!file.existsSync()) {
      throw Exception('pubspec.yaml file does not exist: $pubspecPath');
    }

    final lines = file.readAsLinesSync();
    final updatedLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('version:')) {
        updatedLines.add('version: $newVersion');
        print('✓ Updated $pubspecPath version to: $newVersion');
      } else {
        updatedLines.add(line);
      }
    }

    file.writeAsStringSync(updatedLines.join('\n'));
  }

  /// Validate version number format (semantic versioning)
  bool isValidSemanticVersion(String version) {
    final regex = RegExp(r'^\d+\.\d+\.\d+(-[\w\.-]+)?(\+[\w\.-]+)?$');
    return regex.hasMatch(version);
  }

  /// Update version numbers of all packages
  void updateAllVersions([String? newVersion]) {
    try {
      final config = readVersionConfig();
      final currentVersion = config['version'] as String?;

      if (currentVersion == null) {
        throw Exception(
            'Version field not found in version configuration file');
      }

      final targetVersion = newVersion ?? currentVersion;

      if (!isValidSemanticVersion(targetVersion)) {
        throw Exception(
            'Invalid version number format: $targetVersion (should use semantic versioning, e.g.: 1.0.0)');
      }

      print('Starting to update version to: $targetVersion');
      print('=' * 50);

      final packages = config['packages'] as Map<String, dynamic>?;
      if (packages == null) {
        throw Exception(
            'Packages configuration not found in version configuration file');
      }

      // Update version number for each package
      for (final entry in packages.entries) {
        final packageName = entry.key;
        final packageConfig = entry.value as Map<String, dynamic>;

        final packagePath = packageConfig['path'] as String;
        final pubspecFile = packageConfig['pubspec'] as String;
        final fullPubspecPath =
            packagePath == '.' ? pubspecFile : '$packagePath/$pubspecFile';

        print('Updating package: $packageName');
        updatePubspecVersion(fullPubspecPath, targetVersion);
      }

      // If new version number is specified, update version.yaml file
      if (newVersion != null && newVersion != currentVersion) {
        updateVersionConfig(newVersion);
      }

      print('=' * 50);
      print(
          '✅ All package versions have been successfully updated to: $targetVersion');
    } catch (e) {
      print('❌ Failed to update version number: $e');
      exit(1);
    }
  }

  /// Update version number in version.yaml file
  void updateVersionConfig(String newVersion) {
    final file = File(versionFile);
    final lines = file.readAsLinesSync();
    final updatedLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('version:')) {
        updatedLines.add('version: "$newVersion"');
        print('✓ Updated $versionFile version to: $newVersion');
      } else {
        updatedLines.add(line);
      }
    }

    file.writeAsStringSync(updatedLines.join('\n'));
  }

  /// Display current version information
  void showCurrentVersions() {
    try {
      final config = readVersionConfig();
      final currentVersion = config['version'] as String?;

      print('Current version configuration:');
      print('=' * 30);
      print('Configuration version: $currentVersion');

      final packages = config['packages'] as Map<String, dynamic>?;
      if (packages != null) {
        print('\nPackage version information:');
        for (final entry in packages.entries) {
          final packageName = entry.key;
          final packageConfig = entry.value as Map<String, dynamic>;
          final packagePath = packageConfig['path'] as String;
          final pubspecFile = packageConfig['pubspec'] as String;
          final fullPubspecPath =
              packagePath == '.' ? pubspecFile : '$packagePath/$pubspecFile';

          final actualVersion = getPubspecVersion(fullPubspecPath);
          print('  $packageName: $actualVersion');
        }
      }
    } catch (e) {
      print('❌ Failed to read version information: $e');
      exit(1);
    }
  }

  /// Read version number from pubspec.yaml file
  String getPubspecVersion(String pubspecPath) {
    try {
      final file = File(pubspecPath);
      final lines = file.readAsLinesSync();

      for (final line in lines) {
        if (line.startsWith('version:')) {
          return line.split(':')[1].trim();
        }
      }
      return 'Not found';
    } catch (e) {
      return 'Read failed';
    }
  }
}

/// Display usage help
void showHelp() {
  print('''
Version Management Tool - Usage Instructions
============================================

Usage:
  dart tools/update_version.dart [options] [version]

Options:
  -h, --help     Display this help information
  -s, --show     Display current version information
  -u, --update   Update to specified version number

Examples:
  dart tools/update_version.dart --show           # Display current version
  dart tools/update_version.dart --update 1.0.0  # Update to version 1.0.0
  dart tools/update_version.dart 1.0.0           # Update to version 1.0.0 (shorthand)

Notes:
  - Version number must comply with semantic versioning specification (e.g.: 1.0.0, 2.1.0-beta.1)
  - This tool will update version numbers of both main package and annotation package
  - Please ensure version.yaml configuration file exists and is properly formatted before updating
''');
}

void main(List<String> args) {
  final manager = VersionManager();

  if (args.isEmpty) {
    showHelp();
    return;
  }

  final firstArg = args[0];

  switch (firstArg) {
    case '-h':
    case '--help':
      showHelp();
      break;

    case '-s':
    case '--show':
      manager.showCurrentVersions();
      break;

    case '-u':
    case '--update':
      if (args.length < 2) {
        print('❌ Error: Please specify the version number to update');
        print('Usage: dart tools/update_version.dart --update <version>');
        exit(1);
      }
      manager.updateAllVersions(args[1]);
      break;

    default:
      // Directly specify version number
      if (firstArg.contains('.')) {
        manager.updateAllVersions(firstArg);
      } else {
        print('❌ Error: Invalid parameter or version number format');
        showHelp();
        exit(1);
      }
      break;
  }
}
