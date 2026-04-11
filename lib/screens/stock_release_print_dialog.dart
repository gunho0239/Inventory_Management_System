import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/constants/columns.dart';
import 'package:inventory_management/repository/stock_history_repository.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:inventory_management/constants/columns.dart';
// import 'package:inventory_management/constants/menu_name.dart';
// import 'package:inventory_management/widgets/buttons.dart';
// import 'package:inventory_management/widgets/icons.dart';

class StockReleasePrintDialog extends StatefulWidget {
  const StockReleasePrintDialog({super.key});

  @override
  State<StockReleasePrintDialog> createState() => _StockReleasePrintDialogState();
}

class _StockReleasePrintDialogState extends State<StockReleasePrintDialog> {
  StockHistoryRepository stockHistoryRepo = StockHistoryRepository();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  // --- 상태(State) 변수들 ---
  String _sortCriteria = 'location';
  List<DateTime> _releaseDates = []; // DB에서 가져온 날짜 목록
  Set<DateTime> _selectedDatesForPrint = {}; // 체크박스로 선택된(인쇄할) 날짜들
  
  DateTime? _currentlyViewedDate; // 현재 오른쪽 테이블에서 보고 있는 날짜
  List<dynamic> _viewedStocks = []; // 오른쪽 테이블에 표시할 품목 데이터 (임시 dynamic 타입)

  bool _isLoadingDates = true;
  bool _isLoadingStocks = false;
  bool _isPrinting = false;

  // --- 테이블 컬럼 정의 ---
  final List<DataColumn> columnsDate = const [
    DataColumn(label: Text('출고 일시')), // dateReleased
  ];

  final List<DataColumn> columnsStock = const [
    DataColumn(label: Text(type)), // type
    DataColumn(label: Text(specification)), // specification
    DataColumn(label: Text(maker)), // maker
    DataColumn(label: Text(quantity)), // quantity
    DataColumn(label: Text(location)), // location
  ];

  @override
  void initState() {
    super.initState();
    _fetchReleasedDates();
  }

  // 1. 날짜 목록 가져오기 (초기 로딩)
  Future<void> _fetchReleasedDates() async {
    setState(() => _isLoadingDates = true);
    
    stockHistoryRepo.getDatesOfReleasedStocks().then((dates) {
      setState(() {
        _releaseDates = dates;
        _isLoadingDates = false;
      });
    }).catchError((error) {
      // 에러 처리 (예: 다이얼로그로 알림)
      setState(() => _isLoadingDates = false);
    });
  }

  // 2. 특정 날짜를 클릭했을 때 품목 가져오기
  Future<void> _fetchReleasedStocks(DateTime date) async {
    setState(() {
      _currentlyViewedDate = date;
      _isLoadingStocks = true;
    });

    stockHistoryRepo.getReleasedStocksByDate(date).then((stocks) {
      setState(() {
        _viewedStocks = stocks.map((stock) => {
          'type': stock.type,
          'spec': stock.specification,
          'maker': stock.maker,
          'qty': stock.formattedQuantity,
          'loc': stock.formattedLocation,
        }).toList();
        _isLoadingStocks = false;
      });
    }).catchError((error) {
      // 에러 처리 (예: 다이얼로그로 알림)
      setState(() => _isLoadingStocks = false);
    });
  }


