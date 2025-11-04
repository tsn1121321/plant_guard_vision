import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameCtrl = TextEditingController();
  String? _imagePath;
  bool _saving = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1200,
    );
    if (x != null) {
      setState(() => _imagePath = x.path);
    }
  }

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite seu nome para continuar.')),
      );
      return;
    }

    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    if (_imagePath != null) {
      await prefs.setString('profileImagePath', _imagePath!);
    }
    await prefs.setBool('onboarded', true);

    if (!mounted) return;
    setState(() => _saving = false);

    Navigator.of(context).pushReplacementNamed('/app');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.colorScheme.primary.withOpacity(0.12),
        theme.colorScheme.tertiary.withOpacity(0.10),
        theme.colorScheme.surface,
      ],
    );

    final avatar = _imagePath != null && File(_imagePath!).existsSync()
        ? CircleAvatar(radius: 44, backgroundImage: FileImage(File(_imagePath!)))
        : CircleAvatar(
            radius: 44,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Icon(Icons.person, size: 44, color: theme.colorScheme.primary),
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'Bem-vindo(a) ao PlantGuard Vision',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Antes de começarmos, personalize sua experiência.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // foto de perfil + botão alterar
                avatar,
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Adicionar foto (opcional)'),
                ),
                const SizedBox(height: 20),

                //campo nome
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Seu nome', style: theme.textTheme.labelLarge),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Digite seu nome',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                  ),
                  onSubmitted: (_) => _finish(),
                ),
                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(_saving ? 'Salvando...' : 'Começar'),
                    ),
                    onPressed: _saving ? null : _finish,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
