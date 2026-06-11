import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'voice_recording.dart';

class HardwareVoiceRecorder {
  static const _dataAvailableEvent =
      html.EventStreamProvider<html.Event>('dataavailable');
  static const _stopEvent = html.EventStreamProvider<html.Event>('stop');

  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = [];

  Future<void> start() async {
    if (_recorder?.state == 'recording') return;

    final devices = html.window.navigator.mediaDevices;
    if (devices == null) {
      throw StateError('This browser does not expose microphone access.');
    }

    _chunks.clear();
    _stream = await devices.getUserMedia({'audio': true});
    _recorder = html.MediaRecorder(_stream!);
    _dataAvailableEvent.forTarget(_recorder!).listen((event) {
      final data = (event as dynamic).data as html.Blob?;
      if (data != null && data.size > 0) {
        _chunks.add(data);
      }
    });
    _recorder!.start();
  }

  Future<VoiceRecording> stop() async {
    final recorder = _recorder;
    if (recorder == null || recorder.state == 'inactive') {
      throw StateError('Recording has not started.');
    }

    final stopped = _stopEvent.forTarget(recorder).first;
    recorder.stop();
    await stopped;

    final recorderMimeType = recorder.mimeType;
    final mimeType = recorderMimeType != null && recorderMimeType.isNotEmpty
        ? recorderMimeType
        : 'audio/webm';
    final blob = html.Blob(_chunks, mimeType);
    final bytes = await _blobToBytes(blob);
    _stopTracks();

    return VoiceRecording(
      bytes: bytes,
      mimeType: mimeType,
      fileExtension: _extensionFor(mimeType),
    );
  }

  void dispose() {
    if (_recorder?.state == 'recording') {
      _recorder?.stop();
    }
    _stopTracks();
  }

  Future<Uint8List> _blobToBytes(html.Blob blob) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoadEnd.first;
    final result = reader.result;
    if (result is ByteBuffer) {
      return Uint8List.view(result);
    }
    return Uint8List.fromList(result as List<int>);
  }

  void _stopTracks() {
    for (final track in _stream?.getTracks() ?? <html.MediaStreamTrack>[]) {
      track.stop();
    }
    _stream = null;
  }

  String _extensionFor(String mimeType) {
    if (mimeType.contains('mp4')) return 'm4a';
    if (mimeType.contains('ogg')) return 'ogg';
    if (mimeType.contains('wav')) return 'wav';
    return 'webm';
  }
}
