import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'exceptions.dart';

/// A generated file operation prepared and formatted in memory for commit.
final class PendingGeneratedFile {
  PendingGeneratedFile({
    required this.path,
    required List<int> bytes,
    this.requiredAbsentPath,
  }) : bytes = List<int>.unmodifiable(bytes),
       isDeletion = false;

  factory PendingGeneratedFile.text({
    required String path,
    required String content,
  }) {
    return PendingGeneratedFile(path: path, bytes: utf8.encode(content));
  }

  /// Deletes a stale generated file already confirmed as Dataforge-owned.
  ///
  /// [expectedBytes] is the ownership-check snapshot. The transaction compares
  /// it again under the lock before moving the target, protecting later edits.
  PendingGeneratedFile.delete({
    required this.path,
    required List<int> expectedBytes,
    this.requiredAbsentPath,
  }) : bytes = List<int>.unmodifiable(expectedBytes),
       isDeletion = true;

  final String path;

  /// New write bytes or expected deletion bytes, stored as an immutable copy.
  final List<int> bytes;

  final bool isDeletion;

  /// Source path that must remain absent while deleting an orphaned output.
  ///
  /// This is a commit precondition and is not journaled. Crash recovery always
  /// rolls outputs back without guessing from later source state.
  final String? requiredAbsentPath;
}

/// Same-directory atomic replacement, deletion, and journal recovery for v1.
///
/// Multiple files are not guaranteed to become visible simultaneously.
///
/// The journal is installed before any target moves. Recovery always rolls
/// back to the pre-transaction state, preventing partial new output.
final class GeneratedFileTransaction {
  static const String journalRelativePath =
      '.dart_tool/dataforge/generate-journal.json';
  static const String lockRelativePath = '.dart_tool/dataforge/generate.lock';
  static final Map<String, Future<void>> _inProcessLocks = {};

  const GeneratedFileTransaction({
    FutureOr<void> Function(int entryIndex)? beforeInstallForTesting,
  }) : _beforeInstallForTesting = beforeInstallForTesting;

  final FutureOr<void> Function(int entryIndex)? _beforeInstallForTesting;

  Future<void> recover(String projectRoot) async {
    final root = await _safeRoot(projectRoot);
    final journal = File(p.join(root.path, journalRelativePath));
    final journalType = await FileSystemEntity.type(
      journal.path,
      followLinks: false,
    );
    if (journalType == FileSystemEntityType.notFound) return;
    await _withLock(root, () => _recoverUnlocked(root));
  }

  Future<void> commit({
    required String projectRoot,
    required List<PendingGeneratedFile> files,
    Map<String, List<int>> requiredInputs = const {},
  }) async {
    if (files.isEmpty) return;

    final pendingFiles = List<PendingGeneratedFile>.unmodifiable(files);
    final inputSnapshots = Map<String, List<int>>.unmodifiable({
      for (final entry in requiredInputs.entries)
        p.normalize(p.absolute(entry.key)): List<int>.unmodifiable(entry.value),
    });
    final requiredAbsentPaths = Set<String>.unmodifiable({
      for (final file in pendingFiles)
        if (file.requiredAbsentPath != null)
          p.normalize(p.absolute(file.requiredAbsentPath!)),
    });
    final root = await _safeRoot(projectRoot);
    await _withLock(root, () async {
      await _recoverUnlocked(root);
      await _commitUnlocked(
        root: root,
        files: pendingFiles,
        requiredInputs: inputSnapshots,
        requiredAbsentPaths: requiredAbsentPaths,
      );
    });
  }

