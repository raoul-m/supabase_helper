import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;

import '../supabase_type_mapper.dart';
import '../utils.dart';

class FunctionGenerator {
  static bool enumsUsed = false;
  static Future<void> generate(
    String outputDir,
    List<Map<String, dynamic>> functions,
    List<String> enumNames,
  ) async {
    final functionsDir = Directory(outputDir);
    await functionsDir.create(recursive: true);
    final buffer = StringBuffer()
      ..writeln("import 'package:supabase_flutter/supabase_flutter.dart';\n")
      ..writeln("import 'enums.dart';\n")
      ..writeln('class SupabaseFunctions {')
      ..writeln('  SupabaseFunctions();\n')
      ..writeln(
          '  final SupabaseClient supabase = Supabase.instance.client;\n');

    for (final function in functions) {
      final name = function['function_name'] as String;
      //TODO: Add support for custom access token hook
      if (name == 'authorize' || name == 'custom_access_token_hook') {
        continue;
      }
      var args = <FunctionArg>[];
      if (function['arguments'].isNotEmpty) {
        args = _parseArgs(
            (function['arguments'] as String?)
                    ?.split(',')
                    .map((e) => e.trim())
                    .toList() ??
                [],
            enumNames);
      } else {
        args = [];
      }
      final returnType = _toDartType(
        function['return_type'] as String? ?? 'void',
        enumNames,
      );
      // print('${function['return_type']}, dartType: $returnType');
      buffer.writeln('''
  Future<$returnType> ${toCamelCase(name)}(${args.isNotEmpty ? '{' : ''}${args.map((a) => 'required ${a.dartType} ${a.name},').join('\n    ')}${args.isNotEmpty ? '}' : ''}) async {
    ''');
      returnType == 'void'
          ? buffer.writeln('''     await supabase.rpc(''')
          : buffer.writeln('''      final response = await supabase.rpc(''');

      buffer.writeln('''
      '$name',${args.isNotEmpty ? '''
      params: {
        ${args.map((a) => "'${a.originalName}': ${a.name},").join('\n        ')}
      },''' : ''}
  ).select();
      
    ${_returnStatement(returnType)}
  }''');
      buffer.writeln();
    }

    buffer.writeln('}');
    final formatter =
        DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
    final formattedCode = formatter.format(buffer.toString());

    await File(path.join(functionsDir.path, 'supabase_functions.dart'))
        .writeAsString(formattedCode);
  }

  static List<FunctionArg> _parseArgs(List<dynamic> args, enumNames) {
    return args.map((a) {
      final arg = (a as String).split(' ').map((e) => e.trim()).toList();
      return FunctionArg(
        originalName: arg[0],
        name: toCamelCase(arg[0]),
        dartType: _toDartType(
          arg[1],
          enumNames,
          nullable: arg.length > 2 ? true : false,
        ),
      );
    }).toList();
  }

  static String _returnStatement(String returnType) {
    if (returnType.startsWith('List<')) {
      // print('returnType: $returnType');
      // final innerType = returnType.replaceAll('List<', '').replaceFirst('>', '');
      //
      // print('innerType: $innerType');
      // return 'return response.map((e) => $innerType.fromJson(e)).toList();';
      return 'return response;';
    } else if (returnType == 'void') {
      return 'return;';
    }
    return 'return response;';
  }

  static String _toDartType(String pgType, List<String> enumNames,
      {bool nullable = false}) {
    if (pgType.startsWith('TABLE') || pgType.startsWith('SETOF')) {
      return _toDartType('jsonb[]', enumNames, nullable: true);
    }

    if (pgType.endsWith('[]')) {
      final baseType = pgType.substring(0, pgType.length - 2);
      final dartType = _toDartType(baseType, enumNames);
      return nullable ? 'List<$dartType>?' : 'List<$dartType>';
    }
    final pascalCaseType = toPascalCase(pgType);
    if (enumNames.contains(pascalCaseType)) {
      enumsUsed = true;
      return nullable ? '$pascalCaseType?' : pascalCaseType;
    }
    final dartType = SupabaseTypeMapper.toDartType(pgType);

    return dartType;
  }
}

class FunctionArg {
  final String originalName;
  final String name;
  final String dartType;

  FunctionArg({
    required this.originalName,
    required this.name,
    required this.dartType,
  });
}
