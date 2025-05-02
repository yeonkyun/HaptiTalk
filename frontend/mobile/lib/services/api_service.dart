import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:haptitalk/config/app_config.dart';

class ApiService {
  final String baseUrl;
  final Map<String, String> headers;

  ApiService({
    required this.baseUrl,
    required this.headers,
  });

  // 기본 인스턴스 생성
  factory ApiService.create() {
    return ApiService(
      baseUrl: AppConfig.apiBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  // 헤더 업데이트 (토큰 추가 등)
  void updateHeaders(Map<String, String> newHeaders) {
    headers.addAll(newHeaders);
  }

  // GET 요청
  Future<dynamic> get(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await http.get(uri, headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('GET 요청 실패: $e');
    }
  }

  // POST 요청
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('POST 요청 실패: $e');
    }
  }

  // PUT 요청
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('PUT 요청 실패: $e');
    }
  }

  // DELETE 요청
  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.delete(uri, headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('DELETE 요청 실패: $e');
    }
  }

  // 응답 처리
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 성공적인 응답
      if (response.body.isEmpty) {
        return {};
      }
      return json.decode(response.body);
    } else {
      // 에러 응답
      throw Exception(
          'API 요청 실패: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}
