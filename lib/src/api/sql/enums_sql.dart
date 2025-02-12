class EnumsSql {

  String getQuery(List<String> schemas) {
    String schemasString = schemas.map((e) => e).join("', '");
    String query = '''
      SELECT t.typname AS enum_name, STRING_AGG(e.enumlabel, ', ') AS enum_values
      FROM pg_type t
      JOIN pg_enum e ON t.oid = e.enumtypid
      JOIN pg_namespace n ON n.oid = t.typnamespace
      WHERE n.nspname IN ('$schemasString')
      GROUP BY t.typname;
      ''';
    return query;
  }
}