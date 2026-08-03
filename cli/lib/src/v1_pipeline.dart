import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart' as analyzer_fs;
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dataforge_base/dataforge_base.dart';
import 'package:path/path.dart' as p;

import 'exceptions.dart';
import 'v1_transaction.dart';

const _generatedFileHeader =
    '// GENERATED CODE - DO NOT MODIFY BY HAND\n'
    '// ignore_for_file: prefer_const_constructors, prefer_single_quotes, '
    'unnecessary_cast, unnecessary_non_null_assertion, unused_element';
const _defaultFileHeader = '// GENERATED CODE - DO NOT MODIFY BY HAND';
const _dartFormatWidth = '// dart format width=80';
const _descriptionLine =
    '// **************************************************************************';

/// An immutable in-memory result produced by the resolved v1 frontend.
///
/// All outputs are prepared and validated before [finish] is called. A
/// directory invocation may span multiple Dart packages; each package is then
/// committed through its own lock and crash-recovery journal.
final class V1GenerationPreparation {
  V1GenerationPreparation({
    required this.projectRoot,
    required Set<String> coordinationRoots,
    required Map<String, List<PendingGeneratedFile>> operationsByRoot,
    required Map<String, List<int>> inputSnapshots,
  }) : coordinationRoots = Set<String>.unmodifiable(
         (<String>{
           ...coordinationRoots,
           ...operationsByRoot.keys,
         }.toList()..sort()).map((root) => p.normalize(p.absolute(root))),
       ),
       operationsByRoot = Map<String, List<PendingGeneratedFile>>.unmodifiable({
         for (final root in (operationsByRoot.keys.toList()..sort()))
           p.normalize(
             p.absolute(root),
           ): List<PendingGeneratedFile>.unmodifiable(
             [...operationsByRoot[root]!]
               ..sort((left, right) => left.path.compareTo(right.path)),
           ),
       }),
       outputs = List<PendingGeneratedFile>.unmodifiable(
         [for (final operations in operationsByRoot.values) ...operations]
           ..sort((left, right) => left.path.compareTo(right.path)),
       ),
       inputSnapshots = Map<String, List<int>>.unmodifiable({
         for (final entry in inputSnapshots.entries)
           entry.key: List<int>.unmodifiable(entry.value),
       });

  final String projectRoot;
  final Set<String> coordinationRoots;
  final Map<String, List<PendingGeneratedFile>> operationsByRoot;
  final List<PendingGeneratedFile> outputs;
  final Map<String, List<int>> inputSnapshots;

  List<String> get outputPaths => [
    for (final output in outputs)
      if (!output.isDeletion) output.path,
  ];

  Future<void> finish({required bool check}) async {
    if (check) {
      await _synchronizeGenerationJournals(coordinationRoots, check: true);
    }
    final requiredAbsentPaths = <String>{
      for (final output in outputs)
        if (output.requiredAbsentPath != null) output.requiredAbsentPath!,
    };
    await validateGeneratedInputPreconditions(
      requiredInputs: inputSnapshots,
      requiredAbsentPaths: requiredAbsentPaths,
    );
    if (check) {
      final drifted = <String>[];
      try {
        for (final output in outputs) {
          final file = File(output.path);
          final type = await FileSystemEntity.type(
            output.path,
            followLinks: false,
          );
          final isDrifted = output.isDeletion
              ? type != FileSystemEntityType.notFound
              : type != FileSystemEntityType.file ||
                    !bytesEqual(await file.readAsBytes(), output.bytes);
          if (isDrifted) {
            drifted.add(p.relative(output.path, from: projectRoot));
          }
        }
      } on FileSystemException catch (error) {
        throw DataforgeIoException(
          'Failed to read generated output during check: $error',
          cause: error,
        );
      }
      if (drifted.isNotEmpty) {
        throw DataforgeCheckException(
          'Generated output is out of date:\n${drifted.map((path) => '  $path').join('\n')}',
        );
      }
      return;
    }

    for (final entry in operationsByRoot.entries) {
      await const GeneratedFileTransaction().commit(
        projectRoot: entry.key,
        files: entry.value,
        requiredInputs: inputSnapshots,
      );
    }
  }
}

/// The CLI adapter for the resolved Analyzer-based v1 frontend.
final class V1CliPipeline {
  const V1CliPipeline();

