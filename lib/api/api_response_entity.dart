class BulkRequestResult {
  final int _successCount;
  final int _failedCount;

  BulkRequestResult({required int successCount, required int failedCount})
      : _successCount = successCount,
        _failedCount = failedCount;

  int get successCount => _successCount;
  int get failedCount => _failedCount;
}

class BulkRequestResultWithIds {
  final List<int> _successIds;
  final List<int> _failedIds;

  BulkRequestResultWithIds({required List<int> successIds, required List<int> failedIds})
      : _successIds = successIds,
        _failedIds = failedIds;

  List<int> get successIds => _successIds;
  List<int> get failedIds => _failedIds;
  
}

class SingleRequestResult {
  final bool _isSuccess;
  final String? _errorMessage;

  SingleRequestResult({required bool success, String? errorMessage})
      : _isSuccess = success,
        _errorMessage = errorMessage;

  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;
}