import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/section.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class ImportRow {
  final int rowNumber;
  final String fullName;
  final String rollNo;
  final String enrollmentId;

  ImportRow({
    required this.rowNumber,
    required this.fullName,
    required this.rollNo,
    required this.enrollmentId,
  });
}

class ImportRowError {
  final int rowNumber;
  final String message;

  ImportRowError(this.rowNumber, this.message);
}

class ImportResult {
  final int totalRows;
  final List<ImportRow> validRows;
  final List<ImportRowError> errors;

  ImportResult({
    required this.totalRows,
    required this.validRows,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get validCount => validRows.length;
  int get errorCount => errors.length;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class StudentImportService {
  final SupabaseClient _client = Supabase.instance.client;

  static const int _maxRows = 500;
  static const int _maxNameLength = 100;
  static const int _minNameLength = 2;
  static const int _maxFieldLength = 50;

  static const Map<String, String> _headerAliases = {
    'fullname': 'fullName',
    'full name': 'fullName',
    'name': 'fullName',
    'rollno': 'rollNo',
    'roll no': 'rollNo',
    'roll number': 'rollNo',
    'rollnumber': 'rollNo',
    'enrollmentid': 'enrollmentId',
    'enrollment id': 'enrollmentId',
    'enrollment': 'enrollmentId',
    'enrollment number': 'enrollmentId',
  };

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  Future<ImportResult> parseAndValidate({
    required PlatformFile file,
    required Section section,
  }) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception('Could not read file data.');
    }

    final rawRows = _parseFile(bytes, file.extension);
    if (rawRows.isEmpty) {
      throw Exception('File is empty or has no readable rows.');
    }

    final headers = rawRows.first;
    final columnMap = _mapHeaders(headers);

    for (final required in ['fullName', 'rollNo', 'enrollmentId']) {
      if (!columnMap.values.contains(required)) {
        throw Exception(
          'Missing required column: "$required". '
          'Your file must have columns named fullName, rollNo, and enrollmentId.',
        );
      }
    }

    final validRows = <ImportRow>[];
    final errors = <ImportRowError>[];
    final seenRolls = <String>{};
    final seenEnrolls = <String>{};

    final dataRows = rawRows.skip(1).toList();
    if (dataRows.length > _maxRows) {
      throw Exception(
        'File has ${dataRows.length} rows — maximum allowed is $_maxRows.',
      );
    }

    // Fetch existing roll numbers from Supabase for this section
    final existingRolls = await _fetchExistingRolls(section.id);

    for (var i = 0; i < dataRows.length; i++) {
      final rowNumber = i + 2;
      final row = dataRows[i];

      final fullName = _cell(row, columnMap, 'fullName');
      final rollNo = _cell(row, columnMap, 'rollNo');
      final enrollId = _cell(row, columnMap, 'enrollmentId');

      if (fullName.isEmpty && rollNo.isEmpty && enrollId.isEmpty) {
        continue;
      }

      final nameError = _validateName(fullName);
      if (nameError != null) {
        errors.add(ImportRowError(rowNumber, nameError));
        continue;
      }

      final rollError = _validateRollNo(rollNo);
      if (rollError != null) {
        errors.add(ImportRowError(rowNumber, rollError));
        continue;
      }

      final enrollError = _validateEnrollment(enrollId);
      if (enrollError != null) {
        errors.add(ImportRowError(rowNumber, enrollError));
        continue;
      }

      if (seenRolls.contains(rollNo)) {
        errors.add(ImportRowError(
          rowNumber,
          'Duplicate roll number "$rollNo" already appears earlier in the file.',
        ));
        continue;
      }
      if (seenEnrolls.contains(enrollId)) {
        errors.add(ImportRowError(
          rowNumber,
          'Duplicate enrollment ID "$enrollId" already appears earlier in the file.',
        ));
        continue;
      }

      if (existingRolls.contains(rollNo)) {
        errors.add(ImportRowError(
          rowNumber,
          'Roll number "$rollNo" already exists in this section.',
        ));
        continue;
      }

      seenRolls.add(rollNo);
      seenEnrolls.add(enrollId);

      validRows.add(ImportRow(
        rowNumber: rowNumber,
        fullName: fullName,
        rollNo: rollNo,
        enrollmentId: enrollId,
      ));
    }

    return ImportResult(
      totalRows: dataRows.length,
      validRows: validRows,
      errors: errors,
    );
  }

  /// Inserts all valid rows in a single Supabase batch call.
  /// Then bumps the section counter via RPC.
  Future<int> executeImport({
    required List<ImportRow> rows,
    required Section section,
  }) async {
    if (rows.isEmpty) return 0;
    if (rows.length > _maxRows) {
      throw Exception('Too many rows in a single import.');
    }

    final payload = rows
        .map((r) => {
              'full_name': r.fullName,
              'roll_no': r.rollNo,
              'enrollment_id': r.enrollmentId,
              'department_id': section.departmentId,
              'section_id': section.id,
              'year': section.year,
              'is_active': true,
            })
        .toList();

    // Batch insert (one network round-trip)
    await _client.from('students').insert(payload);

    // Increment section counter by the number inserted
    await _client.rpc('increment_section_students', params: {
      'p_section_id': section.id,
      'p_delta': rows.length,
    });

    return rows.length;
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  List<List<String>> _parseFile(Uint8List bytes, String? ext) {
    final extension = (ext ?? '').toLowerCase();
    if (extension == 'csv') {
      return _parseCsv(bytes);
    } else if (extension == 'xlsx' || extension == 'xls') {
      return _parseExcel(bytes);
    }
    throw Exception('Unsupported file type: .$extension');
  }

  List<List<String>> _parseCsv(Uint8List bytes) {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }
    final parsed = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(text);

    return parsed
        .map<List<String>>((row) =>
            row.map<String>((c) => c.toString().trim()).toList())
        .toList();
  }

  List<List<String>> _parseExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    final firstSheetName = excel.tables.keys.first;
    final sheet = excel.tables[firstSheetName];
    if (sheet == null) return [];

    final result = <List<String>>[];
    for (final row in sheet.rows) {
      final stringRow = <String>[];
      for (final cell in row) {
        stringRow.add(_extractCellText(cell));
      }
      result.add(stringRow);
    }
    return result;
  }

