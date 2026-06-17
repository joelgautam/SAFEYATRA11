import 'voice_recording.dart';

class HardwareVoiceRecorder {
  Future<void> start() async {
    throw UnsupportedError('Voice recording is only available on web here.');
  }

  Future<VoiceRecording> stop() async {
    throw UnsupportedError('Voice recording is only available on web here.');
  }

  void dispose() {}
}
