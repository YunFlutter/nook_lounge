import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

class TurnipApiDataSource {
  TurnipApiDataSource({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  Future<Map<String, dynamic>> requestPrediction({
    required List<int> filter,
  }) async {
    final uri = Uri.parse(
      'https://api.ac-turnip.com/data/',
    ).replace(queryParameters: <String, String>{'f': filter.join('-')});
    developer.log('[TurnipApiDataSource] request $uri', name: 'turnip');

    final request = await _httpClient
        .getUrl(uri)
        .timeout(const Duration(seconds: 8));

    final response = await request.close().timeout(const Duration(seconds: 8));

    if (response.statusCode != HttpStatus.ok) {
      developer.log(
        '[TurnipApiDataSource] non-200 status=${response.statusCode}',
        name: 'turnip',
      );
      throw HttpException('turnip_api_status_${response.statusCode}');
    }

    final body = await utf8.decoder.bind(response).join();
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('turnip_api_invalid_json');
    }
    return decoded;
  }
}
