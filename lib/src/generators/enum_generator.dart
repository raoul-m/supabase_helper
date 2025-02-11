import 'dart:io';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import '../utils.dart';

class EnumGenerator {
  static Future<dynamic> generate(
      String outputDir,
      List<Map<String, dynamic>> enums,
      ) async {
    late List<String> enumNames = [];
    final buffer = StringBuffer();
    final enumsDir = Directory(outputDir);
    await enumsDir.create(recursive: true);

    for (final enumData in enums) {
      final enumName = toPascalCase(enumData['enum_name'] as String);
      enumNames.add(enumName);
      final values = (enumData['enum_values'] as String).split(',').map((e) => e.trim()).toList();

      buffer
        ..writeln('enum $enumName {')
        ..writeln(values.map((v) => '  ${toCamelCase(v)},').join('\n'))
        ..writeln('}\n')
        ..writeln('''
extension ${enumName}Ext on $enumName {
  String get name {
    switch (this) {
      ${values.map((v) => 'case $enumName.${toCamelCase(v)}: return \'$v\';').join('\n      ')}
    }
  }

  static $enumName fromString(String value) {
    switch (value) {
      ${values.map((v) => 'case \'$v\': return $enumName.${toCamelCase(v)};').join('\n      ')}
      default: throw ArgumentError('Unknown enum value: \$value');
    }
  }
}''');
      buffer.writeln();
    }

    final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
    final formattedCode = formatter.format(buffer.toString());

    final filePath = path.join(enumsDir.path, 'enums.dart');
    await File(filePath).writeAsString(formattedCode);

    return enumNames;
  }
}