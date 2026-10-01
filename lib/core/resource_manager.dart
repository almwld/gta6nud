/// Small lifecycle cache for disposable presentation resources.
///
/// The cache uses weak references so retaining a cache key never keeps a
/// resource alive by itself.
class ResourceManager {
  final Map<String, WeakReference<Object>> _cache = {};

  T getOrCreate<T extends Object>(String key, T Function() factory) {
    final existing = _cache[key]?.target;
    if (existing is T) return existing;

    final created = factory();
    _cache[key] = WeakReference<Object>(created);
    return created;
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void cleanup() {
    _cache.removeWhere((_, reference) => reference.target == null);
  }

  void clear() {
    _cache.clear();
  }

  int get size => _cache.length;
}