  Future<void> _commitUnlocked({
    required _SafeRoot root,
    required List<PendingGeneratedFile> files,
    required Map<String, List<int>> requiredInputs,
    required Set<String> requiredAbsentPaths,
  }) async {
    final ordered =
        files
            .map(
              (file) => file.isDeletion
                  ? PendingGeneratedFile.delete(
                      path: _absoluteFromRoot(root.path, file.path),
                      expectedBytes: file.bytes,
                    )
                  : PendingGeneratedFile(
                      path: _absoluteFromRoot(root.path, file.path),
                      bytes: file.bytes,
                    ),
            )
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
    final transactionId = _newTransactionId();
    final entries = <_JournalEntry>[];
    final journal = File(p.join(root.path, journalRelativePath));
    File? journalTemporary;
    var journalTemporaryOwned = false;
    final ownedTemporaryPaths = <String>{};
    var journalOwned = false;

    try {
      await validateGeneratedInputPreconditions(
        requiredInputs: requiredInputs,
        requiredAbsentPaths: requiredAbsentPaths,
      );
      final targets = <String>{};
      // Validate the complete target set before creating any transaction data.
      for (final pending in ordered) {
        if (!targets.add(pending.path)) {
          throw const FormatException(
            'generation transaction target paths must be unique',
          );
        }
        await _validateTargetPath(root, pending.path, requireParent: false);
      }

      for (var index = 0; index < ordered.length; index++) {
        final pending = ordered[index];
        final target = File(pending.path);
        await _ensureSafeDirectory(root, target.parent.path);
        await _validateTargetPath(root, target.path, requireParent: true);
        final originalExisted = await target.exists();
        List<int>? originalBytes;
        String? originalHash;
        if (originalExisted) {
          originalBytes = await target.readAsBytes();
          originalHash = _generatedSha256(originalBytes);
        }
        if (pending.isDeletion) {
          // An externally deleted target already satisfies this operation. Do
          // not journal a no-op that could affect a later same-named file.
          if (!originalExisted) continue;
          if (!bytesEqual(originalBytes!, pending.bytes)) {
            throw DataforgeCheckException(
              'Generated output changed before stale-file deletion: '
              '${target.path}. Run generation again.',
            );
          }
        } else if (originalHash == _generatedSha256(pending.bytes)) {
          // Do not create recoverable state when the target already matches.
          continue;
        }

        final prefix =
            '.${p.basename(target.path)}.dataforge.$transactionId.$index';
        final temporary = File(p.join(target.parent.path, '$prefix.tmp'));
        final backup = File(p.join(target.parent.path, '$prefix.bak'));
        await _validateAuxiliaryPath(
          root,
          temporary.path,
          requireNotFound: true,
        );
        await _validateAuxiliaryPath(root, backup.path, requireNotFound: true);

        final entry = _JournalEntry(
          targetPath: target.path,
          temporaryPath: temporary.path,
          backupPath: backup.path,
          originalHash: originalHash,
          replacementHash: pending.isDeletion
              ? null
              : _generatedSha256(pending.bytes),
          deleteTarget: pending.isDeletion,
          state: _JournalState.prepared,
        );
        entries.add(entry);
        if (!pending.isDeletion) {
          // Register ownership before writing so a partial write is cleaned up.
          await _validateAuxiliaryPath(
            root,
            temporary.path,
            requireNotFound: true,
          );
          await temporary.create(exclusive: true);
          ownedTemporaryPaths.add(temporary.path);
          await temporary.writeAsBytes(pending.bytes, flush: true);
          await _ensureFileHash(
            temporary.path,
            entry.replacementHash!,
            context: 'while preparing generated bytes',
          );
        }
      }
      if (entries.isEmpty) return;
      await _validateJournalEntries(root, entries);

      await _ensureSafeDirectory(root, journal.parent.path);
      await _validateControlFile(root, journal.path, allowMissing: true);
      journalTemporary = File('${journal.path}.$transactionId.tmp');
      await _validateControlFile(
        root,
        journalTemporary.path,
        allowMissing: true,
        requireNotFound: true,
      );
      await journalTemporary.create(exclusive: true);
      journalTemporaryOwned = true;
      await journalTemporary.writeAsString(
        '${jsonEncode({'version': 2, 'entries': entries.map((entry) => entry.toJson()).toList()})}\n',
        flush: true,
      );
      await _validateControlFile(root, journal.path, allowMissing: true);
      if (await journal.exists()) {
        throw StateError('another Dataforge transaction is active');
      }
      await _validateControlFile(root, journalTemporary.path);
      await journalTemporary.rename(journal.path);
      journalTemporaryOwned = false;
      journalTemporary = null;
      journalOwned = true;

      await validateGeneratedInputPreconditions(
        requiredInputs: requiredInputs,
        requiredAbsentPaths: requiredAbsentPaths,
      );

      for (var index = 0; index < entries.length; index++) {
        var entry = entries[index];
        if (_beforeInstallForTesting != null) {
          await _beforeInstallForTesting(index);
        }
        await validateGeneratedInputPreconditions(
          requiredInputs: requiredInputs,
          requiredAbsentPaths: requiredAbsentPaths,
        );
        await _validateTargetPath(root, entry.targetPath, requireParent: true);
        await _validateAuxiliaryPath(root, entry.backupPath);
        if (!entry.deleteTarget) {
          await _validateAuxiliaryPath(root, entry.temporaryPath);
        }

        final target = File(entry.targetPath);
        if (entry.originalHash != null) {
          await _ensureFileHash(
            entry.targetPath,
            entry.originalHash!,
            context: 'immediately before replacing generated output',
          );
          await _renameRegularFile(
            root,
            from: entry.targetPath,
            to: entry.backupPath,
          );
        } else if (await target.exists()) {
          throw DataforgeCheckException(
            'generated target appeared during transaction: '
            '${entry.targetPath}',
          );
        }
        entry = entry.withState(_JournalState.backedUp);
        entries[index] = entry;
        await _appendJournalState(journal, index, entry.state);

        if (!entry.deleteTarget) {
          await _ensureFileHash(
            entry.temporaryPath,
            entry.replacementHash!,
            context: 'immediately before installing generated output',
          );
          await _renameRegularFile(
            root,
            from: entry.temporaryPath,
            to: entry.targetPath,
          );
          ownedTemporaryPaths.remove(entry.temporaryPath);
        }
        entry = entry.withState(_JournalState.installed);
        entries[index] = entry;
        await _appendJournalState(journal, index, entry.state);
      }

      // Journal removal is the commit point; backups are cleanup-only after it.
      await validateGeneratedInputPreconditions(
        requiredInputs: requiredInputs,
        requiredAbsentPaths: requiredAbsentPaths,
      );
      await _deleteRegularFile(root, journal.path, requireExisting: true);
      journalOwned = false;
      for (final entry in entries) {
        try {
          await _deleteRegularFile(root, entry.backupPath);
        } on FileSystemException {
          // Cleanup failure after commit does not affect output or recovery.
        } on FormatException {
          // Preserve a concurrently substituted link instead of following it.
        }
      }
    } catch (error) {
      try {
        if (journalOwned) {
          await _validateRecoveryState(root, entries);
          await _rollback(root, entries);
          await _deleteRegularFile(root, journal.path);
          journalOwned = false;
        } else {
          await _deleteTransactionFiles(root, entries, ownedTemporaryPaths);
          if (journalTemporaryOwned && journalTemporary != null) {
            await _deleteRegularFile(root, journalTemporary.path);
          }
        }
      } on DataforgeCheckException {
        // Preserve all evidence when any content is not proven by the journal.
        rethrow;
      } catch (rollbackError) {
        throw DataforgeIoException(
          'Dataforge transaction failed and rollback was incomplete: '
          '$rollbackError (original error: $error)',
          cause: error,
        );
      }
      if (error is DataforgeCliException) rethrow;
      throw DataforgeIoException(
        'Dataforge transaction failed; all v1 outputs were rolled back: '
        '$error',
        cause: error,
      );
    }
  }

