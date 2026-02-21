class SingleRequestResult {
  final bool _isSuccess;
  final String? _errorMessage;

  SingleRequestResult({required bool success, String? errorMessage})
      : _isSuccess = success,
        _errorMessage = errorMessage;

  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;
}