  Future<V1GenerationPreparation> prepare({
    required List<String> candidateFiles,
    required String projectRoot,
    required bool check,
    required String? orphanScanRoot,
  }) async {
    final normalizedProjectRoot = p.normalize(p.absolute(projectRoot));
    final normalizedScanRoot = orphanScanRoot == null
        ? null
        : await _validatedOrphanScanRoot(
            orphanScanRoot,
            projectRoot: normalizedProjectRoot,
          );
    final normalizedFiles =
        candidateFiles.map((path) => p.normalize(p.absolute(path))).toList()
          ..sort();
    final coordinationRoots = _coordinationRootsFor(
      projectRoot: normalizedProjectRoot,
      candidateFiles: normalizedFiles,
      scanRoot: normalizedScanRoot,
    );
    await _synchronizeGenerationJournals(coordinationRoots, check: check);

    if (candidateFiles.isEmpty && normalizedScanRoot == null) {
      return V1GenerationPreparation(
        projectRoot: normalizedProjectRoot,
        coordinationRoots: coordinationRoots,
        operationsByRoot: const {},
        inputSnapshots: const {},
      );
    }

    for (final file in normalizedFiles) {
      if (_packageConfigFor(file) == null && _looksLikeV1(File(file))) {
        throw DataforgeGenerationException(
          'DF2001 Cannot resolve Dataforge v1 source $file because no '
          '.dart_tool/package_config.json was found. Run dart pub get first.',
        );
      }
    }
    final resolvableFiles =
        normalizedFiles
            .where((path) => _packageConfigFor(path) != null)
            .toList()
          ..sort();
    final roots = <String>{
      for (final file in resolvableFiles) _packageRootFor(file)!,
    }.toList()..sort();
    final outputs = <PendingGeneratedFile>[];
    final inputSnapshots = <String, List<int>>{};
    final preparedLibraries = <_PreparedLibrary>[];
    final resolvedLibraries = <_ResolvedLibraryInfo>[];

    for (final root in roots) {
      final rootFiles = resolvableFiles
          .where((file) => _packageRootFor(file) == root)
          .toList();
      await _captureDiskInput(p.join(root, 'pubspec.yaml'), inputSnapshots);
      await _captureDiskInput(
        p.join(root, '.dart_tool', 'package_config.json'),
        inputSnapshots,
      );
      final collection = AnalysisContextCollection(includedPaths: [root]);
      try {
        final visitedLibraries = <String>{};
        for (final filePath in rootFiles) {
          final context = collection.contextFor(filePath);
          final result = await context.currentSession
              .getResolvedLibraryContaining(filePath);
          if (result is! ResolvedLibraryResult) {
            if (_looksLikeV1(File(filePath))) {
              throw DataforgeGenerationException(
                'Failed to resolve Dataforge v1 library containing $filePath '
                '(${result.runtimeType}).',
              );
            }
            continue;
          }

          final definingPath = p.normalize(
            result.element.firstFragment.source.fullName,
          );
          if (!visitedLibraries.add(definingPath)) continue;
          resolvedLibraries.add(
            _ResolvedLibraryInfo(
              definingPath: definingPath,
              referencedPaths: _referencedDirectivePaths(result),
            ),
          );
          final outputPath = _outputPathFor(definingPath);
          _validateAnalyzerSyntaxDiagnostics(result, outputPath);
          final prepared = await _prepareLibrary(result, definingPath);
          if (prepared == null) continue;
          await _captureResolvedLibraryInputs(result, inputSnapshots);
          _validateAnalyzerDiagnostics(result, outputPath);
          outputs.add(prepared);
          preparedLibraries.add(
            _PreparedLibrary(
              definingPath: definingPath,
              packageRoot: root,
              output: prepared,
            ),
          );
        }
      } on DataforgeCliException {
        rethrow;
      } catch (error) {
        throw DataforgeGenerationException(
          'Failed to resolve or generate Dataforge v1 sources under $root: '
          '$error',
          cause: error,
        );
      } finally {
        await collection.dispose();
      }
    }

    if (normalizedScanRoot != null) {
      final existingOutputs = outputs.map((output) => output.path).toSet();
      for (final deletion in await _prepareMissingSourceOutputDeletions(
        normalizedScanRoot,
      )) {
        if (existingOutputs.add(deletion.path)) outputs.add(deletion);
      }
    }

    final deletedPaths = {
      for (final output in outputs)
        if (output.isDeletion) output.path,
    };
    _throwDeletedOutputReferences(resolvedLibraries, deletedPaths);

    final operationsByRoot = <String, List<PendingGeneratedFile>>{};
    for (final output in outputs) {
      final root = _packageRootFor(output.path) ?? normalizedProjectRoot;
      if (!p.equals(root, output.path) && !p.isWithin(root, output.path)) {
        throw DataforgeGenerationException(
          'Generated output is outside its transaction root: '
          '${output.path} (root: $root).',
        );
      }
      coordinationRoots.add(root);
      operationsByRoot.putIfAbsent(root, () => []).add(output);
    }
    final definingPathsByRoot = <String, Set<String>>{};
    for (final prepared in preparedLibraries) {
      definingPathsByRoot
          .putIfAbsent(prepared.packageRoot, () => {})
          .add(prepared.definingPath);
    }
    final validationRoots = definingPathsByRoot.keys.toList()..sort();
    for (final root in validationRoots) {
      await _validatePreparedLibraries(
        packageRoot: root,
        operations: operationsByRoot[root] ?? const [],
        definingPaths: definingPathsByRoot[root]!,
      );
    }

    // The transaction validates the previous bytes of outputs it replaces or
    // deletes. Keeping those paths as immutable Analyzer inputs would make the
    // final precondition check reject the transaction's own new output.
    for (final output in outputs) {
      inputSnapshots.remove(p.normalize(p.absolute(output.path)));
    }

    return V1GenerationPreparation(
      projectRoot: normalizedProjectRoot,
      coordinationRoots: coordinationRoots,
      operationsByRoot: operationsByRoot,
      inputSnapshots: inputSnapshots,
    );
  }

