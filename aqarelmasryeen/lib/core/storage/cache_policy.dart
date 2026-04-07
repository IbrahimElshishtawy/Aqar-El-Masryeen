import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';

class CachePolicy {
  const CachePolicy._();

  static Stream<List<T>> watchList<T>({
    required LocalCacheService cache,
    required String cacheKey,
    required Stream<List<T>> source,
    required Map<String, dynamic> Function(T item) encode,
    required T Function(Map<String, dynamic> map) decode,
  }) async* {
    final cachedMaps = await cache.readObjectList(cacheKey);
    final cachedItems = cachedMaps.map(decode).toList(growable: false);
    if (cachedItems.isNotEmpty) {
      yield cachedItems;
    }

    try {
      await for (final items in source) {
        await cache.writeObjectList(
          cacheKey,
          items.map(encode).toList(growable: false),
        );
        yield items;
      }
    } catch (_) {
      if (cachedItems.isEmpty) {
        rethrow;
      }
    }
  }

  static Stream<T?> watchObject<T>({
    required LocalCacheService cache,
    required String cacheKey,
    required Stream<T?> source,
    required Map<String, dynamic> Function(T item) encode,
    required T Function(Map<String, dynamic> map) decode,
  }) async* {
    final cachedMap = await cache.readObject(cacheKey);
    final cachedValue = cachedMap == null ? null : decode(cachedMap);
    if (cachedValue != null) {
      yield cachedValue;
    }

    try {
      await for (final value in source) {
        if (value == null) {
          await cache.remove(cacheKey);
        } else {
          await cache.writeObject(cacheKey, encode(value));
        }
        yield value;
      }
    } catch (_) {
      if (cachedValue == null) {
        rethrow;
      }
    }
  }
}
