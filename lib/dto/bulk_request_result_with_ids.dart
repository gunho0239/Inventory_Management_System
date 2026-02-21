class BulkRequestResultWithIds {
  final List<int> _successIds;
  final List<int> _failedIds;

  BulkRequestResultWithIds({required List<int> successIds, required List<int> failedIds})
      : _successIds = successIds,
        _failedIds = failedIds;

  List<int> get successIds => _successIds;
  List<int> get failedIds => _failedIds;
  
}