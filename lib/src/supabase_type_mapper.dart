class SupabaseTypeMapper {
  static const _typeMap = {
    'text': 'String',
    'varchar': 'String',
    'int2': 'int',
    'int4': 'int',
    'int8': 'int',
    'bool': 'bool',
    'integer': 'int',
    'float4': 'double',
    'float8': 'double',
    'json': 'Map<String, dynamic>',
    'jsonb': 'Map<String, dynamic>',
    'timestamp': 'DateTime',
    'timestamptz': 'DateTime',
    'date': 'DateTime',
    'uuid': 'String',
    'numeric': 'double',
    'void': 'void',
  };

  static String toDartType(String pgType, {bool nullable = false}) {
    final dartType = _typeMap[pgType] ?? 'dynamic';
    return nullable && dartType != 'dynamic' ? '$dartType?' : dartType;  }
}