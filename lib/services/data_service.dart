import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import '../providers/transaction_provider.dart';
import '../providers/receivable_provider.dart';

class DataService {
  
  static Future<void> exportData(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactions = prefs.getString('transactions') ?? '[]';
      final receivables = prefs.getString('receivables') ?? '[]';

      // Create Archive
      final archive = Archive();
      archive.addFile(ArchiveFile('transactions.json', transactions.length, utf8.encode(transactions)));
      archive.addFile(ArchiveFile('receivables.json', receivables.length, utf8.encode(receivables)));

      // Encode Zip
      final zipEncoder = ZipEncoder();
      final encodedZip = zipEncoder.encode(archive);

      if (encodedZip == null) return;

      // Save/Share
      final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: Open "Save As" dialog
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar copia de seguridad',
          fileName: 'backup_abarrotes_tito_$dateStr.zip',
          type: FileType.any,
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(encodedZip);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Guardado en: $outputFile'), backgroundColor: Colors.green),
            );
          }
        }
      } else {
        // Mobile: Share (allows "Save to Files")
        // Save to temporary file first
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/backup_abarrotes_tito_$dateStr.zip';
        final file = File(filePath);
        await file.writeAsBytes(encodedZip);
        
        await Share.shareXFiles(
          [XFile(filePath)], 
          text: 'Copia de seguridad Abarrotes Tito',
          subject: 'Copia de seguridad ${DateTime.now().toString().split(' ')[0]}',
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  static Future<void> importData(BuildContext context) async {
    try {
      // Pick File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        
        // Decode Zip
        final archive = ZipDecoder().decodeBytes(bytes);
        
        String? transactionsJson;
        String? receivablesJson;

        for (final file in archive) {
          if (file.name == 'transactions.json') {
            transactionsJson = utf8.decode(file.content as List<int>);
          } else if (file.name == 'receivables.json') {
            receivablesJson = utf8.decode(file.content as List<int>);
          }
        }

        if (transactionsJson != null || receivablesJson != null) {
          // Confirm overwrite
          bool? confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('¿Restaurar datos?', style: TextStyle(color: Colors.white)),
              content: const Text(
                'Esto SOBRESCRIBIRÁ los datos actuales con los del archivo de respaldo. ¿Estás seguro?',
                style: TextStyle(color: Colors.grey),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('RESTAURAR', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final prefs = await SharedPreferences.getInstance();
            if (transactionsJson != null) await prefs.setString('transactions', transactionsJson);
            if (receivablesJson != null) await prefs.setString('receivables', receivablesJson);

            // Reload Providers
            if (context.mounted) {
              await Provider.of<TransactionProvider>(context, listen: false).loadData();
              await Provider.of<ReceivableProvider>(context, listen: false).loadData();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos restaurados correctamente'), backgroundColor: Colors.green),
              );
            }
          }
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivo de respaldo no válido'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al importar: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
