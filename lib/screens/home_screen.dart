import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _serverUrl = 'http://10.0.2.2:5050/analyze';

  final ImagePicker _picker = ImagePicker();
  bool _picking = false;
  bool _sending = false;
  File? _imageFile;
  String? _userName;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'usuário';
    });
  }

  Future<void> _pickFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2400,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _result = null;
        });
      } else {
        debugPrint('Seleção cancelada pelo usuário.');
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir a imagem.')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  //envio de imagem para o servidor
  Future<void> _analyzeImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma imagem primeiro.')),
      );
      return;
    }
    if (_sending) return;

    setState(() {
      _sending = true;
      _result = null;
    });

    try {
      final uri = Uri.parse(_serverUrl);
      final req = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            _imageFile!.path,
            contentType: MediaType('image', _guessImageSubtype(_imageFile!.path)),
          ),
        );

      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = _safeJson(resp.body);
        setState(() {
          _result = data;
        });
      } else {
        debugPrint('HTTP ${resp.statusCode}: ${resp.body}');
        _showError('Erro HTTP ${resp.statusCode}');
      }
    } on TimeoutException {
      _showError('Tempo esgotado. Verifique sua conexão.');
    } catch (e) {
      _showError('Falha ao enviar imagem: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  //tipo de imagens suportadas
  String _guessImageSubtype(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'png';
    if (p.endsWith('.webp')) return 'webp';
    if (p.endsWith('.heic') || p.endsWith('.heif')) return 'heic';
    return 'jpeg';
  }

  Map<String, dynamic> _safeJson(String body) {
    try {
      if (body.trim().isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'raw': decoded};
    } catch (_) {
      return <String, dynamic>{'raw': body};
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  //UI
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = 'Olá, ${_userName ?? "usuário"}! 🌱';

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.colorScheme.primary.withOpacity(0.12),
        theme.colorScheme.tertiary.withOpacity(0.10),
        theme.colorScheme.surface,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('PlantGuard'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text(
                  'Use a câmera ou escolha uma imagem da galeria\ne analise a saúde da sua planta.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OpenContainer(
                  closedElevation: 0,
                  closedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  closedColor: theme.colorScheme.surface.withOpacity(0.9),
                  openColor: theme.colorScheme.surface,
                  transitionType: ContainerTransitionType.fadeThrough,
                  closedBuilder: (BuildContext context, VoidCallback open) {
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : Container(
                                color: theme.colorScheme.surface,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 72,
                                  color: theme.colorScheme.onSurface.withOpacity(0.35),
                                ),
                              ),
                      ),
                    );
                  },
                  openBuilder: (BuildContext context, VoidCallback _) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Pré-visualização')),
                      body: Center(
                        child: _imageFile != null
                            ? InteractiveViewer(child: Image.file(_imageFile!))
                            : const Text('Nenhuma imagem selecionada'),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(),

              //botões inferiores
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  children: [
                    _PrimaryButton(
                      icon: Icons.photo_library_outlined,
                      label: _picking ? 'Abrindo galeria...' : 'Galeria',
                      onPressed: _picking ? null : _pickFromGallery,
                    ),
                    const SizedBox(height: 10),
                    _PrimaryButton(
                      icon: Icons.photo_camera_outlined,
                      label: _picking ? 'Abrindo câmera...' : 'Câmera',
                      onPressed: _picking ? null : _pickFromCamera,
                    ),
                    const SizedBox(height: 10),
                    _PrimaryButton(
                      icon: Icons.biotech_outlined,
                      label: _sending ? 'Analisando...' : 'Analisar imagem',
                      onPressed:
                          (_imageFile == null || _sending || _picking) ? null : _analyzeImage,
                    ),
                  ],
                ),
              ),

              //resultado
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _result == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _ResultCard(data: _result!),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(label),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ResultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final disease = data['disease'] ??
        data['doenca'] ??
        data['diagnosis'] ??
        'Resultado indisponível';

    final causes = (data['cause'] ?? data['causas'] ?? data['causes'] ?? '').toString();
    final treatment = (data['treatment'] ?? data['tratamento'] ?? '').toString();
    final tips = (data['tips'] ?? data['dicas'] ?? '').toString();

    final isAlert = disease.toString().toLowerCase() != 'saudável' &&
        !disease.toString().toLowerCase().contains('healthy');

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isAlert
          ? (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A0F0E)
              : const Color(0xFFFFEDEA))
          : (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0E2A14)
              : const Color(0xFFEAFBEA)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DefaultTextStyle.merge(
          style: theme.textTheme.bodyMedium!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAlert ? '⚠️ Possível doença detectada' : '✅ Sem sinais aparentes',
                style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Doença: ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: disease.toString()),
                  ],
                ),
              ),
              if (causes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Causas: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: causes),
                    ],
                  ),
                ),
              ],
              if (treatment.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Tratamento: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: treatment),
                    ],
                  ),
                ),
              ],
              if (tips.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Dicas: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: tips),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
