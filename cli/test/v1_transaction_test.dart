import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dataforge_cli/src/exceptions.dart';
import 'package:dataforge_cli/src/v1_transaction.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('dataforge_transaction_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('uses platform-native normalized generation control paths', () {
    expect(
      GeneratedFileTransaction.journalRelativePath,
      p.join('.dart_tool', 'dataforge', 'generate-journal.json'),
    );
    expect(
      GeneratedFileTransaction.lockRelativePath,
      p.join('.dart_tool', 'dataforge', 'generate.lock'),
    );
  });

  test('takes an immutable defensive copy of pending bytes', () {
    final source = <int>[1, 2, 3];
    final write = PendingGeneratedFile(
      path: p.join(root.path, 'lib', 'model.data.dart'),
      bytes: source,
    );
    final deletion = PendingGeneratedFile.delete(
      path: p.join(root.path, 'lib', 'stale.data.dart'),
      expectedBytes: source,
    );

    source[0] = 9;

    expect(write.bytes, [1, 2, 3]);
    expect(deletion.bytes, [1, 2, 3]);
    expect(() => write.bytes[0] = 9, throwsUnsupportedError);
    expect(() => deletion.bytes.add(4), throwsUnsupportedError);
  });

  test('commits multiple files and removes the journal', () async {
    final first = p.join(root.path, 'lib', 'a.data.dart');
    final second = p.join(root.path, 'lib', 'b.data.dart');

    await const GeneratedFileTransaction().commit(
      projectRoot: root.path,
      files: [
        PendingGeneratedFile.text(path: first, content: 'new a'),
        PendingGeneratedFile.text(path: second, content: 'new b'),
      ],
    );

    expect(await File(first).readAsString(), 'new a');
    expect(await File(second).readAsString(), 'new b');
    expect(
      File(
        p.join(root.path, GeneratedFileTransaction.journalRelativePath),
      ).existsSync(),
      isFalse,
    );
  });

  test('rolls back an earlier replacement when a later rename fails', () async {
    final first = File(p.join(root.path, 'lib', 'a.data.dart'));
    await first.parent.create(recursive: true);
    await first.writeAsString('old a');
    final invalidTarget = Directory(p.join(root.path, 'lib', 'z.data.dart'));
    await invalidTarget.create();

    await expectLater(
      const GeneratedFileTransaction().commit(
        projectRoot: root.path,
        files: [
          PendingGeneratedFile.text(path: first.path, content: 'new a'),
          PendingGeneratedFile.text(
            path: invalidTarget.path,
            content: 'cannot replace a directory',
          ),
        ],
      ),
      throwsA(isA<DataforgeIoException>()),
    );

    expect(await first.readAsString(), 'old a');
    expect(invalidTarget.existsSync(), isTrue);
  });

  test('commits deletion of an owned stale output', () async {
    final stale = File(p.join(root.path, 'lib', 'stale.data.dart'));
    await stale.parent.create(recursive: true);
    final oldBytes = utf8.encode('old generated output');
    await stale.writeAsBytes(oldBytes);

    await const GeneratedFileTransaction().commit(
      projectRoot: root.path,
      files: [
        PendingGeneratedFile.delete(path: stale.path, expectedBytes: oldBytes),
      ],
    );

    expect(stale.existsSync(), isFalse);
    expect(
      stale.parent.listSync().where((entry) => entry.path.endsWith('.bak')),
      isEmpty,
    );
  });

  test('does not delete a stale output whose bytes changed', () async {
    final stale = File(p.join(root.path, 'lib', 'a.data.dart'));
    final sibling = File(p.join(root.path, 'lib', 'b.data.dart'));
    await stale.parent.create(recursive: true);
    final expected = utf8.encode('owned output');
    await stale.writeAsString('changed by user');
    await sibling.writeAsString('old sibling');

    await expectLater(
      const GeneratedFileTransaction().commit(
        projectRoot: root.path,
        files: [
          PendingGeneratedFile.delete(
            path: stale.path,
            expectedBytes: expected,
          ),
          PendingGeneratedFile.text(path: sibling.path, content: 'new sibling'),
        ],
      ),
      throwsA(isA<DataforgeCheckException>()),
    );

    expect(await stale.readAsString(), 'changed by user');
    expect(await sibling.readAsString(), 'old sibling');
  });

  test('rolls back a deletion when a later installation fails', () async {
    final stale = File(p.join(root.path, 'lib', 'a.data.dart'));
    final sibling = File(p.join(root.path, 'lib', 'b.data.dart'));
    await stale.parent.create(recursive: true);
    final staleBytes = utf8.encode('old stale output');
    await stale.writeAsBytes(staleBytes);
    await sibling.writeAsString('old sibling');
    final transaction = GeneratedFileTransaction(
      beforeInstallForTesting: (index) {
        if (index == 1) throw StateError('injected installation failure');
      },
    );

    await expectLater(
      transaction.commit(
        projectRoot: root.path,
        files: [
          PendingGeneratedFile.delete(
            path: stale.path,
            expectedBytes: staleBytes,
          ),
          PendingGeneratedFile.text(path: sibling.path, content: 'new sibling'),
        ],
      ),
      throwsA(isA<DataforgeIoException>()),
    );

    expect(await stale.readAsString(), 'old stale output');
    expect(await sibling.readAsString(), 'old sibling');
    expect(
      File(
        p.join(root.path, GeneratedFileTransaction.journalRelativePath),
      ).existsSync(),
      isFalse,
    );
  });

  test('源码在事务锁内变化时回滚且不提交过期输出', () async {
    final source = File(p.join(root.path, 'lib', 'model.dart'));
    final target = File(p.join(root.path, 'lib', 'model.data.dart'));
    await source.parent.create(recursive: true);
    final sourceBytes = utf8.encode('old source');
    await source.writeAsBytes(sourceBytes);
    await target.writeAsString('old output');
    final transaction = GeneratedFileTransaction(
      beforeInstallForTesting: (_) => source.writeAsString('new source'),
    );

    await expectLater(
      transaction.commit(
        projectRoot: root.path,
        files: [
          PendingGeneratedFile.text(
            path: target.path,
            content: 'new output from old source',
          ),
        ],
        requiredInputs: {source.path: sourceBytes},
      ),
      throwsA(isA<DataforgeCheckException>()),
    );

    expect(await source.readAsString(), 'new source');
    expect(await target.readAsString(), 'old output');
    expect(
      File(
        p.join(root.path, GeneratedFileTransaction.journalRelativePath),
      ).existsSync(),
      isFalse,
    );
  });

  test('orphan 源码在事务锁内恢复时保留生成输出', () async {
    final source = File(p.join(root.path, 'lib', 'stale.dart'));
    final target = File(p.join(root.path, 'lib', 'stale.data.dart'));
    await target.parent.create(recursive: true);
    final targetBytes = utf8.encode('owned generated output');
    await target.writeAsBytes(targetBytes);
    final transaction = GeneratedFileTransaction(
      beforeInstallForTesting: (_) => source.writeAsString('restored source'),
    );

    await expectLater(
      transaction.commit(
        projectRoot: root.path,
        files: [
          PendingGeneratedFile.delete(
            path: target.path,
            expectedBytes: targetBytes,
            requiredAbsentPath: source.path,
          ),
        ],
      ),
      throwsA(isA<DataforgeCheckException>()),
    );

    expect(await source.readAsString(), 'restored source');
    expect(await target.readAsBytes(), targetBytes);
  });

  test('recovers an interrupted installation by restoring backups', () async {
    final target = File(p.join(root.path, 'lib', 'model.data.dart'));
    await target.parent.create(recursive: true);
    await target.writeAsString('new');
    final backup = File(
      p.join(target.parent.path, '.model.data.dart.dataforge.test.0.bak'),
    );
    await backup.writeAsString('old');
    final temporary = File(
      p.join(target.parent.path, '.model.data.dart.dataforge.test.0.tmp'),
    );
    final journal = File(
      p.join(root.path, GeneratedFileTransaction.journalRelativePath),
    );
    await _writeV2Journal(
      journal,
      targetPath: target.path,
      temporaryPath: temporary.path,
      backupPath: backup.path,
      originalHash: _hashText('old'),
      replacementHash: _hashText('new'),
      deleteTarget: false,
      states: const ['backedUp', 'installed'],
    );

    await const GeneratedFileTransaction().recover(root.path);

    expect(await target.readAsString(), 'old');
    expect(backup.existsSync(), isFalse);
    expect(temporary.existsSync(), isFalse);
    expect(journal.existsSync(), isFalse);
  });

  test('recovers an interrupted stale-output deletion', () async {
    final target = File(p.join(root.path, 'lib', 'stale.data.dart'));
    await target.parent.create(recursive: true);
    final backup = File(
      p.join(target.parent.path, '.stale.data.dart.dataforge.test.0.bak'),
    );
    await backup.writeAsString('old stale output');
    final temporary = File(
      p.join(target.parent.path, '.stale.data.dart.dataforge.test.0.tmp'),
    );
    final journal = File(
      p.join(root.path, GeneratedFileTransaction.journalRelativePath),
    );
    await _writeV2Journal(
      journal,
      targetPath: target.path,
      temporaryPath: temporary.path,
      backupPath: backup.path,
      originalHash: _hashText('old stale output'),
      replacementHash: null,
      deleteTarget: true,
      states: const ['backedUp', 'installed'],
    );

    await const GeneratedFileTransaction().recover(root.path);

    expect(await target.readAsString(), 'old stale output');
    expect(backup.existsSync(), isFalse);
    expect(journal.existsSync(), isFalse);
  });

  test(
    'recovery never deletes a file created after interrupted deletion',
    () async {
      final target = File(p.join(root.path, 'lib', 'stale.data.dart'));
      await target.parent.create(recursive: true);
      await target.writeAsString('new external output');
      final backup = File(
        p.join(target.parent.path, '.stale.data.dart.dataforge.test.0.bak'),
      );
      await backup.writeAsString('old stale output');
      final temporary = File(
        p.join(target.parent.path, '.stale.data.dart.dataforge.test.0.tmp'),
      );
      final journal = File(
        p.join(root.path, GeneratedFileTransaction.journalRelativePath),
      );
      await _writeV2Journal(
        journal,
        targetPath: target.path,
        temporaryPath: temporary.path,
        backupPath: backup.path,
        originalHash: _hashText('old stale output'),
        replacementHash: null,
        deleteTarget: true,
        states: const ['backedUp', 'installed'],
      );

      await expectLater(
        const GeneratedFileTransaction().recover(root.path),
        throwsA(isA<DataforgeCheckException>()),
      );

      expect(await target.readAsString(), 'new external output');
      expect(await backup.readAsString(), 'old stale output');
      expect(journal.existsSync(), isTrue);
    },
  );

  test(
    'recovery preserves a newly installed target modified after a crash',
    () async {
      final target = File(p.join(root.path, 'lib', 'new.data.dart'));
      await target.parent.create(recursive: true);
      await target.writeAsString('user rewrite after crash');
      final temporary = File(
        p.join(target.parent.path, '.new.data.dart.dataforge.test.0.tmp'),
      );
      final backup = File(
        p.join(target.parent.path, '.new.data.dart.dataforge.test.0.bak'),
      );
      final journal = File(
        p.join(root.path, GeneratedFileTransaction.journalRelativePath),
      );
      await _writeV2Journal(
        journal,
        targetPath: target.path,
        temporaryPath: temporary.path,
        backupPath: backup.path,
        originalHash: null,
        replacementHash: _hashText('generated output'),
        deleteTarget: false,
        states: const ['backedUp', 'installed'],
      );

      await expectLater(
        const GeneratedFileTransaction().recover(root.path),
        throwsA(isA<DataforgeCheckException>()),
      );

      expect(await target.readAsString(), 'user rewrite after crash');
      expect(journal.existsSync(), isTrue);
      expect(temporary.existsSync(), isFalse);
      expect(backup.existsSync(), isFalse);
    },
  );

  test(
    'recovery preserves an overwritten target modified after a crash',
    () async {
      final target = File(p.join(root.path, 'lib', 'existing.data.dart'));
      await target.parent.create(recursive: true);
      await target.writeAsString('user rewrite after crash');
      final temporary = File(
        p.join(target.parent.path, '.existing.data.dart.dataforge.test.0.tmp'),
      );
      final backup = File(
        p.join(target.parent.path, '.existing.data.dart.dataforge.test.0.bak'),
      );
      await backup.writeAsString('old generated output');
      final journal = File(
        p.join(root.path, GeneratedFileTransaction.journalRelativePath),
      );
      await _writeV2Journal(
        journal,
        targetPath: target.path,
        temporaryPath: temporary.path,
        backupPath: backup.path,
        originalHash: _hashText('old generated output'),
        replacementHash: _hashText('new generated output'),
        deleteTarget: false,
        states: const ['backedUp', 'installed'],
      );

      await expectLater(
        const GeneratedFileTransaction().recover(root.path),
        throwsA(isA<DataforgeCheckException>()),
      );

      expect(await target.readAsString(), 'user rewrite after crash');
      expect(await backup.readAsString(), 'old generated output');
      expect(temporary.existsSync(), isFalse);
      expect(journal.existsSync(), isTrue);
    },
  );

  test('recovery removes only an exact newly installed replacement', () async {
    final target = File(p.join(root.path, 'lib', 'created.data.dart'));
    await target.parent.create(recursive: true);
    await target.writeAsString('generated output');
    final temporary = File(
      p.join(target.parent.path, '.created.data.dart.dataforge.test.0.tmp'),
    );
    final backup = File(
      p.join(target.parent.path, '.created.data.dart.dataforge.test.0.bak'),
    );
    final journal = File(
      p.join(root.path, GeneratedFileTransaction.journalRelativePath),
    );
    await _writeV2Journal(
      journal,
      targetPath: target.path,
      temporaryPath: temporary.path,
      backupPath: backup.path,
      originalHash: null,
      replacementHash: _hashText('generated output'),
      deleteTarget: false,
      states: const ['backedUp', 'installed'],
    );

    await const GeneratedFileTransaction().recover(root.path);

    expect(target.existsSync(), isFalse);
    expect(temporary.existsSync(), isFalse);
    expect(backup.existsSync(), isFalse);
    expect(journal.existsSync(), isFalse);
  });

  test('recovers when the final installed state append was torn', () async {
    final target = File(p.join(root.path, 'lib', 'torn.data.dart'));
    await target.parent.create(recursive: true);
    await target.writeAsString('new generated output');
    final temporary = File(
      p.join(target.parent.path, '.torn.data.dart.dataforge.test.0.tmp'),
    );
    final backup = File(
      p.join(target.parent.path, '.torn.data.dart.dataforge.test.0.bak'),
    );
    await backup.writeAsString('old generated output');
    final journal = File(
      p.join(root.path, GeneratedFileTransaction.journalRelativePath),
    );
    await _writeV2Journal(
      journal,
      targetPath: target.path,
      temporaryPath: temporary.path,
      backupPath: backup.path,
      originalHash: _hashText('old generated output'),
      replacementHash: _hashText('new generated output'),
      deleteTarget: false,
      states: const ['backedUp'],
    );
    await journal.writeAsString(
      jsonEncode({'entry': 0, 'state': 'installed'}),
      mode: FileMode.append,
    );

    await const GeneratedFileTransaction().recover(root.path);

    expect(await target.readAsString(), 'old generated output');
    expect(temporary.existsSync(), isFalse);
    expect(backup.existsSync(), isFalse);
    expect(journal.existsSync(), isFalse);
  });

  test(
    'recovers when backup rename happened before its state append',
    () async {
      final target = File(p.join(root.path, 'lib', 'backup_window.data.dart'));
      await target.parent.create(recursive: true);
      final temporary = File(
        p.join(
          target.parent.path,
          '.backup_window.data.dart.dataforge.test.0.tmp',
        ),
      );
      await temporary.writeAsString('new generated output');
      final backup = File(
        p.join(
          target.parent.path,
          '.backup_window.data.dart.dataforge.test.0.bak',
        ),
      );
      await backup.writeAsString('old generated output');
      final journal = File(
        p.join(root.path, GeneratedFileTransaction.journalRelativePath),
      );
      await _writeV2Journal(
        journal,
        targetPath: target.path,
        temporaryPath: temporary.path,
        backupPath: backup.path,
        originalHash: _hashText('old generated output'),
        replacementHash: _hashText('new generated output'),
        deleteTarget: false,
      );

      await const GeneratedFileTransaction().recover(root.path);

      expect(await target.readAsString(), 'old generated output');
      expect(temporary.existsSync(), isFalse);
      expect(backup.existsSync(), isFalse);
      expect(journal.existsSync(), isFalse);
    },
  );

  test('never trusts an obsolete journal to delete a new target', () async {
    final target = File(p.join(root.path, 'lib', 'victim.data.dart'));
    await target.parent.create(recursive: true);
    await target.writeAsString('user-owned content');
    final temporary = File(
      p.join(target.parent.path, '.victim.data.dart.dataforge.test.0.tmp'),
    );
    final backup = File(
      p.join(target.parent.path, '.victim.data.dart.dataforge.test.0.bak'),
    );
    final journal = File(
      p.join(root.path, GeneratedFileTransaction.journalRelativePath),
    );
    await journal.parent.create(recursive: true);
    await journal.writeAsString(
      jsonEncode({
        'version': 1,
        'entries': [
          {
            'targetPath': target.path,
            'temporaryPath': temporary.path,
            'backupPath': backup.path,
            'originalExisted': false,
          },
        ],
      }),
    );

    await expectLater(
      const GeneratedFileTransaction().recover(root.path),
      throwsA(isA<DataforgeIoException>()),
    );

    expect(await target.readAsString(), 'user-owned content');
    expect(journal.existsSync(), isTrue);
  });

  test(
    'prepared v2 state cannot claim and delete an existing target',
    () async {
      final target = File(p.join(root.path, 'lib', 'claimed.data.dart'));
      await target.parent.create(recursive: true);
      await target.writeAsString('claimed bytes');
      final temporary = File(
        p.join(target.parent.path, '.claimed.data.dart.dataforge.test.0.tmp'),
      );
      final backup = File(
        p.join(target.parent.path, '.claimed.data.dart.dataforge.test.0.bak'),
      );
      final journal = File(
        p.join(root.path, GeneratedFileTransaction.journalRelativePath),
      );
      await _writeV2Journal(
        journal,
        targetPath: target.path,
        temporaryPath: temporary.path,
        backupPath: backup.path,
        originalHash: null,
        replacementHash: _hashText('claimed bytes'),
        deleteTarget: false,
      );

      await expectLater(
        const GeneratedFileTransaction().recover(root.path),
        throwsA(isA<DataforgeCheckException>()),
      );

      expect(await target.readAsString(), 'claimed bytes');
      expect(journal.existsSync(), isTrue);
    },
  );

  for (final transition in <String, List<String>>{
    'jumped': const ['installed'],
    'repeated': const ['backedUp', 'backedUp'],
    'reversed': const ['backedUp', 'prepared'],
  }.entries) {
    test(
      'rejects a ${transition.key} journal state transition without writes',
      () async {
        final target = File(
          p.join(root.path, 'lib', '${transition.key}.data.dart'),
        );
        await target.parent.create(recursive: true);
        await target.writeAsString('new generated output');
        final temporary = File(
          p.join(
            target.parent.path,
            '.${transition.key}.data.dart.dataforge.test.0.tmp',
          ),
        );
        final backup = File(
          p.join(
            target.parent.path,
            '.${transition.key}.data.dart.dataforge.test.0.bak',
          ),
        );
        await backup.writeAsString('old generated output');
        final journal = File(
          p.join(root.path, GeneratedFileTransaction.journalRelativePath),
        );
        await _writeV2Journal(
          journal,
          targetPath: target.path,
          temporaryPath: temporary.path,
          backupPath: backup.path,
          originalHash: _hashText('old generated output'),
          replacementHash: _hashText('new generated output'),
          deleteTarget: false,
          states: transition.value,
        );

        await expectLater(
          const GeneratedFileTransaction().recover(root.path),
          throwsA(isA<DataforgeIoException>()),
        );

        expect(await target.readAsString(), 'new generated output');
        expect(await backup.readAsString(), 'old generated output');
        expect(temporary.existsSync(), isFalse);
        expect(journal.existsSync(), isTrue);
      },
    );
  }

  test('validates every journal entry before rolling back any file', () async {
    final first = File(p.join(root.path, 'lib', 'first.data.dart'));
    final second = File(p.join(root.path, 'lib', 'second.data.dart'));
    await first.parent.create(recursive: true);
    await first.writeAsString('new first');
    await second.writeAsString('new second');
    final firstTemporary = File(
      p.join(first.parent.path, '.first.data.dart.dataforge.test.0.tmp'),
    );
    final firstBackup = File(
      p.join(first.parent.path, '.first.data.dart.dataforge.test.0.bak'),
    );
    final secondTemporary = File(
      p.join(second.parent.path, '.second.data.dart.dataforge.test.1.tmp'),
    );
    final secondBackup = File(
      p.join(second.parent.path, '.second.data.dart.dataforge.test.1.bak'),
    );
    await firstBackup.writeAsString('old first');
    await secondBackup.writeAsString('tampered second backup');
    final journal = File(
      p.join(root.path, GeneratedFileTransaction.journalRelativePath),
    );
    await journal.parent.create(recursive: true);
    await journal.writeAsString(
      '${[
        jsonEncode({
          'version': 2,
          'entries': [_v2Entry(targetPath: first.path, temporaryPath: firstTemporary.path, backupPath: firstBackup.path, originalHash: _hashText('old first'), replacementHash: _hashText('new first'), deleteTarget: false), _v2Entry(targetPath: second.path, temporaryPath: secondTemporary.path, backupPath: secondBackup.path, originalHash: _hashText('old second'), replacementHash: _hashText('new second'), deleteTarget: false)],
        }),
        jsonEncode({'entry': 0, 'state': 'backedUp'}),
        jsonEncode({'entry': 0, 'state': 'installed'}),
        jsonEncode({'entry': 1, 'state': 'backedUp'}),
        jsonEncode({'entry': 1, 'state': 'installed'}),
      ].join('\n')}\n',
    );

    await expectLater(
      const GeneratedFileTransaction().recover(root.path),
      throwsA(isA<DataforgeCheckException>()),
    );

    expect(await first.readAsString(), 'new first');
    expect(await firstBackup.readAsString(), 'old first');
    expect(await second.readAsString(), 'new second');
    expect(await secondBackup.readAsString(), 'tampered second backup');
    expect(journal.existsSync(), isTrue);
  });

  for (final schema
      in <
        ({
          String name,
          String? originalHash,
          String? replacementHash,
          bool deleteTarget,
        })
      >[
        (
          name: 'deletion without an original hash',
          originalHash: null,
          replacementHash: null,
          deleteTarget: true,
        ),
        (
          name: 'deletion with a replacement hash',
          originalHash: _hashText('old generated output'),
          replacementHash: _hashText('new generated output'),
          deleteTarget: true,
        ),
        (
          name: 'write without a replacement hash',
          originalHash: _hashText('old generated output'),
          replacementHash: null,
          deleteTarget: false,
        ),
      ]) {
    test('rejects ${schema.name} without touching the target', () async {
      final target = File(p.join(root.path, 'lib', 'schema.data.dart'));
      await target.parent.create(recursive: true);
      await target.writeAsString('old generated output');
      final temporary = File(
        p.join(target.parent.path, '.schema.data.dart.dataforge.test.0.tmp'),
      );
      final backup = File(
        p.join(target.parent.path, '.schema.data.dart.dataforge.test.0.bak'),
      );
      final journal = File(
        p.join(root.path, GeneratedFileTransaction.journalRelativePath),
      );
      await _writeV2Journal(
        journal,
        targetPath: target.path,
        temporaryPath: temporary.path,
        backupPath: backup.path,
        originalHash: schema.originalHash,
        replacementHash: schema.replacementHash,
        deleteTarget: schema.deleteTarget,
      );

      await expectLater(
        const GeneratedFileTransaction().recover(root.path),
        throwsA(isA<DataforgeIoException>()),
      );

      expect(await target.readAsString(), 'old generated output');
      expect(temporary.existsSync(), isFalse);
      expect(backup.existsSync(), isFalse);
      expect(journal.existsSync(), isTrue);
    });
  }

  test(
    'serializes concurrent multi-file commits without mixed output',
    () async {
      final first = p.join(root.path, 'lib', 'a.data.dart');
      final second = p.join(root.path, 'lib', 'b.data.dart');

      await Future.wait([
        const GeneratedFileTransaction().commit(
          projectRoot: root.path,
          files: [
            PendingGeneratedFile.text(path: first, content: 'A'),
            PendingGeneratedFile.text(path: second, content: 'A'),
          ],
        ),
        const GeneratedFileTransaction().commit(
          projectRoot: root.path,
          files: [
            PendingGeneratedFile.text(path: first, content: 'B'),
            PendingGeneratedFile.text(path: second, content: 'B'),
          ],
        ),
      ]);

      final firstValue = await File(first).readAsString();
      final secondValue = await File(second).readAsString();
      expect(firstValue, anyOf('A', 'B'));
      expect(secondValue, firstValue);
    },
  );

  test('rejects a journal that targets a path outside the project', () async {
    final outside = File('${root.path}_outside.data.dart');
    await outside.writeAsString('keep');
    addTearDown(() async {
      if (await outside.exists()) await outside.delete();
    });
    final journal = File(
      p.join(root.path, GeneratedFileTransaction.journalRelativePath),
    );
    await _writeV2Journal(
      journal,
      targetPath: outside.path,
      temporaryPath: p.join(
        outside.parent.path,
        '.${p.basename(outside.path)}.dataforge.test.0.tmp',
      ),
      backupPath: p.join(
        outside.parent.path,
        '.${p.basename(outside.path)}.dataforge.test.0.bak',
      ),
      originalHash: _hashText('keep'),
      replacementHash: _hashText('replacement'),
      deleteTarget: false,
    );

    await expectLater(
      const GeneratedFileTransaction().recover(root.path),
      throwsA(isA<DataforgeIoException>()),
    );

    expect(await outside.readAsString(), 'keep');
    expect(journal.existsSync(), isTrue);
  });

  test('rejects a journal that targets a normal source file', () async {
    final target = File(p.join(root.path, 'lib', 'model.dart'));
    await target.parent.create(recursive: true);
    await target.writeAsString('keep');
    final temporary = File(
      p.join(target.parent.path, '.model.dart.dataforge.test.0.tmp'),
    );
    await temporary.writeAsString('malicious');
    final backup = File(
      p.join(target.parent.path, '.model.dart.dataforge.test.0.bak'),
    );
    await backup.writeAsString('also malicious');
    final journal = File(
      p.join(root.path, GeneratedFileTransaction.journalRelativePath),
    );
    await _writeV2Journal(
      journal,
      targetPath: target.path,
      temporaryPath: temporary.path,
      backupPath: backup.path,
      originalHash: _hashText('keep'),
      replacementHash: _hashText('malicious'),
      deleteTarget: false,
    );

    await expectLater(
      const GeneratedFileTransaction().recover(root.path),
      throwsA(isA<DataforgeIoException>()),
    );

    expect(await target.readAsString(), 'keep');
    expect(await temporary.readAsString(), 'malicious');
    expect(await backup.readAsString(), 'also malicious');
    expect(journal.existsSync(), isTrue);
  });

  test('rejects a generated target beneath a symlinked parent', () async {
    if (Platform.isWindows) return;
    final outside = await Directory.systemTemp.createTemp(
      'dataforge_transaction_outside_',
    );
    addTearDown(() async {
      if (await outside.exists()) await outside.delete(recursive: true);
    });
    await Link(p.join(root.path, 'lib')).create(outside.path);
    final escaped = File(p.join(root.path, 'lib', 'escaped.data.dart'));

    await expectLater(
      const GeneratedFileTransaction().commit(
        projectRoot: root.path,
        files: [
          PendingGeneratedFile.text(path: escaped.path, content: 'malicious'),
        ],
      ),
      throwsA(isA<DataforgeIoException>()),
    );

    expect(
      File(p.join(outside.path, 'escaped.data.dart')).existsSync(),
      isFalse,
    );
  });

  test('recovery refuses a journal beneath a symlinked parent', () async {
    if (Platform.isWindows) return;
    final outside = await Directory.systemTemp.createTemp(
      'dataforge_recovery_outside_',
    );
    addTearDown(() async {
      if (await outside.exists()) await outside.delete(recursive: true);
    });
    await Link(p.join(root.path, 'lib')).create(outside.path);
    final target = File(p.join(outside.path, 'model.data.dart'));
    final temporary = File(
      p.join(outside.path, '.model.data.dart.dataforge.test.0.tmp'),
    );
    final backup = File(
      p.join(outside.path, '.model.data.dart.dataforge.test.0.bak'),
    );
    await target.writeAsString('outside target');
    await temporary.writeAsString('outside temporary');
    await backup.writeAsString('outside backup');
    final journal = File(
      p.join(root.path, GeneratedFileTransaction.journalRelativePath),
    );
    await _writeV2Journal(
      journal,
      targetPath: p.join(root.path, 'lib', 'model.data.dart'),
      temporaryPath: p.join(
        root.path,
        'lib',
        '.model.data.dart.dataforge.test.0.tmp',
      ),
      backupPath: p.join(
        root.path,
        'lib',
        '.model.data.dart.dataforge.test.0.bak',
      ),
      originalHash: _hashText('outside target'),
      replacementHash: _hashText('replacement'),
      deleteTarget: false,
    );

    await expectLater(
      const GeneratedFileTransaction().recover(root.path),
      throwsA(isA<DataforgeIoException>()),
    );

    expect(await target.readAsString(), 'outside target');
    expect(await temporary.readAsString(), 'outside temporary');
    expect(await backup.readAsString(), 'outside backup');
    expect(journal.existsSync(), isTrue);
  });

  test('serializes independent processes with the generation lock', () async {
    final first = p.join(root.path, 'lib', 'a.data.dart');
    final second = p.join(root.path, 'lib', 'b.data.dart');
    final worker = File(p.join(root.path, 'generation_worker.dart'));
    await worker.writeAsString(r'''
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dataforge_cli/src/exceptions.dart';
import 'package:dataforge_cli/src/v1_transaction.dart';

Future<void> main(List<String> arguments) async {
  try {
    final transaction = GeneratedFileTransaction(
      beforeInstallForTesting: (index) async {
        if (index == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      },
    );
    await transaction.commit(
      projectRoot: arguments[0],
      files: [
        PendingGeneratedFile.text(
          path: arguments[1],
          content: arguments[3],
        ),
        PendingGeneratedFile.text(
          path: arguments[2],
          content: arguments[3],
        ),
      ],
    );
  } on DataforgeCliException catch (error) {
    stderr.writeln(error);
    exitCode = error.exitCode;
  }
}
''');
    final packageConfig = p.join(
      Directory.current.path,
      '.dart_tool',
      'package_config.json',
    );
    final commonArguments = [
      '--packages=$packageConfig',
      worker.path,
      root.path,
      first,
      second,
    ];

    final processes = await Future.wait([
      Process.start(Platform.resolvedExecutable, [...commonArguments, 'A']),
      Process.start(Platform.resolvedExecutable, [...commonArguments, 'B']),
    ]);
    final errors = <String>[];
    final results = await Future.wait(
      processes.map((process) async {
        await process.stdout.drain<void>();
        errors.add(await utf8.decodeStream(process.stderr));
        return process.exitCode;
      }),
    );

    expect(results, everyElement(0), reason: errors.join('\n'));
    final firstValue = await File(first).readAsString();
    final secondValue = await File(second).readAsString();
    expect(firstValue, anyOf('A', 'B'));
    expect(secondValue, firstValue);
  });
}