  Future<PendingGeneratedFile?> _prepareLibrary(
    ResolvedLibraryResult library,
    String definingPath,
  ) async {
    final generator = const V1ResolvedModelGenerator();
    final builtModels = <_BuiltModel>[];

    // Match source_gen's LibraryReader.allElements candidate set. The library
    // element itself may be annotated and must fail consistently as well.
    final annotatedElements =
        <Element>[
          library.element,
          ...library.element.children,
        ].where(_hasResolvedDataforgeAnnotation).toList()..sort((left, right) {
          final leftFragment = left.firstFragment;
          final rightFragment = right.firstFragment;
          final leftUri = left.library?.uri.toString() ?? '';
          final rightUri = right.library?.uri.toString() ?? '';
          final uriOrder = leftUri.compareTo(rightUri);
          if (uriOrder != 0) return uriOrder;
          final offsetOrder = leftFragment.offset.compareTo(
            rightFragment.offset,
          );
          if (offsetOrder != 0) return offsetOrder;
          return (left.name ?? '').compareTo(right.name ?? '');
        });
    for (final element in annotatedElements) {
      if (element is! ClassElement) {
        throw DataforgeGenerationException(
          'DF1001 @Dataforge can only be applied to classes; found '
          '${element.kind.displayName} ${element.name ?? '<unnamed>'}.',
        );
      }
      final result = generator.generate(element);
      if (result.hasErrors || result.source == null) {
        throw DataforgeGenerationException(
          _diagnosticsMessage(result.diagnostics),
        );
      }
      final fragment = element.firstFragment;
      builtModels.add(
        _BuiltModel(
          result,
          sourceUri: fragment.libraryFragment.source.uri.toString(),
          offset: fragment.offset,
        ),
      );
    }

    if (builtModels.isEmpty) {
      return _prepareOwnedOutputDeletion(_outputPathFor(definingPath));
    }

    builtModels.sort((left, right) {
      final uriOrder = left.sourceUri.compareTo(right.sourceUri);
      if (uriOrder != 0) return uriOrder;
      final offsetOrder = left.offset.compareTo(right.offset);
      if (offsetOrder != 0) return offsetOrder;
      return left.result.modelName.compareTo(right.result.modelName);
    });

    final outputPath = _outputPathFor(definingPath);
    _validatePartDirective(library, definingPath, outputPath);

    final generatedModels = <String>[];
    for (final model in builtModels) {
      generatedModels.add(model.result.source!.trim());
    }

    final content = _renderPart(
      library: library,
      definingPath: definingPath,
      generatedModels: generatedModels,
    );
    return PendingGeneratedFile.text(path: outputPath, content: content);
  }

  void _validatePartDirective(
    ResolvedLibraryResult library,
    String definingPath,
    String outputPath,
  ) {
    final definingUnit = library.unitWithPath(definingPath);
    if (definingUnit == null) {
      throw DataforgeGenerationException(
        'Could not locate defining unit for ${library.element.uri}.',
      );
    }
    final expected = p.basename(outputPath);
    final hasExpected = definingUnit.unit.directives
        .whereType<PartDirective>()
        .any((directive) => directive.uri.stringValue == expected);
    if (!hasExpected) {
      throw DataforgeGenerationException(
        "DF1001 ${p.basename(definingPath)} must declare part '$expected'; "
        'v1 generate never edits source files.',
      );
    }
  }
}

Future<void> _synchronizeGenerationJournals(
  Set<String> roots, {
  required bool check,
}) async {
  final orderedRoots = roots.toList()..sort();
  for (final root in orderedRoots) {
    final normalizedRoot = p.normalize(p.absolute(root));
    final journal = File(
      p.join(normalizedRoot, GeneratedFileTransaction.journalRelativePath),
    );
    if (!check) {
      await const GeneratedFileTransaction().recover(normalizedRoot);
      continue;
    }

    final FileSystemEntityType journalType;
    try {
      journalType = await FileSystemEntity.type(
        journal.path,
        followLinks: false,
      );
    } on FileSystemException catch (error) {
      throw DataforgeIoException(
        'Could not inspect the generation journal during check: '
        '${journal.path}.',
        cause: error,
      );
    }
    if (journalType != FileSystemEntityType.notFound) {
      throw DataforgeCheckException(
        'An unfinished generation transaction exists at ${journal.path}. '
        'check is strictly read-only; run generate to recover it first.',
      );
    }
  }
}

