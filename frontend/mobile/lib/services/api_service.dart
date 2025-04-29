import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hapti_talk/config/app_config.dart';

class ApiService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 토큰 설정
  void setToken(String token) {
    headers['Authorization'] = 'Bearer $token';
  }

  // GET 요청
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('네트워크 요청 실패: $e');
    }
  }

  // POST 요청
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('네트워크 요청 실패: $e');
    }
  }

  // PUT 요청
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('네트워크 요청 실패: $e');
    }
  }

  // DELETE 요청
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('네트워크 요청 실패: $e');
    }
  }

  // 응답 처리
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('API 오류: ${response.statusCode} - ${response.body}');
    }
  }
}
