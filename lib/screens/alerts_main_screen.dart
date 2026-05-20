import 'package:flutter/material.dart';
import 'buttom_navigation_screen.dart';

class AlertsMainScreen extends StatefulWidget {
  const AlertsMainScreen({super.key});

  @override
  State<AlertsMainScreen> createState() => _AlertsMainScreenState();
}

class _AlertsMainScreenState extends State<AlertsMainScreen> {
  bool _isRecording = false;

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    // TODO: Start voice recording here
    // TODO: Start background monitoring and performance tracking here
    debugPrint('Recording started');
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    // TODO: Stop voice recording here
    // TODO: Stop background monitoring here
    debugPrint('Recording stopped');
  }

  void _toggleRecording() {
    _isRecording ? _stopRecording() : _startRecording();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 90),
          child: Column(
            children: [
              Row(
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
              ),
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 196,
                    height: 196,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF2EEFD),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? const Color(0xFFE05555)
                              : const Color(0xFF6E4ACD),
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording
                                      ? const Color(0xFFE05555)
                                      : const Color(0xFF6E4ACD))
                                  .withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            _isRecording
                                ? Icons.graphic_eq_rounded
                                : Icons.mic_none_rounded,
                            key: ValueKey(_isRecording),
                            size: 38,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isRecording ? 'Recording in progress' : 'Start Recording',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF17151F),
                  fontSize: 42 / 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isRecording
                    ? 'Recording is active for your protection.\nYour activity is being logged securely.'
                    : 'Tap the record button to begin recording\nand start background monitoring.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5B5768),
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              if (_isRecording) ...[
                _SignalCard(
                  title: 'LIVE MONITORING',
                  message: 'Analyzing surrounding audio...',
                  trailing: const Icon(Icons.graphic_eq_rounded,
                      color: Color(0xFFB7AEDD), size: 24),
                ),
                const SizedBox(height: 12),
                _SignalCard(
                  title: 'SAFETY KEYWORD FOUND',
                  message: '"Help"',
                  leadingIcon: Icons.sensors,
                ),
                const SizedBox(height: 16),
              ],
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 14, color: Color(0xFF868094)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Emergency contacts will be notified upon verification.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF868094),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _toggleRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording
                        ? const Color(0xFFE05555)
                        : const Color(0xFF6E4ACD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: (_isRecording
                            ? const Color(0xFFE05555)
                            : const Color(0xFF6E4ACD))
                        .withOpacity(0.3),
                  ),
                  child: Text(
                    _isRecording ? 'STOP RECORDING' : 'START RECORDING',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeYatraBottomNav(currentRoute: 'alerts'),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF0EBFC),
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

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'HOME',
                isSelected: false,
                onTap: () => Navigator.pushReplacementNamed(context, '/home'),
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                label: 'EXPLORE',
                isSelected: false,
                onTap: () => Navigator.pushReplacementNamed(context, '/explore'),
              ),
              _NavItem(
                icon: Icons.warning_outlined,
                label: 'ALERTS',
                isSelected: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'PROFILE',
                isSelected: false,
                onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isSelected
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4DEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF6B5FE6), size: 20),
                )
              : Icon(icon, color: const Color(0xFF9B96B8), size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFF6B5FE6)
                  : const Color(0xFF9B96B8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
