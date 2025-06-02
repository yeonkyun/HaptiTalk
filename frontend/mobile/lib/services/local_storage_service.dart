import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _preferences;

  /// 서비스 초기화
  static Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  // 싱글톤 인스턴스
  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // 아이템 저장
  Future<bool> setItem(String key, String value) async {
    return await _preferences!.setString(key, value);
  }

  // 아이템 조회
  Future<String?> getItem(String key) async {
    return _preferences!.getString(key);
  }

  // 아이템 삭제
  Future<bool> removeItem(String key) async {
    return await _preferences!.remove(key);
  }

  // 모든 데이터 삭제
  Future<bool> clear() async {
    return await _preferences!.clear();
  }

  // 특정 키 존재 확인
  bool containsKey(String key) {
    return _preferences!.containsKey(key);
  }

  // 정수 저장
  static Future<bool> setInt(String key, int value) async {
    if (_preferences == null) await getInstance();
    return await _preferences!.setInt(key, value);
  }

  // 정수 불러오기
  static int? getInt(String key) {
    return _preferences?.getInt(key);
  }

  // 부울 저장
  static Future<bool> setBool(String key, bool value) async {
    if (_preferences == null) await getInstance();
    return await _preferences!.setBool(key, value);
  }

  // 부울 불러오기
  static bool? getBool(String key) {
    return _preferences?.getBool(key);
  }

  // 객체 저장
  static Future<bool> setObject(String key, Map<String, dynamic> value) async {
    if (_preferences == null) await getInstance();
    return await _preferences!.setString(key, jsonEncode(value));
  }

  // 객체 불러오기
  static Map<String, dynamic>? getObject(String key) {
    final data = _preferences?.getString(key);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // 객체 리스트 저장
  static Future<bool> setObjectList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    if (_preferences == null) await getInstance();
    return await _preferences!.setString(key, jsonEncode(value));
  }

  // 객체 리스트 불러오기
  static List<Map<String, dynamic>>? getObjectList(String key) {
    final data = _preferences?.getString(key);
    if (data == null) return null;
    return (jsonDecode(data) as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  // 데이터 삭제
  static Future<bool> remove(String key) async {
    if (_preferences == null) await getInstance();
    return await _preferences!.remove(key);
  }
}
