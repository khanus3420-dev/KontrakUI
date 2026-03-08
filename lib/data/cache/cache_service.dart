import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  CacheService._();

  static const _boxName = 'kontrak_cache';
  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static Future<void> saveJson(String key, Map<String, dynamic> value) async {
    await _box.put(key, value);
  }

  static Map<String, dynamic>? getJson(String key) {
    final raw = _box.get(key);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw as Map);
    }
    return null;
  }
}