Set<String> _coordinationRootsFor({
  required String projectRoot,
  required List<String> candidateFiles,
  required String? scanRoot,
}) {
  final roots = <String>{p.normalize(p.absolute(projectRoot))};
  for (final file in candidateFiles) {
    final root = _packageRootFor(file);
    if (root != null) roots.add(root);
  }
  if (scanRoot != null) {
    roots.addAll(_discoverPackageRoots(scanRoot));
  }
  return roots;
}

Set<String> _discoverPackageRoots(String scanRoot) {
  final roots = <String>{};

  void scan(String directoryPath) {
    final parentIsPackageRoot = File(
      p.join(directoryPath, 'pubspec.yaml'),
    ).existsSync();
    if (parentIsPackageRoot) {
      roots.add(p.normalize(p.absolute(directoryPath)));
    }
    for (final entity in Directory(
      directoryPath,
    ).listSync(followLinks: false)) {
      if (entity is! Directory) continue;
      if (_shouldSkipOrphanScanDirectory(
        p.basename(entity.path),
        parentIsPackageRoot: parentIsPackageRoot,
      )) {
        continue;
      }
      scan(entity.path);
    }
  }

  try {
    scan(scanRoot);
    return roots;
  } on FileSystemException catch (error) {
    throw DataforgeIoException(
      'Failed to discover Dart package roots under $scanRoot: $error',
      cause: error,
    );
  }
}

final class _PreparedLibrary {
  const _PreparedLibrary({
    required this.definingPath,
    required this.packageRoot,
    required this.output,
  });

  final String definingPath;
  final String packageRoot;
  final PendingGeneratedFile output;
}

final class _ResolvedLibraryInfo {
  _ResolvedLibraryInfo({
    required this.definingPath,
    required Set<String> referencedPaths,
  }) : referencedPaths = Set<String>.unmodifiable(referencedPaths);

  final String definingPath;
  final Set<String> referencedPaths;
}

final class _BuiltModel {
  const _BuiltModel(
    this.result, {
    required this.sourceUri,
    required this.offset,
  });

  final V1ResolvedGeneration result;
  final String sourceUri;
  final int offset;
}

Future<void> _captureDiskInput(
  String path,
  Map<String, List<int>> snapshots,
) async {
  final normalized = p.normalize(p.absolute(path));
  try {
    final type = await FileSystemEntity.type(normalized, followLinks: false);
    if (type != FileSystemEntityType.file) {
      throw DataforgeCheckException(
        'Generation input is not a regular file: $normalized.',
      );
    }
    _recordInputSnapshot(
      normalized,
      await File(normalized).readAsBytes(),
      snapshots,
    );
  } on DataforgeCliException {
    rethrow;
  } on FileSystemException catch (error) {
    throw DataforgeCheckException(
      'Could not snapshot generation input $normalized: $error.',
      cause: error,
    );
  }
}

Future<void> _captureResolvedLibraryInputs(
  ResolvedLibraryResult root,
  Map<String, List<int>> snapshots,
) async {
  final pending = <({LibraryElement element, ResolvedLibraryResult? result})>[
    (element: root.element, result: root),
  ];
  final visited = <String>{};

  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    final library = current.element;
    if (library.isInSdk || !visited.add(library.identifier)) continue;

    final resolved =
        current.result ??
        await library.session.getResolvedLibraryByElement(library);
    if (resolved is! ResolvedLibraryResult) {
      throw DataforgeGenerationException(
        'Could not snapshot resolved dependency ${library.identifier} '
        '(${resolved.runtimeType}).',
      );
    }

    for (final unit in resolved.units) {
      final path = p.normalize(p.absolute(unit.path));
      try {
        final type = await FileSystemEntity.type(path, followLinks: false);
        if (type != FileSystemEntityType.file) {
          throw DataforgeCheckException(
            'Resolved generation input is no longer a regular file: $path.',
          );
        }
        final bytes = await File(path).readAsBytes();
        String diskContent;
        try {
          diskContent = utf8.decode(bytes);
        } on FormatException catch (error) {
          throw DataforgeCheckException(
            'Resolved generation input is no longer valid UTF-8: $path.',
            cause: error,
          );
        }
        if (diskContent != unit.content) {
          throw DataforgeCheckException(
            'Generation input changed while Analyzer was resolving it: '
            '$path. Run generation again.',
          );
        }
        _recordInputSnapshot(path, bytes, snapshots);
      } on DataforgeCliException {
        rethrow;
      } on FileSystemException catch (error) {
        throw DataforgeCheckException(
          'Could not snapshot resolved generation input $path: $error.',
          cause: error,
        );
      }
    }

    final dependencies =
        <LibraryElement>{
            ...library.firstFragment.importedLibraries,
            ...library.exportedLibraries,
          }.where((dependency) => !dependency.isInSdk).toList()
          ..sort((left, right) => left.identifier.compareTo(right.identifier));
    for (final dependency in dependencies.reversed) {
      pending.add((element: dependency, result: null));
    }
  }
}

