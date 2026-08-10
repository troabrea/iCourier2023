import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../design_system/overlay_components.dart';
import '../services/courier_service.dart';
import '../services/model/mensaje.dart';
import '../theme/brand_tokens.dart';

class MensajesUsuario extends StatefulWidget {
  const MensajesUsuario({super.key});

  @override
  State<MensajesUsuario> createState() => _MensajesUsuarioState();
}

class _MensajesUsuarioState extends State<MensajesUsuario> {
  late Future<List<Mensaje>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = GetIt.I<CourierService>().getMensajes();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'sus_mensajes'.tr(),
        onBack: context.canPop() ? context.pop : null,
      ),
      body: FutureBuilder<List<Mensaje>>(
        future: _messages,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return BrandErrorState(onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const BrandSkeleton();
          }
          final messages = snapshot.requireData;
          if (messages.isEmpty) {
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
                for (final message in messages)
                  MessageRow(
                    message: message,
                    onTap: () => _open(message),
                  ),
                const SizedBox(height: BrandSpace.xs),
                BrandOutlineButton(
                  label: 'todo_leido'.tr(),
                  pill: true,
                  verticalPadding: 12,
                  onPressed: _markAllRead,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _reload({bool ignoreCache = false}) {
    setState(() {
      _messages =
          GetIt.I<CourierService>().getMensajes(ignoreCache: ignoreCache);
    });
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
    final messages = await _messages;
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
