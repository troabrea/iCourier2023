import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../design_system/brand_foundations.dart';
import '../theme/brand_tokens.dart';

/// Renders the assistant's markdown answer as a readable document.
///
/// The webhook writes ordinary markdown: paragraphs, `**bold**` labels, and
/// dashed or starred lists, which is exactly how a branch directory or a list
/// of services arrives. Only that subset is parsed. Anything unrecognised falls
/// through as its literal text rather than disappearing, because an answer the
/// customer cannot read is worse than one carrying a stray asterisk.
///
/// The full brand width is deliberate. A chat bubble would fold every address
/// in this list onto four lines.
class AssistantAnswer extends StatefulWidget {
  const AssistantAnswer({
    super.key,
    required this.markdown,
    this.onOpenLink,
  });

  final String markdown;

  /// Opens a link the answer carried. Links render as plain text when null.
  final ValueChanged<String>? onOpenLink;

  @override
  State<AssistantAnswer> createState() => _AssistantAnswerState();
}

class _AssistantAnswerState extends State<AssistantAnswer> {
  /// Tap recognisers belong to the state, not to `build`.
  ///
  /// A recogniser built inline leaks on every repaint, and an answer listing
  /// nine branches can carry a dozen of them.
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    _disposeRecognizers();
    final blocks = parseAssistantMarkdown(widget.markdown);
    final children = <Widget>[];

    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      if (index > 0) {
        children.add(SizedBox(height: _gapBefore(block, blocks[index - 1])));
      }
      children.add(_buildBlock(context, tokens, block));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Tight inside a list, generous between sections, and most above a heading.
  double _gapBefore(AssistantBlock block, AssistantBlock previous) {
    if (block.kind == AssistantBlockKind.heading) {
      return BrandSpace.md;
    }
    if (block.kind == AssistantBlockKind.listItem &&
        previous.kind == AssistantBlockKind.listItem) {
      return BrandSpace.xs;
    }
    return BrandSpace.sm;
  }

