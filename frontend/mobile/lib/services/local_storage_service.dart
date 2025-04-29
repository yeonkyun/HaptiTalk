import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;

  // 초기화
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 문자열 저장
  static Future<bool> setString(String key, String value) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(key, value);
  }

  // 문자열 불러오기
  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  // 정수 저장
  static Future<bool> setInt(String key, int value) async {
    if (_prefs == null) await init();
    return await _prefs!.setInt(key, value);
  }

  // 정수 불러오기
  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  // 부울 저장
  static Future<bool> setBool(String key, bool value) async {
    if (_prefs == null) await init();
    return await _prefs!.setBool(key, value);
  }

  // 부울 불러오기
  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  // 객체 저장
  static Future<bool> setObject(String key, Map<String, dynamic> value) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(key, jsonEncode(value));
  }

  // 객체 불러오기
  static Map<String, dynamic>? getObject(String key) {
    final data = _prefs?.getString(key);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // 객체 리스트 저장
  static Future<bool> setObjectList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(key, jsonEncode(value));
  }

  // 객체 리스트 불러오기
  static List<Map<String, dynamic>>? getObjectList(String key) {
    final data = _prefs?.getString(key);
    if (data == null) return null;
    return (jsonDecode(data) as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  // 데이터 삭제
  static Future<bool> remove(String key) async {
    if (_prefs == null) await init();
    return await _prefs!.remove(key);
  }

  // 모든 데이터 삭제
  static Future<bool> clear() async {
    if (_prefs == null) await init();
    return await _prefs!.clear();
  }

  // 키 존재 확인
  static bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }
}
