import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('userName') ?? '';
      _imagePath = prefs.getString('profileImagePath');
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 1200);
    if (x != null) {
      setState(() => _imagePath = x.path);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameCtrl.text.trim());
    if (_imagePath != null) await prefs.setString('profileImagePath', _imagePath!);
    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!')),
      );
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history', '[]');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Histórico limpo.')),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final photo = _imagePath != null && File(_imagePath!).existsSync()
        ? CircleAvatar(
            radius: 44,
            backgroundImage: FileImage(File(_imagePath!)),
          )
        : CircleAvatar(
            radius: 44,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Icon(Icons.person, size: 44, color: theme.colorScheme.primary),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: photo),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Alterar foto'),
            ),
          ),
          const SizedBox(height: 12),
          Text('Seu nome', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'Digite seu nome',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(_saving ? 'Salvando...' : 'Salvar alterações'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Ferramentas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Limpar histórico de análises'),
            onTap: _clearHistory,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Idioma'),
            subtitle: const Text('Português (Brasil)'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre'),
            subtitle: const Text('PlantGuard Vision v1.0.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