void _recordInputSnapshot(
  String path,
  List<int> bytes,
  Map<String, List<int>> snapshots,
) {
  final existing = snapshots[path];
  if (existing != null && !bytesEqual(existing, bytes)) {
    throw DataforgeCheckException(
      'Generation input produced inconsistent snapshots: $path. Run '
      'generation again.',
    );
  }
  snapshots[path] = List<int>.unmodifiable(bytes);
}

Future<String> _validatedOrphanScanRoot(
  String scanRoot, {
  required String projectRoot,
}) async {
  final root = p.normalize(p.absolute(projectRoot));
  final scan = p.normalize(p.absolute(scanRoot));
  if (!p.equals(root, scan) && !p.isWithin(root, scan)) {
    throw DataforgeInputException(
      'The v1 orphan scan root must stay inside the project root: $scan.',
    );
  }
  final type = await FileSystemEntity.type(scan, followLinks: false);
  if (type != FileSystemEntityType.directory) {
    throw DataforgeInputException(
      'The v1 orphan scan root must be a regular directory: $scan.',
    );
  }
  return scan;
}

Future<List<PendingGeneratedFile>> _prepareMissingSourceOutputDeletions(
  String scanRoot,
) async {
  final paths = <({String output, String source})>[];

  void scan(String directoryPath) {
    final parentIsPackageRoot = File(
      p.join(directoryPath, 'pubspec.yaml'),
    ).existsSync();
    for (final entity in Directory(
      directoryPath,
    ).listSync(followLinks: false)) {
      if (entity is Directory) {
        if (!_shouldSkipOrphanScanDirectory(
          p.basename(entity.path),
          parentIsPackageRoot: parentIsPackageRoot,
        )) {
          scan(entity.path);
        }
        continue;
      }
      if (!entity.path.endsWith('.data.dart')) continue;
      final outputPath = p.normalize(p.absolute(entity.path));
      final sourcePath = _sourcePathForOutput(outputPath);
      final sourceType = FileSystemEntity.typeSync(
        sourcePath,
        followLinks: false,
      );
      if (sourceType == FileSystemEntityType.notFound) {
        paths.add((output: outputPath, source: sourcePath));
      }
    }
  }

  try {
    scan(scanRoot);
    paths.sort((left, right) => left.output.compareTo(right.output));
    final deletions = <PendingGeneratedFile>[];
    for (final path in paths) {
      final deletion = await _prepareOwnedOutputDeletion(
        path.output,
        requiredAbsentPath: path.source,
      );
      if (deletion != null) deletions.add(deletion);
    }
    return deletions;
  } on DataforgeCliException {
    rethrow;
  } on FileSystemException catch (error) {
    throw DataforgeIoException(
      'Failed to scan for orphaned Dataforge v1 outputs under '
      '$scanRoot: $error',
      cause: error,
    );
  }
}

bool _shouldSkipOrphanScanDirectory(
  String name, {
  required bool parentIsPackageRoot,
}) {
  const toolingDirectories = {
    '.dart_tool',
    '.git',
    '.hg',
    '.svn',
    '.idea',
    '.vscode',
    '.pub-cache',
    'node_modules',
    '.packages',
    '.flutter-plugins',
    '.flutter-plugins-dependencies',
  };
  if (toolingDirectories.contains(name)) return true;
  return parentIsPackageRoot && (name == 'build' || name == 'coverage');
}

String _sourcePathForOutput(String outputPath) {
  const suffix = '.data.dart';
  return '${outputPath.substring(0, outputPath.length - suffix.length)}.dart';
}

Set<String> _referencedDirectivePaths(ResolvedLibraryResult library) {
  final paths = <String>{};
  for (final unit in library.units) {
    for (final directive
        in unit.unit.directives.whereType<UriBasedDirective>()) {
      DirectiveUri? resolvedUri;
      if (directive is PartDirective) {
        resolvedUri = directive.partInclude?.uri;
      } else if (directive is ImportDirective) {
        resolvedUri = directive.libraryImport?.uri;
      } else if (directive is ExportDirective) {
        resolvedUri = directive.libraryExport?.uri;
      }
      if (resolvedUri is DirectiveUriWithSource) {
        paths.add(p.normalize(resolvedUri.source.fullName));
        continue;
      }

      final uri = directive.uri.stringValue;
      if (uri == null) continue;
      final parsed = Uri.tryParse(uri);
      if (parsed == null || parsed.hasScheme || parsed.path.isEmpty) continue;
      paths.add(
        p.normalize(p.absolute(p.join(p.dirname(unit.path), parsed.path))),
      );
    }
  }
  return paths;
}

