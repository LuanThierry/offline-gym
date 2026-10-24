import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpcaoDeAlarme {
  const OpcaoDeAlarme({
    required this.id,
    required this.title,
    required this.description,
    this.categoria = 'Clássicos',
    this.icone = Icons.music_note_rounded,
  });

  final String id;
  final String title;
  final String description;
  final String categoria;
  final IconData icone;
}

/// Níveis de intensidade de vibração e feedback tátil configuráveis pelo usuário.
enum IntensidadeTatil {
  forte,
  media,
  desativada;

  static IntensidadeTatil deString(String? valor) {
    switch (valor?.toLowerCase()) {
      case 'forte':
        return IntensidadeTatil.forte;
      case 'media':
      case 'média':
        return IntensidadeTatil.media;
      case 'desativada':
      case 'desligada':
      case 'nenhuma':
        return IntensidadeTatil.desativada;
      default:
        return IntensidadeTatil.forte;
    }
  }

  String get rotulo {
    switch (this) {
      case IntensidadeTatil.forte:
        return 'Forte';
      case IntensidadeTatil.media:
        return 'Média';
      case IntensidadeTatil.desativada:
        return 'Desativada';
    }
  }

  String get descricao {
    switch (this) {
      case IntensidadeTatil.forte:
        return 'Vibração marcante ao marcar séries e botões';
      case IntensidadeTatil.media:
        return 'Feedback tátil suave e discreto';
      case IntensidadeTatil.desativada:
        return 'Silencioso, sem vibração';
    }
  }
}

class ServicoDeSomDoAlarme with WidgetsBindingObserver {
  ServicoDeSomDoAlarme._();

  static final ServicoDeSomDoAlarme instance = ServicoDeSomDoAlarme._();

  static const String _prefKeyAlarmSound = 'alarm_sound_type';
  static const String _prefKeyAlarmVibrate = 'alarm_vibrate_enabled';
  static const String _prefKeyCountdownBeep = 'alarm_countdown_beep_enabled';
  static const String _prefKeyCustomAudioPath = 'alarm_custom_audio_path';
  static const String _prefKeyCustomAudioName = 'alarm_custom_audio_name';
  static const String _prefKeyHapticIntensity = 'alarm_haptic_intensity';

