import 'package:flutter/material.dart';
import 'package:inventory_management/dto/general_request_result.dart';
import 'package:inventory_management/dto/single_request_result.dart';
import 'package:inventory_management/enums/inventory_menu.dart';
import 'package:inventory_management/repository/backup_repository.dart';
import 'package:inventory_management/style/style.dart';
import 'package:inventory_management/widgets/dialogs.dart';
import 'package:inventory_management/widgets/icons.dart';
import 'package:inventory_management/widgets/title.dart';

class BackupManagementScreen extends StatefulWidget {

  const BackupManagementScreen({super.key});

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  String lastBackupDate = "백업 데이터가 없습니다.";

  @override
  void initState() {
    super.initState();

    _updateLastBackupDate();
  }

  Future<void> _updateLastBackupDate() async {
    BackupRepository backupRepository = BackupRepository();
    GeneralRequestResult response = await backupRepository.getLastBackupDate();
    
    if (response.data == null) {
      lastBackupDate = "백업 데이터가 없습니다.";
    }
    else {
      DateTime lastBackup = DateTime.parse(response.data);
      lastBackupDate = "${lastBackup.year}/${lastBackup.month}/${lastBackup.day}   ${lastBackup.hour.toString().padLeft(2, '0')}:${lastBackup.minute.toString().padLeft(2, '0')}:${lastBackup.second.toString().padLeft(2, '0')}";
    }
    
    setState(() {});
  }

  Future<void> _backupDatabase() async {
    BackupRepository backupRepository = BackupRepository();
    SingleRequestResult response = await backupRepository.backupDatabase();

    if (!mounted) return;

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('재고 데이터가 성공적으로 백업되었습니다.')),
      );
    }
    else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('백업 실패'),
          content: Text('재고 데이터 백업에 실패했습니다.\n오류 메시지: ${response.errorMessage}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            ),
          ],
        ),
      );
    }

    _updateLastBackupDate();
  }

  Future<void> _restoreDatabase() async {
    BackupRepository backupRepository = BackupRepository();
    SingleRequestResult response = await backupRepository.restoreDatabase();

    if (!mounted) return;

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터가 성공적으로 복구되었습니다.')),
      );
    }
    else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('복구 실패'),
          content: Text('데이터 복구에 실패했습니다.\n오류 메시지: ${response.errorMessage}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenTitle(menu: InventoryMenu.backupManagement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            spacing: 20,
            children: [
              Text('마지막 백업:   $lastBackupDate', style: TextStyle(fontSize: 20,fontWeight: FontWeight.w500)),
              _buildBackupButton(),
              _buildRestoreButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackupButton() {
    return ElevatedButton(
      style: AppButtonStyle.newPage,
      onPressed: () async {
        final confirmed = await showDialog(
          context: context,
          builder: (context) =>
              ConfirmDialog(message: "모든 데이터를 백업합니다."),
        );

        if (confirmed == null || confirmed == false) return;

        _backupDatabase();
      },
      child: Row(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(MenuIcons.backup, size: 30),
          Text('지금 백업', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }


  Widget _buildRestoreButton() {
    return ElevatedButton(
      style: AppButtonStyle.newPage,
      onPressed: () async {
        final confirmed = await showDialog(
          context: context,
          builder: (context) =>
              ConfirmDialog(message: "마지막 백업 파일로 모든 데이터를 복원합니다.\n백업되지 않은 데이터는 유실됩니다."),
        );

        if (confirmed == null || confirmed == false) return;

        _restoreDatabase();
      },
      child: Row(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(MenuIcons.restore, size: 30),
          Text('데이터 복구', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}