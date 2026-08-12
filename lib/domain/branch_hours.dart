import 'package:flutter/foundation.dart' show immutable;

/// Where a branch stands against the clock right now.
enum BranchOpenState { open, closingSoon, closed }

/// One continuous stretch a branch is open, over a set of weekdays.
@immutable
class BranchWindow {
  const BranchWindow({
    required this.days,
    required this.opensAt,
    required this.closesAt,
  });

  /// Weekdays the window applies to, as `DateTime.monday` … `DateTime.sunday`.
  final Set<int> days;

  /// Minutes since midnight.
  final int opensAt;
  final int closesAt;
}

/// What can be told about a branch at one point in time.
@immutable
class BranchStatus {
  const BranchStatus._({
    required this.state,
    this.closesAt,
    this.minutesToClose,
    this.opensAt,
    this.opensInDays,
    this.opensOnWeekday,
  });

  final BranchOpenState state;

  /// Minutes since midnight the current window ends, while open.
  final int? closesAt;
  final int? minutesToClose;

  /// Minutes since midnight the next window starts, while closed.
  final int? opensAt;

  /// 0 later today, 1 tomorrow, 2 or more days out.
  final int? opensInDays;

  /// Weekday of that next opening, for the 2-or-more case.
  final int? opensOnWeekday;
}

/// Opening windows read out of a branch's free-text `horario`.
///
/// The backend stores that field as prose typed by each of the 35 brands, in
/// whatever shape whoever filled the form preferred. This parser is therefore
/// deliberately unforgiving: anything it cannot resolve to an exact weekday and
/// clock reading returns null, and the card prints the raw string as before.
/// A wrong "abierto ahora" sends a customer driving to a closed counter, which
/// costs far more than never showing the badge.
@immutable
class BranchHours {
  const BranchHours._(this.windows);

  final List<BranchWindow> windows;

  /// Minutes before closing time at which the branch starts warning.
  static const int closingSoonMinutes = 60;

  /// Reads [raw], or returns null when it cannot be read without guessing.
  static BranchHours? parse(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }
    final tokens = _tokenize(raw);
    if (tokens.isEmpty) {
      return null;
    }

    final windows = <BranchWindow>[];
    var index = 0;
    while (index < tokens.length) {
      // Every clause opens with the days it covers: a clause of bare times has
      // nothing to attach them to.
      final dayEnd = tokens.indexWhere(_isTime, index);
      if (dayEnd <= index) {
        return null;
      }
      final days = _parseDays(tokens.sublist(index, dayEnd));
      if (days == null || days.isEmpty) {
        return null;
      }

      // Times run until the next clause's days begin, and a clause carries
      // exactly one pair. Three timestamps in a row means a shape this parser
      // does not understand well enough to render as a claim.
      var timeEnd = dayEnd;
      while (timeEnd < tokens.length && !_isDay(tokens[timeEnd])) {
        timeEnd++;
      }
      final times = tokens.sublist(dayEnd, timeEnd).where(_isTime).toList();
      if (times.length != 2) {
        return null;
      }
      final window = _parseWindow(days, times[0], times[1]);
      if (window == null) {
        return null;
      }
      windows.add(window);
      index = timeEnd;
    }

    return windows.isEmpty ? null : BranchHours._(windows);
  }

  /// Resolves the branch's state against [now], in the device's own timezone.
  BranchStatus? statusAt(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    final today = _windowsOn(now.weekday);

    for (final window in today) {
      if (minutes >= window.opensAt && minutes < window.closesAt) {
        final remaining = window.closesAt - minutes;
        return BranchStatus._(
          state: remaining <= closingSoonMinutes
              ? BranchOpenState.closingSoon
              : BranchOpenState.open,
          closesAt: window.closesAt,
          minutesToClose: remaining,
        );
      }
    }

    for (final window in today) {
      if (window.opensAt > minutes) {
        return BranchStatus._(
          state: BranchOpenState.closed,
          opensAt: window.opensAt,
          opensInDays: 0,
        );
      }
    }

    for (var ahead = 1; ahead <= 7; ahead++) {
      final weekday = (now.weekday - 1 + ahead) % 7 + 1;
      final upcoming = _windowsOn(weekday);
      if (upcoming.isNotEmpty) {
        return BranchStatus._(
          state: BranchOpenState.closed,
          opensAt: upcoming.first.opensAt,
          opensInDays: ahead,
          opensOnWeekday: weekday,
        );
      }
    }

    return null;
  }

  List<BranchWindow> _windowsOn(int weekday) {
    final matching = windows
        .where((window) => window.days.contains(weekday))
        .toList(growable: false)
      ..sort((first, second) => first.opensAt.compareTo(second.opensAt));
    return matching;
  }
}

