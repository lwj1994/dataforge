import 'package:args/args.dart';
import 'package:data_class_gen/data_class_gen.dart';

void main(List<String> args) {
  print(args);
  final parser = ArgParser();

  parser.addOption("path", defaultsTo: "");
  final res = parser.parse(args);
  String path = res.option("path") ?? "";
  if (path.isEmpty) {
    // By default, only process lib and test directories, avoid processing project root directory
    print('No path specified. Processing lib/ and test/ directories...');
    generate('lib');
    generate('test');
    return;
  }
  generate(path);
}