  Future<void> _recoverUnlocked(_SafeRoot root) async {
    final journal = File(p.join(root.path, journalRelativePath));
    final journalType = await FileSystemEntity.type(
      journal.path,
      followLinks: false,
    );
    if (journalType == FileSystemEntityType.notFound) return;

    try {
      await _validateControlFile(root, journal.path);
      final entries = await _readJournalEntries(journal);
      await _validateJournalEntries(root, entries);
      await _validateRecoveryState(root, entries);
      await _rollback(root, entries);
      await _deleteRegularFile(root, journal.path, requireExisting: true);
    } on DataforgeCliException {
      rethrow;
    } catch (error) {
      throw DataforgeIoException(
        'Failed to recover unfinished Dataforge transaction at '
        '${journal.path}: $error',
        cause: error,
      );
    }
  }

  Future<void> _appendJournalState(
    File journal,
    int entryIndex,
    _JournalState state,
  ) async {
    await journal.writeAsString(
      '${jsonEncode({'entry': entryIndex, 'state': state.name})}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<List<_JournalEntry>> _readJournalEntries(File journal) async {
    final content = await journal.readAsString();
    final lines = content.split('\n');
    if (lines.isEmpty || lines.first.isEmpty) {
      throw const FormatException('generation journal header is missing');
    }
    final document = jsonDecode(lines.first);
    if (document is! Map<String, Object?> || document['version'] != 2) {
      throw const FormatException('unsupported generation journal format');
    }
    final rawEntries = document['entries'];
    if (rawEntries is! List) {
      throw const FormatException('journal entries must be a list');
    }
    final entries = rawEntries
        .map((value) => _JournalEntry.fromJson(value))
        .toList(growable: true);
    if (entries.any((entry) => entry.state != _JournalState.prepared)) {
      throw const FormatException(
        'generation journal header entries must start prepared',
      );
    }

    // A final line without a newline is a crash-torn append. Filesystem hashes
    // permit transaction state to be at most one step ahead of the journal.
    final eventLimit = content.endsWith('\n') ? lines.length : lines.length - 1;
    for (var lineIndex = 1; lineIndex < eventLimit; lineIndex++) {
      final line = lines[lineIndex];
      if (line.isEmpty) continue;
      final event = jsonDecode(line);
      if (event is! Map<String, Object?>) {
        throw const FormatException('invalid generation journal state event');
      }
      final entryIndex = event['entry'];
      final rawState = event['state'];
      if (entryIndex is! int ||
          entryIndex < 0 ||
          entryIndex >= entries.length ||
          rawState is! String) {
        throw const FormatException('invalid journal state event fields');
      }
      final nextState = _JournalState.parse(rawState);
      final current = entries[entryIndex];
      if (nextState.index != current.state.index + 1) {
        throw const FormatException(
          'generation journal state transition is invalid',
        );
      }
      entries[entryIndex] = current.withState(nextState);
    }
    return entries;
  }

  Future<T> _withLock<T>(_SafeRoot root, Future<T> Function() action) async {
    final lockFile = File(p.join(root.path, lockRelativePath));
    final lockPath = p.normalize(p.absolute(lockFile.path));
    final predecessor = _inProcessLocks[lockPath] ?? Future<void>.value();
    final release = Completer<void>();
    final ownLock = release.future;
    _inProcessLocks[lockPath] = ownLock;
    await predecessor;
    RandomAccessFile? handle;
    try {
      await _ensureSafeDirectory(root, lockFile.parent.path);
      await _validateControlFile(root, lockFile.path, allowMissing: true);
      handle = await lockFile.open(mode: FileMode.append);
      await handle.lock(FileLock.blockingExclusive);
      return await action();
    } on DataforgeCliException {
      rethrow;
    } catch (error) {
      throw DataforgeIoException(
        'Failed to acquire or use Dataforge transaction lock at '
        '${lockFile.path}: $error',
        cause: error,
      );
    } finally {
      try {
        if (handle != null) {
          try {
            await handle.unlock();
          } on FileSystemException {
            // Closing the handle still releases the operating-system lock.
          }
          await handle.close();
        }
      } finally {
        release.complete();
        if (identical(_inProcessLocks[lockPath], ownLock)) {
          _inProcessLocks.remove(lockPath);
        }
      }
    }
  }

  Future<void> _validateJournalEntries(
    _SafeRoot root,
    List<_JournalEntry> entries,
  ) async {
    if (entries.isEmpty) {
      throw const FormatException('generation journal cannot be empty');
    }
    final targets = <String>{};
    for (final entry in entries) {
      if (entry.originalHash != null) _validateHash(entry.originalHash!);
      if (entry.replacementHash != null) {
        _validateHash(entry.replacementHash!);
      }
      if (entry.deleteTarget) {
        if (entry.originalHash == null || entry.replacementHash != null) {
          throw const FormatException(
            'generation deletion must have only an originalHash',
          );
        }
      } else if (entry.replacementHash == null) {
        throw const FormatException(
          'generation write must have a replacementHash',
        );
      }
      if (entry.originalHash != null &&
          entry.originalHash == entry.replacementHash) {
        throw const FormatException(
          'generation replacementHash must differ from originalHash',
        );
      }
      if (!_isNormalizedAbsolute(entry.targetPath) ||
          !_isNormalizedAbsolute(entry.temporaryPath) ||
          !_isNormalizedAbsolute(entry.backupPath)) {
        throw const FormatException(
          'journal paths must be normalized absolute paths',
        );
      }
      if (!targets.add(entry.targetPath)) {
        throw const FormatException('journal target paths must be unique');
      }
      await _validateTargetPath(root, entry.targetPath, requireParent: true);

      final targetDirectory = p.dirname(entry.targetPath);
      final targetBase = p.basename(entry.targetPath);
      final prefix = '.$targetBase.dataforge.';
      if (p.dirname(entry.temporaryPath) != targetDirectory ||
          p.dirname(entry.backupPath) != targetDirectory ||
          !p.basename(entry.temporaryPath).startsWith(prefix) ||
          !p.basename(entry.temporaryPath).endsWith('.tmp') ||
          !p.basename(entry.backupPath).startsWith(prefix) ||
          !p.basename(entry.backupPath).endsWith('.bak')) {
        throw const FormatException(
          'journal temporary and backup paths must be tool-owned siblings',
        );
      }
      final temporaryToken = p
          .basename(entry.temporaryPath)
          .substring(
            prefix.length,
            p.basename(entry.temporaryPath).length - '.tmp'.length,
          );
      final backupToken = p
          .basename(entry.backupPath)
          .substring(
            prefix.length,
            p.basename(entry.backupPath).length - '.bak'.length,
          );
      if (temporaryToken.isEmpty || temporaryToken != backupToken) {
        throw const FormatException(
          'journal temporary and backup paths must belong to one entry',
        );
      }
      await _validateAuxiliaryPath(root, entry.temporaryPath);
      await _validateAuxiliaryPath(root, entry.backupPath);
    }
  }

  Future<void> _deleteTransactionFiles(
    _SafeRoot root,
    List<_JournalEntry> entries,
    Set<String> ownedTemporaryPaths,
  ) async {
    for (final entry in entries) {
      final temporaryType = await FileSystemEntity.type(
        entry.temporaryPath,
        followLinks: false,
      );
      if (ownedTemporaryPaths.contains(entry.temporaryPath) &&
          temporaryType == FileSystemEntityType.file) {
        await _ensureFileHash(
          entry.temporaryPath,
          entry.replacementHash!,
          context: 'while cleaning an uncommitted generated temporary',
        );
      }
      final backupType = await FileSystemEntity.type(
        entry.backupPath,
        followLinks: false,
      );
      if (backupType != FileSystemEntityType.notFound) {
        throw DataforgeCheckException(
          'Unexpected generation backup appeared before journal commit: '
          '${entry.backupPath}. Cleanup preserved all auxiliary files.',
        );
      }
    }
    for (final entry in entries) {
      if (ownedTemporaryPaths.contains(entry.temporaryPath)) {
        await _deleteRegularFile(root, entry.temporaryPath);
      }
    }
  }

  Future<void> _validateRecoveryState(
    _SafeRoot root,
    List<_JournalEntry> entries,
  ) async {
    await _validateJournalEntries(root, entries);
    for (final entry in entries) {
      final targetType = await FileSystemEntity.type(
        entry.targetPath,
        followLinks: false,
      );
      final temporaryType = await FileSystemEntity.type(
        entry.temporaryPath,
        followLinks: false,
      );
      final backupType = await FileSystemEntity.type(
        entry.backupPath,
        followLinks: false,
      );
      for (final (label, type) in <(String, FileSystemEntityType)>[
        ('target', targetType),
        ('temporary', temporaryType),
        ('backup', backupType),
      ]) {
        if (type != FileSystemEntityType.notFound &&
            type != FileSystemEntityType.file) {
          throw DataforgeCheckException(
            'Generation recovery $label is no longer a regular file for '
            '${entry.targetPath}; recovery preserved the transaction.',
          );
        }
      }

      final targetHash = targetType == FileSystemEntityType.file
          ? await _readFileHash(entry.targetPath)
          : null;
      final temporaryHash = temporaryType == FileSystemEntityType.file
          ? await _readFileHash(entry.temporaryPath)
          : null;
      final backupHash = backupType == FileSystemEntityType.file
          ? await _readFileHash(entry.backupPath)
          : null;

      if (targetHash != null &&
          targetHash != entry.originalHash &&
          targetHash != entry.replacementHash) {
        throw DataforgeCheckException(
          'Generated output changed after an interrupted transaction: '
          '${entry.targetPath}. Recovery preserved the user content and '
          'journal.',
        );
      }
      if (backupHash != null && backupHash != entry.originalHash) {
        throw DataforgeCheckException(
          'Generation recovery backup has unknown content for '
          '${entry.targetPath}; recovery preserved the transaction.',
        );
      }
      if (temporaryHash != null &&
          (entry.deleteTarget || temporaryHash != entry.replacementHash)) {
        throw DataforgeCheckException(
          'Generation recovery temporary has unknown content for '
          '${entry.targetPath}; recovery preserved the transaction.',
        );
      }
      if (entry.originalHash == null && backupHash != null) {
        throw DataforgeCheckException(
          'Generation journal claims a new target but has an unexpected '
          'backup for ${entry.targetPath}; recovery preserved all files.',
        );
      }

      final valid = switch (entry.state) {
        _JournalState.prepared => _isPreparedRecoveryState(
          entry,
          targetHash: targetHash,
          temporaryHash: temporaryHash,
          backupHash: backupHash,
        ),
        _JournalState.backedUp => _isBackedUpRecoveryState(
          entry,
          targetHash: targetHash,
          temporaryHash: temporaryHash,
          backupHash: backupHash,
        ),
        _JournalState.installed => _isInstalledRecoveryState(
          entry,
          targetHash: targetHash,
          temporaryHash: temporaryHash,
          backupHash: backupHash,
        ),
      };
      if (!valid) {
        throw DataforgeCheckException(
          'Generation journal state ${entry.state.name} does not match the '
          'files for ${entry.targetPath}; recovery preserved the transaction.',
        );
      }
    }
  }

  Future<void> _rollback(_SafeRoot root, List<_JournalEntry> entries) async {
    // The caller validates every path, hash, and state before rollback starts.
    for (final entry in entries.reversed) {
      final backupType = await FileSystemEntity.type(
        entry.backupPath,
        followLinks: false,
      );
      if (backupType == FileSystemEntityType.file) {
        await _ensureFileHash(
          entry.backupPath,
          entry.originalHash!,
          context: 'immediately before restoring generated backup',
        );
        final targetType = await FileSystemEntity.type(
          entry.targetPath,
          followLinks: false,
        );
        if (targetType == FileSystemEntityType.file) {
          await _ensureFileHash(
            entry.targetPath,
            entry.replacementHash!,
            context: 'immediately before removing transaction-owned output',
          );
          await _deleteRegularFile(root, entry.targetPath);
        }
        await _renameRegularFile(
          root,
          from: entry.backupPath,
          to: entry.targetPath,
        );
      } else if (entry.originalHash == null) {
        final targetType = await FileSystemEntity.type(
          entry.targetPath,
          followLinks: false,
        );
        if (targetType == FileSystemEntityType.file) {
          await _ensureFileHash(
            entry.targetPath,
            entry.replacementHash!,
            context: 'immediately before removing transaction-owned output',
          );
          await _deleteRegularFile(root, entry.targetPath);
        }
      }
      final temporaryType = await FileSystemEntity.type(
        entry.temporaryPath,
        followLinks: false,
      );
      if (temporaryType == FileSystemEntityType.file) {
        await _ensureFileHash(
          entry.temporaryPath,
          entry.replacementHash!,
          context: 'immediately before removing generated temporary',
        );
        await _deleteRegularFile(root, entry.temporaryPath);
      }
    }
  }
}

/// Revalidates Analyzer inputs and orphan-source absence preconditions.
///
/// This function is read-only and safe for `check`. Normal generation also
/// calls it under the transaction lock before target changes and final commit,
/// rolling back instead of committing output derived from changed sources.
Future<void> validateGeneratedInputPreconditions({
  required Map<String, List<int>> requiredInputs,
  required Set<String> requiredAbsentPaths,
}) async {
  final inputPaths = requiredInputs.keys.toList()..sort();
  final absentPaths = requiredAbsentPaths.toList()..sort();
  try {
    for (final path in inputPaths) {
      final normalized = p.normalize(p.absolute(path));
      if (normalized != path) {
        throw DataforgeCheckException(
          'Generation input path is not normalized and absolute: $path.',
        );
      }
      final type = await FileSystemEntity.type(path, followLinks: false);
      if (type != FileSystemEntityType.file) {
        throw DataforgeCheckException(
          'Generation input is no longer a regular file: $path. Run '
          'generation again.',
        );
      }
      final current = await File(path).readAsBytes();
      final expected = requiredInputs[path]!;
      if (!bytesEqual(current, expected)) {
        throw DataforgeCheckException(
          'Generation input changed after it was resolved: $path. No stale '
          'generated output was committed; run generation again.',
        );
      }
    }

    for (final path in absentPaths) {
      final normalized = p.normalize(p.absolute(path));
      if (normalized != path) {
        throw DataforgeCheckException(
          'Orphan source precondition path is not normalized and absolute: '
          '$path.',
        );
      }
      final type = await FileSystemEntity.type(path, followLinks: false);
      if (type != FileSystemEntityType.notFound) {
        throw DataforgeCheckException(
          'A source file reappeared before its generated orphan could be '
          'deleted: $path. The generated output was preserved.',
        );
      }
    }
  } on DataforgeCheckException {
    rethrow;
  } on FileSystemException catch (error) {
    throw DataforgeCheckException(
      'Could not revalidate generation inputs before commit: $error.',
      cause: error,
    );
  }
}

String _generatedSha256(List<int> bytes) => sha256.convert(bytes).toString();

Future<String> _readFileHash(String path) async {
  try {
    return _generatedSha256(await File(path).readAsBytes());
  } on FileSystemException catch (error) {
    throw DataforgeCheckException(
      'Generation transaction file can no longer be read: $path.',
      cause: error,
    );
  }
}

Future<void> _ensureFileHash(
  String path,
  String expectedHash, {
  required String context,
}) async {
  try {
    final actualHash = _generatedSha256(await File(path).readAsBytes());
    if (actualHash != expectedHash) {
      throw DataforgeCheckException(
        'Generation transaction file changed $context: $path '
        '(expected $expectedHash, found $actualHash).',
      );
    }
  } on DataforgeCheckException {
    rethrow;
  } on FileSystemException catch (error) {
    throw DataforgeCheckException(
      'Generation transaction file could not be read $context: $path.',
      cause: error,
    );
  }
}

void _validateHash(String value) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw const FormatException(
      'generation journal hashes must be lowercase SHA-256 digests',
    );
  }
}

