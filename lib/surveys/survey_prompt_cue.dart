import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../design_system/brand_foundations.dart';
import '../theme/brand_tokens.dart';

/// Builds the floating surface used for survey invitations.
SnackBar buildSurveyPromptSnackBar(
  BuildContext context, {
  required VoidCallback onAnswer,
  required VoidCallback onPostpone,
}) {
  final tokens = context.brand;
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 14),
    elevation: 8,
    backgroundColor: tokens.surface,
    margin: const EdgeInsets.all(BrandSpace.sm),
    padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radiusLg),
    ),
    clipBehavior: Clip.antiAlias,
    content: SurveyPromptCue(
      onAnswer: onAnswer,
      onPostpone: onPostpone,
    ),
  );
}

/// Compact, non-modal invitation shown when a survey becomes available.
final class SurveyPromptCue extends StatelessWidget {
  const SurveyPromptCue({
    super.key,
    required this.onAnswer,
    required this.onPostpone,
  });

  final VoidCallback onAnswer;
  final VoidCallback onPostpone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final accent = tokens.softAccentPair(tokens.primary);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.background,
                borderRadius: BorderRadius.circular(BrandShape.glyphTile),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 19,
                color: accent.foreground,
              ),
            ),
          ),
          const SizedBox(width: BrandSpace.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'encuesta_disponible'.tr(),
                  style: tokens.body(13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'encuesta_invitacion'.tr(),
                  style: tokens.body(
                    12,
                    color: tokens.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: BrandSpace.xs),
                Wrap(
                  spacing: BrandSpace.xs,
                  runSpacing: BrandSpace.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: onPostpone,
                      style: TextButton.styleFrom(
                        foregroundColor: tokens.textMuted,
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: tokens.body(12, weight: FontWeight.w700),
                      ),
                      child: Text('posponer_encuesta'.tr()),
                    ),
                    BrandPrimaryButton(
                      label: 'responder_encuesta'.tr(),
                      onPressed: onAnswer,
                      expand: false,
                      pill: true,
                      fontSize: 12,
                      verticalPadding: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A quiet, persistent route to the active survey from notifications.
final class SurveyNotificationAction extends StatelessWidget {
  const SurveyNotificationAction({
    super.key,
    required this.onOpen,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final accent = tokens.softAccentPair(tokens.primary);
    return Semantics(
      button: true,
      label: '${'encuesta_disponible'.tr()}. ${'abrir_encuesta'.tr()}',
      hint: 'abre_enlace_externo'.tr(),
      child: ExcludeSemantics(
        child: BrandCard(
          onTap: onOpen,
          margin: const EdgeInsets.only(bottom: BrandSpace.sm),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.background,
                  borderRadius: BorderRadius.circular(BrandShape.glyphTile),
                ),
                child: Icon(
                  Icons.poll_outlined,
                  size: 19,
                  color: accent.foreground,
                ),
              ),
              const SizedBox(width: BrandSpace.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'encuesta_disponible'.tr(),
                      style: tokens.body(13, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'abrir_encuesta'.tr(),
                          style: tokens.body(
                            12,
                            color: tokens.primary,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 14,
                          color: tokens.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
