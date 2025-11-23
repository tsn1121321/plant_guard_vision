import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _serverUrl = 'http://10.0.2.2:5050/analyze';

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
  Map<String, dynamic>? _lastResult;
  String? _rawText;

  String _userName = 'usuário';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('userName');
    if (!mounted) return;
    setState(() {
      _userName = (saved != null && saved.trim().isNotEmpty) ? saved.trim() : 'usuário';
    });
  }

  Color _cardColor(bool isAlert, ThemeData theme) {
    if (isAlert) {
      return theme.brightness == Brightness.dark
          ? const Color(0xFF2A0F0E)
          : const Color(0xFFFFEDEA);
    } else {
      return theme.brightness == Brightness.dark
          ? const Color(0xFF0E2A14)
          : const Color(0xFFEAFBEA);
    }
  }

  Color _accentIconColor(bool isAlert) {
    return isAlert ? Colors.redAccent : Colors.green;
  }

  Future<void> _saveToHistory(Map<String, dynamic> data) async {
    if (_imageFile == null) return;

    final disease = data['doenca'] ?? data['disease'] ?? 'Resultado indisponível';

    final confidenceRaw = data['confidence'] ?? data['score'] ?? data['prob'] ?? data['probability'] ?? '';
    final confidenceStr = confidenceRaw.toString();

    final prefs = await SharedPreferences.getInstance();

    List<dynamic> list = [];
    final raw = prefs.getString('history');
    if (raw != null && raw.isNotEmpty) {
      try {
        list = jsonDecode(raw) as List;
      } catch (_) {
        list = [];
      }
    }

    final item = {
      'imagePath': _imageFile!.path,
      'name': disease.toString(),
      'date': DateTime.now().toIso8601String(),
      'confidence': confidenceStr,
    };

    list.insert(0, item);

    await prefs.setString('history', jsonEncode(list));
  }

  Future<void> _sendImageToServer(File imageFile) async {
    setState(() {
      _sending = true;
      _lastResult = null;
      _rawText = null;
    });

    try {
      final uri = Uri.parse(_serverUrl);
      final req = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        )
        ..headers['Accept'] = 'application/json';

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final map = jsonDecode(resp.body) as Map<String, dynamic>;
        if (map['result'] != null && map['result'] is Map<String, dynamic>) {
          final resultMap = Map<String, dynamic>.from(map['result'] as Map);

          setState(() {
            _lastResult = resultMap;
          });

          await _saveToHistory(resultMap);
        } else if (map['raw'] != null) {
          setState(() {
            _rawText = map['raw'].toString();
          });
        } else {
          setState(() {
            _rawText = resp.body;
          });
        }
      } else {
        setState(() {
          _rawText = 'ERRO ${resp.statusCode}: ${resp.body}';
        });
      }
    } catch (e) {
      setState(() {
        _rawText = 'Erro ao enviar imagem: $e';
      });
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (picked != null) {
        final file = File(picked.path);
        setState(() {
          _imageFile = file;
          _lastResult = null;
          _rawText = null;
        });
        await _sendImageToServer(file);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showDetailedTips(BuildContext context, Map<String, dynamic> data) {
    final disease = (data['doenca'] ?? data['disease'] ?? '').toString().toLowerCase();
    final isHealthy = disease == 'saudável' || disease.contains('healthy');

    final List<String> extraTips = isHealthy
        ? <String>[
            'Regue moderadamente e evite encharcar o substrato.',
            'Gire o vaso quinzenalmente para crescimento uniforme.',
            'Aplique adubo orgânico leve a cada 30–45 dias.',
            'Faça inspeções semanais para detectar pragas precocemente.',
            'Mantenha boa ventilação e iluminação indireta adequada.',
          ]
        : <String>[
            'Remova folhas afetadas com tesoura higienizada (álcool 70%).',
            'Evite molhar as folhas ao regar; priorize o solo.',
            'Aumente a circulação de ar e reduza a umidade ambiente.',
            'Aplique fungicida/óleo de neem conforme rótulo e doença identificada.',
            'Isole a planta, troque parte do substrato e lave o vaso.',
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: 12 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(
                      isHealthy ? Icons.eco_rounded : Icons.local_hospital_rounded,
                      size: 48,
                      color: isHealthy ? Colors.green.shade700 : Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isHealthy
                        ? 'Cuidados para manter sua planta saudável'
                        : 'Passos práticos para tratar a doença',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  for (final tip in extraTips)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: isHealthy ? Colors.green : Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tip,
                              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.check),
                      label: const Text('Entendi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isHealthy ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard(BuildContext context) {
    final theme = Theme.of(context);

    if (_lastResult == null && _rawText != null) {
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _rawText!,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    if (_lastResult == null) return const SizedBox.shrink();

    final data = _lastResult!;
    final disease = data['doenca'] ?? data['disease'] ?? 'Resultado indisponível';
    final causes = (data['causaProvavel'] ?? data['causas'] ?? '').toString();
    final treatment = (data['tratamento'] ?? '').toString();

    final isAlert = disease.toString().toLowerCase() != 'saudável' &&
        !disease.toString().toLowerCase().contains('healthy');
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: _cardColor(isAlert, theme),
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showDetailedTips(context, data),
                  icon: const Icon(Icons.medical_information_outlined),
                  label: const Text('Ver cuidados detalhados'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _HeaderHero(BuildContext context) {
    final theme = Theme.of(context);

    final gradient = LinearGradient(
      colors: [
        Theme.of(context).colorScheme.primary.withOpacity(0.20),
        Theme.of(context).colorScheme.tertiary.withOpacity(0.18),
        Theme.of(context).colorScheme.surface.withOpacity(0.0),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.20),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.spa_rounded,
                    size: 32, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $_userName',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vamos analisar a saúde das suas plantas?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ImageDropArea(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.20),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _imageFile != null
            ? Image.file(_imageFile!, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 48, color: theme.disabledColor),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione uma imagem da galeria\nou use a câmera',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plant Guard Vision'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderHero(context),
              const SizedBox(height: 16),
              _ImageDropArea(context),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _picking || _sending ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galeria'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _picking || _sending ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Câmera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_sending) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Analisando imagem...',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildResultCard(context),
              if (_imageFile != null && _lastResult == null && _rawText == null && !_sending)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Nenhum resultado disponível.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipTip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ChipTip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.20),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
