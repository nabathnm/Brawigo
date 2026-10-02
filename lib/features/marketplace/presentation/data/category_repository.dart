import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryRepository {
  CategoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _client.from('categories').select();
    return List<Map<String, dynamic>>.from(response);
  }
}
