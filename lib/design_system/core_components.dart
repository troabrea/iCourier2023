import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../domain/package_stage.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.greeting,
    required this.account,
    required this.capabilities,
    this.points,
    this.unread = 0,
    this.onMessages,
  });

  final String greeting;
  final String account;
  final BrandCapabilities capabilities;
  final num? points;
  final int unread;
  final VoidCallback? onMessages;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tokens.primary, tokens.headerGradientEnd],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(tokens.radiusLg),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: tokens.onPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: tokens.onPrimary),
                    ),
                    if (capabilities.points && points != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        points.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(color: tokens.onPrimary),
                      ),
                    ],
                  ],
                ),
              ),
              Badge.count(
                count: unread,
                isLabelVisible: unread > 0,
                child: IconButton(
                  onPressed: onMessages,
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: tokens.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: onBack == null
          ? null
          : IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
      actions: trailing == null ? null : [trailing!],
    );
  }
}

class BrandTabBar extends StatelessWidget {
  const BrandTabBar({
    super.key,
    required this.modules,
    required this.index,
    required this.onTap,
    required this.logoMark,
  });

  final List<TabModule> modules;
  final int index;
  final ValueChanged<int> onTap;
  final String logoMark;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Material(
      color: tokens.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var itemIndex = 0; itemIndex < modules.length; itemIndex++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: itemIndex == index,
                    label: _tabLabel(modules[itemIndex]),
                    child: InkResponse(
                      onTap: () => onTap(itemIndex),
                      child: Center(
                        child: _tabIcon(
                          modules[itemIndex],
                          itemIndex == index
                              ? tokens.primary
                              : tokens.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabIcon(TabModule module, Color color) {
    if (module == TabModule.home && logoMark.isNotEmpty) {
      return Image.asset(
        logoMark,
        width: 29,
        height: 29,
        color: color,
        colorBlendMode: BlendMode.srcIn,
      );
    }
    return Icon(_tabIconData(module), size: 29, color: color);
  }
}

class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final visible = actions.where((action) => action.enabled).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final action = visible[index];
        return Semantics(
          button: true,
          label: action.label,
          child: InkWell(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            onTap: action.onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border.all(color: tokens.border),
                borderRadius: BorderRadius.circular(tokens.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, color: tokens.primary),
                    const SizedBox(height: 6),
                    Text(
                      action.label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.stage,
    this.retained = false,
  });

  final PackageStage stage;
  final bool retained;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final background = retained
        ? tokens.warning
        : switch (stage) {
            PackageStage.disponible => tokens.primary,
            PackageStage.entregado => tokens.success,
            _ => tokens.surfaceAlt,
          };
    final foreground = retained ||
            stage == PackageStage.disponible ||
            stage == PackageStage.entregado
        ? _bestForeground(background, tokens)
        : tokens.text;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          retained ? 'retenido'.tr() : _stageLabel(stage).tr(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: foreground),
        ),
      ),
    );
  }
}

class MacroStepper extends StatelessWidget {
  const MacroStepper({super.key, required this.stage});

  final PackageStage stage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final activeIndex = stage == PackageStage.entregado ? 3 : stage.index;
    return Row(
      children: [
        for (var index = 0; index < 4; index++) ...[
          Expanded(
            child: Container(
              height: index == activeIndex ? 6 : 4,
              decoration: BoxDecoration(
                color:
                    index <= activeIndex ? tokens.primary : tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(tokens.radiusSm),
              ),
            ),
          ),
          if (index != 3) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class PackageCard extends StatelessWidget {
  const PackageCard({
    super.key,
    required this.package,
    this.onTap,
  });

  final Recepcion package;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = PackageStatusMapper.map(
      status: package.estatus,
      isAvailable: package.disponible,
      progress: package.progreso,
    );
    final tokens = context.brand;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      package.numeroRastreo.isEmpty
                          ? package.recepcionID
                          : package.numeroRastreo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusBadge(
                    stage: status.stage,
                    retained: package.retenido,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                package.contenido.isEmpty
                    ? package.suplidor
                    : package.contenido,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              MacroStepper(stage: status.stage),
            ],
          ),
        ),
      ),
    );
  }
}

