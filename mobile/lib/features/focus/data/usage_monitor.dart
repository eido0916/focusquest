import 'package:flutter/services.dart';
import '../domain/focus_session.dart';

class UsageEvidence {
  const UsageEvidence({required this.available, required this.targetUsed});
  final bool available;
  final bool targetUsed;
}

class InstalledApp {
  const InstalledApp(this.package, this.name);
  final String package;
  final String name;
}

class UsageMonitor {
  static const _channel = MethodChannel('dev.focusquest/usage');
  Future<bool> hasAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasAccess') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> requestAccess() => _channel.invokeMethod<void>('requestAccess');
  Future<List<InstalledApp>> apps() async {
    final apps = await _channel.invokeListMethod<dynamic>('apps') ?? [];
    return apps
        .map((e) => InstalledApp(e['package'] as String, e['name'] as String))
        .toList();
  }

  Future<UsageEvidence> evidence(FocusSession session, DateTime now) async {
    try {
      final data = await _channel.invokeMapMethod<String, dynamic>('evidence', {
        'start': session.startedAt.millisecondsSinceEpoch,
        'end': (now.isBefore(session.endsAt) ? now : session.endsAt)
            .millisecondsSinceEpoch,
        'packages': session.targetPackages,
      });
      return UsageEvidence(
          available: data?['available'] == true,
          targetUsed: data?['targetUsed'] == true);
    } on PlatformException {
      return const UsageEvidence(available: false, targetUsed: false);
    } on MissingPluginException {
      return const UsageEvidence(available: false, targetUsed: false);
    }
  }
}
