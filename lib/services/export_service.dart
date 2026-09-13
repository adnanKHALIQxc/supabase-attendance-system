import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_report.dart';
import 'attendance_service.dart';

enum ExportFormat { excel, png }

class ExportService {
  final SupabaseClient _client = Supabase.instance.client;
  final AttendanceService _attendance = AttendanceService();

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

  Future<Uint8List> generateSectionZip({
    required String sectionId,
    required String sectionName,
    required ExportFormat format,
  }) async {
    final report = await _attendance.getSectionReport(sectionId);
    final zip = Archive();

    for (final student in report.students) {
      final bytes = _buildStudentFile(student, sectionName, format);
      final fileName = _studentFileName(student, format);
      zip.addFile(ArchiveFile(fileName, bytes.length, bytes));
    }

    final encoded = ZipEncoder().encode(zip);
    if (encoded == null) {
      throw Exception('ZIP encoding failed');
    }
    return Uint8List.fromList(encoded);
  }

  Future<Uint8List> generateYearZip({
    required String departmentId,
    required int year,
    required String yearLabel,
    required ExportFormat format,
  }) async {
    final sectionRows = await _client
        .from('sections')
        .select('id, name')
        .eq('department_id', departmentId)
        .eq('year', year)
        .eq('is_active', true)
        .order('name', ascending: true);

    final zip = Archive();
    final sanitizedYear = _sanitize(yearLabel);

    for (final row in sectionRows as List) {
      final sectionId = row['id'] as String;
      final report = await _attendance.getSectionReport(sectionId);

      for (final student in report.students) {
        final bytes = _buildStudentFile(student, sectionId, format);
        final fileName =
            '$sanitizedYear/$sectionId/${_studentFileName(student, format)}';
        zip.addFile(ArchiveFile(fileName, bytes.length, bytes));
      }
    }

    final encoded = ZipEncoder().encode(zip);
    if (encoded == null) {
      throw Exception('ZIP encoding failed');
    }
    return Uint8List.fromList(encoded);
  }

  // ===========================================================================
  // EXCEL BUILDER
  // ===========================================================================

  

