import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('history') ?? '[]';
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    setState(() => _items = list);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history', '[]');
    await _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Histórico limpo.')),
      );
    }
  }

  String _friendlyDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _items.isEmpty ? null : _clearHistory,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar histórico',
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('Nenhuma análise registrada ainda.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final it = _items[i];
                final img = it['imagePath']?.toString();
                final disease = it['name']?.toString() ?? 'Indefinido';
                final date = it['date']?.toString() ?? '';
                final conf = it['confidence']?.toString() ?? '';

                final isAlert = disease.toLowerCase() != 'saudável' &&
                    !disease.toLowerCase().contains('healthy');

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: isAlert
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A0F0E)
                          : const Color(0xFFFFEDEA))
                      : (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0E2A14)
                          : const Color(0xFFEAFBEA)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: img != null && File(img).existsSync()
                          ? Image.file(File(img), width: 64, height: 64, fit: BoxFit.cover)
                          : Container(
                              width: 64,
                              height: 64,
                              color: theme.colorScheme.surface,
                              child: Icon(Icons.image_not_supported_outlined,
                                  color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            ),
                    ),
                    title: Text(
                      disease,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${_friendlyDate(date)} ${conf.isNotEmpty ? '• conf.: $conf' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () {
                      if (img != null && File(img).existsSync()) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => _ImagePreviewPage(imagePath: img, title: disease),
                        ));
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _ImagePreviewPage extends StatelessWidget {
  final String imagePath;
  final String title;

  const _ImagePreviewPage({required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: InteractiveViewer(child: Image.file(File(imagePath)))),
    );
  }
}