bool _isPreparedRecoveryState(
  _JournalEntry entry, {
  required String? targetHash,
  required String? temporaryHash,
  required String? backupHash,
}) {
  final temporaryIsPrepared = entry.deleteTarget
      ? temporaryHash == null
      : temporaryHash == entry.replacementHash;
  if (!temporaryIsPrepared) return false;
  if (entry.originalHash == null) {
    return !entry.deleteTarget && targetHash == null && backupHash == null;
  }
  final beforeBackup = targetHash == entry.originalHash && backupHash == null;
  final backupRenameOneStepAhead =
      targetHash == null && backupHash == entry.originalHash;
  return beforeBackup || backupRenameOneStepAhead;
}

bool _isBackedUpRecoveryState(
  _JournalEntry entry, {
  required String? targetHash,
  required String? temporaryHash,
  required String? backupHash,
}) {
  final backupMatches = entry.originalHash == null
      ? backupHash == null
      : backupHash == entry.originalHash;
  if (!backupMatches) return false;
  if (entry.deleteTarget) {
    return targetHash == null && temporaryHash == null;
  }
  final waitingToInstall =
      targetHash == null && temporaryHash == entry.replacementHash;
  final installOneStepAhead =
      targetHash == entry.replacementHash && temporaryHash == null;
  return waitingToInstall || installOneStepAhead;
}

