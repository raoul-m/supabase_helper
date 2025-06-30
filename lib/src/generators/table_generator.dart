import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;

import '../columns_mapper.dart';
import '../config/config.dart';
import '../supabase_type_mapper.dart';
import '../utils.dart';

class TableGenerator {
  static bool enumsUsed = false;
  static Future<void> generate(
    String outputDir,
    Map<String, Map<String, List<TableColumn>>> schemas,
    List<String> enumNames,
    GeneratorConfig config,
  ) async {
    final tablesDir = Directory(path.join(outputDir, 'tables'));
    await tablesDir.create(recursive: true);

    for (final schema in schemas.entries) {
      final schemaName = schema.key;
      final tables = schema.value;

      final schemaDir = schemas.length > 1
          ? Directory(path.join(tablesDir.path, schemaName))
          : tablesDir;
      await schemaDir.create(recursive: true);

      for (final table in tables.entries) {
        String? mappedTableName;

        enumsUsed = false;
        final tableName = table.key;

        if (config.tableMappings.isNotEmpty &&
            config.tableMappings.containsKey(tableName)) {
          mappedTableName = config.tableMappings[tableName];
        }

        final className = toPascalCase(mappedTableName ?? tableName);
        final generateIsar =
            (config.generateIsar && config.includedTables.contains(tableName));

        final classBuffer = StringBuffer();
        classBuffer.writeln('class $className {');

        final columns = tables[tableName]!;

        // Generate fields
        for (final column in columns) {
          final colName = column.name;
          final format = column.format;
          final isPrimary = column.isPrimaryKey;
          final isNullable = column.isNullable;

          if (generateIsar && isPrimary) {
            classBuffer.writeln('\n  @Id()');
          }

          final dartType = _toDartType(
            format,
            enumNames,
            nullable: isNullable,
          );
          // print('$format ${isNullable ? "null" : ""}, dartType: $dartType');
          final fieldName = toCamelCase(colName);
          classBuffer.writeln('  final $dartType $fieldName;');
        }

        // Converters
        classBuffer
          ..writeln(
              '\n  static List<$className> converter(List<Map<String, dynamic>> data) {')
          ..writeln('    return data.map($className.fromJson).toList();')
          ..writeln('  }\n')
          ..writeln(
              '  static $className converterSingle(Map<String, dynamic> data) {')
          ..writeln('    return $className.fromJson(data);')
          ..writeln('  }');

        // Constructor
        classBuffer
          ..writeln('\n  $className({')
          ..write(columns
              .map((c) =>
                  '${c.isNullable ? '    ' : '    required '}this.${toCamelCase(c.name)}')
              .join(',\n'))
          ..writeln('\n });');

        // fromJson
        classBuffer
          ..writeln(
              '\n  factory $className.fromJson(Map<String, dynamic> json) => $className(')
          ..write(columns.map((c) {
            final name = c.name;
            final fieldName = toCamelCase(name);
            final format = c.format;
            final isNullable = c.isNullable;

            if (format.startsWith('_') &&
                enumNames.contains(toPascalCase(format))) {
              // Handle List of enum types
              final baseFormat = format.substring(1);
              final enumType = toPascalCase(baseFormat);
              return isNullable
                  ? '    $fieldName: (json[\'$name\'] as List<dynamic>?)?.map((e) => $enumType.values.where((g) => g.name == e).firstOrNull).whereType<$enumType>().toList()'
                  : '    $fieldName: (json[\'$name\'] as List<dynamic>).map((e) => $enumType.values.where((g) => g.name == e).firstOrNull).whereType<$enumType>().toList()';
            } else if (format.startsWith('_')) {
              // Handle List types by mapping over the List<dynamic>
              final baseFormat = format.substring(1);
              final baseDartType = _toDartType(baseFormat, enumNames);

              if (isNullable) {
                return '    $fieldName: (json[\'$name\'] as List<dynamic>?)?.map((e) => e as $baseDartType).toList()';
              } else {
                return '    $fieldName: (json[\'$name\'] as List<dynamic>).map((e) => e as $baseDartType).toList()';
              }
            } else if (format == 'timestamp' ||
                format == 'date' ||
                format == 'timestamptz') {
              // Handle DateTime types
              return '    $fieldName: json[\'$name\'] != null ? DateTime.tryParse(json[\'$name\'].toString()) as DateTime : DateTime.fromMillisecondsSinceEpoch(0)';
            } else if (enumNames.contains(toPascalCase(format))) {
              // Handle enum types
              return isNullable
                  ? '    $fieldName: json[\'$name\'] != null ? ${toPascalCase(format)}.values.where((g) => g.name == json[\'$name\']).firstOrNull : null'
                  : '    $fieldName: ${toPascalCase(format)}.values.firstWhere((g) => g.name == json[\'$name\'])';
            } else if (format == 'json' || format == 'jsonb') {
              return isNullable
                  ? '    $fieldName: json[\'$name\'] is Map<String, dynamic> ? json[\'$name\'] as Map<String, dynamic>? : null'
                  : '    $fieldName: json[\'$name\'] as Map<String, dynamic>';
            } else if (format == 'numeric' ||
                format == 'float4' ||
                format == 'float8') {
              // Special handling for average_rating: int or double
              return isNullable
                  ? '    $fieldName: (json[\'$name\'] is int) ? (json[\'$name\'] as int).toDouble() : json[\'$name\'] as double?'
                  : '    $fieldName: (json[\'$name\'] is int) ? (json[\'$name\'] as int).toDouble() : json[\'$name\'] as double';
            } else {
              // Handle scalar types with a direct cast
              final dartType =
                  _toDartType(format, enumNames, nullable: isNullable);
              return '    $fieldName: json[\'$name\'] as $dartType';
            }
          }).join(',\n'))
          ..writeln(');');

        // toJson
        classBuffer
          ..writeln('\n  Map<String, dynamic> toJson() => {')
          ..write(columns.map((c) {
            final name = c.name;
            final fieldName = toCamelCase(name);
            return '    \'$name\': $fieldName';
          }).join(',\n'))
          ..writeln('\n  };');

        // copyWith
        classBuffer
          ..writeln('\n  $className copyWith({')
          ..write(columns.map((c) {
            final name = c.name;
            final fieldName = toCamelCase(name);
            return '    ${_toDartType(c.format, enumNames)}? $fieldName';
          }).join(',\n'))
          ..writeln('\n  }) {')
          ..writeln('    return $className(')
          ..write(columns.map((c) {
            final name = c.name;
            final fieldName = toCamelCase(name);
            return '      $fieldName: $fieldName ?? this.$fieldName';
          }).join(',\n'))
          ..writeln('    );')
          ..writeln('  }');

        // toString
        classBuffer
          ..writeln('\n  @override')
          ..writeln('  String toString() {')
          ..writeln('    return \'$className(${columns.map((c) {
            final fieldName = toCamelCase(c.name);
            return '$fieldName: \$$fieldName';
          }).join(', ')})\';')
          ..writeln('  }');

        // Ending the class
        classBuffer.writeln('}');

        final importBuffer = StringBuffer();

        if (enumsUsed == true) {
          if (schemaDir == tablesDir) {
            importBuffer.writeln("import '../enums.dart';\n");
          } else {
            importBuffer.writeln("import '../../enums.dart';\n");
          }
        }

        // Add imports
        for (final annotation in config.annotations) {
          importBuffer.writeln("import '${annotation.import}';");
        }

        if (generateIsar) {
          importBuffer.writeln("import 'package:isar/isar.dart';\n");
          importBuffer.writeln("part '${toSnakeCase(className)}.g.dart';\n");
        }

        // Add class annotations
        if (generateIsar) {
          importBuffer.writeln('@Collection()');
        }
        for (final annotation in config.annotations) {
          importBuffer.writeln(annotation.annotations.join('\n'));
        }

        final fileName = '${toSnakeCase(className)}.dart';
        final fileBuffer = StringBuffer();
        fileBuffer.write(importBuffer);
        fileBuffer.write(classBuffer);

        final formatter =
            DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
        final formattedCode = formatter.format(fileBuffer.toString());

        await File(path.join(schemaDir.path, toSnakeCase(fileName)))
            .writeAsString(formattedCode);

        print('  ✅  Successfully generated $className');
      }
    }
  }

  static String _toDartType(String pgType, List<String> enumNames,
      {bool nullable = false}) {
    if (pgType.startsWith('_')) {
      final baseType = pgType.substring(1);
      final dartType = _toDartType(baseType, enumNames);
      return nullable ? 'List<$dartType>?' : 'List<$dartType>';
    }
    final pascalCaseType = toPascalCase(pgType);
    if (enumNames.contains(pascalCaseType)) {
      enumsUsed = true;
      return nullable ? '$pascalCaseType?' : pascalCaseType;
    }
    final dartType = SupabaseTypeMapper.toDartType(pgType, nullable: nullable);
    return dartType;
  }
}
