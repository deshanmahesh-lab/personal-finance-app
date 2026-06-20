import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';

class SmsAnalyzerScreen extends ConsumerStatefulWidget {
  const SmsAnalyzerScreen({super.key});

  @override
  ConsumerState<SmsAnalyzerScreen> createState() => _SmsAnalyzerScreenState();
}

class _SmsAnalyzerScreenState extends ConsumerState<SmsAnalyzerScreen> {
  final SmsQuery _query = SmsQuery();
  List<SmsMessage> _allMessages = [];
  List<String> _uniqueSenders = [];
  String? _selectedSender;
  bool _isLoading = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetchSmsData();
  }

  Future<void> _fetchSmsData() async {
    setState(() => _isLoading = true);

    final status = await Permission.sms.request();
    if (status.isGranted) {
      final messages = await _query.querySms(kinds: [SmsQueryKind.inbox], sort: true);

      final senders = messages
          .map((m) => m.sender?.trim() ?? 'Unknown')
          .where((s) => RegExp(r'^[A-Za-z\s_-]+$').hasMatch(s))
          .toSet()
          .toList();
      senders.sort();

      setState(() {
        _allMessages = messages;
        _uniqueSenders = senders;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToTxt() async {
    if (_selectedSender == null) return;
    setState(() => _isExporting = true);

    try {
      final exportMessages = _allMessages.where((m) => m.sender == _selectedSender).take(100).toList();
      if (exportMessages.isEmpty) {
        setState(() => _isExporting = false);
        return;
      }

      StringBuffer sb = StringBuffer();
      sb.writeln("--- SMS Export for $_selectedSender ---");
      sb.writeln("Total Messages: ${exportMessages.length}\n");

      for (var msg in exportMessages) {
        sb.writeln("Date: ${msg.date}");
        sb.writeln("Body: ${msg.body}");
        sb.writeln("--------------------------------------------------");
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${_selectedSender}_sms_export.txt');
      await file.writeAsString(sb.toString());

      await Share.shareXFiles([XFile(file.path)], text: 'Developer SMS Export: $_selectedSender');

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e')));
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final filteredMessages = _allMessages.where((m) => m.sender == _selectedSender).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(AppTranslations.getText('dev_tools', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Bank / Sender',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blueGrey.shade50,
                  ),
                  value: _selectedSender,
                  items: _uniqueSenders.map((sender) {
                    return DropdownMenuItem(value: sender, child: Text(sender));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedSender = val),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (_selectedSender == null || _isExporting) ? null : _exportToTxt,
                    icon: _isExporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.file_download_rounded, color: Colors.white),
                    label: Text(_isExporting ? 'Exporting...' : 'Export 100 SMS as .txt File', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                )
              ],
            ),
          ),

          Expanded(
            child: _selectedSender == null
                ? Center(child: Text('Select a sender to view formats', style: TextStyle(color: Colors.grey.shade600)))
                : ListView.builder(
              itemCount: filteredMessages.length,
              itemBuilder: (context, index) {
                final msg = filteredMessages[index];
                final body = msg.body ?? 'No Content';
                final date = msg.date?.toString().split('.').first ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(body, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}