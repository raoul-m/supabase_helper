class ColumnsSql {

String getQuery(List<String> schemas) {
  String schemasString = schemas.map((e) => e).join("', '");
  String query = '''
    SELECT 
      c.table_schema AS schema,
      c.table_name AS table,
      c.column_name AS column,
      c.ordinal_position AS ordinal_position,
      COALESCE(base_udt.typname, udt.typname) AS format,  -- Added format column
      CASE 
          WHEN c.is_nullable = 'YES' THEN TRUE 
          ELSE FALSE 
      END AS is_nullable,
      CASE 
          WHEN pk.column_name IS NOT NULL THEN TRUE 
          ELSE FALSE 
      END AS is_primary_key
    FROM
      information_schema.columns c
    LEFT JOIN
      pg_type t ON c.udt_name = t.typname AND t.typtype = 'e'
    LEFT JOIN
      pg_type udt ON c.udt_name = udt.typname
    LEFT JOIN
      pg_type base_udt ON udt.typbasetype = base_udt.oid AND udt.typtype = 'd'
    LEFT JOIN (
      SELECT 
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name
      FROM 
        information_schema.table_constraints tc
      JOIN 
        information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
      WHERE 
        tc.constraint_type = 'PRIMARY KEY'
    ) pk ON c.table_schema = pk.table_schema AND c.table_name = pk.table_name AND c.column_name = pk.column_name
    WHERE 
      c.table_schema IN ('$schemasString')
    ORDER BY 
      c.table_name, c.ordinal_position;
    ''';
  return query;
  }
}