void _throwDeletedOutputReferences(
  List<_ResolvedLibraryInfo> libraries,
  Set<String> deletedPaths,
) {
  if (deletedPaths.isEmpty) return;
  final references = <(String, String)>[];
  for (final library in libraries) {
    for (final referencedPath in library.referencedPaths) {
      if (deletedPaths.contains(referencedPath)) {
        references.add((library.definingPath, referencedPath));
      }
    }
  }
  if (references.isEmpty) return;
  references.sort((left, right) {
    final libraryOrder = left.$1.compareTo(right.$1);
    return libraryOrder != 0 ? libraryOrder : left.$2.compareTo(right.$2);
  });
  throw DataforgeGenerationException(
    'DF2001 A surviving Dart library still references a generated output '
    'scheduled for deletion:\n'
    '${references.map((reference) => '  ${reference.$1} -> ${reference.$2}').join('\n')}',
  );
}

Future<PendingGeneratedFile?> _prepareOwnedOutputDeletion(
  String outputPath, {
  String? requiredAbsentPath,
}) async {
  try {
    final type = await FileSystemEntity.type(outputPath, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw DataforgeIoException(
        'Refusing to inspect stale generated output because it is not a '
        'regular file: $outputPath.',
      );
    }

    final bytes = await File(outputPath).readAsBytes();
    if (!_isOwnedDataforgeOutput(bytes)) return null;
    return PendingGeneratedFile.delete(
      path: outputPath,
      expectedBytes: bytes,
      requiredAbsentPath: requiredAbsentPath,
    );
  } on DataforgeCliException {
    rethrow;
  } on FileSystemException catch (error) {
    throw DataforgeIoException(
      'Failed to inspect stale generated output $outputPath: $error',
      cause: error,
    );
  }
}

bool _isOwnedDataforgeOutput(List<int> bytes) {
  late final String content;
  try {
    content = utf8.decode(bytes);
  } on FormatException {
    return false;
  }
  return content.startsWith('$_defaultFileHeader\n') &&
      content.contains('// ignore_for_file: prefer_const_constructors') &&
      content.contains('\n// DataforgeGenerator\n') &&
      content.contains('$_descriptionLine\n// DataforgeGenerator\n');
}

Future<void> _validatePreparedLibraries({
  required String packageRoot,
  required List<PendingGeneratedFile> operations,
  required Set<String> definingPaths,
}) async {
  if (definingPaths.isEmpty) return;

  final orderedOperations = [...operations]
    ..sort((left, right) => left.path.compareTo(right.path));
  final overlay = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);
  final deletedPaths = <String>{};
  for (var index = 0; index < orderedOperations.length; index++) {
    final output = orderedOperations[index];
    if (output.isDeletion) {
      deletedPaths.add(output.path);
    } else {
      overlay.setOverlay(
        output.path,
        content: utf8.decode(output.bytes),
        modificationStamp: index + 1,
      );
    }
  }
  final provider = _DeletedPathResourceProvider(overlay, deletedPaths);
  final orderedDefiningPaths = definingPaths.toList()..sort();

  final collection = AnalysisContextCollection(
    includedPaths: [packageRoot],
    resourceProvider: provider,
  );
  try {
    for (final definingPath in orderedDefiningPaths) {
      final context = collection.contextFor(definingPath);
      final result = await context.currentSession.getResolvedLibraryContaining(
        definingPath,
      );
      if (result is! ResolvedLibraryResult) {
        throw DataforgeGenerationException(
          'Failed to validate generated Dataforge v1 output for '
          '$definingPath (${result.runtimeType}).',
        );
      }
      _throwAnalyzerErrors(
        result.units,
        where: (_, diagnostic) =>
            diagnostic.diagnosticCode.severity == DiagnosticSeverity.ERROR,
      );
    }
  } on DataforgeCliException {
    rethrow;
  } catch (error) {
    throw DataforgeGenerationException(
      'Failed to validate generated Dataforge v1 outputs under '
      '$packageRoot: $error',
      cause: error,
    );
  } finally {
    await collection.dispose();
  }
}

/// Makes pending deletions appear absent from Analyzer's candidate filesystem.
final class _DeletedPathResourceProvider
    implements analyzer_fs.ResourceProvider {
  _DeletedPathResourceProvider(this.baseProvider, Set<String> deletedPaths)
    : deletedPaths = Set<String>.unmodifiable(deletedPaths);

  final analyzer_fs.ResourceProvider baseProvider;
  final Set<String> deletedPaths;

  bool _isDeleted(String path) => deletedPaths.contains(p.normalize(path));

  @override
  p.Context get pathContext => baseProvider.pathContext;

  @override
  analyzer_fs.File getFile(String path) {
    final file = baseProvider.getFile(path);
    return _isDeleted(path) ? _DeletedFile(this, file) : file;
  }

  @override
  analyzer_fs.Folder getFolder(String path) => baseProvider.getFolder(path);

  @override
  analyzer_fs.Link getLink(String path) => baseProvider.getLink(path);

  @override
  analyzer_fs.Resource getResource(String path) =>
      _isDeleted(path) ? getFile(path) : baseProvider.getResource(path);

  @override
  analyzer_fs.Folder? getStateLocation(String pluginId) =>
      baseProvider.getStateLocation(pluginId);
}

