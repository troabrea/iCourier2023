/// THESIS: an assistant answer is a document, not a chat message. This screen
/// refuses the bubble thread — a right-aligned column would fold a nine-branch
/// address list into four lines each. One answer owns the full width; earlier
/// exchanges compress into a ribbon of questions above it.
/// OWN-WORLD: the app's own brand system, unchanged. `BrandTokens` colour and
/// type, `BrandCard` rows, `BrandChevron`, the parcel-scanner reveal. No font,
/// colour or radius is named here.
/// STORY: the customer asks in their own words, waits against an honest state,
/// reads a full-width answer, and taps one button to land on the screen it was
/// about. The conversation is waiting for them when they come back, and a
/// person is one tap away in the header the whole time.
/// FIRST VIEWPORT: brand header, a first-run callout pointing at the WhatsApp
/// action, a greeting by first name, four real starter questions as tappable
/// rows, composer pinned above the keyboard.
/// FORM: answer-as-document, candidate 7 of 7, seed key 7114e227.
/// FINISH: unreviewed and undocumented is unfinished; this build ends with the
/// finish review, the verdict, and DESIGN.md.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../design_system/overlay_components.dart';
import '../design_system/motion_components.dart';
import '../helpers/contact_action.dart';
import '../navigation/app_routes.dart';
import '../services/assistant_service.dart';
import '../services/courier_service.dart';
import '../services/model/asistente_model.dart';
import '../services/model/assistant_settings.dart';
import '../services/model/empresa.dart';
import '../services/model/login_model.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'assistant_avatar.dart';
import 'assistant_conversation.dart';
import 'assistant_markdown.dart';
import 'assistant_shortcuts.dart';
import 'bloc/asistente_bloc.dart';

/// Conversational assistant over the customer's own courier data.
class AsistentePage extends StatefulWidget {
  const AsistentePage({super.key});

  @override
  State<AsistentePage> createState() => _AsistentePageState();
}

class _AsistentePageState extends State<AsistentePage> {
  /// Built once the identity is known, because the conversation it resumes is
  /// only this customer's if the account it was remembered for still matches.
  AsistenteBloc? _bloc;
  final TextEditingController _composer = TextEditingController();
  final FocusNode _composerFocus = FocusNode();
  final ScrollController _document = ScrollController();
  late Future<_AssistantContext> _context;

