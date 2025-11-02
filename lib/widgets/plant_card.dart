import 'package:flutter/material.dart';

class PlantCard extends StatelessWidget {
  final String plantName;
  final String status;
  final String confidence;
  final String? imageUrl;
  final VoidCallback onTap;

  const PlantCard({
    super.key,
    required this.plantName,
    required this.status,
    required this.confidence,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHealthy = status.toLowerCase().contains("saud");
    final color = isHealthy
        ? theme.colorScheme.primary
        : theme.colorScheme.error.withOpacity(0.9);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.secondaryContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.15),
              offset: const Offset(2, 4),
              blurRadius: 8,
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            //capa (placeholder)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Container(
                height: 110,
                width: 110,
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                child: Icon(
                  Icons.local_florist_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plantName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          isHealthy
                              ? Icons.eco_rounded
                              : Icons.warning_amber_rounded,
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Precisão: $confidence",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
