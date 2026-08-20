import 'package:flutter/material.dart';

import '../domain/package_stage.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_config.dart';

class WidgetStateV1 {
  const WidgetStateV1({
    required this.brand,
    required this.session,
    required this.counts,
    required this.featured,
    required this.deepLink,
    required this.generatedAt,
    required this.staleAfter,
  });

  static const schemaVersion = 1;
  static const storageKey = 'widget_state';
  static const logoFileName = 'widget_logo.png';

  final WidgetBrandState brand;
  final WidgetSessionState session;
  final WidgetCounts counts;
  final WidgetFeaturedPackage? featured;
  final String deepLink;
  final DateTime generatedAt;
  final DateTime staleAfter;

  bool isStaleAt(DateTime now) => !now.isBefore(staleAfter);

  Map<String, dynamic> toJson() => {
        'schema': schemaVersion,
        'brand': brand.toJson(),
        'session': session.toJson(),
        'counts': counts.toJson(),
        'featured': featured?.toJson(),
        'deepLink': deepLink,
        'generatedAt': _isoTimestamp(generatedAt),
        'staleAfter': _isoTimestamp(staleAfter),
      };
}

class WidgetBrandState {
  const WidgetBrandState({
    required this.slug,
    required this.primary,
    required this.onPrimary,
    required this.surface,
    required this.text,
    required this.muted,
    required this.logoAsset,
  });

  final String slug;
  final String primary;
  final String onPrimary;
  final String surface;
  final String text;
  final String muted;
  final String logoAsset;

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'primary': primary,
        'onPrimary': onPrimary,
        'surface': surface,
        'text': text,
        'muted': muted,
        'logoAsset': logoAsset,
      };
}

class WidgetSessionState {
  const WidgetSessionState({
    required this.signedIn,
    required this.accountCode,
    required this.accountName,
  });

  final bool signedIn;
  final String accountCode;
  final String accountName;

  Map<String, dynamic> toJson() => {
        'signedIn': signedIn,
        'accountCode': accountCode,
        'accountName': accountName,
      };
}

class WidgetCounts {
  const WidgetCounts({
    required this.available,
    required this.retained,
    required this.inRoute,
    required this.inProcess,
    required this.total,
  });

  const WidgetCounts.empty()
      : available = 0,
        retained = 0,
        inRoute = 0,
        inProcess = 0,
        total = 0;

  final int available;
  final int retained;
  final int inRoute;
  final int inProcess;
  final int total;

  Map<String, dynamic> toJson() => {
        'disponible': available,
        'retenido': retained,
        'enRuta': inRoute,
        'enProceso': inProcess,
        'total': total,
      };
}

class WidgetFeaturedPackage {
  const WidgetFeaturedPackage({
    required this.id,
    required this.content,
    required this.stage,
    required this.statusLabel,
    required this.stageIndex,
    required this.stageCount,
    required this.retained,
    required this.amountUsd,
    required this.branch,
    required this.lastEvent,
  });

  final String id;
  final String content;
  final PackageStage stage;
  final String statusLabel;
  final int stageIndex;
  final int stageCount;
  final bool retained;
  final double amountUsd;
  final String? branch;
  final DateTime? lastEvent;

  Map<String, dynamic> toJson() => {
        'id': id,
        'contenido': content,
        'macro': stage.name,
        'estadoLabel': statusLabel,
        'stageIndex': stageIndex,
        'stageCount': stageCount,
        'retenido': retained,
        'montoUsd': amountUsd,
        'sucursal': branch,
        'ultimoEvento': _optionalIsoTimestamp(lastEvent),
      };
}

abstract final class WidgetSnapshotBuilder {
  static const staleDuration = Duration(hours: 4);

  static WidgetStateV1 build({
    required BrandConfig config,
    required Brightness brightness,
    required String accountCode,
    required String accountName,
    required List<Recepcion> packages,
    required DateTime generatedAt,
    String? branch,
  }) {
    final palette = brightness == Brightness.dark ? config.dark : config.light;
    final ranked = [...packages]..sort(_comparePackages);
    final featured = ranked.isEmpty ? null : ranked.first;
    final featuredStatus = featured == null
        ? null
        : PackageStatusMapper.map(
            status: featured.estatus,
            isAvailable: featured.disponible,
            progress: featured.progreso,
          );
    return WidgetStateV1(
      brand: _brand(config, palette),
      session: WidgetSessionState(
        signedIn: true,
        accountCode: accountCode,
        accountName: accountName,
      ),
      counts: _counts(packages),
      featured: featured == null
          ? null
          : WidgetFeaturedPackage(
              id: featured.recepcionID,
              content: featured.contenido,
              stage: featuredStatus!.stage,
              statusLabel: featured.estatus,
              stageIndex: _stageIndex(featuredStatus.stage),
              stageCount: 4,
              retained: featured.retenido,
              amountUsd: featured.montoTotal(),
              branch: branch,
              lastEvent: _lastEvent(featured),
            ),
      deepLink: '${config.urlScheme}://inicio',
      generatedAt: generatedAt,
      staleAfter: generatedAt.add(staleDuration),
    );
  }