bool _isInstalledRecoveryState(
  _JournalEntry entry, {
  required String? targetHash,
  required String? temporaryHash,
  required String? backupHash,
}) {
  final backupMatches = entry.originalHash == null
      ? backupHash == null
      : backupHash == entry.originalHash;
  if (!backupMatches || temporaryHash != null) return false;
  return entry.deleteTarget
      ? targetHash == null
      : targetHash == entry.replacementHash;
}

final class _SafeRoot {
  const _SafeRoot(this.path, this.realPath);

  final String path;
  final String realPath;
}

Future<_SafeRoot> _safeRoot(String projectRoot) async {
  final root = p.normalize(p.absolute(projectRoot));
  final type = await FileSystemEntity.type(root, followLinks: false);
  if (type != FileSystemEntityType.directory) {
    throw DataforgeIoException(
      'Dataforge project root must be an existing regular directory: $root',
    );
  }
  final real = p.normalize(await Directory(root).resolveSymbolicLinks());
  return _SafeRoot(root, real);
}

String _absoluteFromRoot(String root, String path) =>
    p.normalize(p.absolute(p.isAbsolute(path) ? path : p.join(root, path)));

bool _isNormalizedAbsolute(String path) =>
    p.isAbsolute(path) && p.normalize(path) == path;

