import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final args = ModalRoute.of(context)?.settings.arguments;
    final data = (args is Map<String, dynamic>) ? args : <String, dynamic>{};

    final plant = data['plant'] ?? data['plant_name'] ?? 'Planta';
    final disease = data['disease'] ?? data['disease_name'] ?? '—';
    final status = (data['status'] ?? '').toString().toLowerCase();
    final advice = data['advice'] ?? data['care'] ?? data['treatment'] ?? '—';
    final conf = _formatConfidence(data['confidence']);

    final isHealthy = status.contains('saud') || disease.toString().toLowerCase().contains('healthy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da análise'),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.12),
              cs.tertiary.withOpacity(0.10),
              cs.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ResultHeader(
              plant: plant.toString(),
              disease: disease.toString(),
              confidence: conf,
              isHealthy: isHealthy,
            ),
            const SizedBox(height: 16),
            _AdviceCard(advice: advice.toString()),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Nova análise'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatConfidence(dynamic c) {
    if (c == null) return '—';
    try {
      final v = (c is num) ? c.toDouble() : double.parse(c.toString());
      final pct = (v <= 1.0 ? v * 100 : v).clamp(0, 100);
      return '${pct.toStringAsFixed(1)}%';
    } catch (_) {
      return c.toString();
    }
  }
}

class _ResultHeader extends StatelessWidget {
  final String plant;
  final String disease;
  final String confidence;
  final bool isHealthy;

  const _ResultHeader({
    required this.plant,
    required this.disease,
    required this.confidence,
    required this.isHealthy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isHealthy ? theme.colorScheme.primary : theme.colorScheme.error;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(isHealthy ? Icons.eco_rounded : Icons.warning_rounded, color: color),
              const SizedBox(width: 8),
              Text(
                isHealthy ? 'Sem sinais aparentes' : 'Sinais de doença',
                style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Conf.: $confidence', style: theme.textTheme.labelMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Planta: $plant', style: theme.textTheme.titleMedium),
          Text('Doença: $disease', style: theme.textTheme.bodyLarge),
        ]),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final String advice;
  const _AdviceCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(Icons.medical_services_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Cuidados & Tratamento', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(advice, style: theme.textTheme.bodyMedium),
        ]),
      ),
    );
  }
}
