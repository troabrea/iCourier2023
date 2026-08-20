import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../design_system/overlay_components.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../services/model/mensaje.dart';
import '../surveys/survey_launcher.dart';
import '../surveys/survey_prompt_coordinator.dart';
import '../surveys/survey_prompt_cue.dart';
import '../theme/brand_tokens.dart';

class MensajesUsuario extends StatefulWidget {
  const MensajesUsuario({
    super.key,
    this.openSurvey,
  });

  final Future<bool> Function(SurveyInvitation invitation)? openSurvey;

  @override
  State<MensajesUsuario> createState() => _MensajesUsuarioState();
}

class _MensajesUsuarioState extends State<MensajesUsuario> {
  late Future<_NotificationCenterData> _data;
  bool _isOpeningSurvey = false;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'sus_mensajes'.tr(),
        onBack: context.popOrHome,
      ),
      body: FutureBuilder<_NotificationCenterData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return BrandErrorState(onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const BrandSkeleton();
          }
          final data = snapshot.requireData;
          if (data.messages.isEmpty && data.survey == null) {
            return const BrandEmptyState(
              messageKey: 'no_resultados',
              glyph: BrandIcons.information,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(ignoreCache: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                BrandSpace.lg,
                BrandSpace.md,
                BrandSpace.lg,
                BrandTabBar.height,
              ),
              children: [
                if (data.survey case final survey?)
                  SurveyNotificationAction(
                    onOpen: () => _openSurvey(survey),
                  ),
                for (final message in data.messages)
                  MessageRow(
                    message: message,
                    onTap: () => _open(message),
                  ),
                if (data.messages.isNotEmpty) ...[
                  const SizedBox(height: BrandSpace.xs),
                  BrandOutlineButton(
                    label: 'todo_leido'.tr(),
                    pill: true,
                    verticalPadding: 12,
                    onPressed: _markAllRead,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _reload({bool ignoreCache = false}) {
    setState(() {
      _data = _loadData(ignoreCache: ignoreCache);
    });
  }

  Future<_NotificationCenterData> _loadData({bool ignoreCache = false}) async {
    final service = GetIt.I<CourierService>();
    final survey = _loadSurvey(service, ignoreCache: ignoreCache);
    final messages = await service.getMensajes(ignoreCache: ignoreCache);
    return _NotificationCenterData(
      messages: messages,
      survey: await survey,
    );
  }

  Future<SurveyInvitation?> _loadSurvey(
    CourierService service, {
    required bool ignoreCache,
  }) async {
    try {
      final company = await service.getEmpresa(ignoreCache: ignoreCache);
      return SurveyInvitation.activeFor(company, DateTime.now());
    } on Exception catch (error) {
      debugPrint('Notification center survey check failed: $error');
      return null;
    }
  }

  Future<void> _openSurvey(SurveyInvitation invitation) async {
    if (_isOpeningSurvey) {
      return;
    }
    _isOpeningSurvey = true;
    var opened = false;
    try {
      final customOpen = widget.openSurvey;
      if (customOpen != null) {
        opened = await customOpen(invitation);
      } else {
        final preferences = await SharedPreferences.getInstance();
        opened = await SurveyLauncher(
          store: SharedPreferencesSurveyPromptStore(preferences),
        ).open(invitation);
      }
    } on Exception catch (error) {
      debugPrint('Notification center survey launch failed: $error');
    } finally {
      _isOpeningSurvey = false;
    }
    if (opened || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('encuesta_no_abierta'.tr())),
    );
  }

  /// Opens the message and marks it read, which also clears the bell badge.
  Future<void> _open(Mensaje message) async {
    await _markRead(message);
    if (!mounted) {
      return;
    }
    await showBrandSheet<void>(
      context,
      scrollable: true,
      child: _MessageSheet(message: message),
    );
  }

  Future<void> _markRead(Mensaje message) async {
    if (message.read) return;
    await GetIt.I<CourierService>().setMessagesRead([message.registroId]);
    if (!mounted) return;
    setState(() => message.read = true);
  }

  Future<void> _markAllRead() async {
    final messages = (await _data).messages;
    await GetIt.I<CourierService>().setMessagesRead(
      messages.map((message) => message.registroId).toList(growable: false),
    );
    if (!mounted) return;
    setState(() {
      for (final message in messages) {
        message.read = true;
      }
    });
  }
}

final class _NotificationCenterData {
  const _NotificationCenterData({
    required this.messages,
    required this.survey,
  });

  final List<Mensaje> messages;
  final SurveyInvitation? survey;
}

/// Reading template for a single message: no image, marks read on open.
class _MessageSheet extends StatelessWidget {
  const _MessageSheet({required this.message});

  final Mensaje message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandSheet(
      title: message.titulo,
      subtitle: DateFormat('dd-MMM-yyyy').format(message.fecha),
      maxHeightFactor: 0.8,
      children: [
        Text(
          message.contenido,
          style: tokens.body(15, height: 1.6),
        ),
      ],
    );
  }
}
