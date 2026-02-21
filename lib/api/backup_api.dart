import 'package:inventory_management/api/api_client.dart';
import 'package:inventory_management/api/endpoints.dart';
import 'package:inventory_management/dto/general_request_result.dart';
import 'package:inventory_management/dto/single_request_result.dart';

class BackupApi {
  Future<SingleRequestResult> backupDatabase() async {
    final responseBody = await ApiClient.post("${Endpoints.backup}/dump", null);
    return SingleRequestResult(success: responseBody["success"], errorMessage: responseBody["message"]);
  }

  Future<SingleRequestResult> restoreDatabase() async {
    final responseBody = await ApiClient.post("${Endpoints.backup}/restore", null);
    return SingleRequestResult(success: responseBody["success"], errorMessage: responseBody["message"]);
  }

  Future<GeneralRequestResult> getLastBackupDate() async {
    final responseBody = await ApiClient.get("${Endpoints.backup}/last-backup");
    return GeneralRequestResult(data: responseBody['data'], message: responseBody['message']);
  }
}