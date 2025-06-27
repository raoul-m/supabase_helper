import 'dart:io';

import 'package:args/args.dart';
import 'package:supabase_helper/supabase_helper.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('project-ref', help: 'Supabase project reference ID')
    ..addOption('access-token', help: 'Supabase access-token')
    ..addOption('output', abbr: 'o')
    ..addOption('config', abbr: 'c', defaultsTo: 'supabase_helper.yaml');
  print('✅  Supabase Helper is powering up!');

  final results = parser.parse(args);
  final configFile = File(results['config'] as String);
  final config = GeneratorConfig.fromYaml(await configFile.readAsString());
  final outputDir = results['output'] as String? ?? config.outputDir;

  final projectRef = results['project-ref'] as String? ?? config.projectRef;

  final accessToken = results['access-token'] as String? ?? config.accessToken;
  if (projectRef == null) {
    throw ArgumentError('Supabase project reference ID is not provided. '
        'Please provide it via --project-ref option or in the config file.');
  }
  if (accessToken == null) {
    throw ArgumentError('Supabase access-token is not provided. '
        'Please provide it via --access-token option or in the config file.');
  }
  print(' Output directory: $outputDir');
  final api =
      SupabaseManagementApi(projectRef: projectRef, accessToken: accessToken);

  try {
    late List<String> enumNames = [];

    // Generate models
    if (config.generateEnums) {
      final enums = await _fetchEnums(api, config.schemas);
      enumNames = await EnumGenerator.generate(outputDir, enums);
      print('✅  Successfully generated enums!');
    }

    if (config.generateTables) {
      final tables = await _fetchTables(api, config.schemas);
      await TableGenerator.generate(outputDir, tables, enumNames, config);
      print('✅  Successfully generated tables!');
    }

    if (config.generateFunctions) {
      final functions = await _fetchFunctions(api, config.schemas);
      await FunctionGenerator.generate(outputDir, functions, enumNames);
      print('✅  Successfully generated functions!');
    }

    print('✅  Successfully generated all models!');
    if (config.generateIsar ||
        config.generateJson ||
        config.annotations.isNotEmpty) {
      print(
          '✅  Annotations added to files. Don\'t forget to run build_runner if necessary!');
    }
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  } finally {
    api.client.close();
    exit(0);
  }
}

Future<List<Map<String, dynamic>>> _fetchEnums(
    SupabaseManagementApi api, List<String> schemas) async {
  final enums = await api.getEnums(schemas);
  final result = <Map<String, dynamic>>[];
  for (final e in enums) {
    result.add({'enum_name': e['enum_name'], 'enum_values': e['enum_values']});
  }
  print('✅  Enums fetched');

  return result;
}

Future<Map<String, Map<String, List<TableColumn>>>> _fetchTables(
    SupabaseManagementApi api, List<String> schemas) async {
  final columns = await api.getColumns(schemas);

  print('✅  Tables fetched');

  final groupedColumns = await ColumnsMapper().mapColumns(columns);

  return groupedColumns;
}

Future<List<Map<String, dynamic>>> _fetchFunctions(
    SupabaseManagementApi api, List<String> schemas) async {
  final functions = await api.getFunctions(schemas);
  print('✅  Functions fetched');
  return functions;
}
