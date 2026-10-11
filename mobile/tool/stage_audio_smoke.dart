import 'dart:io';
import 'package:flutter/material.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_audio.dart';

/// Native media-engine check; plays both music tracks and all combat effects.
void main() {
  runApp(const MaterialApp(
      home: Scaffold(body: Center(child: Text('Audio check')))));
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final output = NativeStageAudioOutput();
    try {
      await output.music('battle', paused: false);
      await Future<void>.delayed(const Duration(seconds: 1));
      await output.music('battle', paused: true);
      await output.music('battle', paused: false);
      await output.music('boss', paused: false);
      for (final sound in BattleSound.values) {
        await output.effect(sound);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      await output.music(null, paused: false);
      await output.dispose();
      stdout.writeln('FOCUSQUEST_NATIVE_AUDIO_OK');
      exit(0);
    } catch (error, stack) {
      stderr.writeln('FOCUSQUEST_NATIVE_AUDIO_FAILED: $error\n$stack');
      exit(1);
    }
  });
}