Future<void> _ensureSafeDirectory(_SafeRoot root, String directoryPath) async {
  final directory = p.normalize(p.absolute(directoryPath));
  _requireLexicallyWithin(root.path, directory, allowRoot: true);
  final relative = p.relative(directory, from: root.path);
  var current = root.path;
  if (relative == '.') return;

  for (final component in p.split(relative)) {
    current = p.join(current, component);
    var type = await FileSystemEntity.type(current, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      await Directory(current).create();
      type = await FileSystemEntity.type(current, followLinks: false);
    }
    if (type == FileSystemEntityType.link) {
      throw const FormatException(
        'generation transaction directory must not be a symbolic link',
      );
    }
    if (type != FileSystemEntityType.directory) {
      throw const FormatException(
        'generation transaction parent must be a directory',
      );
    }
    await _requireRealDirectoryWithin(root, current);
  }
}

Future<void> _validateDirectoryChain(
  _SafeRoot root,
  String directoryPath, {
  required bool requireExisting,
}) async {
  final directory = p.normalize(p.absolute(directoryPath));
  _requireLexicallyWithin(root.path, directory, allowRoot: true);
  final relative = p.relative(directory, from: root.path);
  var current = root.path;
  if (relative == '.') return;

  for (final component in p.split(relative)) {
    current = p.join(current, component);
    final type = await FileSystemEntity.type(current, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      if (requireExisting) {
        throw const FormatException(
          'generation transaction parent directory does not exist',
        );
      }
      return;
    }
    if (type == FileSystemEntityType.link) {
      throw const FormatException(
        'generation transaction directory must not be a symbolic link',
      );
    }
    if (type != FileSystemEntityType.directory) {
      throw const FormatException(
        'generation transaction parent must be a directory',
      );
    }
    await _requireRealDirectoryWithin(root, current);
  }
}