  static const List<OpcaoDeAlarme> sonsDisponiveis = <OpcaoDeAlarme>[
    // Clássicos
    OpcaoDeAlarme(
      id: 'digital',
      title: 'Beep Digital',
      description: 'Três bips rápidos e nítidos de alta frequência.',
      categoria: 'Clássicos',
      icone: Icons.alarm_rounded,
    ),
    OpcaoDeAlarme(
      id: 'classic',
      title: 'Alarme Clássico',
      description: 'Tom duplo estilo despertador eletrônico.',
      categoria: 'Clássicos',
      icone: Icons.access_time_filled_rounded,
    ),
    OpcaoDeAlarme(
      id: 'bell',
      title: 'Campainha de Academia',
      description: 'Tom de sino/gongo com reverberação suave.',
      categoria: 'Clássicos',
      icone: Icons.notifications_active_rounded,
    ),
    OpcaoDeAlarme(
      id: 'soft',
      title: 'Bip Suave',
      description: 'Tom agradável e discreto de tom médio.',
      categoria: 'Clássicos',
      icone: Icons.volume_down_rounded,
    ),
    // Esportivos & Luta
    OpcaoDeAlarme(
      id: 'boxing_gong',
      title: 'Gongo de Boxe',
      description: 'Gongo metálico ressonante de ringue e round.',
      categoria: 'Esportivos & Luta',
      icone: Icons.sports_mma_rounded,
    ),
    OpcaoDeAlarme(
      id: 'boxing_gong_double',
      title: 'Gongo Duplo de Round',
      description: 'Dois toques potentes marcando o fim do descanso.',
      categoria: 'Esportivos & Luta',
      icone: Icons.fitness_center_rounded,
    ),
    OpcaoDeAlarme(
      id: 'whistle',
      title: 'Apito de Treino',
      description: 'Apito esportivo vibrante de alta energia.',
      categoria: 'Esportivos & Luta',
      icone: Icons.sports_rounded,
    ),
    OpcaoDeAlarme(
      id: 'whistle_triple',
      title: 'Apito Triplo de Árbitro',
      description: 'Três silvos curtos e ágeis de retorno imediato.',
      categoria: 'Esportivos & Luta',
      icone: Icons.sports_score_rounded,
    ),
    OpcaoDeAlarme(
      id: 'air_horn',
      title: 'Corneta de Torcida',
      description: 'Corneta esportiva potente de celebração de estádio.',
      categoria: 'Esportivos & Luta',
      icone: Icons.campaign_rounded,
    ),
    // Sintetizadores & Neon
    OpcaoDeAlarme(
      id: 'countdown',
      title: 'Largada 3-2-1',
      description: 'Três bips de preparação e tom agudo de liberação.',
      categoria: 'Sintetizadores & Neon',
      icone: Icons.timer_outlined,
    ),
    OpcaoDeAlarme(
      id: 'pulse',
      title: 'Pulso Sci-Fi Neon',
      description: 'Onda futurista sintetizada com modulação rápida.',
      categoria: 'Sintetizadores & Neon',
      icone: Icons.waves_rounded,
    ),
    OpcaoDeAlarme(
      id: 'laser_synth',
      title: 'Laser Synth Neon',
      description: 'Sweep descendente de sintetizador futurista.',
      categoria: 'Sintetizadores & Neon',
      icone: Icons.flash_on_rounded,
    ),
    OpcaoDeAlarme(
      id: 'arcade_powerup',
      title: 'Power-Up Arcade 8-Bit',
      description: 'Arpeggio ascendente retrô celebrando sua série.',
      categoria: 'Sintetizadores & Neon',
      icone: Icons.sports_esports_rounded,
    ),
    OpcaoDeAlarme(
      id: 'sonar_ping',
      title: 'Sonar Ping Submarino',
      description: 'Pulso harmônico profundo e nítido com eco.',
      categoria: 'Sintetizadores & Neon',
      icone: Icons.radar_rounded,
    ),
    OpcaoDeAlarme(
      id: 'electro_drop',
      title: 'Sub-Bass Drop 808',
      description: 'Impacto grave eletrônico com presença forte.',
      categoria: 'Sintetizadores & Neon',
      icone: Icons.speaker_rounded,
    ),
    // Sistema & Celular
    OpcaoDeAlarme(
      id: 'system',
      title: 'Som do Sistema',
      description: 'Bip padrão audível com a vibração configurada.',
      categoria: 'Sistema & Celular',
      icone: Icons.phonelink_ring_rounded,
    ),
    OpcaoDeAlarme(
      id: 'custom',
      title: 'Música / Áudio do Celular',
      description: 'Escolha um arquivo MP3/WAV/M4A da memória do aparelho.',
      categoria: 'Sistema & Celular',
      icone: Icons.audio_file_rounded,
    ),
  ];

  AudioPlayer? _player;
  AudioPlayer? _tickPlayer;
  Uint8List? _cachedTickWav;
  final Map<String, Uint8List> _cachedSounds = <String, Uint8List>{};
  String _currentSoundId = 'digital';
  bool _vibrateEnabled = true;
  IntensidadeTatil _intensidadeTatil = IntensidadeTatil.forte;
  bool _countdownBeepEnabled = true;
  String? _customAudioPath;
  String? _customAudioName;
  bool _isPlaying = false;
  bool _isAppForeground = true;
  int _playbackGeneration = 0;
  Timer? _autoStopTimer;
  bool _initialized = false;

  String get currentSoundId => _currentSoundId;
  bool get vibrateEnabled =>
      _vibrateEnabled && _intensidadeTatil != IntensidadeTatil.desativada;
  IntensidadeTatil get intensidadeTatil => _intensidadeTatil;
  bool get countdownBeepEnabled => _countdownBeepEnabled;
  String? get customAudioPath => _customAudioPath;
  String? get customAudioName => _customAudioName;
  bool get isPlaying => _isPlaying;

