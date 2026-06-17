import 'dart:typed_data';

class VoiceRecording {
  final Uint8List bytes;
  final String mimeType;
  final String fileExtension;

  const VoiceRecording({
    required this.bytes,
    required this.mimeType,
    required this.fileExtension,
  });
}
