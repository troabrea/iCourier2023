import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';

class BrandSkeleton extends StatelessWidget {
  const BrandSkeleton({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Semantics(
        label: 'trabajando'.tr(),
        child: Container(
          height: index.isEven ? 92 : 64,
          decoration: BoxDecoration(
            color: tokens.surfaceAlt,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
        ),
      ),
    );
  }
}

class BrandEmptyState extends StatelessWidget {
  const BrandEmptyState({
    super.key,
    required this.messageKey,
    this.icon = Icons.inventory_2_outlined,
  });

  final String messageKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: tokens.textMuted),
            const SizedBox(height: 12),
            Text(
              messageKey.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class BrandErrorState extends StatelessWidget {
  const BrandErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          onTap: onRetry,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, color: tokens.danger),
                const SizedBox(width: 12),
                Flexible(child: Text('error_reintentar'.tr())),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