final class _DeletedFile implements analyzer_fs.File {
  const _DeletedFile(this.provider, this._delegate);

  @override
  final _DeletedPathResourceProvider provider;
  final analyzer_fs.File _delegate;

  Never _notFound() {
    throw analyzer_fs.PathNotFoundException(
      path,
      'File is deleted in the Dataforge candidate file system.',
    );
  }

  @override
  bool get exists => false;

  @override
  int get lengthSync => _notFound();

  @override
  int get modificationStamp => _notFound();

  @override
  analyzer_fs.Folder get parent => provider.getFolder(p.dirname(path));

  @override
  String get path => _delegate.path;

  @override
  String get shortName => _delegate.shortName;

  @override
  analyzer_fs.File copyTo(analyzer_fs.Folder parentFolder) => _notFound();

  @override
  void delete() => _notFound();

  @override
  bool isOrContains(String candidate) => p.equals(path, candidate);

  @override
  Uint8List readAsBytesSync() => _notFound();

  @override
  String readAsStringSync() => _notFound();

  @override
  analyzer_fs.File renameSync(String newPath) => _notFound();

  @override
  analyzer_fs.Resource resolveSymbolicLinksSync() => this;

  @override
  Uri toUri() => _delegate.toUri();

  @override
  analyzer_fs.ResourceWatcher watch() => _delegate.watch();

  @override
  void writeAsBytesSync(List<int> bytes) => _notFound();

  @override
  void writeAsStringSync(String content) => _notFound();
}

void _validateAnalyzerSyntaxDiagnostics(
  ResolvedLibraryResult library,
  String expectedOutputPath,
) {
  _throwAnalyzerErrors(
    library.units,
    where: (unit, diagnostic) {
      return !_isExpectedGeneratedOutput(unit.path, expectedOutputPath) &&
          diagnostic.diagnosticCode.type == DiagnosticType.SYNTACTIC_ERROR;
    },
  );
}

void _validateAnalyzerDiagnostics(
  ResolvedLibraryResult library,
  String expectedOutputPath,
) {
  _throwAnalyzerErrors(
    library.units,
    where: (unit, diagnostic) {
      return !_isExpectedGeneratedOutput(unit.path, expectedOutputPath) &&
          diagnostic.diagnosticCode.severity == DiagnosticSeverity.ERROR &&
          !_isGeneratedReferenceDiagnostic(
            unit,
            diagnostic,
            expectedOutputPath,
          );
    },
  );
}

void _throwAnalyzerErrors(
  List<ResolvedUnitResult> units, {
  required bool Function(ResolvedUnitResult, Diagnostic) where,
}) {
  final errors = <Diagnostic>[
    for (final unit in units)
      for (final diagnostic in unit.diagnostics)
        if (where(unit, diagnostic)) diagnostic,
  ];
  if (errors.isEmpty) return;

  errors.sort((left, right) {
    final sourceOrder = left.source.fullName.compareTo(right.source.fullName);
    if (sourceOrder != 0) return sourceOrder;
    final offsetOrder = left.offset.compareTo(right.offset);
    if (offsetOrder != 0) return offsetOrder;
    return left.diagnosticCode.uniqueName.compareTo(
      right.diagnosticCode.uniqueName,
    );
  });
  throw DataforgeGenerationException(
    'DF2001 Analyzer errors prevent Dataforge v1 generation:\n'
    '${errors.map(_formatAnalyzerDiagnostic).join('\n')}',
  );
}

bool _isGeneratedReferenceDiagnostic(
  ResolvedUnitResult unit,
  Diagnostic diagnostic,
  String expectedOutputPath,
) {
  final expectedPartUri = p.basename(expectedOutputPath);
  for (final directive in unit.unit.directives.whereType<PartDirective>()) {
    if (directive.uri.stringValue == expectedPartUri &&
        _containsDiagnostic(directive.uri, diagnostic)) {
      return true;
    }
  }

  for (final declaration
      in unit.unit.declarations.whereType<ClassDeclaration>()) {
    final element = declaration.declaredFragment?.element;
    if (element == null) continue;
    final implementationBase = _dataforgeImplementationBase(element);
    if (implementationBase == null) continue;
    for (final mixin in declaration.withClause?.mixinTypes ?? <NamedType>[]) {
      if (mixin.name.lexeme == '_\$$implementationBase' &&
          _containsDiagnostic(mixin, diagnostic)) {
        return true;
      }
    }
    for (final constructor
        in declaration.members.whereType<ConstructorDeclaration>()) {
      final redirected = constructor.redirectedConstructor;
      if (redirected != null &&
          _isGeneratedRedirect(redirected.toSource(), implementationBase) &&
          _containsDiagnostic(redirected, diagnostic)) {
        return true;
      }
    }
  }
  return false;
}

