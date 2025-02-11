import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sql/columns_sql.dart';
import 'sql/functions_sql.dart';
import 'sql/enums_sql.dart';

class SupabaseManagementApi {
  static const _baseUrl = 'https://api.supabase.com/v1';
  final String projectRef;
  final String accessToken;
  final http.Client client;

  SupabaseManagementApi({
    required this.projectRef,
    required this.accessToken,
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> runQuery(String sql) async {
    final response = await client.post(
      Uri.parse('$_baseUrl/projects/$projectRef/database/query'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'query': sql}),
    );

    if (response.statusCode != 201) {
      throw Exception('Query failed: ${response.body}');
    }

    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<List<Map<String, dynamic>>> getColumns(List<String> schemas) async {
    final sql = ColumnsSql().getQuery(schemas);
    final result = await runQuery(sql);

    return result;
  }

  Future<List<Map<String, dynamic>>> getEnums(List<String> schemas) async {
    final sql = EnumsSql().getQuery(schemas);
    final result = await runQuery(sql);

    return result;
  }

  Future<List<Map<String, dynamic>>> getFunctions(List<String> schemas) async {
    final sql = FunctionsSql().getQuery(schemas);
    final result = await runQuery(sql);

    return result;
  }
}