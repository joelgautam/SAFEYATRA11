import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class DeviationAlertScreen extends StatefulWidget {
  const DeviationAlertScreen({super.key});

  @override
  State<DeviationAlertScreen> createState() => _DeviationAlertScreenState();
}

class _DeviationAlertScreenState extends State<DeviationAlertScreen>
    with SingleTickerProviderStateMixin {
  int _secondsLeft = 30;
  Timer? _countdownTimer;

  late AnimationController _circleController;
  late Animation<double> _circleAnimation;

  @override
  void initState() {
    super.initState();

    // Circle countdown animation
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _circleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.linear),
    );
    _circleController.forward();

    // Countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 1) {
        t.cancel();
        // Auto alert sent
        if (mounted) _sendAutoAlert();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _circleController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _imSafe() {
    _countdownTimer?.cancel();
    _circleController.stop();
    Navigator.pushReplacementNamed(context, '/passive');
  }

  void _needHelp() {
    _countdownTimer?.cancel();
    _circleController.stop();
    _showSosDialog();
  }

  void _sendAutoAlert() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('🚨 Alert Sent!',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
              'Your emergency contacts have been notified with your live location.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, '/passive');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚨 Sending SOS Alert',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Alerting your emergency contacts with your live location now!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/passive');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Blurred background ───────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB0A090),
                  Color(0xFF909080),
                  Color(0xFF808870),
                ],
              ),
            ),
          ),

          // ── Top Bar ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.menu, color: Color(0xFF8B3030), size: 24),
                  const SizedBox(width: 14),
                  const Text('SafeYatra',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      )),
                  const Spacer(),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/kathmandu_map.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: const Icon(Icons.person,
                        color: Color(0xFF6B5FE6), size: 22),
                  ),
                ],
              ),
            ),
          ),

          // ── Main Alert Card ──────────────────────────────────────────
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Warning icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFEBEE),
                    ),
                    child: const Icon(Icons.warning_rounded,
                        color: Color(0xFFB71C1C), size: 36),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    "You've moved off-route.",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  const Text(
                    'Are you safe? We noticed a deviation from your planned journey to Thamel.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9B96B8),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Countdown circle
                  AnimatedBuilder(
                    animation: _circleAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: _CountdownPainter(
                              progress: _circleAnimation.value),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$_secondsLeft',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const Text('SECONDS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF9B96B8),
                                      letterSpacing: 1.2,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // I'm Safe button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _imSafe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8E6F0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_outline,
                              color: Color(0xFF6B5FE6), size: 20),
                          SizedBox(width: 8),
                          Text("I'm Safe",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              )),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Need Help button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _needHelp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.location_on,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Need Help',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Auto alert countdown
                  Text(
                    'AUTOMATIC ALERT IN ${_secondsLeft - 2 > 0 ? _secondsLeft - 2 : 0}S',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9B96B8),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── SOS button ────────────────────────────────────────────────
          Positioned(
            right: 20,
            bottom: 90,
            child: GestureDetector(
              onTap: _needHelp,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB71C1C).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('SOS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      )),
                ),
              ),
            ),
          ),

          // ── Bottom Navigation ─────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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
                          icon: Icons.explore_outlined,
                          label: 'EXPLORE',
                          isSelected: false,
                          onTap: () {}),
                      _NavItem(
                          icon: Icons.book_outlined,
                          label: 'JOURNEY',
                          isSelected: true,
                          onTap: () {}),
                      _NavItem(
                          icon: Icons.shield_outlined,
                          label: 'SAFETY',
                          isSelected: false,
                          onTap: () {}),
                      _NavItem(
                          icon: Icons.person_outline,
                          label: 'PROFILE',
                          isSelected: false,
                          onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Countdown Circle Painter ───────────────────────────────────────────────
class _CountdownPainter extends CustomPainter {
  final double progress;
  _CountdownPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE8E6F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = const Color(0xFFB71C1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CountdownPainter old) => old.progress != progress;
}

// ── Nav Item ───────────────────────────────────────────────────────────────
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
                    color: const Color(0xFFFFE4E4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFFE05555), size: 20),
                )
              : Icon(icon, color: const Color(0xFF9B96B8), size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFFE05555)
                    : const Color(0xFF9B96B8),
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}
