import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../services/model/mensaje.dart';

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
    return Scaffold(
      appBar: ScreenHeader(
        title: 'sus_mensajes'.tr(),
        trailing: TextButton(
          onPressed: _markAllRead,
          child: Text('todo_leido'.tr()),
        ),
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
          if (snapshot.requireData.isEmpty) {
            return const BrandEmptyState(messageKey: 'no_resultados');
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(ignoreCache: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.requireData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final message = snapshot.requireData[index];
                return MessageRow(
                  message: message,
                  onTap: () => _markRead(message),
                );
              },
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