  void _buildSummarySheet(Sheet sheet, StudentReport s, String sectionName) {
    const primaryHex = 'FF1E3A8A';
    const white = 'FFFFFFFF';
    const lightGrey = 'FFF3F4F6';

    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 32);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 14);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('ATTENDANCE REPORT')
      ..cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(primaryHex),
        fontColorHex: ExcelColor.fromHexString(white),
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    sheet.setRowHeight(0, 40);

    _infoRow(sheet, 2, 'Name', s.fullName);
    _infoRow(sheet, 3, 'Roll No', s.rollNo);
    _infoRow(sheet, 4, 'Enrollment', s.enrollmentId);
    _infoRow(sheet, 5, 'Section', sectionName);
    _infoRow(sheet, 6, 'Generated',
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()));

    const headers = ['Code', 'Subject', 'Conducted', 'Attended', '%'];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 8))
        ..value = TextCellValue(headers[c])
        ..cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(primaryHex),
          fontColorHex: ExcelColor.fromHexString(white),
          bold: true,
          fontSize: 12,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
    }
    sheet.setRowHeight(8, 28);

    var row = 9;
    for (final subj in s.subjects) {
      final isEven = (row - 9).isEven;
      final bg = isEven ? lightGrey : white;
      final pct = subj.percentage;
      final pctHex = pct >= 75
          ? 'FF10B981'
          : pct >= 60
              ? 'FFF59E0B'
              : 'FFEF4444';

      _dataCell(sheet, 0, row, subj.subjectId,
          bg: bg, align: HorizontalAlign.Center);
      _dataCell(sheet, 1, row, subj.subjectName, bg: bg);
      _dataCell(sheet, 2, row, '${subj.conductedSlots}',
          bg: bg, align: HorizontalAlign.Center);
      _dataCell(sheet, 3, row, '${subj.attendedSlots}',
          bg: bg, align: HorizontalAlign.Center);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        ..value = TextCellValue('${pct.toStringAsFixed(1)}%')
        ..cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(bg),
          fontColorHex: ExcelColor.fromHexString(pctHex),
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      row++;
    }
  }

  void _infoRow(Sheet sheet, int row, String label, String value) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('$label:')
      ..cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('FF6B7280'),
        fontSize: 11,
      );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
      ..value = TextCellValue(value)
      ..cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
      );
  }

  void _dataCell(
    Sheet sheet,
    int col,
    int row,
    String value, {
    required String bg,
    HorizontalAlign align = HorizontalAlign.Left,
  }) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
      ..value = TextCellValue(value)
      ..cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(bg),
        fontSize: 12,
        horizontalAlign: align,
        verticalAlign: VerticalAlign.Center,
      );
  }

    Uint8List _buildStudentExcel(StudentReport s, String sectionName) {
    final excel = Excel.createExcel();

    // Rename default sheet → Summary
    final defaultName = excel.getDefaultSheet();
    if (defaultName != null && defaultName != 'Summary') {
      excel.rename(defaultName, 'Summary');
    }

    _buildSummarySheet(excel['Summary'], s, sectionName);

    // One sheet per subject
    final usedNames = <String>{'Summary'};
    for (final subj in s.subjects) {
      final sheetName = _uniqueSheetName(subj.subjectId, usedNames);
      usedNames.add(sheetName);
      _buildSubjectSheet(excel[sheetName], subj, s, sectionName);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Excel encoding failed');
    }
    return Uint8List.fromList(bytes);
  }

  /// Excel sheet names: max 31 chars, no \ / ? * [ ] :
  String _uniqueSheetName(String raw, Set<String> used) {
    var name = raw.replaceAll(RegExp(r'[\\/?*\[\]:]'), '_');
    if (name.length > 31) name = name.substring(0, 31);
    if (!used.contains(name)) return name;

    // Collision — append _2, _3, ...
    var suffix = 2;
    while (true) {
      final candidate = '${name}_$suffix';
      final trimmed = candidate.length > 31
          ? candidate.substring(0, 31)
          : candidate;
      if (!used.contains(trimmed)) return trimmed;
      suffix++;
    }
  }

  void _buildSubjectSheet(
    Sheet sheet,
    SubjectReport subj,
    StudentReport s,
    String sectionName,
  ) {
    const primaryHex = 'FF1E3A8A';
    const white = 'FFFFFFFF';
    const lightGrey = 'FFF3F4F6';
    const greenBg = 'FFDCFCE7';
    const redBg = 'FFFEE2E2';

    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 14);

    // Title
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('${subj.subjectId} — ${subj.subjectName}')
      ..cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(primaryHex),
        fontColorHex: ExcelColor.fromHexString(white),
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    sheet.setRowHeight(0, 40);

    // Student info line
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 2),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
      ..value = TextCellValue('${s.fullName}  |  ${s.rollNo}  |  $sectionName')
      ..cellStyle = CellStyle(bold: true, fontSize: 12);

    // Attendance stats line
    final pct = subj.percentage;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
      ..value = TextCellValue(
        'Conducted: ${subj.conductedSlots}   Attended: ${subj.attendedSlots}   Percentage: ${pct.toStringAsFixed(1)}%',
      )
      ..cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        fontColorHex: ExcelColor.fromHexString(
          pct >= 75
              ? 'FF10B981'
              : pct >= 60
                  ? 'FFF59E0B'
                  : 'FFEF4444',
        ),
      );

    // Table header (row 5)
    const headers = ['Date', 'Slot', 'Status', 'Marked At'];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 5))
        ..value = TextCellValue(headers[c])
        ..cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(primaryHex),
          fontColorHex: ExcelColor.fromHexString(white),
          bold: true,
          fontSize: 12,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
    }
    sheet.setRowHeight(5, 26);

    // Data rows
    var row = 6;
    for (final sess in subj.sessions) {
      final isPresent = sess.status == 'present';
      final statusBg = isPresent ? greenBg : redBg;
      final isEven = row.isEven;
      final bg = isEven ? lightGrey : white;

      _dataCell(sheet, 0, row, sess.date,
          bg: bg, align: HorizontalAlign.Center);
      _dataCell(sheet, 1, row,
          sess.slotCount > 1 ? '${sess.slot} (${sess.slotCount})' : sess.slot,
          bg: bg, align: HorizontalAlign.Center);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
        ..value = TextCellValue(isPresent ? 'Present' : 'Absent')
        ..cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(statusBg),
          bold: true,
          fontSize: 12,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      _dataCell(sheet, 3, row, '-',
          bg: bg, align: HorizontalAlign.Center);
      row++;
    }

    if (subj.sessions.isEmpty) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 6),
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        ..value = TextCellValue('No sessions recorded yet.')
        ..cellStyle = CellStyle(
          fontColorHex: ExcelColor.fromHexString('FF6B7280'),
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      sheet.setRowHeight(6, 30);
    }
  }

  
  // ===========================================================================
  // PNG BUILDER
  // ===========================================================================

  Uint8List _buildStudentPng(StudentReport s, String sectionName) {
    const width = 900;
    const headerHeight = 90;
    const infoHeight = 90;
    const tableHeaderHeight = 40;
    const rowHeight = 38;
    const footerHeight = 50;

    final tableHeight = tableHeaderHeight + s.subjects.length * rowHeight;
    final height = headerHeight + infoHeight + tableHeight + footerHeight;

    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    final primary = img.ColorRgb8(30, 58, 138);
    final white = img.ColorRgb8(255, 255, 255);
    final dark = img.ColorRgb8(15, 23, 42);
    final grey = img.ColorRgb8(107, 114, 128);
    final light = img.ColorRgb8(243, 244, 246);

    img.fillRect(image,
        x1: 0, y1: 0, x2: width, y2: headerHeight, color: primary);
    img.drawString(image, 'ATTENDANCE REPORT',
        font: img.arial48, x: 30, y: 25, color: white);

    var y = headerHeight + 20;
    img.drawString(image, s.fullName,
        font: img.arial24, x: 30, y: y, color: dark);
    y += 28;
    img.drawString(image, '${s.rollNo}  •  ${s.enrollmentId}  •  $sectionName',
        font: img.arial14, x: 30, y: y, color: grey);

    final tableStartY = headerHeight + infoHeight;
    img.fillRect(image,
        x1: 0,
        y1: tableStartY,
        x2: width,
        y2: tableStartY + tableHeaderHeight,
        color: primary);

    final headerY = tableStartY + 12;
    img.drawString(image, 'CODE',
        font: img.arial14, x: 30, y: headerY, color: white);
    img.drawString(image, 'SUBJECT',
        font: img.arial14, x: 150, y: headerY, color: white);
    img.drawString(image, 'CONDUCTED',
        font: img.arial14, x: 520, y: headerY, color: white);
    img.drawString(image, 'ATTENDED',
        font: img.arial14, x: 640, y: headerY, color: white);
    img.drawString(image, 'PERCENT',
        font: img.arial14, x: 780, y: headerY, color: white);

    for (var i = 0; i < s.subjects.length; i++) {
      final subj = s.subjects[i];
      final rowY = tableStartY + tableHeaderHeight + i * rowHeight;

      if (i.isEven) {
        img.fillRect(image,
            x1: 0, y1: rowY, x2: width, y2: rowY + rowHeight, color: light);
      }

      final ty = rowY + 11;
      img.drawString(image, subj.subjectId,
          font: img.arial14, x: 30, y: ty, color: dark);
      img.drawString(image, subj.subjectName,
          font: img.arial14, x: 150, y: ty, color: dark);
      img.drawString(image, '${subj.conductedSlots}',
          font: img.arial14, x: 550, y: ty, color: dark);
      img.drawString(image, '${subj.attendedSlots}',
          font: img.arial14, x: 670, y: ty, color: dark);

      final pct = subj.percentage;
      final pctColor = pct >= 75
          ? img.ColorRgb8(16, 185, 129)
          : pct >= 60
              ? img.ColorRgb8(245, 158, 11)
              : img.ColorRgb8(239, 68, 68);
      img.drawString(image, '${pct.toStringAsFixed(1)}%',
          font: img.arial14, x: 790, y: ty, color: pctColor);
    }

    img.drawString(
      image,
      'Generated by UniAttend  •  ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      font: img.arial14,
      x: 30,
      y: height - 30,
      color: grey,
    );

    return Uint8List.fromList(img.encodePng(image));
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Uint8List _buildStudentFile(
    StudentReport s,
    String sectionName,
    ExportFormat format,
  ) {
    return format == ExportFormat.excel
        ? _buildStudentExcel(s, sectionName)
        : _buildStudentPng(s, sectionName);
  }

  String _studentFileName(StudentReport s, ExportFormat format) {
    final ext = format == ExportFormat.excel ? 'xlsx' : 'png';
    return '${_sanitize(s.rollNo)}_${_sanitize(s.fullName)}.$ext';
  }

  String _sanitize(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}