class BulkRequestResult {
  final int _successCount;
  final int _failedCount;

  BulkRequestResult({required int successCount, required int failedCount})
      : _successCount = successCount,
        _failedCount = failedCount;

  int get successCount => _successCount;
  int get failedCount => _failedCount;
}