Future<void> _requireRealDirectoryWithin(
  _SafeRoot root,
  String directory,
) async {
  final real = p.normalize(await Directory(directory).resolveSymbolicLinks());
  if (!p.equals(root.realPath, real) && !p.isWithin(root.realPath, real)) {
    throw const FormatException(
      'generation transaction path resolves outside the project root',
    );
  }
}

void _requireLexicallyWithin(
  String root,
  String path, {
  bool allowRoot = false,
}) {
  if ((!allowRoot || !p.equals(root, path)) && !p.isWithin(root, path)) {
    throw const FormatException(
      'generation transaction path must stay inside the project root',
    );
  }
}

Future<void> _validateTargetPath(
  _SafeRoot root,
  String targetPath, {
  required bool requireParent,
}) async {
  final target = p.normalize(p.absolute(targetPath));
  if (!_isNormalizedAbsolute(targetPath) || !target.endsWith('.data.dart')) {
    throw const FormatException(
      'generation target must be a normalized absolute .data.dart path',
    );
  }
  _requireLexicallyWithin(root.path, target);
  await _validateDirectoryChain(
    root,
    p.dirname(target),
    requireExisting: requireParent,
  );
  final type = await FileSystemEntity.type(target, followLinks: false);
  if (type == FileSystemEntityType.link ||
      (type != FileSystemEntityType.file &&
          type != FileSystemEntityType.notFound)) {
    throw const FormatException(
      'generation target must be a regular file or not exist',
    );
  }
}

Future<void> _validateAuxiliaryPath(
  _SafeRoot root,
  String path, {
  bool requireNotFound = false,
}) async {
  final normalized = p.normalize(p.absolute(path));
  if (!_isNormalizedAbsolute(path)) {
    throw const FormatException(
      'generation transaction file path must be normalized and absolute',
    );
  }
  _requireLexicallyWithin(root.path, normalized);
  await _validateDirectoryChain(
    root,
    p.dirname(normalized),
    requireExisting: true,
  );
  final type = await FileSystemEntity.type(normalized, followLinks: false);
  if (type == FileSystemEntityType.link ||
      (type != FileSystemEntityType.file &&
          type != FileSystemEntityType.notFound)) {
    throw const FormatException(
      'generation transaction file must be regular or not exist',
    );
  }
  if (requireNotFound && type != FileSystemEntityType.notFound) {
    throw const FormatException('generation transaction file already exists');
  }
}

