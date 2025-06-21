class FunctionsSql {
  String getQuery(List<String> schemas) {
    String schemasString = schemas.map((e) => e).join("', '");
    String query = '''
      SELECT
          n.nspname AS schema,
          p.proname AS function_name,
          pg_get_function_arguments(p.oid) AS arguments,
          pg_get_function_result(p.oid) AS return_type,
          l.lanname AS language
      FROM 
          pg_proc p
      JOIN 
          pg_namespace n ON p.pronamespace = n.oid 
      LEFT JOIN 
          pg_language l ON p.prolang = l.oid
      WHERE 
          l.lanname = 'plpgsql'
          AND n.nspname IN ('$schemasString');
      ''';
    return query;
  }
}
