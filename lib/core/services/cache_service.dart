// lib/core/services/cache_service.dart
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

  // 🆕 Set list data with expiration
  Future<bool> setList<T>(
    String key,
    List<T> dataList, {
    Duration? duration,
  }) async {
    await init();
    
    final expirationTime = duration != null
        ? DateTime.now().add(duration).millisecondsSinceEpoch
        : null;

    final cacheData = {
      'data': dataList,
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

  // 🆕 Get list data with expiration check
  Future<List<T>?> getList<T>(String key) async {
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

      final dataList = cacheData['data'] as List;
      return dataList.cast<T>();
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

  // 🆕 Batch operations for better performance
  Future<bool> setBatch(Map<String, dynamic> data) async {
    await init();
    bool success = true;
    
    for (final entry in data.entries) {
      final result = await set(entry.key, entry.value);
      if (!result) success = false;
    }
    
    return success;
  }

  // 🆕 Get multiple keys at once
  Future<Map<String, dynamic>> getBatch(List<String> keys) async {
    final results = <String, dynamic>{};
    
    for (final key in keys) {
      final value = await get(key);
      if (value != null) {
        results[key] = value;
      }
    }
    
    return results;
  }

  // 🆕 Get all keys with a specific prefix
  Future<List<String>> getKeysWithPrefix(String prefix) async {
    await init();
    return _prefs!.getKeys().where((key) => key.startsWith(prefix)).toList();
  }

  // 🆕 Remove all keys with a specific prefix
  Future<bool> removeKeysWithPrefix(String prefix) async {
    await init();
    final keys = await getKeysWithPrefix(prefix);
    bool success = true;
    
    for (final key in keys) {
      final result = await remove(key);
      if (!result) success = false;
    }
    
    return success;
  }
}