  Widget _buildBlock(
    BuildContext context,
    BrandTokens tokens,
    AssistantBlock block,
  ) {
    switch (block.kind) {
      case AssistantBlockKind.heading:
        return Text.rich(
          _spans(context, tokens, block.spans, tokens.head(16, height: 1.35)),
        );
      case AssistantBlockKind.rule:
        return Divider(color: tokens.border, height: 1, thickness: 1);
      case AssistantBlockKind.paragraph:
        return Text.rich(
          _spans(context, tokens, block.spans, tokens.body(15, height: 1.55)),
        );
      case AssistantBlockKind.listItem:
        const size = 15.0;
        const lineHeight = 1.55;
        const dot = 5.0;
        final base = tokens.body(size, height: lineHeight);
        // Centres the dot on the first line at any system text size. A fixed
        // offset drifts up the moment the customer scales type.
        final dotOffset =
            (MediaQuery.textScalerOf(context).scale(size) * lineHeight - dot) /
                2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: block.marker == null
                  ? Padding(
                      padding: EdgeInsets.only(top: dotOffset),
                      child: Container(
                        width: dot,
                        height: dot,
                        decoration: BoxDecoration(
                          color: tokens.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : Text(
                      block.marker!,
                      style: base.copyWith(
                        color: tokens.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            Expanded(
                child: Text.rich(_spans(context, tokens, block.spans, base))),
          ],
        );
    }
  }

  TapGestureRecognizer _recognizerFor(String link) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => widget.onOpenLink!(link);
    _recognizers.add(recognizer);
    return recognizer;
  }

  TextSpan _spans(
    BuildContext context,
    BrandTokens tokens,
    List<AssistantSpan> spans,
    TextStyle base,
  ) =>
      TextSpan(
        children: [
          for (final span in spans)
            if (widget.onOpenLink != null &&
                isSupportedAssistantLink(span.link))
              TextSpan(
                text: span.text,
                style: base.copyWith(
                  color: tokens.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: tokens.primary,
                ),
                recognizer: _recognizerFor(span.link!),
              )
            else
              TextSpan(
                text: span.text,
                style: base.copyWith(
                  fontWeight: span.bold ? FontWeight.w700 : null,
                  fontStyle: span.italic ? FontStyle.italic : null,
                  color: span.code ? tokens.primary : null,
                ),
              ),
        ],
      );
}

/// Whether the app can actually open [link].
///
/// An answer can name any scheme it likes. Painting an unopenable one as an
/// underlined brand-coloured control would leave a control that does nothing on
/// tap, so anything outside this list renders as ordinary text.
bool isSupportedAssistantLink(String? link) {
  if (link == null) {
    return false;
  }
  final scheme = Uri.tryParse(link)?.scheme.toLowerCase();
  return scheme != null &&
      const {'http', 'https', 'mailto', 'tel'}.contains(scheme);
}

/// The shapes the answer parser recognises.
enum AssistantBlockKind { paragraph, heading, listItem, rule }

/// One rendered block of an answer.
@immutable
final class AssistantBlock {
  const AssistantBlock({
    required this.kind,
    required this.spans,
    this.marker,
  });

  final AssistantBlockKind kind;
  final List<AssistantSpan> spans;

  /// Ordinal for a numbered item; null for a bullet or any other block.
  final String? marker;
}

/// A run of answer text sharing one emphasis.
@immutable
final class AssistantSpan {
  const AssistantSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.link,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool code;
  final String? link;
}

final _headingPattern = RegExp(r'^(#{1,6})\s+(.*)$');
final _bulletPattern = RegExp(r'^\s{0,3}[*+-]\s+(.*)$');
final _orderedPattern = RegExp(r'^\s{0,3}(\d{1,2})[.)]\s+(.*)$');
final _rulePattern = RegExp(r'^\s{0,3}([-*_])\s*\1\s*\1[\s\-*_]*$');
final _inlinePattern = RegExp(
  r'\[([^\]]+)\]\(([^)\s]+)\)'
  r'|\*\*(.+?)\*\*'
  r'|__(.+?)__'
  r'|(?<![*\w])\*(?!\s)(.+?)(?<!\s)\*(?![*\w])'
  r'|(?<![_\w])_(?!\s)(.+?)(?<!\s)_(?![_\w])'
  r'|`([^`]+)`',
  dotAll: true,
);

/// Splits an answer into the blocks [AssistantAnswer] draws.
///
/// Exposed for testing: the parser is the part of this surface most likely to
/// meet a shape the workflow author never mentioned.
List<AssistantBlock> parseAssistantMarkdown(String markdown) {
  final blocks = <AssistantBlock>[];
  final paragraph = <String>[];

  void flushParagraph() {
    if (paragraph.isEmpty) {
      return;
    }
    blocks.add(
      AssistantBlock(
        kind: AssistantBlockKind.paragraph,
        spans: parseAssistantSpans(paragraph.join(' ')),
      ),
    );
    paragraph.clear();
  }

  for (final rawLine in markdown.replaceAll('\r\n', '\n').split('\n')) {
    final line = rawLine.trimRight();
    if (line.trim().isEmpty) {
      flushParagraph();
      continue;
    }

    if (_rulePattern.hasMatch(line)) {
      flushParagraph();
      blocks.add(
        const AssistantBlock(kind: AssistantBlockKind.rule, spans: []),
      );
      continue;
    }

    final heading = _headingPattern.firstMatch(line);
    if (heading != null) {
      flushParagraph();
      blocks.add(
        AssistantBlock(
          kind: AssistantBlockKind.heading,
          spans: parseAssistantSpans(heading.group(2)!),
        ),
      );
      continue;
    }

    final ordered = _orderedPattern.firstMatch(line);
    if (ordered != null) {
      flushParagraph();
      blocks.add(
        AssistantBlock(
          kind: AssistantBlockKind.listItem,
          marker: '${ordered.group(1)}.',
          spans: parseAssistantSpans(ordered.group(2)!),
        ),
      );
      continue;
    }

    final bullet = _bulletPattern.firstMatch(line);
    if (bullet != null) {
      flushParagraph();
      blocks.add(
        AssistantBlock(
          kind: AssistantBlockKind.listItem,
          spans: parseAssistantSpans(bullet.group(1)!),
        ),
      );
      continue;
    }

    paragraph.add(line.trim());
  }

  flushParagraph();
  return blocks;
}

/// Splits one line into emphasis runs.
List<AssistantSpan> parseAssistantSpans(String line) {
  final spans = <AssistantSpan>[];
  var cursor = 0;

  for (final match in _inlinePattern.allMatches(line)) {
    if (match.start > cursor) {
      spans.add(AssistantSpan(line.substring(cursor, match.start)));
    }
    if (match.group(1) != null) {
      spans.add(AssistantSpan(match.group(1)!, link: match.group(2)));
    } else if (match.group(3) != null) {
      spans.add(AssistantSpan(match.group(3)!, bold: true));
    } else if (match.group(4) != null) {
      spans.add(AssistantSpan(match.group(4)!, bold: true));
    } else if (match.group(5) != null) {
      spans.add(AssistantSpan(match.group(5)!, italic: true));
    } else if (match.group(6) != null) {
      spans.add(AssistantSpan(match.group(6)!, italic: true));
    } else if (match.group(7) != null) {
      spans.add(AssistantSpan(match.group(7)!, code: true));
    }
    cursor = match.end;
  }

  if (cursor < line.length) {
    spans.add(AssistantSpan(line.substring(cursor)));
  }
  return spans.isEmpty ? [AssistantSpan(line)] : spans;
}