// ---------------------------------------------------------------------------
// Tokenizer
// ---------------------------------------------------------------------------

const Map<String, String> _accents = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ü': 'u',
  'ñ': 'n',
};

/// Words that carry no meaning between a day and a time.
const Set<String> _filler = {
  'de',
  'del',
  'desde',
  'a',
  'al',
  'hasta',
  'the',
  'from',
  'to',
  'horario',
  'horarios',
  'hora',
  'horas',
  'atencion',
  'abierto',
  'abierta',
  'abiertos',
  'abiertas',
  'open',
  'hours',
  'los',
  'las',
  'el',
  'la',
  '-',
};

/// Joins two separate day groups: "lunes a viernes y sabados".
const Set<String> _dayJoiners = {'y', 'e', 'and'};

/// Opens a day range: "lunes a viernes", "monday to friday".
const Set<String> _rangeConnectors = {'a', 'al', 'hasta', '-', 'to', 'thru'};

/// Day names, down to the single letters brands actually store.
///
/// "L-V 9:00am a 7:00pm, S 9:00am a 4:00pm" is what the production data looks
/// like, so the one-letter forms are not an edge case, they are the common one.
/// `m` is the deliberate omission: it stands for martes and miércoles equally,
/// and a schedule that leans on it gets refused rather than guessed. Ranges do
/// not need it — the `l`-to-`v` in "L-V" covers both days without naming them.
const Map<String, int> _weekdays = {
  'lunes': DateTime.monday,
  'lun': DateTime.monday,
  'l': DateTime.monday,
  'monday': DateTime.monday,
  'mon': DateTime.monday,
  'martes': DateTime.tuesday,
  'mar': DateTime.tuesday,
  'tuesday': DateTime.tuesday,
  'tue': DateTime.tuesday,
  'miercoles': DateTime.wednesday,
  'mie': DateTime.wednesday,
  'mier': DateTime.wednesday,
  'x': DateTime.wednesday,
  'wednesday': DateTime.wednesday,
  'wed': DateTime.wednesday,
  'jueves': DateTime.thursday,
  'jue': DateTime.thursday,
  'j': DateTime.thursday,
  'thursday': DateTime.thursday,
  'thu': DateTime.thursday,
  'viernes': DateTime.friday,
  'vie': DateTime.friday,
  'v': DateTime.friday,
  'friday': DateTime.friday,
  'fri': DateTime.friday,
  'sabado': DateTime.saturday,
  'sabados': DateTime.saturday,
  'sab': DateTime.saturday,
  's': DateTime.saturday,
  'saturday': DateTime.saturday,
  'sat': DateTime.saturday,
  'domingo': DateTime.sunday,
  'domingos': DateTime.sunday,
  'dom': DateTime.sunday,
  'd': DateTime.sunday,
  'sunday': DateTime.sunday,
  'sun': DateTime.sunday,
};

/// Phrases that mean the whole week, matched on the normalized string.
final RegExp _everyDay = RegExp(
  r'\b(todos los dias|todos los d.as|toda la semana|every ?day|daily)\b',
);

final RegExp _timeToken = RegExp(r'^(\d{1,2})(?::(\d{2}))?(am|pm)?$');

