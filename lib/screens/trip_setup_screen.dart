import 'package:flutter/material.dart';

class TripSetupScreen extends StatefulWidget {
  const TripSetupScreen({super.key});

  @override
  State<TripSetupScreen> createState() => _TripSetupScreenState();
}

class _TripSetupScreenState extends State<TripSetupScreen>
    with SingleTickerProviderStateMixin {
  final _startController = TextEditingController(text: 'Thamel, Kathmandu');
  final _destController = TextEditingController(text: 'Patan Durbar Square');
  bool _isPassiveActivated = false;
  bool _isButtonPressed = false;
  int _selectedNavIndex = 1;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TransformationController _mapController = TransformationController();
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _startController.dispose();
    _destController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _scale = (_scale + 0.5).clamp(0.5, 4.0);
      _mapController.value = Matrix4.identity()..scale(_scale);
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale - 0.5).clamp(0.5, 4.0);
      _mapController.value = Matrix4.identity()..scale(_scale);
    });
  }

  void _onNavTap(int index) {
    setState(() => _selectedNavIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/alerts');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  void _showNotificationPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No notifications yet'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── TOP: Full Map ──────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.52,
            child: InteractiveViewer(
              transformationController: _mapController,
              minScale: 0.5,
              maxScale: 4.0,
              child: SizedBox(
                width: double.infinity,
                height: screenHeight * 0.52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/kathmandu_map.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFD8E8C8),
                        child: CustomPaint(painter: _MapBgPainter()),
                      ),
                    ),
                    CustomPaint(painter: _RoutePainter()),
                  ],
                ),
              ),
            ),
          ),

          // ── Top Bar ────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _MapButton(icon: Icons.menu, onTap: () {}),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text('SafeYatra',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3D2FC4),
                          )),
                    ),
                    const Spacer(),
                    _MapButton(
                        icon: Icons.notifications_outlined,
                        onTap: _showNotificationPlaceholder),
                  ],
                ),
              ),
            ),
          ),

          // ── Safe Corridor Active badge — ONLY shows when passive is ON ─
          if (_isPassiveActivated)
            Positioned(
              top: screenHeight * 0.30,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) =>
                      Opacity(opacity: _pulseAnimation.value, child: child),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.shield, color: Color(0xFF6B5FE6), size: 14),
                        SizedBox(width: 6),
                        Text('Safe Corridor Active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Zoom buttons ───────────────────────────────────────────────
          Positioned(
            right: 16,
            top: screenHeight * 0.32,
            child: Column(
              children: [
                _MapButton(icon: Icons.add, onTap: _zoomIn),
                const SizedBox(height: 4),
                _MapButton(icon: Icons.remove, onTap: _zoomOut),
              ],
            ),
          ),

          // ── BOTTOM SHEET ───────────────────────────────────────────────
          Positioned(
            top: screenHeight * 0.46,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4DEFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PLAN YOUR JOURNEY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B5FE6),
                                letterSpacing: 1.8,
                              )),
                          const SizedBox(height: 2),
                          const Text('Secure Route',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                                letterSpacing: -0.5,
                              )),
                          const SizedBox(height: 14),
                          _RouteInputCard(
                            label: 'START POINT',
                            controller: _startController,
                            isDot: true,
                          ),
                          const SizedBox(height: 10),
                          _RouteInputCard(
                            label: 'DESTINATION',
                            controller: _destController,
                            isDot: false,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4DEFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.lock_outline,
                                    size: 11, color: Color(0xFF9B96B8)),
                                SizedBox(width: 5),
                                Text(
                                  'YOUR LOCATION IS SECURE & PRIVATE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF9B96B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ── Activate Button ──────────────────────────
                          GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _isButtonPressed = true),
                            onTapUp: (_) {
                              setState(() {
                                _isButtonPressed = false;
                                _isPassiveActivated = true;
                              });
                              Future.delayed(const Duration(milliseconds: 600),
                                  () {
                                if (mounted) {
                                  Navigator.pushNamed(context, '/passive');
                                }
                              });
                            },
                            onTapCancel: () =>
                                setState(() => _isButtonPressed = false),
                            child: AnimatedScale(
                              scale: _isButtonPressed ? 0.96 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: _isPassiveActivated
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF6B5FE6),
                                  borderRadius: BorderRadius.circular(27),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isPassiveActivated
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFF6B5FE6))
                                          .withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isPassiveActivated
                                          ? Icons.check_circle
                                          : Icons.shield,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isPassiveActivated
                                          ? 'Monitoring ON — Tap to Stop'
                                          : 'Activate Passive Mode',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color(0xFF6B5FE6).withOpacity(0.12),
                                ),
                                child: const Icon(Icons.info_outline,
                                    size: 15, color: Color(0xFF6B5FE6)),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Passive Monitoring',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A2E),
                                        )),
                                    SizedBox(height: 3),
                                    Text(
                                      "We'll silently monitor your route and only alert your emergency contacts if you deviate significantly from the corridor.",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9B96B8),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Navigation ──────────────────────────────────────────
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
                        icon: Icons.home_outlined,
                        label: 'HOME',
                        isSelected: _selectedNavIndex == 0,
                        onTap: () => _onNavTap(0),
                      ),
                      _NavItem(
                        icon: Icons.explore_outlined,
                        label: 'EXPLORE',
                        isSelected: _selectedNavIndex == 1,
                        onTap: () => _onNavTap(1),
                      ),
                      _NavItem(
                        icon: Icons.warning_outlined,
                        label: 'ALERTS',
                        isSelected: _selectedNavIndex == 2,
                        onTap: () => _onNavTap(2),
                      ),
                      _NavItem(
                        icon: Icons.person_outline,
                        label: 'PROFILE',
                        isSelected: _selectedNavIndex == 3,
                        onTap: () => _onNavTap(3),
                      ),
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

