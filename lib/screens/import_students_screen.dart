import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/section.dart';
import '../services/student_import_service.dart';

class ImportStudentsScreen extends StatefulWidget {
  final Section section;

  const ImportStudentsScreen({super.key, required this.section});

  @override
  State<ImportStudentsScreen> createState() => _ImportStudentsScreenState();
}

class _ImportStudentsScreenState extends State<ImportStudentsScreen> {
  final _service = StudentImportService();

  PlatformFile? _file;
  ImportResult? _result;
  bool _isParsing = false;
  bool _isImporting = false;
  String? _errorMessage;

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
      _result = null;
      _file = null;
    });

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    setState(() {
      _file = file;
      _isParsing = true;
    });

    try {
      final result = await _service.parseAndValidate(
        file: file,
        section: widget.section,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _isParsing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isParsing = false;
      });
    }
  }

  Future<void> _confirmImport() async {
    final result = _result;
    if (result == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Import'),
        content: Text(
          'You are about to import ${result.validCount} students '
          'into section ${widget.section.id}.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isImporting = true);

    try {
      final count = await _service.executeImport(
        rows: result.validRows,
        section: widget.section,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count students imported ✅')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Students'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              _buildErrorBanner(_errorMessage!),
              const SizedBox(height: 16),
            ],
            if (_isParsing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_result == null)
              _buildPickFile()
            else
              _buildPreview(_result!),
            const SizedBox(height: 24),
            if (_result != null && !_result!.hasErrors) ...[
              ElevatedButton.icon(
                onPressed: _isImporting ? null : _confirmImport,
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  _isImporting
                      ? 'Importing...'
                      : 'Import ${_result!.validCount} Students',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _isImporting ? null : _pickFile,
                child: const Text('Choose a different file'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Section: ${widget.section.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your file must have columns named:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text('• fullName'),
            const Text('• rollNo'),
            const Text('• enrollmentId'),
            const SizedBox(height: 8),
            const Text(
              'Column order does not matter. Extra columns are ignored.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickFile() {
    return Column(
      children: [
        const Icon(Icons.upload_file, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'Select an Excel (.xlsx) or CSV file',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open),
          label: const Text('Select File'),
        ),
      ],
    );
  }

  Widget _buildPreview(ImportResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'File: ${_file?.name ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                label: 'Total rows',
                value: '${result.totalRows}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                label: 'Valid',
                value: '${result.validCount}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                label: 'Errors',
                value: '${result.errorCount}',
                color: result.errorCount > 0 ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (result.hasErrors) ...[
          const Text(
            'Errors — fix these and re-upload:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: result.errors.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = result.errors[i];
                return ListTile(
                  dense: true,
                  leading: Text('Row ${e.rowNumber}'),
                  title: Text(e.message),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (result.validCount > 0) ...[
            const Text(
              'Note: NO students will be imported because the file has errors.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ] else ...[
          const Text(
            'Preview (first 5 valid rows):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: result.validRows
                  .take(5)
                  .map(
                    (r) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.person),
                      title: Text(r.fullName),
                      subtitle: Text('${r.rollNo} • ${r.enrollmentId}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}