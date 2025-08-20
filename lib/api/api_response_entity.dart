class BulkRequestResult {
  final int _successCount;
  final int _failedCount;

  BulkRequestResult({required int successCount, required int failedCount})
      : _successCount = successCount,
        _failedCount = failedCount;

  int get successCount => _successCount;
  int get failedCount => _failedCount;
}

class SingleRequestResult {
  final bool _success;
  final String? _errorMessage;

  SingleRequestResult({required bool success, String? errorMessage})
      : _success = success,
        _errorMessage = errorMessage;

  bool get success => _success;
  String? get errorMessage => _errorMessage;
}