  /// Kept so a handoff can be opened after the answer arrives, not only while
  /// the context future is in scope.
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _context = _loadContext();
  }

  @override
  void dispose() {
    _bloc?.close();
    _composer.dispose();
    _composerFocus.dispose();
    _document.dispose();
    super.dispose();
  }

  Future<_AssistantContext> _loadContext() async {
    final courier = GetIt.I<CourierService>();
    final companyRequest = courier.getEmpresa();
    final identityRequest = GetIt.I<AssistantService>().identity();
    final profileRequest = courier.getUserProfile();

    final identity = await identityRequest;
    final conversation = GetIt.I<AssistantConversation>()
      ..adoptAccount(identity.userAccount);
    _bloc ??= AsistenteBloc(GetIt.I<AssistantService>(), conversation);

    // Kept so a handoff can be opened after an answer arrives, not only while
    // this future is in scope.
    _profile = await profileRequest;

    final company = await companyRequest;
    return (
      company: company,
      identity: identity,
      profile: _profile,
      settings: AssistantSettings.parse(company.assistantSettings),
    );
  }

  /// Opens the contact channel with the workflow's summary already written.
  ///
  /// The customer still presses send. Nothing leaves the phone on their behalf.
  Future<void> _openHandoff(String summary) async {
    final uri = resolveHandoffUri(_profile, message: summary);
    if (uri == null) {
      return;
    }
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_se_pudo_abrir_enlace'.tr())),
      );
    }
  }

  void _ask(String question) {
    _bloc!.add(AssistantQuestionAsked(question));
    _composer.clear();
    _composerFocus.unfocus();
    if (_document.hasClients) {
      _document.jumpTo(0);
    }
  }

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    const allowed = {'http', 'https', 'mailto', 'tel'};
    if (uri == null || !allowed.contains(uri.scheme.toLowerCase())) {
      return;
    }
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_se_pudo_abrir_enlace'.tr())),
      );
    }
  }

  /// Clears the conversation, after asking.
  ///
  /// The turns are not stored anywhere, so this cannot be undone, and the
  /// answer on screen may be one the customer is still reading.
  Future<void> _reset() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'asistente_reiniciar'.tr(),
      message: 'asistente_reiniciar_detalle'.tr(),
      confirmLabel: 'asistente_reiniciar_accion'.tr(),
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    _bloc!.add(const AssistantConversationCleared());
    _composer.clear();
    _composerFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_AssistantContext>(
        future: _context,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _frame(
              context,
              body: BrandErrorState(
                onRetry: () => setState(() => _context = _loadContext()),
              ),
            );
          }
          if (!snapshot.hasData) {
            return _frame(context, body: const BrandSkeleton(rows: 4));
          }
          final data = snapshot.requireData;
          final assistantName = data.settings.displayName(
            GetIt.I<BrandConfig>().name,
          );
          // Every way in is hidden for a courier without the module, so this
          // only catches a restored route or a deep link. It says so plainly
          // rather than opening a composer whose questions nobody will answer.
          if (!data.company.hasAssistantModule) {
            return _frame(
              context,
              title: assistantName,
              body: const BrandEmptyState(
                messageKey: 'asistente_no_disponible',
                glyph: BrandIcons.assistant,
              ),
            );
          }
          return BlocProvider.value(
            value: _bloc!,
            child: BlocBuilder<AsistenteBloc, AsistenteState>(
              builder: (context, state) => _frame(
                context,
                title: assistantName,
                // Only offered once there is something to clear.
                trailing: state.hasConversation
                    ? _ResetAction(onReset: _reset)
                    : null,
                body: _Conversation(
                  state: state,
                  data: data,
                  composer: _composer,
                  composerFocus: _composerFocus,
                  documentScroll: _document,
                  onAsk: _ask,
                  onSelect: (index) =>
                      _bloc!.add(AssistantAnswerSelected(index)),
                  onRetry: () => _bloc!.add(const AssistantRetryRequested()),
                  onOpenLink: _openLink,
                  onHandoff: _openHandoff,
                ),
              ),
            ),
          );
        },
      );

  /// The screen's chrome, identical in every state so the header never blinks.
  Widget _frame(
    BuildContext context, {
    required Widget body,
    String? title,
    Widget? trailing,
  }) =>
      Scaffold(
        backgroundColor: context.brand.bg,
        appBar: ScreenHeader(
          title: title ?? GetIt.I<BrandConfig>().name,
          onBack: context.popOrHome,
          trailing: trailing,
        ),
        body: body,
      );
}

/// Starts the conversation over.
class _ResetAction extends StatelessWidget {
  const _ResetAction({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onReset,
        tooltip: 'asistente_reiniciar'.tr(),
        icon: Icon(
          Icons.restart_alt_rounded,
          size: 22,
          color: context.brand.onPrimary,
        ),
      );
}

/// What the screen needs from the backend before the first question.
typedef _AssistantContext = ({
  Empresa company,
  AssistantIdentity identity,
  UserProfile? profile,
  AssistantSettings settings,
});

class _Conversation extends StatelessWidget {
  const _Conversation({
    required this.state,
    required this.data,
    required this.composer,
    required this.composerFocus,
    required this.documentScroll,
    required this.onAsk,
    required this.onSelect,
    required this.onRetry,
    required this.onOpenLink,
    required this.onHandoff,
  });

  final AsistenteState state;
  final _AssistantContext data;

  final TextEditingController composer;
  final FocusNode composerFocus;
  final ScrollController documentScroll;
  final ValueChanged<String> onAsk;
  final ValueChanged<int> onSelect;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenLink;