  String _extractCellText(Data? cell) {
    if (cell == null) return '';
    final v = cell.value;
    if (v == null) return '';

    if (v is TextCellValue) {
      return (v.value.text ?? '').trim();
    }
    if (v is IntCellValue) {
      return v.value.toString().trim();
    }
    if (v is DoubleCellValue) {
      final d = v.value;
      if (d == d.roundToDouble()) {
        return d.toInt().toString().trim();
      }
      return d.toString().trim();
    }
    if (v is BoolCellValue) {
      return v.value.toString().trim();
    }
    if (v is FormulaCellValue) {
      return v.formula.trim();
    }
    return v.toString().trim();
  }

  Map<int, String> _mapHeaders(List<String> headers) {
    final map = <int, String>{};
    for (var i = 0; i < headers.length; i++) {
      final raw = headers[i].trim().toLowerCase();
      final canonical = _headerAliases[raw];
      if (canonical != null && !map.values.contains(canonical)) {
        map[i] = canonical;
      }
    }
    return map;
  }

  String _cell(List<String> row, Map<int, String> columnMap, String field) {
    for (final entry in columnMap.entries) {
      if (entry.value == field && entry.key < row.length) {
        return row[entry.key].trim();
      }
    }
    return '';
  }

  Future<Set<String>> _fetchExistingRolls(String sectionId) async {
    final rows = await _client
        .from('students')
        .select('roll_no')
        .eq('section_id', sectionId)
        .eq('is_active', true);

    return (rows as List)
        .map((r) => (r['roll_no'] as String? ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  String? _validateName(String value) {
    if (value.isEmpty) return 'Full name is empty.';
    if (value.length < _minNameLength) return 'Full name is too short.';
    if (value.length > _maxNameLength) return 'Full name is too long.';
    if (!RegExp(r"^[A-Za-z][A-Za-z .'\-]*$").hasMatch(value)) {
      return 'Full name contains invalid characters.';
    }
    return null;
  }

  String? _validateRollNo(String value) {
    if (value.isEmpty) return 'Roll number is empty.';
    if (value.length > _maxFieldLength) return 'Roll number is too long.';
    if (!RegExp(r'^[A-Za-z0-9\-/]+$').hasMatch(value)) {
      return 'Roll number can only contain letters, digits, hyphens, and slashes.';
    }
    return null;
  }

  String? _validateEnrollment(String value) {
    if (value.isEmpty) return 'Enrollment ID is empty.';
    if (value.length > _maxFieldLength) return 'Enrollment ID is too long.';
    if (!RegExp(r'^[A-Za-z0-9\-/]+$').hasMatch(value)) {
      return 'Enrollment ID can only contain letters, digits, hyphens, and slashes.';
    }
    return null;
  }
}