String _hashText(String value) => sha256.convert(utf8.encode(value)).toString();

Future<void> _writeV2Journal(
  File journal, {
  required String targetPath,
  required String temporaryPath,
  required String backupPath,
  required String? originalHash,
  required String? replacementHash,
  required bool deleteTarget,
  List<String> states = const [],
}) async {
  await journal.parent.create(recursive: true);
  final lines = <String>[
    jsonEncode({
      'version': 2,
      'entries': [
        _v2Entry(
          targetPath: targetPath,
          temporaryPath: temporaryPath,
          backupPath: backupPath,
          originalHash: originalHash,
          replacementHash: replacementHash,
          deleteTarget: deleteTarget,
        ),
      ],
    }),
    for (final state in states) jsonEncode({'entry': 0, 'state': state}),
  ];
  await journal.writeAsString('${lines.join('\n')}\n');
}

Map<String, Object?> _v2Entry({
  required String targetPath,
  required String temporaryPath,
  required String backupPath,
  required String? originalHash,
  required String? replacementHash,
  required bool deleteTarget,
}) => {
  'targetPath': targetPath,
  'temporaryPath': temporaryPath,
  'backupPath': backupPath,
  'originalHash': originalHash,
  'replacementHash': replacementHash,
  'deleteTarget': deleteTarget,
  'state': 'prepared',
};
