import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class CacheService {
  SharedPreferences? _prefs;

  CacheService();

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Set data with expiration
  Future<bool> set<T>(
    String key,
    T data, {
    Duration? duration,
  }) async {
    await init();
    
    final expirationTime = duration != null
        ? DateTime.now().add(duration).millisecondsSinceEpoch
        : null;

    final cacheData = {
      'data': data,
      'expiration': expirationTime,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return await _prefs!.setString(key, jsonEncode(cacheData));
  }

  // Get data with expiration check
  Future<T?> get<T>(String key) async {
    await init();
    
    final cachedString = _prefs!.getString(key);
    if (cachedString == null) return null;

    try {
      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final expiration = cacheData['expiration'] as int?;
      
      // Check if data has expired
      if (expiration != null && DateTime.now().millisecondsSinceEpoch > expiration) {
        await remove(key);
        return null;
      }

      return cacheData['data'] as T;
    } catch (e) {
      // If parsing fails, remove corrupted data
      await remove(key);
      return null;
    }
  }

  // Remove specific key
  Future<bool> remove(String key) async {
    await init();
    return await _prefs!.remove(key);
  }

  // Clear all cache
  Future<bool> clear() async {
    await init();
    return await _prefs!.clear();
  }

  // Check if key exists and is not expired
  Future<bool> exists(String key) async {
    final data = await get(key);
    return data != null;
  }

  // Get cache info
  Future<Map<String, dynamic>> getCacheInfo(String key) async {
    await init();
    
    final cachedString = _prefs!.getString(key);
    if (cachedString == null) return {};

    try {
      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int?;
      final expiration = cacheData['expiration'] as int?;
      
      return {
        'exists': true,
        'timestamp': timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null,
        'expiration': expiration != null ? DateTime.fromMillisecondsSinceEpoch(expiration) : null,
        'isExpired': expiration != null ? DateTime.now().millisecondsSinceEpoch > expiration : false,
      };
    } catch (e) {
      return {'exists': false, 'error': e.toString()};
    }
  }
}