/// Folds accents and case, and glues meridiems onto the digits they qualify.
///
/// The meridiem rules only fire behind a digit, so "8:00 a. m." collapses to
/// "8:00am" while "lunes a martes" and "a mediodia" are left alone.
List<String> _tokenize(String raw) {
  final buffer = StringBuffer();
  for (final rune in raw.toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    buffer.write(_accents[character] ?? character);
  }

  var value = buffer
      .toString()
      .replaceAll(RegExp('[‐-―−]'), '-')
      .replaceAllMapped(
        RegExp(r'(\d)\s*a\.?\s?m\.?(?![a-z])'),
        (match) => '${match.group(1)}am',
      )
      .replaceAllMapped(
        RegExp(r'(\d)\s*p\.?\s?m\.?(?![a-z])'),
        (match) => '${match.group(1)}pm',
      )
      .replaceAllMapped(
        RegExp(r'(\d)\s*h(?:rs?)?\b'),
        (match) => match.group(1)!,
      );

  if (_everyDay.hasMatch(value)) {
    value = value.replaceAll(_everyDay, 'lunes a domingo');
  }

  return value
      .replaceAll('-', ' - ')
      .replaceAll(RegExp('[^a-z0-9:-]'), ' ')
      .split(RegExp(r'\s+'))
      // A colon only carries meaning between digits. Hanging off a word it is
      // punctuation — "L a V: 9:00am" is a real record, and leaving the colon
      // glued to the "v" turned a weekday into an unknown token and threw the
      // whole schedule away.
      .map((token) => token.replaceAll(RegExp(r'^:+|:+$'), ''))
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}

bool _isTime(String token) => _timeToken.hasMatch(token);

bool _isDay(String token) => _weekdays.containsKey(token);

// ---------------------------------------------------------------------------
// Clause parsing
// ---------------------------------------------------------------------------

/// Reads the weekdays a clause covers, or null when a word is unrecognized.
///
/// Bailing on unknown words is the whole point: "lunes a viernes, sabados con
/// cita previa" must not quietly become "open Saturday".
Set<int>? _parseDays(List<String> tokens) {
  final days = <int>{};
  var index = 0;
  while (index < tokens.length) {
    final token = tokens[index];
    if (_filler.contains(token) || _dayJoiners.contains(token)) {
      index++;
      continue;
    }
    final start = _weekdays[token];
    if (start == null) {
      return null;
    }
    index++;

    // A range connector must be followed by another day, otherwise the "a" was
    // the filler that introduces the times and this is a single day.
    if (index + 1 < tokens.length &&
        _rangeConnectors.contains(tokens[index]) &&
        _isDay(tokens[index + 1])) {
      final end = _weekdays[tokens[index + 1]]!;
      var cursor = start;
      days.add(cursor);
      while (cursor != end) {
        cursor = cursor % 7 + 1;
        days.add(cursor);
      }
      index += 2;
      continue;
    }
    days.add(start);
  }
  return days;
}

/// Resolves a pair of timestamps into a window, or null when ambiguous.
BranchWindow? _parseWindow(Set<int> days, String rawOpen, String rawClose) {
  final open = _readTime(rawOpen);
  final close = _readTime(rawClose);
  if (open == null || close == null) {
    return null;
  }

  var opensAt = open.minutes;
  var closesAt = close.minutes;

  // A branch that opens in the morning cannot shut before it opened, so a bare
  // closing time landing earlier can only have meant the afternoon. That makes
  // "de 8:00 a 5:00" resolvable without guessing, while "8:00 a 12:00" stays
  // noon because it already reads forward. The morning guard matters: promoting
  // the close of "17:00-8:00" would invent a 17:00–20:00 day out of what is
  // simply a record someone typed backwards.
  if (!close.explicit && closesAt <= opensAt && opensAt < 12 * 60) {
    closesAt += 12 * 60;
  }
  if (closesAt <= opensAt || closesAt > 24 * 60) {
    return null;
  }
  return BranchWindow(days: days, opensAt: opensAt, closesAt: closesAt);
}

@immutable
class _Time {
  const _Time(this.minutes, {required this.explicit});

  final int minutes;

  /// Whether the source pinned the half of the day, by meridiem or by a
  /// 24-hour reading.
  final bool explicit;
}

_Time? _readTime(String token) {
  final match = _timeToken.firstMatch(token);
  if (match == null) {
    return null;
  }
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2) ?? '0');
  final meridiem = match.group(3);
  if (minute > 59 || hour > 24) {
    return null;
  }

  if (meridiem == 'am') {
    return hour > 12 ? null : _Time((hour % 12) * 60 + minute, explicit: true);
  }
  if (meridiem == 'pm') {
    return hour > 12 ? null : _Time((hour % 12 + 12) * 60 + minute, explicit: true);
  }
  if (hour > 12 || hour == 0) {
    return _Time(hour * 60 + minute, explicit: true);
  }
  return _Time(hour * 60 + minute, explicit: false);
}