Future<void> _validateControlFile(
  _SafeRoot root,
  String path, {
  bool allowMissing = false,
  bool requireNotFound = false,
}) async {
  final normalized = p.normalize(p.absolute(path));
  if (!_isNormalizedAbsolute(path)) {
    throw const FormatException(
      'generation control file path must be normalized and absolute',
    );
  }
  _requireLexicallyWithin(root.path, normalized);
  await _validateDirectoryChain(
    root,
    p.dirname(normalized),
    requireExisting: true,
  );
  final type = await FileSystemEntity.type(normalized, followLinks: false);
  if (type == FileSystemEntityType.link ||
      (type != FileSystemEntityType.file &&
          (type != FileSystemEntityType.notFound || !allowMissing))) {
    throw const FormatException(
      'generation journal and lock must be regular files',
    );
  }
  if (requireNotFound && type != FileSystemEntityType.notFound) {
    throw const FormatException('generation control file already exists');
  }
}

Future<void> _renameRegularFile(
  _SafeRoot root, {
  required String from,
  required String to,
}) async {
  final fromIsTarget = from.endsWith('.data.dart');
  if (fromIsTarget) {
    await _validateTargetPath(root, from, requireParent: true);
  } else {
    await _validateAuxiliaryPath(root, from);
  }
  final sourceType = await FileSystemEntity.type(from, followLinks: false);
  if (sourceType != FileSystemEntityType.file) {
    throw const FormatException('generation rename source must be a file');
  }

  final toIsTarget = to.endsWith('.data.dart');
  if (toIsTarget) {
    await _validateTargetPath(root, to, requireParent: true);
  } else {
    await _validateAuxiliaryPath(root, to, requireNotFound: true);
  }
  final destinationType = await FileSystemEntity.type(to, followLinks: false);
  if (destinationType != FileSystemEntityType.notFound) {
    throw const FormatException(
      'generation rename destination must not already exist',
    );
  }
  await File(from).rename(to);
}

Future<void> _deleteRegularFile(
  _SafeRoot root,
  String path, {
  bool requireExisting = false,
}) async {
  if (path.endsWith('.data.dart')) {
    await _validateTargetPath(root, path, requireParent: true);
  } else if (p.basename(path).startsWith('generate-') ||
      p.basename(path).startsWith('generate.')) {
    await _validateControlFile(root, path, allowMissing: !requireExisting);
  } else {
    await _validateAuxiliaryPath(root, path);
  }
  final type = await FileSystemEntity.type(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    if (requireExisting) {
      throw const FormatException('generation file unexpectedly disappeared');
    }
    return;
  }
  if (type != FileSystemEntityType.file) {
    throw const FormatException('generation delete target must be a file');
  }
  await File(path).delete();
}

String _newTransactionId() {
  final random = Random.secure();
  final token = List<int>.generate(
    4,
    (_) => random.nextInt(1 << 32),
  ).map((value) => value.toRadixString(16).padLeft(8, '0')).join();
  return '${DateTime.now().microsecondsSinceEpoch}_${pid}_$token';
}

enum _JournalState {
  prepared,
  backedUp,
  installed;

  static _JournalState parse(String value) {
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
    throw const FormatException('invalid generation journal entry state');
  }
}

final class _JournalEntry {
  const _JournalEntry({
    required this.targetPath,
    required this.temporaryPath,
    required this.backupPath,
    required this.originalHash,
    required this.replacementHash,
    required this.deleteTarget,
    required this.state,
  });

  factory _JournalEntry.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('invalid journal entry');
    final targetPath = value['targetPath'];
    final temporaryPath = value['temporaryPath'];
    final backupPath = value['backupPath'];
    final originalHash = value['originalHash'];
    final replacementHash = value['replacementHash'];
    final deleteTarget = value['deleteTarget'];
    final rawState = value['state'];
    if (targetPath is! String ||
        temporaryPath is! String ||
        backupPath is! String ||
        (originalHash != null && originalHash is! String) ||
        (replacementHash != null && replacementHash is! String) ||
        deleteTarget is! bool ||
        rawState is! String) {
      throw const FormatException('invalid journal entry fields');
    }
    return _JournalEntry(
      targetPath: targetPath,
      temporaryPath: temporaryPath,
      backupPath: backupPath,
      originalHash: originalHash as String?,
      replacementHash: replacementHash as String?,
      deleteTarget: deleteTarget,
      state: _JournalState.parse(rawState),
    );
  }

  final String targetPath;
  final String temporaryPath;
  final String backupPath;
  final String? originalHash;
  final String? replacementHash;
  final bool deleteTarget;
  final _JournalState state;

  _JournalEntry withState(_JournalState nextState) => _JournalEntry(
    targetPath: targetPath,
    temporaryPath: temporaryPath,
    backupPath: backupPath,
    originalHash: originalHash,
    replacementHash: replacementHash,
    deleteTarget: deleteTarget,
    state: nextState,
  );

  Map<String, Object?> toJson() => {
    'targetPath': targetPath,
    'temporaryPath': temporaryPath,
    'backupPath': backupPath,
    'originalHash': originalHash,
    'replacementHash': replacementHash,
    'deleteTarget': deleteTarget,
    'state': state.name,
  };
}

bool bytesEqual(List<int> left, List<int> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  if (left is Uint8List && right is Uint8List) {
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