  /// Opens the contact channel with the workflow's summary already written.
  final ValueChanged<String> onHandoff;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            if (state.turns.length > 1)
              _QuestionRibbon(
                turns: state.turns,
                selectedIndex: state.selectedIndex,
                onSelect: onSelect,
              ),
            Expanded(child: _body(context)),
            if (!state.hasSpentQuota)
              _Composer(
                controller: composer,
                focusNode: composerFocus,
                enabled: !state.isAsking,
                onSubmit: onAsk,
              ),
          ],
        ),
      );

  Widget _body(BuildContext context) {
    if (state.isAsking) {
      if (state.hasStreamingAnswer) {
        return _StreamingDocument(
          question: state.pendingQuestion!,
          answer: state.streamingAnswer,
          avatarSvg: data.settings.avatarSvg,
          assistantName: data.settings.displayName(GetIt.I<BrandConfig>().name),
          scrollController: documentScroll,
          onOpenLink: onOpenLink,
        );
      }
      return _Thinking(
        question: state.pendingQuestion!,
        statusCode: state.streamingStatus,
        avatarSvg: data.settings.avatarSvg,
        assistantName: data.settings.displayName(GetIt.I<BrandConfig>().name),
      );
    }
    if (state.quotaScope case final scope?) {
      return _QuotaUnavailable(
        // The scope is deliberately not presented: allowances belong to the
        // courier's commercial agreement, not to the customer's experience.
        key: ValueKey(scope),
        onOpenWhatsApp:
            data.profile?.whatsappSucursal.trim().isNotEmpty ?? false
                ? () => onHandoff(
                      'asistente_ayuda_whatsapp_mensaje'.tr(
                        args: [data.identity.userAccount],
                      ),
                    )
                : null,
        onOpenFaq: data.company.hasPreguntas
            ? () => openAssistantShortcut(context, AppRoutes.faq)
            : null,
      );
    }
    if (state.failure != null) {
      return _Failure(failure: state.failure!, onRetry: onRetry);
    }
    final turn = state.selected;
    if (turn == null) {
      return _Welcome(
        firstName: data.identity.firstName,
        company: data.company,
        assistantName: data.settings.displayName(GetIt.I<BrandConfig>().name),
        avatarSvg: data.settings.avatarSvg,
        onAsk: onAsk,
      );
    }
    return _Document(
      key: ValueKey(state.selectedIndex),
      turn: turn,
      reveal: state.justAnswered,
      shortcuts: AssistantShortcuts.resolve(
        question: turn.question,
        answer: turn.answer,
        source: turn.reply.source,
        available: _availableRoutes(data.company),
      ),
      scrollController: documentScroll,
      onOpenLink: onOpenLink,
      // A handoff cannot be offered to an account with nowhere to send it.
      onHandoff: resolveHandoffUri(data.profile) == null ? null : onHandoff,
    );
  }

  /// Routes this brand and this session can actually open.
  ///
  /// A brand that never enabled pre-alerts must not be offered a button into
  /// them, so entitlement is resolved here rather than being assumed by the
  /// keyword table.
  static Set<String> _availableRoutes(Empresa company) {
    final capabilities = GetIt.I<BrandConfig>().capabilities.resolve(company);
    return {
      AppRoutes.receptions,
      AppRoutes.branches,
      AppRoutes.services,
      AppRoutes.tracking,
      AppRoutes.calculator,
      AppRoutes.invoices,
      AppRoutes.accountStatement,
      AppRoutes.history,
      if (capabilities.prealerts) AppRoutes.prealert,
      if (company.hasPreguntas) AppRoutes.faq,
    };
  }
}

/// The growing answer, visually attributed to the assistant until it closes.
class _StreamingDocument extends StatelessWidget {
  const _StreamingDocument({
    required this.question,
    required this.answer,
    required this.avatarSvg,
    required this.assistantName,
    required this.scrollController,
    required this.onOpenLink,
  });