class EventTimeline extends StatelessWidget {
  const EventTimeline({
    super.key,
    required this.events,
    required this.stage,
  });

  final List<Historia> events;
  final PackageStage stage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final accent = switch (stage) {
      PackageStage.entregado => tokens.success,
      PackageStage.disponible => tokens.primary,
      _ => tokens.textMuted,
    };
    final sorted = [...events]..sort((a, b) {
        return _safeDate(b).compareTo(_safeDate(a));
      });
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (context, index) => Divider(color: tokens.border),
      itemBuilder: (context, index) {
        final event = sorted[index];
        return DecoratedBox(
          decoration: BoxDecoration(
            color: index == 0 ? tokens.timelineGlow(accent) : null,
            borderRadius: BorderRadius.circular(tokens.radiusSm),
          ),
          child: ListTile(
            leading: Icon(Icons.circle, size: 12, color: accent),
            title: Text(
              event.nombreEstatus.isEmpty ? event.ciudad : event.nombreEstatus,
              style: index == 0
                  ? Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)
                  : null,
            ),
            subtitle: Text(event.fecha),
          ),
        );
      },
    );
  }
}

class SelectableRow extends StatelessWidget {
  const SelectableRow({
    super.key,
    required this.package,
    required this.checked,
    required this.onToggle,
  });

  final Recepcion package;
  final bool checked;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: checked,
      onChanged: package.retenido ? null : (value) => onToggle(value ?? false),
      title: Text(package.numeroRastreo),
      subtitle: Text(package.estatus),
      secondary: package.retenido
          ? Icon(Icons.lock_outline, color: context.brand.warning)
          : null,
    );
  }
}

class SelectionSummaryBar extends StatelessWidget {
  const SelectionSummaryBar({
    super.key,
    required this.count,
    required this.total,
    required this.currency,
    required this.paymentsEnabled,
    required this.onPay,
  });

  final int count;
  final double total;
  final String currency;
  final bool paymentsEnabled;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    if (count < 1 || !paymentsEnabled) {
      return const SizedBox.shrink();
    }
    return Material(
      color: context.brand.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$count · $currency ${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton(onPressed: onPay, child: Text('pagar_ahora'.tr())),
            ],
          ),
        ),
      ),
    );
  }
}

class GroupRow extends StatelessWidget {
  const GroupRow({
    super.key,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }
    return ListTile(
      onTap: onTap,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(label: Text('$count')),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

String _stageLabel(PackageStage stage) => switch (stage) {
      PackageStage.origen => 'recibido',
      PackageStage.ruta => 'en_ruta',
      PackageStage.destino => 'en_destino',
      PackageStage.disponible => 'disponibles',
      PackageStage.entregado => 'entregado',
    };

String _tabLabel(TabModule module) => switch (module) {
      TabModule.news => 'noticias'.tr(),
      TabModule.branches => 'sucursales'.tr(),
      TabModule.home => 'mi_courier'.tr(),
      TabModule.calculator => 'calculadora'.tr(),
      TabModule.more => 'informacion_adicional'.tr(),
      TabModule.services => 'servicios'.tr(),
    };

IconData _tabIconData(TabModule module) => switch (module) {
      TabModule.news => Icons.newspaper_outlined,
      TabModule.branches => Icons.location_on_outlined,
      TabModule.home => Icons.inventory_2_outlined,
      TabModule.calculator => Icons.calculate_outlined,
      TabModule.more => Icons.more_horiz,
      TabModule.services => Icons.local_shipping_outlined,
    };

Color _bestForeground(Color background, BrandTokens tokens) {
  final textRatio = _contrast(background, tokens.text);
  final surfaceRatio = _contrast(background, tokens.surface);
  return textRatio >= surfaceRatio ? tokens.text : tokens.surface;
}

double _contrast(Color first, Color second) {
  final a = first.computeLuminance() + 0.05;
  final b = second.computeLuminance() + 0.05;
  return a > b ? a / b : b / a;
}

DateTime _safeDate(Historia event) {
  try {
    return event.dateTime();
  } on FormatException {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
