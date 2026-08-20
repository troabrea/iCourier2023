import 'package:url_launcher/url_launcher.dart';

import 'survey_prompt_coordinator.dart';

/// Opens survey links and records successful handoffs to the browser.
final class SurveyLauncher {
  SurveyLauncher({
    required SurveyPromptStore store,
    Future<bool> Function(Uri uri)? launch,
  })  : _store = store,
        _launch = launch ?? _launchExternal;

  final SurveyPromptStore _store;
  final Future<bool> Function(Uri uri) _launch;

  /// Opens [invitation] and marks it handled only when the browser accepts it.
  Future<bool> open(SurveyInvitation invitation) async {
    final opened = await _launch(invitation.uri);
    if (opened) {
      await _store.markAnswered(invitation.uri.toString());
    }
    return opened;
  }

  static Future<bool> _launchExternal(Uri uri) => launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
}
