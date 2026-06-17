import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/app_session.dart';
import '../services/external_url.dart';
import '../services/voice_recorder.dart';
import 'buttom_navigation_screen.dart';

class AlertsMainScreen extends StatefulWidget {
  const AlertsMainScreen({super.key});

  @override
  State<AlertsMainScreen> createState() => _AlertsMainScreenState();
}

class _AlertsMainScreenState extends State<AlertsMainScreen> {
  final HardwareVoiceRecorder _recorder = HardwareVoiceRecorder();
  final List<_SavedRecording> _recordings = [];

  String _userId = '';
  String? _sessionId;
  bool _isRecording = false;
  bool _isBusy = false;
  bool _isLoadingRecordings = true;
  int _recipientsNotified = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndRecordings();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndRecordings() async {
    final user = await AppSession.loadUser();
    _userId = user['id'] ?? '';
    if (_userId.isEmpty) {
      setState(() => _isLoadingRecordings = false);
      _showSnack('Please sign up again before using voice alerts.');
      return;
    }
    await _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoadingRecordings = true);
    try {
      final response = await http.get(
        Uri.parse('${AppSession.apiBaseUrl}/audio-sessions/?user=$_userId'),
      );
      if (response.statusCode != 200) {
        throw StateError('Could not load recordings.');
      }

      final decoded = jsonDecode(response.body);
      final rows = decoded is Map<String, dynamic>
          ? decoded['results'] as List<dynamic>? ?? <dynamic>[]
          : decoded as List<dynamic>;
      final recordings = rows
          .map((item) => _SavedRecording.fromJson(item as Map<String, dynamic>))
          .where((item) => item.recordingUrl.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _recordings
            ..clear()
            ..addAll(recordings);
          _isLoadingRecordings = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRecordings = false);
        _showSnack('Could not load saved voice recordings.');
      }
    }
  }

  Future<void> _startVoiceAlert() async {
    if (_userId.isEmpty) {
      _showSnack('Please sign up again before using voice alerts.');
      return;
    }

    setState(() => _isBusy = true);
    try {
      await _recorder.start();

      final response = await http.post(
        Uri.parse('${AppSession.apiBaseUrl}/audio-sessions/start-alert/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user': _userId,
          'keyword_detected': 'Voice alert button',
        }),
      );

      if (response.statusCode != 201) {
        await _recorder.stop();
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _showSnack(data['detail']?.toString() ?? 'Could not start alert.');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final session = data['session'] as Map<String, dynamic>;
      setState(() {
        _sessionId = session['id']?.toString();
        _recipientsNotified = data['recipients_notified'] as int? ?? 0;
        _isRecording = true;
      });
      _showSnack(
        'Voice alert started. $_recipientsNotified emergency contacts queued.',
      );
    } catch (_) {
      _showSnack('Microphone access failed. Please allow microphone access.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _stopAndSaveRecording() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    setState(() => _isBusy = true);
    try {
      final recording = await _recorder.stop();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${AppSession.apiBaseUrl}/audio-sessions/$sessionId/upload-recording/',
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'recording',
          recording.bytes,
          filename:
              'voice-alert-${DateTime.now().millisecondsSinceEpoch}.${recording.fileExtension}',
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _showSnack(data['detail']?.toString() ?? 'Could not save recording.');
        return;
      }

      setState(() {
        _isRecording = false;
        _sessionId = null;
      });
      _showSnack('Voice recording saved for your account.');
      await _loadRecordings();
    } catch (_) {
      _showSnack('Could not stop or upload the voice recording.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
   final statusTitle =
    _isRecording ? 'Recording in progress' : 'Start Recording';
    final statusText = _isRecording
        ? 'The screen is dimmed and silent for your protection. Your activity is being logged securely.'
        : 'Tap the record button to begin recording and start background monitoring.';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Header(),
              const SizedBox(height: 30),
              _MicBadge(isRecording: _isRecording),
              const SizedBox(height: 24),
              Text(
                statusTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF17151F),
                  fontSize: 42 / 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5B5768),
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              _SignalCard(
                title: _isRecording ? 'LIVE MONITORING' : 'VOICE ACCESS',
                message: _isRecording
                    ? 'Recording surrounding audio...'
                    : 'Microphone permission requested on start',
                trailing: const Icon(Icons.graphic_eq_rounded,
                    color: Color(0xFFB7AEDD), size: 24),
              ),
              const SizedBox(height: 12),
              _SignalCard(
                title: 'EMERGENCY CONTACTS',
                message: _isRecording
                    ? '$_recipientsNotified contacts queued'
                    : 'Contacts are alerted when recording starts',
                leadingIcon: Icons.sensors,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isBusy
                      ? null
                      : _isRecording
                          ? _stopAndSaveRecording
                          : _startVoiceAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording
                        ? const Color(0xFFE45357)
                        : const Color(0xFF6E4ACD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF6E4ACD).withOpacity(0.22),
                  ),
                  child: _isBusy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isRecording ? 'STOP & SAVE' : 'START RECORDING',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _SavedRecordingsPanel(
                isLoading: _isLoadingRecordings,
                recordings: _recordings,
                onRefresh: _loadRecordings,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeYatraBottomNav(currentRoute: 'alerts'),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.shield_outlined,
            color: Color(0xFF9C2D2D), size: 24),
        const SizedBox(width: 8),
        const Text(
          'SafeYatra',
          style: TextStyle(
            color: Color(0xFF9C2D2D),
            fontSize: 36 / 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black12,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }
}

class _MicBadge extends StatelessWidget {
  final bool isRecording;

  const _MicBadge({required this.isRecording});

  @override
  Widget build(BuildContext context) {
    final color =
        isRecording ? const Color(0xFFE45357) : const Color(0xFF6E4ACD);
    return Center(
      child: Container(
        width: 196,
        height: 196,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF2EEFD),
        ),
        child: Center(
          child: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.mic_none_rounded,
                size: 36, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData? leadingIcon;
  final Widget? trailing;

  const _SignalCard({
    required this.title,
    required this.message,
    this.leadingIcon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF0EBFC),
              ),
              child: Icon(leadingIcon, color: const Color(0xFF8E73D6), size: 18),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF938CAB),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 20 / 1.6,
                    color: Color(0xFF23202D),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SavedRecordingsPanel extends StatelessWidget {
  final bool isLoading;
  final List<_SavedRecording> recordings;
  final Future<void> Function() onRefresh;

  const _SavedRecordingsPanel({
    required this.isLoading,
    required this.recordings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Saved voice records',
                  style: TextStyle(
                    color: Color(0xFF17151F),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Color(0xFF6E4ACD)),
              ),
            ],
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (recordings.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                'No saved recordings yet.',
                style: TextStyle(color: Color(0xFF868094)),
              ),
            )
          else
            ...recordings.map((recording) => _RecordingTile(recording)),
        ],
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  final _SavedRecording recording;

  const _RecordingTile(this.recording);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq, color: Color(0xFF6E4ACD)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recording.startedAtLabel,
                  style: const TextStyle(
                    color: Color(0xFF23202D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recording.keyword,
                  style: const TextStyle(
                    color: Color(0xFF868094),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => openExternalUrl(recording.recordingUrl),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _SavedRecording {
  final String keyword;
  final String recordingUrl;
  final String startedAtLabel;

  const _SavedRecording({
    required this.keyword,
    required this.recordingUrl,
    required this.startedAtLabel,
  });

  factory _SavedRecording.fromJson(Map<String, dynamic> json) {
    final url = json['recording_file_url']?.toString().isNotEmpty == true
        ? json['recording_file_url'].toString()
        : json['recording_url']?.toString() ?? '';
    return _SavedRecording(
      keyword: json['keyword_detected']?.toString().isNotEmpty == true
          ? json['keyword_detected'].toString()
          : 'Voice alert',
      recordingUrl: url,
      startedAtLabel: _formatDate(json['started_at']?.toString() ?? ''),
    );
  }

  static String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return 'Saved voice record';
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}