bool _isGeneratedRedirect(String source, String modelName) {
  final implementation = '_$modelName';
  return source == implementation ||
      source.startsWith('$implementation.') ||
      source.startsWith('$implementation<');
}

bool _containsDiagnostic(AstNode node, Diagnostic diagnostic) {
  return diagnostic.offset >= node.offset && diagnostic.offset < node.end;
}

bool _isExpectedGeneratedOutput(String path, String expectedOutputPath) =>
    p.normalize(p.absolute(path)) ==
    p.normalize(p.absolute(expectedOutputPath));

String _formatAnalyzerDiagnostic(Diagnostic diagnostic) {
  return '${diagnostic.source.fullName}:${diagnostic.offset} '
      '${diagnostic.diagnosticCode.uniqueName}: ${diagnostic.message}';
}

bool _hasResolvedDataforgeAnnotation(Element element) {
  return _resolvedDataforgeAnnotation(element) != null;
}

String? _dataforgeImplementationBase(ClassElement element) {
  final annotation = _resolvedDataforgeAnnotation(element);
  if (annotation == null) return null;
  final configuredName = annotation.getField('name')?.toStringValue();
  if (configuredName != null && configuredName.isNotEmpty) {
    return configuredName;
  }
  return element.name;
}

DartObject? _resolvedDataforgeAnnotation(Element element) {
  for (final annotation in element.metadata.annotations) {
    final value = annotation.computeConstantValue();
    if (value is! DartObject) continue;
    final type = value.type;
    if (type is! InterfaceType) continue;
    if (type.element.name == V1ResolvedModelGenerator.dataforgeAnnotationName &&
        type.element.library.uri.toString() ==
            V1ResolvedModelGenerator.dataforgeAnnotationLibraryUri) {
      return value;
    }
  }
  return null;
}

String _renderPart({
  required ResolvedLibraryResult library,
  required String definingPath,
  required List<String> generatedModels,
}) {
  final buffer = StringBuffer()
    ..writeln(_generatedFileHeader)
    ..writeln();
  final override = library.element.languageVersion.override;
  if (override != null) {
    buffer.writeln('// @dart=${override.major}.${override.minor}');
  }
  buffer
    ..writeln("part of '${p.basename(definingPath)}';")
    ..writeln()
    ..writeln(_descriptionLine)
    ..writeln('// DataforgeGenerator')
    ..writeln(_descriptionLine)
    ..writeln()
    ..writeln(generatedModels.join('\n\n'));

  var code = buffer.toString();
  if (code.startsWith('$_defaultFileHeader\n')) {
    code =
        '$_defaultFileHeader\n'
        '$_dartFormatWidth\n'
        '${code.substring(_defaultFileHeader.length)}';
  } else {
    code = '$_dartFormatWidth\n$code';
  }
  try {
    return DartFormatter(
      languageVersion: library.element.languageVersion.effective,
    ).format(code);
  } catch (error) {
    throw DataforgeGenerationException(
      'Failed to format generated output for ${library.element.uri}: $error',
      cause: error,
    );
  }
}

String _diagnosticsMessage(List<GenerationDiagnostic> diagnostics) {
  if (diagnostics.isEmpty) {
    return 'Dataforge v1 generation failed without a diagnostic.';
  }
  return diagnostics
      .map(
        (diagnostic) => diagnostic.details.isEmpty
            ? diagnostic.toString()
            : '${diagnostic.toString()} details=${diagnostic.details}',
      )
      .join('\n');
}

String _outputPathFor(String definingPath) {
  return '${definingPath.substring(0, definingPath.length - '.dart'.length)}.data.dart';
}

bool _looksLikeV1(File file) {
  try {
    final content = file.readAsStringSync();
    final hasV1Modifier =
        RegExp(r'\babstract\s+final\s+class\b').hasMatch(content) ||
        RegExp(r'\bfinal\s+abstract\s+class\b').hasMatch(content);
    final hasDataforgeShape =
        RegExp(r'@(?:[\w$]+\.)?Dataforge\b').hasMatch(content) ||
        RegExp(r'\bwith\s+_\$[A-Za-z_$]').hasMatch(content) ||
        RegExp(r'''\bpart\s+['"][^'"]+\.data\.dart['"]''').hasMatch(content);
    return hasV1Modifier && hasDataforgeShape;
  } on FileSystemException {
    return false;
  }
}

String? _packageConfigFor(String filePath) {
  final root = _packageRootFor(filePath);
  if (root == null) return null;
  final config = p.join(root, '.dart_tool', 'package_config.json');
  return File(config).existsSync() ? config : null;
}

String? _packageRootFor(String filePath) {
  var current = p.dirname(filePath);
  while (true) {
    if (File(p.join(current, 'pubspec.yaml')).existsSync()) return current;
    final parent = p.dirname(current);
    if (parent == current) return null;
    current = parent;
  }
}
