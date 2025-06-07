class TableColumn {
  final String name;
  final String format;
  final bool isNullable;
  final bool isPrimaryKey;

  TableColumn({
    required this.name,
    required this.format,
    required this.isNullable,
    required this.isPrimaryKey,
  });

  Map<String, Object> toJson() => {
    'name': name,
    'format': format,
    'is_nullable': isNullable,
    'is_primary_key': isPrimaryKey,
  };
}

class ColumnsMapper {
  Future<Map<String,Map<String,List<TableColumn>>>> mapColumns(List<Map<String,dynamic>> columns ) async {
    final Map<String, Map<String, List<TableColumn>>> groupedColumns = {};

    for (final column in columns) {
      final schema = column['schema'];
      final table = column['table'];

      if (!groupedColumns.containsKey(schema)) {
        groupedColumns[schema] = {};
      }

      if (!groupedColumns[schema]!.containsKey(table)) {
        groupedColumns[schema]![table] = [];
      }

      final cleanedColumn = TableColumn(
        name: column['column'],
        format: column['format'],
        isNullable: column['is_nullable'],
        isPrimaryKey: column['is_primary_key'],
      );

      groupedColumns[schema]![table]!.add(cleanedColumn);
    }
    return groupedColumns;
  }
}