import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/repository/stock_history_repository.dart';

class StockReleasePrintDialog extends StatefulWidget {
  const StockReleasePrintDialog({super.key});

  @override
  State<StockReleasePrintDialog> createState() => _StockReleasePrintDialogState();
}

class _StockReleasePrintDialogState extends State<StockReleasePrintDialog> {
  final StockHistoryRepository _stockHistoryRepo = StockHistoryRepository();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  // --- 상태 변수 ---
  List<DateTime> _releaseDates = [];
  final Set<DateTime> _selectedDatesForPrint = {};
  
  DateTime? _currentlyViewedDate;
  List<Map<String, dynamic>> _viewedStocks = [];

  bool _isLoadingDates = true;
  bool _isLoadingStocks = false;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _fetchReleasedDates();
  }

  // 1. 날짜 목록 가져오기 (async/await로 개선)
  Future<void> _fetchReleasedDates() async {
    setState(() => _isLoadingDates = true);
    try {
      final dates = await _stockHistoryRepo.getDatesOfReleasedStocks();
      if (!mounted) return;
      setState(() {
        _releaseDates = dates;
        _isLoadingDates = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDates = false);
      _showErrorSnackBar('날짜 목록을 불러오지 못했습니다.');
    }
  }

  // 2. 특정 날짜 상세 내역 가져오기
  Future<void> _fetchReleasedStocks(DateTime date) async {
    if (_currentlyViewedDate == date) return;

    setState(() {
      _currentlyViewedDate = date;
      _isLoadingStocks = true;
    });

    try {
      final stocks = await _stockHistoryRepo.getReleasedStocksByDate(date);
      if (!mounted) return;
      setState(() {
        _viewedStocks = stocks.map((s) => {
          'type': s.type ?? '',
          'spec': s.specification ?? '',
          'maker': s.maker ?? '',
          'qty': s.formattedQuantity ?? '',
          'loc': s.formattedLocation ?? '',
        }).toList();
        _isLoadingStocks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStocks = false);
      _showErrorSnackBar('상세 내역을 불러오지 못했습니다.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 3. 인쇄 핸들러 (StatefulBuilder 미리보기 포함)
  Future<void> _handlePrint() async {
    if (_selectedDatesForPrint.isEmpty) return;

    setState(() => _isPrinting = true);

    try {
      final sortedDates = _selectedDatesForPrint.toList()..sort();
      final Map<DateTime, List<dynamic>> allPrintData = {};
      
      for (var date in sortedDates) {
        allPrintData[date] = await _stockHistoryRepo.getReleasedStocksByDate(date);
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          String previewSortCriteria = 'location';
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 1000, height: 800,
                  child: Column(
                    children: [
                      _buildPreviewHeader(context, previewSortCriteria, (val) {
                        setStateDialog(() => previewSortCriteria = val);
                      }),
                      Expanded(
                        child: PdfPreview(
                          build: (format) => _generatePdf(format, sortedDates, allPrintData, previewSortCriteria),
                          pdfFileName: '출고_보고서_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          canDebug: false,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      _showErrorSnackBar('인쇄 준비 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  // --- UI 빌더 메서드 분리 ---

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.print_outlined, size: 28),
          SizedBox(width: 12),
          Text('출고 품목 인쇄', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Container(
        width: 1100, height: 700,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildDateSelectionSide(),
            const VerticalDivider(width: 1, thickness: 1),
            _buildStockDetailSide(),
          ],
        ),
      ),
      actions: _buildActions(),
    );
  }

  // 왼쪽: 날짜 선택 영역
  Widget _buildDateSelectionSide() {
    return SizedBox(
      width: 300,
      child: _isLoadingDates
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  child: const Center(child: Text("출고 일시 목록", style: TextStyle(fontWeight: FontWeight.bold))),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 10,
                      showCheckboxColumn: true,
                      columns: const [DataColumn(label: Text('날짜 선택'))],
                      rows: _releaseDates.map((date) => DataRow(
                        selected: _selectedDatesForPrint.contains(date),
                        onSelectChanged: (val) => setState(() {
                          val == true ? _selectedDatesForPrint.add(date) : _selectedDatesForPrint.remove(date);
                        }),
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(_dateFormat.format(date), 
                                style: TextStyle(color: _currentlyViewedDate == date ? Colors.blue : null, fontWeight: _currentlyViewedDate == date ? FontWeight.bold : null)),
                            ),
                            onTap: () => _fetchReleasedStocks(date),
                          ),
                        ],
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // 오른쪽: 상세 품목 영역
  Widget _buildStockDetailSide() {
    return Expanded(
      child: _isLoadingStocks
          ? const Center(child: CircularProgressIndicator())
          : _currentlyViewedDate == null
              ? const Center(child: Text('왼쪽 목록에서 날짜를 클릭하면 상세 내역이 표시됩니다.'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('📌 상세 내역: ${_dateFormat.format(_currentlyViewedDate!)}', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                          dataRowMaxHeight: double.infinity,
                          columns: const [
                            DataColumn(label: Text(type)),
                            DataColumn(label: Text(specification)),
                            DataColumn(label: Text(maker)),
                            DataColumn(label: Text(quantity)),
                            DataColumn(label: Text(location)),
                          ],
                          rows: _viewedStocks.map((s) => DataRow(cells: [
                            DataCell(Text(s['type'])),
                            DataCell(Text(s['spec'])),
                            DataCell(Text(s['maker'])),
                            DataCell(Text(s['qty'])),
                            DataCell(Text(s['loc'])),
                          ])).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // 미리보기 헤더 (주로 정렬 기능)
  Widget _buildPreviewHeader(BuildContext context, String criteria, Function(String) onUpdate) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colorScheme.surface, border: Border(bottom: BorderSide(color: theme.dividerColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context), tooltip: '닫기',),
          Row(
            children: [
              Icon(Icons.sort, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Text('정렬 기준: ', style: TextStyle(fontWeight: FontWeight.bold,  color: colorScheme.onSurface,)),
              DropdownButton<String>(
                value: criteria,
                underline: const SizedBox(),
                dropdownColor: colorScheme.surface,
                iconEnabledColor: colorScheme.onSurface,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                items: [
                  DropdownMenuItem(value: 'location', child: Text('위치순', style: TextStyle(color: colorScheme.onSurface)),),
                  DropdownMenuItem(value: 'date', child: Text('일시순', style: TextStyle(color: colorScheme.onSurface)),),
                ],
                onChanged: (v) => v != null ? onUpdate(v) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
      ElevatedButton.icon(
        onPressed: (_selectedDatesForPrint.isEmpty || _isPrinting) ? null : _handlePrint,
        icon: _isPrinting 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Icon(Icons.print),
        label: Text('선택 항목 출력 (${_selectedDatesForPrint.length})'),
      ),
    ];
  }

  // PDF 생성 로직 (별도 함수)
  Future<Uint8List> _generatePdf(PdfPageFormat format, List<DateTime> sortedDates, Map<DateTime, List<dynamic>> allData, String sort) async {
    final font = await PdfGoogleFonts.nanumGothicRegular();
    final fontBold = await PdfGoogleFonts.nanumGothicBold();

    final List<Map<String, dynamic>> flatData = [];
    for (var date in sortedDates) {
      final stocks = allData[date] ?? [];
      for (var s in stocks) {
        flatData.add({
          'date': _dateFormat.format(date),
          'type': s.type ?? '', 'spec': s.specification ?? '',
          'maker': s.maker ?? '', 'qty': s.formattedQuantity ?? '', 'loc': s.formattedLocation ?? '',
        });
      }
    }

    flatData.sort((a, b) {
      if (sort == 'date') {
        int c = a['date'].compareTo(b['date']);
        return c != 0 ? c : a['loc'].compareTo(b['loc']);
      }
      int c = a['loc'].compareTo(b['loc']);
      return c != 0 ? c : a['spec'].compareTo(b['spec']);
    });

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      pageFormat: format,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) => [
        pw.Header(level: 0, child: pw.Text('출고 품목 (${sort == 'date' ? '일시순' : '위치순'})', style: pw.TextStyle(fontSize: 18, font: fontBold,))),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['출고 일시', type, specification, maker, quantity, location],
          data: flatData.map((r) => [r['date'], r['type'], r['spec'], r['maker'], r['qty'], r['loc']]).toList(),
          headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: pw.Alignment.center,
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5), 1: const pw.FlexColumnWidth(2.0), 
            2: const pw.FlexColumnWidth(2.5), 3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(0.8), 5: const pw.FlexColumnWidth(1.0),
          },
        ),
      ],
    ));
    return pdf.save();
  }
}