import 'package:yaml/yaml.dart';

class GeneratorConfig {
  final String? projectRef;
  final String? accessToken;
  final bool generateEnums;
  final bool generateTables;
  final bool generateFunctions;
  final bool generateIsar;
  final bool generateJson;
  final List<String> schemas;
  final Set<String> includedTables;
  final List<CustomAnnotation> annotations;
  final Map<String, String> tableMappings;
  final String outputDir;

  GeneratorConfig({
    this.projectRef,
    this.accessToken,
    required this.generateEnums,
    required this.generateTables,
    required this.generateFunctions,
    required this.generateIsar,
    required this.generateJson,
    required this.schemas,
    required this.includedTables,
    required this.annotations,
    required this.tableMappings,
    required this.outputDir,
  });

  factory GeneratorConfig.fromYaml(String content) {
    final yaml = loadYaml(content);
    final projectRef = yaml['project-ref']?.toString();
    final accessToken = yaml['access-token']?.toString();
    final enumConfig = yaml['enums'] ?? {};
    final tableConfig = yaml['tables'] ?? {};
    final functionConfig = yaml['functions'] ?? {};
    final isarConfig = yaml['isar'] ?? {};

    return GeneratorConfig(
      projectRef: projectRef,
      accessToken: accessToken,
      generateEnums: enumConfig['disabled'] == true ? false : true,
      generateTables: tableConfig?['disabled'] == true ? false : true,
      generateFunctions: functionConfig?['disabled'] == true ? false : true,
      generateIsar: isarConfig.isNotEmpty ?? false,
      generateJson: yaml['json_serializable']?['enabled'] ?? true,
      schemas: List<String>.from(yaml['general']['schemas'] ?? ['public']),
      includedTables: Set.from(isarConfig?['includedTables'] ?? []),
      annotations: _parseAnnotations(yaml['custom_annotations'] ?? YamlList()),
      tableMappings: Map<String, String>.from(yaml['tables']['mappings'] ?? {}),
      outputDir: yaml['general']['output'] ?? 'lib/models',
    );
  }

  static List<CustomAnnotation> _parseAnnotations(YamlList list) {
    return list.map((item) {
      return CustomAnnotation(
        import: item['import'],
        annotations: List<String>.from(item['annotations']),
      );
    }).toList();
  }
}

class TableConfig {
  final String? primaryKey;
  final bool include;

  TableConfig({this.primaryKey, required this.include});
}

class CustomAnnotation {
  final String import;
  final List<String> annotations;

  CustomAnnotation({required this.import, required this.annotations});
}