  static AudioContext get audioContextConfig => AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
      );

  Future<void> inicializar() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentSoundId = prefs.getString(_prefKeyAlarmSound) ?? 'digital';
      _vibrateEnabled = prefs.getBool(_prefKeyAlarmVibrate) ?? true;
      final intSalva = prefs.getString(_prefKeyHapticIntensity);
      if (intSalva != null) {
        _intensidadeTatil = IntensidadeTatil.deString(intSalva);
      } else {
        _intensidadeTatil = _vibrateEnabled
            ? IntensidadeTatil.forte
            : IntensidadeTatil.desativada;
      }
      _countdownBeepEnabled = prefs.getBool(_prefKeyCountdownBeep) ?? true;
      _customAudioPath = prefs.getString(_prefKeyCustomAudioPath);
      _customAudioName = prefs.getString(_prefKeyCustomAudioName);

      try {
        await AudioPlayer.global.setAudioContext(audioContextConfig);
      } catch (_) {}

      _player = AudioPlayer();
      await _player?.setReleaseMode(ReleaseMode.stop);
      try {
        await _player?.setAudioContext(audioContextConfig);
      } catch (_) {}

      WidgetsBinding.instance.addObserver(this);
      _initialized = true;
    } catch (_) {
      // Falha silenciosa usando valores padrão se preferências indisponíveis
    }
  }

  Future<void> definirSom(String soundId) async {
    _currentSoundId = soundId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyAlarmSound, soundId);
    } catch (_) {}
  }

  /// Define a intensidade da resposta háptica e persiste nas preferências.
  Future<void> definirIntensidadeTatil(IntensidadeTatil novaIntensidade) async {
    _intensidadeTatil = novaIntensidade;
    _vibrateEnabled = novaIntensidade != IntensidadeTatil.desativada;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyHapticIntensity, novaIntensidade.name);
      await prefs.setBool(_prefKeyAlarmVibrate, _vibrateEnabled);
    } catch (_) {}
    vibrarImpacto();
  }

  Future<void> definirVibracao(bool enabled) async {
    _vibrateEnabled = enabled;
    _intensidadeTatil =
        enabled ? IntensidadeTatil.forte : IntensidadeTatil.desativada;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyAlarmVibrate, enabled);
      await prefs.setString(_prefKeyHapticIntensity, _intensidadeTatil.name);
    } catch (_) {}
  }

  /// Vibração para cliques, seleção de medidas e botões da interface.
  void vibrarClique() {
    switch (_intensidadeTatil) {
      case IntensidadeTatil.forte:
        unawaited(HapticFeedback.mediumImpact());
        break;
      case IntensidadeTatil.media:
        unawaited(HapticFeedback.selectionClick());
        break;
      case IntensidadeTatil.desativada:
        break;
    }
  }

  /// Vibração de impacto para séries concluídas, metas batidas e final de cronômetro.
  void vibrarImpacto() {
    switch (_intensidadeTatil) {
      case IntensidadeTatil.forte:
        unawaited(HapticFeedback.heavyImpact());
        break;
      case IntensidadeTatil.media:
        unawaited(HapticFeedback.mediumImpact());
        break;
      case IntensidadeTatil.desativada:
        break;
    }
  }

  Future<void> definirBipContagemRegressiva(bool enabled) async {
    _countdownBeepEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyCountdownBeep, enabled);
    } catch (_) {}
  }

  Future<bool> selecionarAudioPersonalizado() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'Áudio',
        extensions: <String>['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'opus'],
        mimeTypes: <String>['audio/*'],
      );
      final arquivo = await openFile(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );
      if (arquivo != null) {
        await pararAudio();
        final documents = await getApplicationDocumentsDirectory();
        final audioDirectory = Directory(p.join(documents.path, 'alarm_audio'));
        await audioDirectory.create(recursive: true);
        final extension = p.extension(arquivo.name).isEmpty
            ? '.audio'
            : p.extension(arquivo.name);
        final localFile = File(
          p.join(
            audioDirectory.path,
            'alarm_${DateTime.now().microsecondsSinceEpoch}$extension',
          ),
        );
        await localFile.writeAsBytes(await arquivo.readAsBytes(), flush: true);

        _customAudioPath = localFile.path;
        _customAudioName = arquivo.name;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeyCustomAudioPath, localFile.path);
        await prefs.setString(_prefKeyCustomAudioName, arquivo.name);
        await definirSom('custom');
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> removerAudioPersonalizado() async {
    await pararAudio();
    final oldPath = _customAudioPath;
    _customAudioPath = null;
    _customAudioName = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyCustomAudioPath);
      await prefs.remove(_prefKeyCustomAudioName);
      if (_currentSoundId == 'custom') {
        await definirSom('digital');
      }
    } catch (_) {}
    final documents = await getApplicationDocumentsDirectory();
    final managedAudioDirectory = p.join(documents.path, 'alarm_audio');
    if (oldPath != null && p.isWithin(managedAudioDirectory, oldPath)) {
      try {
        await File(oldPath).delete();
      } catch (_) {}
    }
  }

  Future<void> pararAudio() async {
    _playbackGeneration++;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _isPlaying = false;
    try {
      await _player?.stop();
    } catch (_) {
      try {
        await _player?.dispose();
      } catch (_) {}
      _player = null;
    }
  }

  @visibleForTesting
  Future<void> Function()? mockTocarAlarme;

  Future<void> tocarAlarme() async {
    if (mockTocarAlarme != null) {
      await mockTocarAlarme!();
      return;
    }
    await tocarSom(_currentSoundId);
  }

  /// Toca um bip curto de preparação (3, 2, 1) nos últimos 3 segundos do descanso.
  Future<void> tocarBipContagemRegressiva() async {
    if (!_countdownBeepEnabled) return;
    if (!_isAppForeground) return;
    if (_vibrateEnabled && _intensidadeTatil != IntensidadeTatil.desativada) {
      vibrarClique();
    }
    try {
      if (_tickPlayer == null) {
        final tick = AudioPlayer();
        await tick.setReleaseMode(ReleaseMode.stop);
        try {
          await tick.setAudioContext(audioContextConfig);
        } catch (_) {}
        _tickPlayer = tick;
      }
      final filePath = await _obterCaminhoDoTickWav();
      await _tickPlayer?.play(DeviceFileSource(filePath));
    } catch (_) {
      if (_isAppForeground) {
        unawaited(SystemSound.play(SystemSoundType.click));
      }
    }
  }

  Future<void> tocarSom(String soundId) async {
    await pararAudio();
    final requestGeneration = _playbackGeneration;
    if (!_isAppForeground) return;

    if (_vibrateEnabled && _intensidadeTatil != IntensidadeTatil.desativada) {
      vibrarImpacto();
    }

    if (soundId == 'system') {
      // O alerta nativo pode ficar mudo em alguns aparelhos. Usa o bipe digital
      // interno no mesmo reprodutor para que a opção de sistema tenha som.
      soundId = 'digital';
    }

    if (soundId == 'custom') {
      final caminho = _customAudioPath;
      if (caminho != null && File(caminho).existsSync()) {
        try {
          if (_player == null) {
            final p = AudioPlayer();
            await p.setReleaseMode(ReleaseMode.stop);
            try {
              await p.setAudioContext(audioContextConfig);
            } catch (_) {}
            _player = p;
          }
          if (requestGeneration != _playbackGeneration || !_isAppForeground) {
            return;
          }
          _isPlaying = true;
          await _player?.play(DeviceFileSource(caminho));
          if (!_isAppForeground) {
            await _player?.stop();
            return;
          }
          if (requestGeneration != _playbackGeneration) return;
          _autoStopTimer = Timer(const Duration(seconds: 5), () {
            if (requestGeneration == _playbackGeneration) {
              unawaited(pararAudio());
            }
          });
          return;
        } catch (_) {
          if (requestGeneration != _playbackGeneration) return;
          _isPlaying = false;
          try {
            await _player?.dispose();
          } catch (_) {}
          _player = null;
          if (_isAppForeground) {
            unawaited(SystemSound.play(SystemSoundType.alert));
          }
          return;
        }
      } else {
        unawaited(SystemSound.play(SystemSoundType.alert));
        return;
      }
    }

    try {
      if (_player == null) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        try {
          await p.setAudioContext(audioContextConfig);
        } catch (_) {}
        _player = p;
      }
      if (requestGeneration != _playbackGeneration || !_isAppForeground) return;
      _isPlaying = true;
      final filePath = await _obterCaminhoDoArquivoWav(soundId);
      await _player?.play(DeviceFileSource(filePath));
      if (!_isAppForeground) {
        await _player?.stop();
        return;
      }
      if (requestGeneration != _playbackGeneration) return;
      _autoStopTimer = Timer(const Duration(seconds: 5), () {
        if (requestGeneration == _playbackGeneration) unawaited(pararAudio());
      });
    } catch (_) {
      if (requestGeneration != _playbackGeneration) return;
      _isPlaying = false;
      try {
        await _player?.dispose();
      } catch (_) {}
      _player = null;
      if (_isAppForeground) {
        unawaited(SystemSound.play(SystemSoundType.alert));
      }
    }
  }

  Future<String> _obterCaminhoDoArquivoWav(String soundId) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, 'offline_gym_sound_$soundId.wav'));
    if (!file.existsSync() || file.lengthSync() == 0) {
      final wavBytes = _generateWavBytes(soundId);
      await file.writeAsBytes(wavBytes, flush: true);
    }
    return file.path;
  }

  Future<String> _obterCaminhoDoTickWav() async {
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, 'offline_gym_tick_beep.wav'));
    if (!file.existsSync() || file.lengthSync() == 0) {
      _cachedTickWav ??= _buildShortTickBeep(22050);
      await file.writeAsBytes(_cachedTickWav!, flush: true);
    }
    return file.path;
  }

  Uint8List _generateWavBytes(String soundId) {
    return _cachedSounds.putIfAbsent(soundId, () {
      const sampleRate = 22050;

      switch (soundId) {
        case 'classic':
          return _buildClassicAlarm(sampleRate);
        case 'bell':
          return _buildBell(sampleRate);
        case 'soft':
          return _buildSoftBeep(sampleRate);
        case 'boxing_gong':
          return _buildBoxingGong(sampleRate);
        case 'boxing_gong_double':
          return _buildBoxingGongDouble(sampleRate);
        case 'whistle':
          return _buildWhistle(sampleRate);
        case 'whistle_triple':
          return _buildWhistleTriple(sampleRate);
        case 'air_horn':
          return _buildAirHorn(sampleRate);
        case 'countdown':
          return _buildCountdown(sampleRate);
        case 'pulse':
          return _buildPulse(sampleRate);
        case 'laser_synth':
          return _buildLaserSynth(sampleRate);
        case 'arcade_powerup':
          return _buildArcadePowerup(sampleRate);
        case 'sonar_ping':
          return _buildSonarPing(sampleRate);
        case 'electro_drop':
          return _buildElectroDrop(sampleRate);
        case 'digital':
        default:
          return _buildDigitalBeep(sampleRate);
      }
    });
  }

  /// Gera um arquivo WAV mono de 16 bits a partir de uma lista de amostras de áudio (-1.0 a 1.0)
  Uint8List _pcmToWav(List<double> samples, int sampleRate) {
    final byteData = ByteData(44 + samples.length * 2);

    // "RIFF"
    byteData.setUint8(0, 0x52);
    byteData.setUint8(1, 0x49);
    byteData.setUint8(2, 0x46);
    byteData.setUint8(3, 0x46);

    // Tamanho total do arquivo - 8 bytes
    final fileSize = 36 + samples.length * 2;
    byteData.setUint32(4, fileSize, Endian.little);

    // "WAVE"
    byteData.setUint8(8, 0x57);
    byteData.setUint8(9, 0x41);
    byteData.setUint8(10, 0x56);
    byteData.setUint8(11, 0x45);

    // "fmt "
    byteData.setUint8(12, 0x66);
    byteData.setUint8(13, 0x6D);
    byteData.setUint8(14, 0x74);
    byteData.setUint8(15, 0x20);

    // Tamanho do subchunk fmt (16 para PCM)
    byteData.setUint32(16, 16, Endian.little);
    // Formato de áudio 1 = PCM linear
    byteData.setUint16(20, 1, Endian.little);
    // 1 canal (mono)
    byteData.setUint16(22, 1, Endian.little);
    // Taxa de amostragem
    byteData.setUint32(24, sampleRate, Endian.little);
    // Taxa de bytes: sampleRate * 1 canal * 16 bits / 8
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    // Block align (1 canal * 2 bytes por amostra)
    byteData.setUint16(32, 2, Endian.little);
    // Bits por amostra
    byteData.setUint16(34, 16, Endian.little);

    // "data"
    byteData.setUint8(36, 0x64);
    byteData.setUint8(37, 0x61);
    byteData.setUint8(38, 0x74);
    byteData.setUint8(39, 0x61);

    // Tamanho dos dados
    byteData.setUint32(40, samples.length * 2, Endian.little);

    var deslocamento = 44;
    for (var i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      final intSample = (clamped * 32767).round();
      byteData.setInt16(deslocamento, intSample, Endian.little);
      deslocamento += 2;
    }

    return byteData.buffer.asUint8List();
  }

  Uint8List _buildDigitalBeep(int sampleRate) {
    final samples = <double>[];
    const beepDuration = 0.12;
    const pauseDuration = 0.08;
    const frequency = 1400.0;

    for (var beep = 0; beep < 3; beep++) {
      final beepSamples = (beepDuration * sampleRate).round();
      for (var i = 0; i < beepSamples; i++) {
        final t = i / sampleRate;
        final env = math.sin(math.pi * (i / beepSamples));
        final val = math.sin(2 * math.pi * frequency * t) * env * 0.85;
        samples.add(val);
      }
      if (beep < 2) {
        final pauseSamples = (pauseDuration * sampleRate).round();
        for (var i = 0; i < pauseSamples; i++) {
          samples.add(0.0);
        }
      }
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildClassicAlarm(int sampleRate) {
    final samples = <double>[];
    const duracao = 0.8;
    final totalSamples = (duracao * sampleRate).round();

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final freq = (t % 0.2 < 0.1) ? 880.0 : 1046.5; // Alterna Lá5 e Dó6
      final env = (1.0 - (t / duracao)).clamp(0.0, 1.0);
      final val = (math.sin(2 * math.pi * freq * t) > 0 ? 0.6 : -0.6) * env;
      samples.add(val);
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildBell(int sampleRate) {
    final samples = <double>[];
    const duracao = 1.0;
    final totalSamples = (duracao * sampleRate).round();

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = math.exp(-3.5 * t);
      // Harmônicos de sino
      final val = (math.sin(2 * math.pi * 784.0 * t) * 0.6 +
              math.sin(2 * math.pi * 1176.0 * t) * 0.3 +
              math.sin(2 * math.pi * 1568.0 * t) * 0.1) *
          env;
      samples.add(val);
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildSoftBeep(int sampleRate) {
    final samples = <double>[];
    const duracao = 0.45;
    final totalSamples = (duracao * sampleRate).round();

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = math.sin(math.pi * (i / totalSamples));
      final val = math.sin(2 * math.pi * 659.25 * t) * env * 0.7; // Mi5
      samples.add(val);
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildBoxingGong(int sampleRate) {
    final samples = <double>[];
    const duracao = 1.6;
    final totalSamples = (duracao * sampleRate).round();

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = math.exp(-2.2 * t);
      final val = (math.sin(2 * math.pi * 260.0 * t) * 0.5 +
              math.sin(2 * math.pi * 520.0 * t) * 0.3 +
              math.sin(2 * math.pi * 780.0 * t) * 0.15 +
              math.sin(2 * math.pi * 315.0 * t) * 0.1) *
          env;
      samples.add(val);
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildWhistle(int sampleRate) {
    final samples = <double>[];
    const duracao = 0.42;
    final totalSamples = (duracao * sampleRate).round();

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final env = progress < 0.1
          ? (progress / 0.1)
          : (progress > 0.85 ? (1.0 - progress) / 0.15 : 1.0);
      final flutter = 1.0 + 0.25 * math.sin(2 * math.pi * 28.0 * t);
      final val = (math.sin(2 * math.pi * 2800.0 * t) * 0.5 +
              math.sin(2 * math.pi * 2950.0 * t) * 0.5) *
          flutter *
          env *
          0.75;
      samples.add(val);
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildCountdown(int sampleRate) {
    final samples = <double>[];
    const prepDuration = 0.08;
    const pauseDuration = 0.14;
    const finishDuration = 0.35;
    const prepFreq = 880.0;
    const finishFreq = 1760.0;

    // 3 short preparatory beeps
    for (var b = 0; b < 3; b++) {
      final bSamples = (prepDuration * sampleRate).round();
      for (var i = 0; i < bSamples; i++) {
        final t = i / sampleRate;
        final env = math.sin(math.pi * (i / bSamples));
        samples.add(math.sin(2 * math.pi * prepFreq * t) * env * 0.7);
      }
      final pSamples = (pauseDuration * sampleRate).round();
      for (var i = 0; i < pSamples; i++) {
        samples.add(0.0);
      }
    }

    // 1 triumphant finish beep
    final fSamples = (finishDuration * sampleRate).round();
    for (var i = 0; i < fSamples; i++) {
      final t = i / sampleRate;
      final env = math.exp(-3.0 * t);
      samples.add(math.sin(2 * math.pi * finishFreq * t) * env * 0.85);
    }

    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildPulse(int sampleRate) {
    final samples = <double>[];
    const sweepDuration = 0.25;
    const pauseDuration = 0.06;

    for (var burst = 0; burst < 2; burst++) {
      final sSamples = (sweepDuration * sampleRate).round();
      for (var i = 0; i < sSamples; i++) {
        final progress = i / sSamples;
        final freq = 380.0 + 1100.0 * progress;
        final t = i / sampleRate;
        final env = math.sin(math.pi * progress);
        samples.add(math.sin(2 * math.pi * freq * t) * env * 0.75);
      }
      if (burst == 0) {
        final pSamples = (pauseDuration * sampleRate).round();
        for (var i = 0; i < pSamples; i++) {
          samples.add(0.0);
        }
      }
    }

    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildBoxingGongDouble(int sampleRate) {
    final samples = <double>[];
    const duracaoHit = 0.85;
    final samplesHit = (duracaoHit * sampleRate).round();

    for (var hit = 0; hit < 2; hit++) {
      for (var i = 0; i < samplesHit; i++) {
        final t = i / sampleRate;
        final env = math.exp(-2.8 * t);
        final val = (math.sin(2 * math.pi * 260.0 * t) * 0.5 +
                math.sin(2 * math.pi * 520.0 * t) * 0.3 +
                math.sin(2 * math.pi * 780.0 * t) * 0.15 +
                math.sin(2 * math.pi * 1040.0 * t) * 0.05) *
            env *
            0.85;
        samples.add(val.clamp(-1.0, 1.0));
      }
      if (hit == 0) {
        final pauseSamples = (0.12 * sampleRate).round();
        for (var p = 0; p < pauseSamples; p++) {
          samples.add(0.0);
        }
      }
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildWhistleTriple(int sampleRate) {
    final samples = <double>[];
    const duracaoBurst = 0.14;
    const pausa = 0.07;
    final bSamples = (duracaoBurst * sampleRate).round();
    final pSamples = (pausa * sampleRate).round();

    for (var b = 0; b < 3; b++) {
      for (var i = 0; i < bSamples; i++) {
        final t = i / sampleRate;
        final progress = i / bSamples;
        final env = progress < 0.15
            ? (progress / 0.15)
            : (progress > 0.85 ? (1.0 - progress) / 0.15 : 1.0);
        final tremolo = 1.0 + 0.15 * math.sin(2 * math.pi * 32.0 * t);
        final val = (math.sin(2 * math.pi * 2550.0 * t) * 0.6 +
                math.sin(2 * math.pi * 2700.0 * t) * 0.4) *
            env *
            tremolo *
            0.65;
        samples.add(val.clamp(-1.0, 1.0));
      }
      if (b < 2) {
        for (var p = 0; p < pSamples; p++) {
          samples.add(0.0);
        }
      }
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildAirHorn(int sampleRate) {
    final samples = <double>[];
    const duracao = 0.65;
    final totalSamples = (duracao * sampleRate).round();

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final env = progress < 0.08
          ? (progress / 0.08)
          : (progress > 0.8 ? (1.0 - progress) / 0.2 : 1.0);
      final val = (math.sin(2 * math.pi * 470.0 * t) * 0.5 +
              math.sin(2 * math.pi * 375.0 * t) * 0.4 +
              math.sin(2 * math.pi * 940.0 * t) * 0.2) *
          env *
          0.7;
      samples.add(val.clamp(-1.0, 1.0));
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildLaserSynth(int sampleRate) {
    final samples = <double>[];
    const duracao = 0.38;
    final totalSamples = (duracao * sampleRate).round();

    for (var i = 0; i < totalSamples; i++) {
      final progress = i / totalSamples;
      final freq = 2800.0 * math.pow(0.12, progress);
      final t = i / sampleRate;
      final env = 1.0 - progress;
      final val = math.sin(2 * math.pi * freq * t) * env * 0.75;
      samples.add(val.clamp(-1.0, 1.0));
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildArcadePowerup(int sampleRate) {
    final samples = <double>[];
    const notas = [523.25, 659.25, 783.99, 1046.50, 1318.51];
    const duracaoNota = 0.07;
    final samplesNota = (duracaoNota * sampleRate).round();

    for (final freq in notas) {
      for (var i = 0; i < samplesNota; i++) {
        final t = i / sampleRate;
        final env = 1.0 - (i / samplesNota) * 0.3;
        final sinVal = math.sin(2 * math.pi * freq * t);
        final squareVal = sinVal >= 0 ? 0.75 : -0.75;
        final val = squareVal * env * 0.55;
        samples.add(val.clamp(-1.0, 1.0));
      }
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildSonarPing(int sampleRate) {
    final samples = <double>[];
    const duracao = 1.35;
    final totalSamples = (duracao * sampleRate).round();
    const freq = 1150.0;

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = math.exp(-3.2 * t);
      final val = (math.sin(2 * math.pi * freq * t) * 0.8 +
              math.sin(2 * math.pi * (freq * 2) * t) * 0.2) *
          env *
          0.8;
      samples.add(val.clamp(-1.0, 1.0));
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildElectroDrop(int sampleRate) {
    final samples = <double>[];
    const duracao = 0.55;
    final totalSamples = (duracao * sampleRate).round();

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final freq = 180.0 * math.exp(-3.5 * progress) + 40.0;
      final env = math.exp(-2.8 * t);
      final val = math.sin(2 * math.pi * freq * t) * env * 0.9;
      samples.add(val.clamp(-1.0, 1.0));
    }
    return _pcmToWav(samples, sampleRate);
  }

  Uint8List _buildShortTickBeep(int sampleRate) {
    final samples = <double>[];
    const duracao = 0.085;
    final totalSamples = (duracao * sampleRate).round();
    const freq = 987.77; // Si5 curto e nítido de preparação

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = math.sin(math.pi * (i / totalSamples));
      samples.add(math.sin(2 * math.pi * freq * t) * env * 0.65);
    }
    return _pcmToWav(samples, sampleRate);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoStopTimer?.cancel();
    _player?.dispose();
    _player = null;
    _tickPlayer?.dispose();
    _tickPlayer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppForeground = state == AppLifecycleState.resumed;
    if (!_isAppForeground) unawaited(pararAudio());
  }
}
