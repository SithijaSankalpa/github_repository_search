import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

class ApiClient {
  final http.Client _client;
  final Future<String?> Function() getToken;

  ApiClient({required this.getToken, http.Client? client})
      : _client = client ?? http.Client();

  static const String _baseHost = 'api.github.com';

  Future<Map<String, dynamic>> get(String path, Map<String, String> queryParams) async {
    final uri = Uri.https(_baseHost, path, queryParams);
    final token = await getToken();

    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      ).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw NetworkException();
    } on http.ClientException {
      throw NetworkException();
    } catch (_) {
      throw NetworkException();
    }

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return jsonDecode(response.body) as Map<String, dynamic>;
      case 401:
        throw UnauthorizedException();
      case 403:
      case 429:
        throw RateLimitException();
      case 422:
        throw InvalidQueryException();
      default:
        throw UnknownApiException('Request failed with status ${response.statusCode}');
    }
  }
}