  static WidgetStateV1 signedOut({
    required BrandConfig config,
    required Brightness brightness,
    required DateTime generatedAt,
  }) {
    final palette = brightness == Brightness.dark ? config.dark : config.light;
    return WidgetStateV1(
      brand: _brand(config, palette),
      session: const WidgetSessionState(
        signedIn: false,
        accountCode: '',
        accountName: '',
      ),
      counts: const WidgetCounts.empty(),
      featured: null,
      deepLink: '${config.urlScheme}://login',
      generatedAt: generatedAt,
      staleAfter: generatedAt.add(staleDuration),
    );
  }

  static WidgetBrandState _brand(
    BrandConfig config,
    BrandPalette palette,
  ) {
    return WidgetBrandState(
      slug: config.slug,
      primary: _hex(palette.primary),
      onPrimary: _hex(palette.onPrimary),
      surface: _hex(palette.surface),
      text: _hex(palette.text),
      muted: _hex(palette.textMuted),
      logoAsset: WidgetStateV1.logoFileName,
    );
  }

  static WidgetCounts _counts(List<Recepcion> packages) {
    var available = 0;
    var retained = 0;
    var inRoute = 0;
    var inProcess = 0;
    for (final package in packages) {
      final status = PackageStatusMapper.map(
        status: package.estatus,
        isAvailable: package.disponible,
        progress: package.progreso,
      );
      if (status.stage == PackageStage.disponible) {
        available++;
      } else if (package.retenido) {
        retained++;
      } else if (status.stage == PackageStage.ruta ||
          status.stage == PackageStage.destino) {
        inRoute++;
      } else if (status.stage == PackageStage.origen) {
        inProcess++;
      }
    }
    return WidgetCounts(
      available: available,
      retained: retained,
      inRoute: inRoute,
      inProcess: inProcess,
      total: packages.length,
    );
  }

  static int _comparePackages(Recepcion first, Recepcion second) {
    final priority = _priority(first).compareTo(_priority(second));
    if (priority != 0) {
      return priority;
    }
    final firstDate =
        _lastEvent(first) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final secondDate =
        _lastEvent(second) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return secondDate.compareTo(firstDate);
  }

  static int _priority(Recepcion package) {
    final status = PackageStatusMapper.map(
      status: package.estatus,
      isAvailable: package.disponible,
      progress: package.progreso,
    );
    if (status.stage == PackageStage.disponible) {
      return 0;
    }
    if (package.retenido) {
      return 1;
    }
    if (status.stage == PackageStage.ruta ||
        status.stage == PackageStage.destino) {
      return 2;
    }
    if (status.stage == PackageStage.origen) {
      return 3;
    }
    return 4;
  }

  static DateTime? _lastEvent(Recepcion package) {
    final dates = <DateTime>[];
    final receptionDate = DateTime.tryParse(package.fechaHora);
    if (receptionDate != null) {
      dates.add(receptionDate);
    }
    for (final event in package.paquetes.expand((item) => item.historia)) {
      final date = DateTime.tryParse(event.fechaHora);
      if (date != null) {
        dates.add(date);
      }
    }
    if (dates.isEmpty) {
      return null;
    }
    dates.sort();
    return dates.last;
  }

  static int _stageIndex(PackageStage stage) => switch (stage) {
        PackageStage.origen => 0,
        PackageStage.ruta => 1,
        PackageStage.destino => 2,
        PackageStage.disponible || PackageStage.entregado => 3,
      };

  static String _hex(Color color) {
    final value = color.toARGB32() & 0x00ffffff;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

/// Serializes widget dates as unambiguous UTC timestamps for both native SDKs.
String _isoTimestamp(DateTime value) => value.toUtc().toIso8601String();

String? _optionalIsoTimestamp(DateTime? value) =>
    value == null ? null : _isoTimestamp(value);
