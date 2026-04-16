import 'package:flutter/material.dart';
import 'dart:async';

class PassiveModeScreen extends StatefulWidget {
  const PassiveModeScreen({super.key});

  @override
  State<PassiveModeScreen> createState() => _PassiveModeScreenState();
}

class _PassiveModeScreenState extends State<PassiveModeScreen>
    with TickerProviderStateMixin {
  // ETA countdown
  int _etaMinutes = 8;
  Timer? _etaTimer;

  // Pulsing dot animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Route animation
  late AnimationController _routeController;
  late Animation<double> _routeAnimation;

  // SOS button press
  bool _sosPressing = false;

  @override
  void initState() {
    super.initState();
    // Pulse animation for ACTIVE dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Route animation
    _routeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _routeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _routeController, curve: Curves.linear),
    );

    // ETA countdown
    _etaTimer = Timer.periodic(const Duration(seconds: 60), (t) {
      if (_etaMinutes > 0) {
        setState(() => _etaMinutes--);
      } else {
        t.cancel();
      }
    });
// ── Simulate deviation after 8 seconds ──
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        Navigator.pushNamed(context, '/deviation');
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _routeController.dispose();
    _etaTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top Bar ──────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.menu,
                          color: Color(0xFF1A1A2E), size: 24),
                      const SizedBox(width: 14),
                      const Text('SafeYatra',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          )),
                      const Spacer(),
                      // Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE4DEFF),
                          border: Border.all(
                            color: const Color(0xFF6B5FE6),
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.person,
                            color: Color(0xFF6B5FE6), size: 22),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // ── Monitoring Card ───────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Monitoring Your Trip',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1A1A2E),
                                        )),
                                    SizedBox(height: 8),
                                    Text(
                                      'You are on the safe route. Emergency contacts have been notified of your departure.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF9B96B8),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // ACTIVE badge
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) => Opacity(
                                  opacity: _pulseAnimation.value,
                                  child: child,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text('ACTIVE',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF4CAF50),
                                            letterSpacing: 0.8,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Map Card ──────────────────────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: 300,
                            child: Stack(
                              children: [
                                // Dark purple map background
                                Container(
                                  width: double.infinity,
                                  height: 300,
                                  color: const Color(0xFF1A1035),
                                  child: CustomPaint(
                                    painter: _DarkMapPainter(
                                      animation: _routeAnimation,
                                    ),
                                  ),
                                ),

                                // Map image overlay with dark tint
                                Image.asset(
                                  'assets/kathmandu_map.png',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 300,
                                  color:
                                      const Color(0xFF2D1B69).withOpacity(0.75),
                                  colorBlendMode: BlendMode.multiply,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),

                                // Route overlay
                                CustomPaint(
                                  size: const Size(double.infinity, 300),
                                  painter: _GlowRoutePainter(
                                      animation: _routeAnimation),
                                ),

                                // Next Stop card at bottom
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFEBEE),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                              Icons.directions_bus,
                                              color: Color(0xFFE05555),
                                              size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              Text('NEXT STOP',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF9B96B8),
                                                    letterSpacing: 1.2,
                                                  )),
                                              SizedBox(height: 2),
                                              Text('Pulchowk',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF1A1A2E),
                                                  )),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '$_etaMinutes min',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFE05555),
                                              ),
                                            ),
                                            const Text('ETA 18:42',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF9B96B8),
                                                )),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Live Share + Safety Vault cards ───────────────
                        Row(
                          children: [
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.location_searching,
                                iconColor: const Color(0xFF6B5FE6),
                                title: 'Live Share',
                                subtitle: 'Sharing with 3 friends',
                                badge: null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.security,
                                iconColor: const Color(0xFF6B5FE6),
                                title: 'Safety Vault',
                                subtitle: 'Audio recording active',
                                badge: 'SOS',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── SOS Floating Button ────────────────────────────────────
            Positioned(
              right: 20,
              bottom: 90,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _sosPressing = true),
                onTapUp: (_) {
                  setState(() => _sosPressing = false);
                  _showSosDialog(context);
                },
                onTapCancel: () => setState(() => _sosPressing = false),
                child: AnimatedScale(
                  scale: _sosPressing ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE05555),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE05555).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emergency,
                        color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),

            // ── Bottom Navigation ──────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚨 Send SOS Alert?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'This will immediately alert your emergency contacts with your live location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9B96B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05555),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                const Text('Send SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Dark Map Painter ───────────────────────────────────────────────────────
