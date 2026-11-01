class CachedResult<T> {
  const CachedResult(this.data, {this.offline = false, this.cachedAt});

  final T data;
  final bool offline;
  final DateTime? cachedAt;
}
