class GeneralRequestResult {
  final dynamic data;
  final String msg;

  GeneralRequestResult({required dynamic data, required String message})
      : data = data,
        msg = message;

  bool get isSuccess => data != null;
  String? get message => msg;
}