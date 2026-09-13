import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

/// Shows a bottom popup menu with Excel / PNG export options.
/// Returns the chosen format, or null if cancelled.
Future<String?> showExportMenu(BuildContext context) async {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Export attendance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('Excel (.xlsx)'),
            subtitle: const Text('Styled spreadsheets, per student'),
            onTap: () => Navigator.pop(ctx, 'excel'),
          ),
          ListTile(
            leading: const Icon(Icons.image, color: Colors.orange),
            title: const Text('PNG (.png)'),
            subtitle: const Text('Report card images, per student'),
            onTap: () => Navigator.pop(ctx, 'png'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Runs an export future with a blocking progress dialog.
/// On success, downloads the file via FileSaver.
Future<void> runExport({
  required BuildContext context,
  required Future<Uint8List> Function() build,
  required String fileName,
}) async {
  // Show blocking progress dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ExportProgressDialog(),
  );

  try {
    final bytes = await build();

    if (!context.mounted) return;
    Navigator.pop(context); // close progress

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: 'zip',
      mimeType: MimeType.zip,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export ready ✅')),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context); // close progress
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export failed: ${e.toString()}'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}

class _ExportProgressDialog extends StatelessWidget {
  const _ExportProgressDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: const [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Generating exports...')),
          ],
        ),
      ),
    );
  }
}