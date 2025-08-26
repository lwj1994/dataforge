import 'dart:io';
import 'package:args/args.dart';

/// 一键格式化脚本
/// 执行 dart fix --apply 和 dart format 来格式化整个工程
void main(List<String> args) async {
  final parser = ArgParser();
  parser.addOption('path',
      abbr: 'p', defaultsTo: '.', help: '指定要格式化的目录路径，默认为当前目录');
  parser.addFlag('help', abbr: 'h', negatable: false, help: '显示帮助信息');

  try {
    final results = parser.parse(args);

    if (results['help'] as bool) {
      print('一键格式化脚本');
      print('用法: dart run tools/format_project.dart [选项]');
      print('');
      print('选项:');
      print(parser.usage);
      print('');
      print('示例:');
      print('  dart run tools/format_project.dart              # 格式化当前目录');
      print('  dart run tools/format_project.dart -p lib       # 格式化lib目录');
      print('  dart run tools/format_project.dart --path test  # 格式化test目录');
      return;
    }

    final path = results['path'] as String;

    print('🚀 开始格式化项目...');
    print('📁 目标路径: $path');
    print('');

    await _formatProject(path);

    print('');
    print('✅ 项目格式化完成！');
  } catch (e) {
    print('❌ 参数解析错误: $e');
    print('使用 --help 查看帮助信息');
    exit(1);
  }
}

/// 格式化项目
Future<void> _formatProject(String path) async {
  // 检查路径是否存在
  final directory = Directory(path);
  if (!await directory.exists()) {
    print('❌ 错误: 路径 "$path" 不存在');
    exit(1);
  }

  // 执行 dart fix --apply
  print('🔧 正在执行 dart fix --apply...');
  await _runCommand('dart', ['fix', '--apply', path]);

  // 执行 dart format
  print('🎨 正在执行 dart format...');
  await _runCommand('dart', ['format', path]);
}

/// 运行命令
Future<void> _runCommand(String command, List<String> arguments) async {
  try {
    final result = await Process.run(command, arguments);

    if (result.exitCode == 0) {
      print('   ✅ $command ${arguments.join(' ')} 执行成功');
      if (result.stdout.toString().trim().isNotEmpty) {
        print('   📝 输出: ${result.stdout.toString().trim()}');
      }
    } else {
      print('   ⚠️  $command ${arguments.join(' ')} 执行完成，但有警告');
      if (result.stderr.toString().trim().isNotEmpty) {
        print('   ⚠️  警告: ${result.stderr.toString().trim()}');
      }
      if (result.stdout.toString().trim().isNotEmpty) {
        print('   📝 输出: ${result.stdout.toString().trim()}');
      }
    }
  } catch (e) {
    print('   ❌ 执行 $command ${arguments.join(' ')} 时出错: $e');
    print('   💡 请确保已安装 Dart SDK 并且 $command 命令可用');
    exit(1);
  }
}