  // 1. 인쇄 준비 및 미리보기 다이얼로그 호출
  Future<void> _handlePrint() async {
    if (_selectedDatesForPrint.isEmpty) return;

    setState(() => _isPrinting = true);

    try {
      List<DateTime> sortedDates = _selectedDatesForPrint.toList()..sort();
      Map<DateTime, List<dynamic>> allPrintData = {};
      for (var date in sortedDates) {
        final stocks = await stockHistoryRepo.getReleasedStocksByDate(date);
        allPrintData[date] = stocks;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            String previewSortCriteria = 'location'; 

            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 다이얼로그 모서리 둥글게
                  clipBehavior: Clip.antiAlias, // 자식 위젯이 모서리를 침범하지 않도록
                  child: SizedBox(
                    width: 1000, 
                    height: 800, 
                    child: Column(
                      children: [
                        // --- 상단: 정렬 컨트롤 패널 (깔끔한 헤더 스타일) ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양끝 정렬
                            children: [
                              // 1. 좌측: 직관적인 닫기 버튼 추가
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(context).pop(),
                                tooltip: '닫기',
                              ),
                              // 2. 우측: 정렬 드롭다운
                              Row(
                                children: [
                                  const Icon(Icons.sort, size: 20, color: Colors.black87),
                                  const SizedBox(width: 8),
                                  const Text('정렬 기준: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                  DropdownButton<String>(
                                    value: previewSortCriteria,
                                    underline: const SizedBox(), 
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                                    items: const [
                                      DropdownMenuItem(value: 'location', child: Text('위치순 (동선 최적화)')),
                                      DropdownMenuItem(value: 'date', child: Text('출고일시순 (시간순)')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) setStateDialog(() => previewSortCriteria = value);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // --- 하단: PDF 미리보기 ---
                        Expanded(
                          child: PdfPreview(
                            build: (format) => _generatePdf(format, sortedDates, allPrintData, previewSortCriteria),
                            pdfFileName: '출고_품목_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                            canChangeOrientation: false, 
                            canChangePageFormat: false, 
                            canDebug: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            );
          },
        );
      }
    } catch (e) {
      debugPrint("Print Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인쇄 문서를 준비하는 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  // 파라미터 끝에 String sortCriteria 추가
  Future<Uint8List> _generatePdf(
    PdfPageFormat format, 
    List<DateTime> sortedDates, 
    Map<DateTime, List<dynamic>> allPrintData,
    String sortCriteria, // <-- 새로 추가된 파라미터
  ) async {
    final font = await PdfGoogleFonts.nanumGothicRegular();
    final fontBold = await PdfGoogleFonts.nanumGothicBold();

    List<Map<String, dynamic>> flatData = [];
    for (var date in sortedDates) {
      final stocks = allPrintData[date] ?? [];
      for (var stock in stocks) {
        flatData.add({
          'date': _dateFormat.format(date),
          'type': stock.type ?? '',
          'spec': stock.specification ?? '',
          'maker': stock.maker ?? '',
          'qty': stock.formattedQuantity ?? '',
          'loc': stock.formattedLocation ?? '',
        });
      }
    }

    // 넘어온 sortCriteria 값에 따른 정렬 로직 분기
    flatData.sort((a, b) {
      if (sortCriteria == 'date') {
        // [출고일시순] 1차: 일시 -> 2차: 위치
        int dateCmp = a['date'].compareTo(b['date']);
        if (dateCmp != 0) return dateCmp;
        return a['loc'].compareTo(b['loc']);
      } else {
        // [위치순] 1차: 위치 -> 2차: 규격
        int locCmp = a['loc'].compareTo(b['loc']);
        if (locCmp != 0) return locCmp;
        return a['spec'].compareTo(b['spec']);
      }
    });

    final tableData = flatData.map((row) => [
      row['date'], row['type'], row['spec'], row['maker'], row['qty'], row['loc'],
    ]).toList();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              // 제목에도 현재 어떤 정렬 상태인지 살짝 표시해주면 좋습니다.
              child: pw.Text('출고 품목 (${sortCriteria == 'date' ? '일시순' : '위치순'})', 
                style: pw.TextStyle(font: fontBold, fontSize: 18)),
            ),
            pw.SizedBox(height: 10),

            if (flatData.isEmpty)
              pw.Text('출고 내역이 없습니다.', style: const pw.TextStyle(fontSize: 10)),

            if (flatData.isNotEmpty)
              pw.TableHelper.fromTextArray(
                headers: ['출고 일시', type, specification, maker, quantity, location],
                data: tableData,
                headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.center,
                cellPadding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(2.0),
                  2: const pw.FlexColumnWidth(2.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(0.8),
                  5: const pw.FlexColumnWidth(1.0),
                },
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.print, size: 30), // MenuIcons.print
          SizedBox(width: 8),
          Text('출고 품목 인쇄', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 1100, // 데스크톱용 다이얼로그 전체 너비 고정
        height: 700, // 높이 고정 (내부에서 스크롤)
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 왼쪽: 날짜 목록 테이블 ---
            SizedBox(
              width: 250,
              child: _isLoadingDates
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: columnsDate,
                        showCheckboxColumn: true,
                        // 날짜 리스트를 DataRow로 변환
                        rows: _releaseDates.map((date) {
                          return DataRow(
                            selected: _selectedDatesForPrint.contains(date),
                            // 체크박스 클릭: 인쇄 대기열에 추가/삭제
                            onSelectChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedDatesForPrint.add(date);
                                } else {
                                  _selectedDatesForPrint.remove(date);
                                }
                              });
                            },
                            // 행(빈 공간) 클릭: 오른쪽 테이블에 상세 품목 표시
                            cells: [
                              DataCell(
                                Text(_dateFormat.format(date), style: TextStyle(
                                  fontWeight: _currentlyViewedDate == date ? FontWeight.bold : FontWeight.normal,
                                  color: _currentlyViewedDate == date ? Colors.blue : null,
                                )),
                                onTap: () => _fetchReleasedStocks(date),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
            
            const VerticalDivider(width: 40), // 좌우 구분선

            // --- 오른쪽: 상세 품목 테이블 ---
            Expanded(
              child: _isLoadingStocks
                  ? const Center(child: CircularProgressIndicator())
                  : _currentlyViewedDate == null
                      ? const Center(child: Text('왼쪽에서 날짜를 선택하여 품목을 확인하세요.'))
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_dateFormat.format(_currentlyViewedDate!)} 출고 내역', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              DataTable(
                                dataRowMaxHeight: double.infinity,
                                columns: columnsStock,
                                // 품목 리스트를 DataRow로 변환
                                rows: _viewedStocks.map((stock) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(stock['type'])),
                                      DataCell(Text(stock['spec'])),
                                      DataCell(Text(stock['maker'])),
                                      DataCell(Text(stock['qty'].toString())),
                                      DataCell(Text(stock['loc'])),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      actions: [
        // Row(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     const Text('정렬 기준: ', style: TextStyle(fontSize: 12)),
        //     DropdownButton<String>(
        //       value: _sortCriteria,
        //       items: const [
        //         DropdownMenuItem(value: 'date', child: Text('출고일시순', style: TextStyle(fontSize: 12))),
        //         DropdownMenuItem(value: 'location', child: Text('위치순', style: TextStyle(fontSize: 12))),
        //       ],
        //       onChanged: (value) {
        //         if (value != null) setState(() => _sortCriteria = value);
        //       },
        //     ),
        //   ],
        // ),
        // 인쇄 버튼 (선택된 항목이 없거나 인쇄 중일 때는 비활성화)
        ElevatedButton.icon(
          onPressed: (_selectedDatesForPrint.isEmpty || _isPrinting) ? null : _handlePrint,
          icon: _isPrinting 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Icon(Icons.print),
          label: Text('선택 항목 인쇄 (${_selectedDatesForPrint.length}건)'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}