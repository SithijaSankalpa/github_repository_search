import '../../../core/network/api_client.dart';
import 'models/repository_model.dart';

class RepositorySearchRepository {
  final ApiClient apiClient;
  RepositorySearchRepository(this.apiClient);

  Future<List<RepositoryModel>> search({
    required String query,
    required int page,
    required int perPage,
  }) async {
    final json = await apiClient.get('/search/repositories', {
      'q': query,
      'page': '$page',
      'per_page': '$perPage',
    });

    final items = (json['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => RepositoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}