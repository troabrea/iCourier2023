import 'package:flutter/foundation.dart';

import '../navigation/app_routes.dart';

/// A screen the current answer is about.
///
/// The assistant advises; it never acts for the customer. A shortcut therefore
/// only ever opens an existing screen — no pickup notice, no delivery request,
/// no payment is triggered from an answer.
@immutable
final class AssistantShortcut {
  const AssistantShortcut({required this.labelKey, required this.route});

  /// Translation key for the button label.
  final String labelKey;

  /// Canonical location from [AppRoutes].
  final String route;

  @override
  bool operator ==(Object other) =>
      other is AssistantShortcut &&
      other.labelKey == labelKey &&
      other.route == route;

  @override
  int get hashCode => Object.hash(labelKey, route);
}

/// Matches an exchange to the screens it talks about.
///
/// The webhook answers in prose and knows nothing about this app's navigation,
/// so the match is made here, on the customer's own words plus the answer text.
/// Keeping it local means the workflow never has to learn a route table, and a
/// brand that does not ship a module simply never passes that route in
/// `available`.
abstract final class AssistantShortcuts {
  /// Most a single answer may offer. Two buttons still read as an offer; a row
  /// of five reads as a menu the customer now has to choose from.
  static const int maxShortcuts = 2;

  static const List<_Rule> _rules = [
    _Rule(
      labelKey: 'asistente_ir_prealerta',
      route: AppRoutes.prealert,
      terms: ['prealerta', 'pre alerta'],
    ),
    _Rule(
      labelKey: 'asistente_ir_calculadora',
      route: AppRoutes.calculator,
      // Weight is not an intent: a list of received packages names pounds on
      // every line, and offering the calculator for that is answering a
      // question nobody asked.
      terms: [
        'calculadora',
        'calcular',
        'cuanto cuesta',
        'cuanto me cuesta',
        'costo',
        'tarifa',
        'precio',
      ],
    ),
    _Rule(
      labelKey: 'asistente_ir_estado_cuenta',
      route: AppRoutes.accountStatement,
      terms: ['estado de cuenta', 'saldo', 'deuda', 'balance', 'pendiente'],
    ),
    _Rule(
      labelKey: 'asistente_ir_facturados',
      route: AppRoutes.invoices,
      terms: ['factura', 'facturado'],
    ),
    // Declared ahead of the live-package rules it supersedes: an exchange about
    // packages that already came and went belongs in the date-range search, not
    // in the current reception list or the tracker.
    _Rule(
      labelKey: 'asistente_ir_historico',
      route: AppRoutes.history,
      supersedes: {AppRoutes.receptions, AppRoutes.tracking},
      // Only an unambiguous past reference takes the live screens away. A
      // package can be "entregado" and still be this week's business, so that
      // word counts toward the score and earns the history a second button
      // beside the reception list, rather than replacing it.
      decisive: [
        'historico',
        'historica',
        'mes pasado',
        'ano pasado',
        'semana pasada',
        'ultimo mes',
        'ultimos meses',
        'meses atras',
        'meses anteriores',
        'hace un mes',
        'hace dos meses',
        'hace tres meses',
        'anteriores',
        'antiguos',
        'viejos',
        'ya retire',
        'ya recibi',
        'ya me entregaron',
        'ya me lo entregaron',
      ],
      terms: ['entregad', 'entregaron', 'anterior'],
    ),
    _Rule(
      labelKey: 'asistente_ir_rastreo',
      route: AppRoutes.tracking,
      terms: ['rastre', 'tracking', 'numero de guia'],
    ),
    _Rule(
      labelKey: 'asistente_ir_sucursales',
      route: AppRoutes.branches,
      terms: [
        'sucursal',
        'horario',
        'direccion',
        'ubicacion',
        'abierto',
        'mapa',
      ],
    ),
    _Rule(
      labelKey: 'asistente_ir_paquetes',
      route: AppRoutes.receptions,
      terms: [
        'paquete',
        'envio',
        'recepcion',
        'disponible',
        'retiro',
        'entrega',
      ],
    ),
    _Rule(
      labelKey: 'asistente_ir_servicios',
      route: AppRoutes.services,
      terms: ['servicio', 'ofrecen'],
    ),
    _Rule(
      labelKey: 'asistente_ir_faq',
      route: AppRoutes.faq,
      terms: ['pregunta frecuente', 'preguntas frecuentes', 'faq'],
    ),
  ];

  /// Returns at most [maxShortcuts] destinations for one exchange.
  ///
  /// [available] is the set of routes this brand and this session can actually
  /// open, so a module the brand never enabled can never be offered. Rules are
  /// ranked by how many of their terms the exchange used, and ties fall back to
  /// the declaration order above, which runs from the most specific intent to
  /// the most general.
  ///
  /// A rule that matched one of its decisive words also removes the routes it
  /// supersedes, so an exchange about last month's packages offers the date
  /// search instead of the current reception list, not beside it.
  static List<AssistantShortcut> resolve({
    required String question,
    required String answer,
    required Set<String> available,
  }) {
    final haystack = '${_fold(question)} ${_fold(answer)}';
    final scored = <(int rank, int score, _Rule rule)>[];
    for (var index = 0; index < _rules.length; index++) {
      final rule = _rules[index];
      if (!available.contains(rule.route)) {
        continue;
      }
      final score = rule.allTerms.where(haystack.contains).length;
      if (score > 0) {
        scored.add((index, score, rule));
      }
    }
    final superseded = <String>{
      for (final entry in scored)
        if (entry.$3.decisive.any(haystack.contains)) ...entry.$3.supersedes,
    };
    scored.removeWhere((entry) => superseded.contains(entry.$3.route));
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
    });
    return scored
        .take(maxShortcuts)
        .map(
          (entry) => AssistantShortcut(
            labelKey: entry.$3.labelKey,
            route: entry.$3.route,
          ),
        )
        .toList(growable: false);
  }

  /// Lowercases and strips the accents Spanish keyboards make optional.
  ///
  /// Customers type "direccion" as often as "dirección", and the webhook writes
  /// the accented form back. Folding both sides means the same intent matches
  /// either way.
  static String _fold(String value) {
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      buffer.write(
          _accents[String.fromCharCode(rune)] ?? String.fromCharCode(rune));
    }
    return buffer.toString();
  }

  static const Map<String, String> _accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
}

@immutable
final class _Rule {
  const _Rule({
    required this.labelKey,
    required this.route,
    required this.terms,
    this.decisive = const [],
    this.supersedes = const {},
  });

  final String labelKey;
  final String route;

  /// Words that count toward this rule's score.
  ///
  /// Matching is `contains`, so a singular already covers its plural and no
  /// term should be a prefix of another in the same list: a duplicate pair
  /// would count twice and outrank a rule that states its idea once.
  final List<String> terms;

  /// Words that, on their own, settle what the exchange is about.
  ///
  /// They score like any other term and additionally release [supersedes].
  final List<String> decisive;

  /// Every word this rule answers to.
  List<String> get allTerms => [...decisive, ...terms];

  /// Routes this rule takes the place of when it matches.
  ///
  /// A historical answer says "paquete" as often as a live one, so scoring
  /// alone would keep offering the current reception list beside it. The two
  /// answer different questions, and offering both asks the customer to guess
  /// which one their own question was.
  final Set<String> supersedes;
}
