import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name); 
    await prefs.setBool('onboarded', true);  

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pushReplacementNamed('/app'); 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primary.withOpacity(0.16),
        theme.colorScheme.tertiary.withOpacity(0.14),
        theme.colorScheme.surface,
      ],
    );

    Widget _brand() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.spa_rounded, size: 32, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Text(
            'Plant Guard Vision',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    Widget _heroCard() {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.tertiary.withOpacity(0.10),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.18),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Bem-vindo(a)!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Antes de começar, diga como podemos chamar você.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
                height: 1.3,
              ),
            ),
          ],
        ),
      );
    }

    Widget _nameForm() {
      return Form(
        key: _formKey,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Seu nome', style: theme.textTheme.labelLarge),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Digite seu nome',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
              ),
              validator: (value) {
                final v = (value ?? '').trim();
                if (v.isEmpty) return 'Digite seu nome para continuar.';
                if (v.length < 2) return 'Nome muito curto.';
                return null;
              },
              onFieldSubmitted: (_) => _finish(),
            ),
          ],
        ),
      );
    }

    Widget _cta() {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(_saving ? 'Salvando...' : 'Começar'),
          ),
          onPressed: _saving ? null : _finish,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520), // melhor em tablets/desktop
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _brand(),
                    const SizedBox(height: 24),
                    _heroCard(),
                    const SizedBox(height: 24),
                    _nameForm(),
                    const Spacer(),
                    _cta(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