// ── Map Button ─────────────────────────────────────────────────────────────
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF6B5FE6), size: 20),
      ),
    );
  }
}

// ── Route Input Card ───────────────────────────────────────────────────────
class _RouteInputCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDot;

  const _RouteInputCard({
    required this.label,
    required this.controller,
    required this.isDot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          isDot
              ? Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6B5FE6),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 7,
                      height: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              : const Icon(Icons.location_on,
                  color: Color(0xFF6B5FE6), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9B96B8),
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 3),
                TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A2E),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map Background Painter ─────────────────────────────────────────────────
class _MapBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFD8E8C8));
    final road = Paint()
      ..color = const Color(0xFFC8D8B8)
      ..strokeWidth = 2;
    final main = Paint()
      ..color = const Color(0xFFF5C842)
      ..strokeWidth = 7;
    final hw = Paint()
      ..color = const Color(0xFFE8873A)
      ..strokeWidth = 10;
    for (int i = 1; i <= 8; i++) {
      canvas.drawLine(Offset(0, size.height * i / 9),
          Offset(size.width, size.height * i / 9), road);
      canvas.drawLine(Offset(size.width * i / 9, 0),
          Offset(size.width * i / 9, size.height), road);
    }
    canvas.drawLine(Offset(size.width * 0.15, 0),
        Offset(size.width * 0.22, size.height), hw);
    canvas.drawLine(Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.48), main);
    canvas.drawLine(Offset(0, size.height * 0.65),
        Offset(size.width, size.height * 0.70), main);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Route Painter ──────────────────────────────────────────────────────────
class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width * 0.42;
    final sy = size.height * 0.20;
    final ex = size.width * 0.44;
    final ey = size.height * 0.78;

    canvas.drawLine(
        Offset(sx + 2, sy + 2),
        Offset(ex + 2, ey + 2),
        Paint()
          ..color = const Color(0xFF6B5FE6).withOpacity(0.2)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        Offset(sx, sy),
        Offset(ex, ey),
        Paint()
          ..color = const Color(0xFF6B5FE6)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(sx, sy), 14, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(sx, sy), 10, Paint()..color = const Color(0xFF6B5FE6));
    canvas.drawCircle(Offset(sx, sy), 4, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(ex, ey), 14, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(ex, ey), 10, Paint()..color = const Color(0xFF6B5FE6));
    canvas.drawCircle(Offset(ex, ey), 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Bottom Nav Item ────────────────────────────────────────────────────────
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
          Text(label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF6B5FE6)
                    : const Color(0xFF9B96B8),
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}