  final String question;
  final String answer;
  final String avatarSvg;
  final String assistantName;
  final ScrollController scrollController;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return ListView(
      key: const ValueKey('assistant-streaming-document'),
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        BrandSpace.lg,
        BrandSpace.lg,
        BrandSpace.lg,
        BrandSpace.xl,
      ),
      children: [
        Text(question, style: tokens.head(18, height: 1.3)),
        const SizedBox(height: BrandSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AssistantAvatar(
              avatarSvg: avatarSvg,
              semanticLabel: assistantName,
              // Configured artwork carries its own frame, so it is given the
              // room the tinted circle used to take.
              size: avatarSvg.isEmpty ? 32 : 40,
              backgroundColor: tokens.accentWash(tokens.primary),
              padding: 4,
            ),
            const SizedBox(width: BrandSpace.sm),
            Expanded(
              child: SelectionArea(
                child: AssistantAnswer(
                  markdown: answer,
                  onOpenLink: onOpenLink,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The answer on screen, at full brand width.
class _Document extends StatelessWidget {
  const _Document({
    super.key,
    required this.turn,
    required this.shortcuts,
    required this.reveal,
    required this.scrollController,
    required this.onOpenLink,
    required this.onHandoff,
  });

  final AssistantTurn turn;
  final List<AssistantShortcut> shortcuts;

  /// Whether this answer has just arrived, and so earns the arrival reveal.
  final bool reveal;

  final ScrollController scrollController;
  final ValueChanged<String> onOpenLink;

  /// Opens the contact channel with the reply's summary, or null when this
  /// account has no channel to hand the conversation to.
  final ValueChanged<String>? onHandoff;

  /// Whether this answer ends in a person rather than in a screen.
  bool get offersHandoff => turn.reply.hasHandoff && onHandoff != null;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final document = ListView(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        BrandSpace.lg,
        BrandSpace.lg,
        BrandSpace.lg,
        BrandSpace.xl,
      ),
      children: [
        Text(
          turn.question,
          style: tokens.head(18, height: 1.3),
        ),
        const SizedBox(height: BrandSpace.md),
        // Branch addresses and account codes are things customers copy out.
        SelectionArea(
          child: AssistantAnswer(
            markdown: turn.answer,
            onOpenLink: onOpenLink,
          ),
        ),
        // Ahead of the shortcuts: when the workflow says this needs a person,
        // no screen in the app is the answer.
        if (turn.reply.hasHandoff && onHandoff != null) ...[
          const SizedBox(height: BrandSpace.xl),
          _HumanHandoff(
            onTap: () => onHandoff!(turn.reply.summary),
          ),
        ],
        if (shortcuts.isNotEmpty) ...[
          const SizedBox(height: BrandSpace.xl),
          for (var index = 0; index < shortcuts.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              // The first destination is the answer's own next step; a
              // second one is an alternative, never a second primary action.
              // With a handoff above, every destination steps down: the person
              // is the primary action and nothing else may compete with it.
              child: index == 0 && !offersHandoff
                  ? BrandPrimaryButton(
                      label: shortcuts[index].labelKey.tr(),
                      onPressed: () => openAssistantShortcut(
                          context, shortcuts[index].route),
                    )
                  : BrandOutlineButton(
                      label: shortcuts[index].labelKey.tr(),
                      onPressed: () => openAssistantShortcut(
                          context, shortcuts[index].route),
                    ),
            ),
        ],
        const SizedBox(height: BrandSpace.md),
        const _AnswerProvenance(messageKey: 'asistente_procedencia'),
      ],
    );
    return reveal ? BrandManifestReveal(child: document) : document;
  }
}

/// Sends the customer to the screen an answer pointed at.
///
/// A tab root lives inside the navigation shell, so pushing it stacks the shell
/// on top of itself and the navigator raises duplicate page keys — a red screen,
/// not a navigation glitch. Those destinations switch branches instead, which
/// also closes the assistant: the customer asked to be taken there, not to keep
/// the conversation open behind it. Every other destination is a stacked screen
/// and pushes normally, so the back button returns to the answer.
///
/// Exposed for testing; the guard is the whole reason this is not a `push`.
void openAssistantShortcut(BuildContext context, String route) {
  if (GetIt.I<BrandConfig>().navigation.isTabRoot(route)) {
    context.go(route);
    return;
  }
  context.push(route);
}

/// Offers the conversation to a person, carrying what was already said.
///
/// The workflow decides this, not the app: it knows when its own tools came up
/// empty and when the customer asked for someone. The summary travels with the
/// tap so the customer does not retype their problem into WhatsApp.
class _HumanHandoff extends StatelessWidget {
  const _HumanHandoff({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      color: tokens.surfaceAlt,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'asistente_humano_card_titulo'.tr(),
            style: tokens.body(14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'asistente_humano_traspaso'.tr(),
            style: tokens.body(
              12,
              color: tokens.readableMuted(tokens.surfaceAlt),
              height: 1.4,
            ),
          ),
          const SizedBox(height: BrandSpace.sm),
          BrandPrimaryButton(
            label: 'asistente_humano_escribir'.tr(),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

/// Says who writes the answers.
///
/// Branch hours and shipping costs read as app fact once they are set in the
/// app's own type. They are not: they are written by a language model over the
/// company's data. The line is quiet because it rides under every correct
/// answer, and a warning band would cry wolf on all of them.
class _AnswerProvenance extends StatelessWidget {
  const _AnswerProvenance({required this.messageKey});

  /// Before the first question the line says what the assistant will do; under
  /// an answer it says what the text above it is.
  final String messageKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final muted = tokens.readableMuted(tokens.bg);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.info_outline_rounded, size: 14, color: muted),
        ),
        const SizedBox(width: BrandSpace.xs),
        Expanded(
          child: Text(
            messageKey.tr(),
            style: tokens.body(12, color: muted, height: 1.4),
          ),
        ),
      ],
    );
  }
}

/// First run: who is asking, and four questions worth asking.
class _Welcome extends StatelessWidget {
  const _Welcome({
    required this.firstName,
    required this.company,
    required this.assistantName,
    required this.avatarSvg,
    required this.onAsk,
  });

  final String firstName;
  final Empresa company;
  final String assistantName;
  final String avatarSvg;
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final starters = <String>[
      'asistente_sugerencia_paquetes'.tr(),
      'asistente_sugerencia_sucursales'.tr(),
      'asistente_sugerencia_costo'.tr(),
      'asistente_sugerencia_servicios'.tr(),
    ];
    // Centred rather than top-aligned: before the first question this block is
    // the whole screen, and pinning it to the top leaves a third of the phone
    // empty above the composer.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          BrandSpace.lg,
          BrandSpace.xl,
          BrandSpace.lg,
          BrandSpace.xl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // Clamped: with the tip above it and the keyboard below, the space
            // left can be smaller than the padding, and a negative minimum
            // asserts instead of scrolling.
            minHeight: math.max(0, constraints.maxHeight - BrandSpace.xl * 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BrandManifestReveal(
                child: Column(
                  children: [
                    AssistantAvatarEntrance(
                      rotate: true,
                      delay: const Duration(milliseconds: 280),
                      duration: const Duration(milliseconds: 650),
                      child: Hero(
                        tag: AssistantAvatar.heroTag,
                        child: AssistantAvatar(
                          avatarSvg: avatarSvg,
                          semanticLabel: assistantName,
                          size: avatarSvg.isEmpty ? 96 : 128,
                          backgroundColor: tokens.accentWash(tokens.primary),
                          padding: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: BrandSpace.sm),
                    Text(
                      firstName.isEmpty
                          ? 'asistente_saludo_generico'.tr()
                          : 'asistente_saludo'.tr(args: [firstName]),
                      textAlign: TextAlign.center,
                      style: tokens.head(20, height: 1.25),
                    ),
                    const SizedBox(height: BrandSpace.xxs),
                    Text.rich(
                      key: const ValueKey('assistant-introduction'),
                      TextSpan(
                        children: [
                          TextSpan(text: '${'asistente_soy'.tr()} '),
                          TextSpan(
                            text: assistantName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ', ${'asistente_intro'.tr()}'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: tokens.body(
                        13,
                        color: tokens.readableMuted(tokens.bg),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BrandSpace.lg),
              for (var index = 0; index < starters.length; index++)
                BrandManifestReveal(
                  delay: brandManifestDelay(index, startMilliseconds: 45),
                  child: BrandCard(
                    onTap: () => onAsk(starters[index]),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            starters[index],
                            style: tokens.body(14, weight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: BrandSpace.xs),
                        // Tapping asks the question rather than opening a screen, so
                        // this repeats the composer's send mark instead of a chevron.
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 18,
                          color: tokens.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: BrandSpace.xs),
              const _AnswerProvenance(
                messageKey: 'asistente_procedencia_inicio',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The wait, told honestly.
///
/// Measured answers run from three to twenty-two seconds, so the question and
/// assistant stay on screen from the first instant. Past ten seconds the screen
/// says so rather than letting the customer wonder whether the app is stuck.
class _Thinking extends StatefulWidget {
  const _Thinking({
    required this.question,
    required this.statusCode,
    required this.avatarSvg,
    required this.assistantName,
  });

  final String question;
  final String statusCode;
  final String avatarSvg;
  final String assistantName;

  /// When the wait stops being ordinary and the screen admits it.
  static const Duration slow = Duration(seconds: 10);

  @override
  State<_Thinking> createState() => _ThinkingState();
}

class _ThinkingState extends State<_Thinking> {
  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _slowTimer = Timer(_Thinking.slow, () {
      if (mounted) {
        setState(() => _slow = true);
      }
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final statusMessage =
        (_slow ? 'asistente_tardando' : _statusMessageKey).tr();
    return Semantics(
      liveRegion: true,
      label: statusMessage,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          BrandSpace.lg,
          BrandSpace.lg,
          BrandSpace.lg,
          BrandSpace.xl,
        ),
        children: [
          Text(widget.question, style: tokens.head(18, height: 1.3)),
          const SizedBox(height: BrandSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AssistantAvatarEntrance(
                duration: const Duration(milliseconds: 360),
                peakScale: 1.08,
                child: AssistantAvatar(
                  avatarSvg: widget.avatarSvg,
                  semanticLabel: widget.assistantName,
                  size: widget.avatarSvg.isEmpty ? 32 : 40,
                  backgroundColor: tokens.accentWash(tokens.primary),
                  padding: 4,
                ),
              ),
              const SizedBox(width: BrandSpace.sm),
              Expanded(
                child: AnimatedSwitcher(
                  duration: MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
                  child: Text(
                    statusMessage,
                    key: ValueKey(statusMessage),
                    style: tokens.body(
                      15,
                      weight: FontWeight.w600,
                      color: tokens.readableMuted(tokens.bg),
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _statusMessageKey => switch (widget.statusCode) {
        'checking_packages' => 'asistente_estado_paquetes',
        'checking_branches' => 'asistente_estado_sucursales',
        'calculating_shipping' => 'asistente_estado_calculando',
        _ => 'asistente_preparando',
      };
}

/// The question could not be answered, and what to do about it.
class _Failure extends StatelessWidget {
  const _Failure({required this.failure, required this.onRetry});

  final AssistantFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (failure == AssistantFailure.signedOut) {
      return BrandEmptyState(
        messageKey: 'asistente_sesion_terminada',
        glyph: BrandIcons.user,
        actionLabel: 'iniciar_sesion'.tr(),
        onAction: () => context.go(AppRoutes.login),
      );
    }
    return BrandErrorState(
      onRetry: onRetry,
      messageKey: 'asistente_sin_respuesta',
    );
  }
}

/// Offers human and published help without exposing commercial allowances.
class _QuotaUnavailable extends StatelessWidget {
  const _QuotaUnavailable({
    super.key,
    this.onOpenWhatsApp,
    this.onOpenFaq,
  });

  final VoidCallback? onOpenWhatsApp;
  final VoidCallback? onOpenFaq;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSpace.lg,
          vertical: 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandGlyphTile(
              asset: BrandIcons.assistant,
              size: 74,
              glyphSize: 40,
              shape: BoxShape.circle,
            ),
            const SizedBox(height: BrandSpace.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                'asistente_no_puedo_responder_ahora'.tr(),
                textAlign: TextAlign.center,
                style: tokens.body(
                  13,
                  color: tokens.readableMuted(tokens.bg),
                  height: 1.45,
                ),
              ),
            ),
            if (onOpenWhatsApp != null || onOpenFaq != null) ...[
              const SizedBox(height: BrandSpace.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onOpenWhatsApp != null)
                      BrandPrimaryButton(
                        label: 'asistente_humano_escribir'.tr(),
                        onPressed: onOpenWhatsApp,
                      ),
                    if (onOpenWhatsApp != null && onOpenFaq != null)
                      const SizedBox(height: BrandSpace.sm),
                    if (onOpenFaq != null)
                      BrandOutlineButton(
                        label: 'asistente_ir_faq'.tr(),
                        onPressed: onOpenFaq,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Earlier questions, newest last, as a one-line index of the conversation.
class _QuestionRibbon extends StatefulWidget {
  const _QuestionRibbon({
    required this.turns,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<AssistantTurn> turns;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  State<_QuestionRibbon> createState() => _QuestionRibbonState();
}

class _QuestionRibbonState extends State<_QuestionRibbon> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    // The ribbon is built for the first time on the second answer, so its
    // newest pill would otherwise start life off the right edge.
    _revealNewest(animate: false);
  }

  @override
  void didUpdateWidget(_QuestionRibbon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.turns.length != oldWidget.turns.length) {
      _revealNewest(animate: true);
    }
  }

  void _revealNewest({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) {
        return;
      }
      final end = _controller.position.maxScrollExtent;
      if (animate) {
        _controller.animateTo(
          end,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        _controller.jumpTo(end);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: SizedBox(
        height: 56,
        // A pill scrolled past the edge would otherwise end flush at x=0,
        // mid-word, which reads as broken layout instead of as more to see.
        child: ShaderMask(
          shaderCallback: _fadeEdges.createShader,
          blendMode: BlendMode.dstIn,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: BrandSpace.lg,
              vertical: BrandSpace.xs,
            ),
            itemCount: widget.turns.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: BrandSpace.xs),
            itemBuilder: (context, index) {
              final selected = index == widget.selectedIndex;
              final background = selected ? tokens.primary : tokens.surfaceAlt;
              return Semantics(
                selected: selected,
                button: true,
                child: InkWell(
                  onTap: () => widget.onSelect(index),
                  borderRadius: BorderRadius.circular(BrandShape.pill),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 220),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(BrandShape.pill),
                      border: Border.all(
                        color: selected ? background : tokens.border,
                      ),
                    ),
                    child: Text(
                      widget.turns[index].question,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tokens.body(
                        13,
                        weight: FontWeight.w600,
                        color: selected
                            ? tokens.onAccent(background)
                            : tokens.text,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Fades the ribbon's two edges so a pill scrolled past them dissolves instead
/// of being cut. Opacity only: the colours never reach the screen.
const _fadeEdges = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  stops: [0, 0.045, 0.955, 1],
  colors: [
    Color(0x00000000),
    Color(0xff000000),
    Color(0xff000000),
    Color(0x00000000),
  ],
);

/// Where the next question is written.
class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onSubmit;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final ready = widget.enabled && widget.controller.text.trim().isNotEmpty;
    final sendBackground = ready ? tokens.primary : tokens.surfaceAlt;
    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BrandSpace.lg,
            BrandSpace.sm,
            BrandSpace.lg,
            BrandSpace.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: tokens.body(15, height: 1.4),
                  cursorColor: tokens.primary,
                  onSubmitted: ready ? widget.onSubmit : null,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    // `surface`, not `surfaceAlt`: the muted hint clears 4.5:1
                    // against it in the light palette, and does not there.
                    fillColor: tokens.surface,
                    hintText: 'asistente_placeholder'.tr(),
                    hintStyle: tokens.body(15, color: tokens.textMuted),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide(color: tokens.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide(color: tokens.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide(color: tokens.primary),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide(color: tokens.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: BrandSpace.xs),
              Semantics(
                button: true,
                enabled: ready,
                label: 'asistente_enviar'.tr(),
                child: InkWell(
                  onTap: ready
                      ? () => widget.onSubmit(widget.controller.text)
                      : null,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sendBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 22,
                      color: ready
                          ? tokens.onAccent(sendBackground)
                          : tokens.textMuted,
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
}
