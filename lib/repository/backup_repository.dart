import 'package:inventory_management/api/backup_api.dart';
import 'package:inventory_management/dto/general_request_result.dart';
import 'package:inventory_management/dto/single_request_result.dart';

class BackupRepository {
  final _api = BackupApi();

  Future<SingleRequestResult> backupDatabase() => _api.backupDatabase();
  Future<SingleRequestResult> restoreDatabase() => _api.restoreDatabase();
  Future<GeneralRequestResult> getLastBackupDate() => _api.getLastBackupDate();
    
}