class _DarkMapPainter extends CustomPainter {
  final Animation<double> animation;
  _DarkMapPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFF6B4FA0).withOpacity(0.5)
      ..strokeWidth = 2;
    final main = Paint()
      ..color = const Color(0xFFB060FF).withOpacity(0.7)
      ..strokeWidth = 6;

    for (int i = 1; i <= 8; i++) {
      canvas.drawLine(Offset(0, size.height * i / 9),
          Offset(size.width, size.height * i / 9), road);
      canvas.drawLine(Offset(size.width * i / 9, 0),
          Offset(size.width * i / 9, size.height), road);
    }
    canvas.drawLine(Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.48), main);
    canvas.drawLine(Offset(size.width * 0.3, 0),
        Offset(size.width * 0.35, size.height), main);
    canvas.drawLine(Offset(size.width * 0.6, 0),
        Offset(size.width * 0.65, size.height), main);
  }

  @override
  bool shouldRepaint(_DarkMapPainter old) => true;
}

// ── Glow Route Painter ─────────────────────────────────────────────────────
class _GlowRoutePainter extends CustomPainter {
  final Animation<double> animation;
  _GlowRoutePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width * 0.42;
    final sy = size.height * 0.15;
    final ex = size.width * 0.44;
    final ey = size.height * 0.80;

    // Glow effect
    canvas.drawLine(
        Offset(sx, sy),
        Offset(ex, ey),
        Paint()
          ..color = const Color(0xFFB060FF).withOpacity(0.3)
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Main dashed route
    final dashPaint = Paint()
      ..color = const Color(0xFFD090FF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final totalLen = (ey - sy);
    const dashLen = 12.0;
    const gapLen = 8.0;
    double pos = 0;
    final offset = (animation.value * (dashLen + gapLen));

    while (pos < totalLen) {
      final start = pos + offset;
      final end = start + dashLen;
      if (start < totalLen) {
        canvas.drawLine(
          Offset(sx, sy + (start % totalLen)),
          Offset(ex, sy + (end.clamp(0, totalLen) % totalLen)),
          dashPaint,
        );
      }
      pos += dashLen + gapLen;
    }

    // Moving location dot
    final dotProgress = animation.value;
    final dotY = sy + (ey - sy) * dotProgress;
    canvas.drawCircle(Offset(sx, dotY), 8, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(sx, dotY), 5, Paint()..color = const Color(0xFFE05555));

    // Start pin
    canvas.drawCircle(Offset(sx, sy), 12, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(sx, sy), 8, Paint()..color = const Color(0xFF6B5FE6));
    canvas.drawCircle(Offset(sx, sy), 3, Paint()..color = Colors.white);

    // End pin
    canvas.drawCircle(Offset(ex, ey), 12, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(ex, ey), 8, Paint()..color = const Color(0xFF6B5FE6));
    canvas.drawCircle(Offset(ex, ey), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_GlowRoutePainter old) => true;
}

// ── Feature Card ───────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      )),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              )),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9B96B8),
              )),
        ],
      ),
    );
  }
}

// ── Bottom Navigation ──────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
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
                icon: Icons.explore_outlined,
                label: 'EXPLORE',
                isSelected: false,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.book_outlined,
                label: 'JOURNEY',
                isSelected: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.shield_outlined,
                label: 'SAFETY',
                isSelected: false,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'PROFILE',
                isSelected: false,
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/profile'),
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
