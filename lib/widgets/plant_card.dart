import 'dart:io';
import 'package:flutter/material.dart';

class PlantCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final VoidCallback? onTap;

  const PlantCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exists = imagePath != null && File(imagePath!).existsSync();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: exists
                    ? Image.file(File(imagePath!), width: 72, height: 72, fit: BoxFit.cover)
                    : Container(
                        width: 72,
                        height: 72,
                        color: theme.colorScheme.surface,
                        child: Icon(Icons.image_outlined,
                            color: theme.colorScheme.onSurface.withOpacity(0.35)),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: theme.textTheme.bodyMedium!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
