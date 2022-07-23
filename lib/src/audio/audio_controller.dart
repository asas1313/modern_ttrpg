import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

import '../settings/settings.dart';
import 'sounds.dart';

class AudioController {
  static final _log = Logger('AudioController');

  final _musicPlayer = AudioPlayer();
  final _sfxPlayer = AudioPlayer();

  SettingsController? _settings;

  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  // Define the music playlist
  late final ConcatenatingAudioSource _musicPlaylist;

  final Random _random = Random();

  AudioController() {}

  /// Enables the [AudioController] to listen to [AppLifecycleState] events,
  /// and therefore do things like stopping playback when the game
  /// goes into the background.
  void attachLifecycleNotifier(
      ValueNotifier<AppLifecycleState> lifecycleNotifier) {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);

    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;
  }

  initialize() {
    // Define the music playlist
    _musicPlaylist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      shuffleOrder: DefaultShuffleOrder(),
      children: [
        AudioSource.uri(Uri.file("assets/music/Mr_Smith-Azul.mp3")),
        AudioSource.uri(Uri.file("assets/music/Mr_Smith-Sonorus.mp3")),
        AudioSource.uri(Uri.file("assets/music/Mr_Smith-Sunday_Solitude.mp3")),
      ],
    );

    _musicPlayer.setAudioSource(_musicPlaylist,
        initialIndex: 0, initialPosition: Duration.zero);
    _musicPlayer.setLoopMode(LoopMode.all);
    _musicPlayer.setShuffleModeEnabled(true);
  }

  /// Enables the [AudioController] to track changes to settings.
  /// Namely, when any of [SettingsController.muted],
  /// [SettingsController.musicOn] or [SettingsController.soundsOn] changes,
  /// the audio controller will act accordingly.
  void attachSettings(SettingsController settingsController) {
    if (_settings == settingsController) {
      // Already attached to this instance. Nothing to do.
      return;
    }

    // Remove handlers from the old settings controller if present
    final oldSettings = _settings;
    if (oldSettings != null) {
      oldSettings.muted.removeListener(_mutedHandler);
      oldSettings.musicOn.removeListener(_musicOnHandler);
      oldSettings.soundsOn.removeListener(_soundsOnHandler);
    }

    _settings = settingsController;

    // Add handlers to the new settings controller
    settingsController.muted.addListener(_mutedHandler);
    settingsController.musicOn.addListener(_musicOnHandler);
    settingsController.soundsOn.addListener(_soundsOnHandler);

    if (!settingsController.muted.value && settingsController.musicOn.value) {
      _startMusic();
    }
  }

  void dispose() {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    _stopAllSound();
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
  }

  /// Plays a single sound effect, defined by [type].
  ///
  /// The controller will ignore this call when the attached settings'
  /// [SettingsController.muted] is `true` or if its
  /// [SettingsController.soundsOn] is `false`.
  void playSfx(SfxType type) async {
    final muted = _settings?.muted.value ?? true;
    if (muted) {
      _log.info(() => 'Ignoring playing sound ($type) because audio is muted.');
      return;
    }
    final soundsOn = _settings?.soundsOn.value ?? false;
    if (!soundsOn) {
      _log.info(() =>
          'Ignoring playing sound ($type) because sounds are turned off.');
      return;
    }

    _log.info(() => 'Playing sound: $type');
    final options = soundTypeToFilename(type);
    final fileIndex = _random.nextInt(options.length);
    _log.info(() => '- Chosen filename: ${options[fileIndex].toString()}');
    _sfxPlayer.setUrl(soundsPrefix + options[fileIndex]);
    _sfxPlayer.play();
  }

  void _handleAppLifecycle() {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopAllSound();
        break;
      case AppLifecycleState.resumed:
        if (!_settings!.muted.value && _settings!.musicOn.value) {
          _resumeMusic();
        }
        break;
      case AppLifecycleState.inactive:
        // No need to react to this state change.
        break;
    }
  }

  void _musicOnHandler() {
    if (_settings!.musicOn.value) {
      // Music got turned on.
      if (!_settings!.muted.value) {
        _resumeMusic();
      }
    } else {
      // Music got turned off.
      _pauseMusic();
    }
  }

  void _mutedHandler() {
    if (_settings!.muted.value) {
      // All sound just got muted.
      _stopAllSound();
    } else {
      // All sound just got un-muted.
      if (_settings!.musicOn.value) {
        _resumeMusic();
      }
    }
  }

  Future<void> _resumeMusic() async {
    _log.info('Resuming music');
    _musicPlayer.seekToNext();
    _musicPlayer.play();
  }

  void _soundsOnHandler() {
    if (_sfxPlayer.playerState.playing) _sfxPlayer.stop();
  }

  void _startMusic() {
    _log.info('starting music');
    _musicPlayer.seek(Duration.zero, index: 0);
    _musicPlayer.play();
  }

  void _stopAllSound() {
    if (_musicPlayer.playerState.playing) {
      _musicPlayer.pause();
    }
    _sfxPlayer.stop();
  }

  void _pauseMusic() {
    _log.info('Pausing music');
    _musicPlayer.pause();
  }
}
