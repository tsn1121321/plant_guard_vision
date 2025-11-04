import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kServerAnalyzeUrl = 'http://10.0.2.2:5050/analyze';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _picking = false;
  bool _sending = false;

  File? _imageFile;
  Map<String, dynamic>? _result;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('userName') ?? 'usuário');
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2200,
        maxHeight: 2200,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _result = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _analyze() async {
    final file = _imageFile;
    if (file == null || _sending) return;

    setState(() => _sending = true);
    try {
      final uri = Uri.parse(kServerAnalyzeUrl);
      final req = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', file.path))
        ..headers['Accept'] = 'application/json';

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        final decoded = (jsonDecode(body) as Map<String, dynamic>);
        Map<String, dynamic>? parsed;
        if (decoded['result'] is Map<String, dynamic>) {
          parsed = (decoded['result'] as Map<String, dynamic>);
        } else if (decoded['raw'] is String) {
          try {
            parsed = jsonDecode(decoded['raw'] as String) as Map<String, dynamic>;
          } catch (_) {
            parsed = {'doenca': 'Resultado indisponível'};
          }
        }
        setState(() => _result = parsed ?? {'doenca': 'Resultado indisponível'});
      } else {
        // mensagens comuns de erro
        String msg = 'Erro ${streamed.statusCode}';
        try {
          final m = jsonDecode(body) as Map<String, dynamic>;
          msg = m['error']?.toString() ?? msg;
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao analisar: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  //abre sheet com cuidados detalhados
  void _openCareSheet(Map<String, dynamic> data) {
    final disease = (data['doenca'] ??
            data['disease'] ??
            data['diagnosis'] ??
            data['resultado'] ??
            '')
        .toString();

    final causes = (data['causaProvavel'] ??
            data['causas'] ??
            data['cause'] ??
            data['causes'] ??
            '')
        .toString();

    final treatment =
        (data['tratamento'] ?? data['treatment'] ?? '').toString();

    final tips = (data['dicas'] ?? data['tips'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final healthy = _isHealthy(disease);
            final icon = healthy ? Icons.eco_rounded : Icons.medical_services;
            final iconColor = healthy ? Colors.green : Colors.redAccent;
            final title = healthy
                ? 'Como manter sua planta saudável'
                : 'Cuidados recomendados';

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(icon, color: iconColor, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!healthy) ...[
                    _bullet('Doença', disease),
                    if (causes.isNotEmpty) _bullet('Causa provável', causes),
                    if (treatment.isNotEmpty) _bullet('Tratamento', treatment),
                  ] else ...[
                    _bullet('Rotina', 'Mantenha regas regulares sem encharcar.'),
                    _bullet('Luz', 'Prefira luz indireta brilhante para a maioria das espécies.'),
                    _bullet('Folhas', 'Remova folhas secas e faça inspeções semanais.'),
                    if (tips.isNotEmpty) _bullet('Dicas', tips),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Entendi'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isHealthy(String s) {
    final x = s.toLowerCase().trim();
    return x == 'nenhuma' ||
        x == 'saudável' ||
        x.contains('sem doença') ||
        x.contains('healthy') ||
        x.contains('no disease');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bg = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.12),
            theme.colorScheme.tertiary.withOpacity(0.10),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );

    return Stack(
      children: [
        bg,
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.colorScheme.background.withOpacity(.6),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${_userName ?? 'usuário'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Vamos analisar a saúde da sua planta?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(.7),
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _imagePickerCard(theme),
                  const SizedBox(height: 16),
                  if (_imageFile != null)
                    FilledButton.icon(
                      onPressed: _sending ? null : _analyze,
                      icon: _sending
                          ? const SizedBox(
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search_rounded),
                      label: Text(_sending ? 'Analisando...' : 'Analisar imagem'),
                    ),
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    _ResultCard(
                      data: _result!,
                      onOpenCare: () => _openCareSheet(_result!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePickerCard(ThemeData theme) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: theme.colorScheme.surface.withOpacity(.95),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Icon(Icons.local_florist_rounded,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                'Selecione uma folha de perto, com boa luz.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _picking ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(_picking ? 'Abrindo...' : 'Galeria'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _picking ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Câmera'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: content),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onOpenCare;

  const _ResultCard({
    required this.data,
    required this.onOpenCare,
  });

  bool _isHealthy(String s) {
    final x = s.toLowerCase().trim();
    return x == 'nenhuma' ||
        x == 'saudável' ||
        x.contains('sem doença') ||
        x.contains('healthy') ||
        x.contains('no disease');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final planta =
        (data['planta'] ?? data['plant'] ?? data['species'] ?? '—').toString();

    final diseaseRaw = (data['doenca'] ??
            data['disease'] ??
            data['diagnosis'] ??
            data['resultado'] ??
            'Resultado indisponível')
        .toString();

    final causes = (data['causaProvavel'] ??
            data['causas'] ??
            data['cause'] ??
            data['causes'] ??
            '')
        .toString();

    final treatment =
        (data['tratamento'] ?? data['treatment'] ?? '').toString();

    final tips = (data['dicas'] ?? data['tips'] ?? '').toString();

    final healthy = _isHealthy(diseaseRaw);

    final gradient = healthy
        ? const LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final icon = healthy ? Icons.eco_rounded : Icons.warning_amber_rounded;
    final iconColor = healthy ? Colors.green : Colors.redAccent;
    final title = healthy
        ? '🌿 Sua planta está saudável!'
        : '⚠️ Possível doença detectada';
    final subtitle = healthy
        ? 'Nenhum sinal de pragas ou infecções foi encontrado.'
        : 'Veja detalhes abaixo.';

    final maxCardHeight = MediaQuery.of(context).size.height * 0.80;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxCardHeight),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onOpenCare,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.bodyMedium!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, size: 72, color: iconColor),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 24, thickness: 1),
                    _infoRow('👤 Planta', planta),
                    _infoRow('🦠 Doença', healthy ? 'Nenhuma' : diseaseRaw),
                    if (causes.trim().isNotEmpty)
                      _infoRow('📋 Causa provável', causes),
                    if (!healthy && treatment.trim().isNotEmpty)
                      _infoRow('💊 Tratamento', treatment),
                    if (tips.trim().isNotEmpty) _infoRow('💡 Dicas', tips),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onOpenCare,
                      icon: const Icon(Icons.menu_open_rounded),
                      label: const Text('Ver cuidados detalhados'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: iconColor,
                        side: BorderSide(color: iconColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
