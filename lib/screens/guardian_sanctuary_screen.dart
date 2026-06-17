import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/app_session.dart';

class GuardianSanctuaryScreen extends StatefulWidget {
  const GuardianSanctuaryScreen({super.key});

  @override
  State<GuardianSanctuaryScreen> createState() =>
      _GuardianSanctuaryScreenState();
}

class _GuardianSanctuaryScreenState extends State<GuardianSanctuaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<_SanctuaryGuardian> _guardians = [];
  bool _voiceShared = false;
  bool _isLoadingGuardians = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadGuardians();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Share Voice Update ───────────────────────────────────────────────────
  void _shareVoice() {
    setState(() => _voiceShared = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎤 Voice update shared with guardians!'),
        backgroundColor: const Color(0xFF6B5FE6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _loadGuardians() async {
    final sessionUser = await AppSession.loadUser();
    final userId = sessionUser['id'] ?? '';
    if (userId.isEmpty) {
      if (mounted) setState(() => _isLoadingGuardians = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppSession.apiBaseUrl}/guardian-contacts/?user=$userId'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = decoded is Map<String, dynamic>
            ? decoded['results'] as List<dynamic>
            : decoded as List<dynamic>;
        if (!mounted) return;
        setState(() {
          _guardians
            ..clear()
            ..addAll(items.map((item) {
              return _SanctuaryGuardian.fromJson(item as Map<String, dynamic>);
            }));
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load guardian contacts.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGuardians = false);
    }
  }

  // ── Police SOS ───────────────────────────────────────────────────────────
  void _policeSOS() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚨 Call Police?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'This will call Nepal Police (100) and share your live location with them immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9B96B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Call 100',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ── Call Guardians ───────────────────────────────────────────────────
  void _callGuardians() {
    final guardians = _guardians;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Call Guardians',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 16),
            if (guardians.isEmpty)
              const Text(
                'No guardian contacts saved yet.',
                style: TextStyle(color: Color(0xFF9B96B8)),
              )
            else
              ...guardians.map((guardian) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CallRow(
                    initial: guardian.initial,
                    name: guardian.name,
                    phone: guardian.phone,
                  ),
                );
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── View Responses ───────────────────────────────────────────────────────
  void _viewResponses() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nearby Support Responses',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 16),
            _ResponseTile(
              name: 'Sita Sharma',
              message: 'I am 2 minutes away. Stay where you are.',
              time: 'Just now',
              distance: '50m away',
            ),
            const SizedBox(height: 10),
            _ResponseTile(
              name: 'SafeYatra Volunteer',
              message: 'Police has been notified. Help is on the way.',
              time: '1 min ago',
              distance: '200m away',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Mark Safe ────────────────────────────────────────────────────────────
  void _markSafe() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✅ You are safe?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'This will notify all guardians that you are safe and end the emergency.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9B96B8))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, I\'m Safe',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ───────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.menu,
                        color: Color(0xFF1A1A2E), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Text('Guardian Sanctuary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB71C1C),
                      )),
                  const Spacer(),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE4DEFF),
                      border: Border.all(
                          color: const Color(0xFF6B5FE6), width: 1.5),
                    ),
                    child: const Icon(Icons.person,
                        color: Color(0xFF6B5FE6), size: 20),
                  ),
                ],
              ),
            ),

            // ── Red Alert Banner ──────────────────────────────────────────
            Container(
              width: double.infinity,
              color: const Color.fromARGB(255, 42, 39, 116),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _CheckRow(text: 'Guardians notified'),
                  SizedBox(height: 5),
                  _CheckRow(text: 'Location shared'),
                  SizedBox(height: 5),
                  _CheckRow(text: 'Nearby users alerted'),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Map ───────────────────────────────────────────────
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 220,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5E6C8),
                          ),
                          child: Image.asset(
                            'assets/kathmandu_map.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 220,
                            color: const Color(0xFFF5C842).withOpacity(0.3),
                            colorBlendMode: BlendMode.multiply,
                            errorBuilder: (_, __, ___) => CustomPaint(
                              size: const Size(double.infinity, 220),
                              painter: _WarmMapPainter(),
                            ),
                          ),
                        ),

                        // Pulsing red location dot
                        Positioned(
                          top: 90,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer pulse ring
                                  Transform.scale(
                                    scale: _pulseAnimation.value * 1.8,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFB71C1C)
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                  // Inner dot
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFB71C1C),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFB71C1C)
                                              .withOpacity(0.4),
                                          blurRadius: 10,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Live Tracking badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) => Opacity(
                                    opacity: _pulseAnimation.value,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFB71C1C),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('Live Tracking Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A2E),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Main Content ──────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Guardians Notified header
                          const Text('Guardians Notified',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              )),
                          const SizedBox(height: 4),
                          const Text('They are monitoring your situation.',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF9B96B8))),
                          const SizedBox(height: 16),

                          if (_isLoadingGuardians)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF6B5FE6),
                                ),
                              ),
                            )
                          else if (_guardians.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No guardian contacts saved yet.',
                                style: TextStyle(
                                  color: Color(0xFF9B96B8),
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else
                            ..._guardians.asMap().entries.map((entry) {
                              final index = entry.key;
                              final guardian = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == _guardians.length - 1 ? 0 : 10,
                                ),
                                child: _GuardianCard(
                                  initial: guardian.initial,
                                  name: guardian.name,
                                  status: index == 0 ? 'Viewing Live' : 'Notified',
                                  statusColor: index == 0
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF9B96B8),
                                  onCall: _callGuardians,
                                ),
                              );
                            }),

                          const SizedBox(height: 20),

                          // Share Voice Update
                          GestureDetector(
                            onTap: _shareVoice,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _voiceShared
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFEDE9FF),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _voiceShared ? Icons.check : Icons.mic,
                                    color: _voiceShared
                                        ? Colors.white
                                        : const Color(0xFF6B5FE6),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _voiceShared
                                        ? 'Voice Shared ✓'
                                        : 'Share Voice Update',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _voiceShared
                                          ? Colors.white
                                          : const Color(0xFF6B5FE6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Police SOS
                          GestureDetector(
                            onTap: _policeSOS,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B1A1A),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB71C1C)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.shield,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Police SOS',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      )),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Call All Guardians
                          GestureDetector(
                            onTap: _callGuardians,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.call,
                                      color: Color.fromARGB(255, 46, 28, 183),
                                      size: 20),
                                  SizedBox(width: 8),
                                  Text('Call All Guardians',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color.fromARGB(255, 19, 21, 122),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Nearby Support Card ───────────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFEDE9FF),
                                ),
                                child: const Icon(Icons.people,
                                    color: Color(0xFF6B5FE6), size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Nearby Support (50m)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1A1A2E),
                                        )),
                                    SizedBox(height: 2),
                                    Text(
                                      '1 nearby user is actively responding',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFB71C1C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: _viewResponses,
                            child: Container(
                              width: double.infinity,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(23),
                                border: Border.all(
                                  color: const Color(0xFFE4DEFF),
                                ),
                              ),
                              child: const Center(
                                child: Text('View Responses',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A2E),
                                    )),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── I am Safe Now ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: _markSafe,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('I am Safe Now',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Navigation ────────────────────────────────────────────────
      bottomNavigationBar: Container(
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
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/explore'),
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
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Check Row ──────────────────────────────────────────────────────────────
class _CheckRow extends StatelessWidget {
  final String text;
  const _CheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Guardian Card ──────────────────────────────────────────────────────────
class _GuardianCard extends StatelessWidget {
  final String initial, name, status;
  final Color statusColor;
  final VoidCallback onCall;

  const _GuardianCard({
    required this.initial,
    required this.name,
    required this.status,
    required this.statusColor,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE4DEFF),
            ),
            child: Center(
              child: Text(initial,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B5FE6))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: statusColor),
                    ),
                    const SizedBox(width: 5),
                    Text(status,
                        style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCall,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFEBEE),
              ),
              child: const Icon(Icons.call, color: Color(0xFFB71C1C), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Call Row ───────────────────────────────────────────────────────────────
class _CallRow extends StatelessWidget {
  final String initial, name, phone;
  const _CallRow(
      {required this.initial, required this.name, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0xFFE4DEFF)),
          child: Center(
            child: Text(initial,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF6B5FE6))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              Text(phone,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF9B96B8))),
            ],
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0xFFB71C1C)),
          child: const Icon(Icons.call, color: Colors.white, size: 18),
        ),
      ],
    );
  }
}

// ── Response Tile ──────────────────────────────────────────────────────────
class _SanctuaryGuardian {
  final String id;
  final String name;
  final String phone;

  const _SanctuaryGuardian({
    required this.id,
    required this.name,
    required this.phone,
  });

  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  factory _SanctuaryGuardian.fromJson(Map<String, dynamic> json) {
    return _SanctuaryGuardian(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Guardian',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class _ResponseTile extends StatelessWidget {
  final String name, message, time, distance;
  const _ResponseTile(
      {required this.name,
      required this.message,
      required this.time,
      required this.distance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const Spacer(),
              Text(distance,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B5FE6),
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(message,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9B96B8), height: 1.4)),
          const SizedBox(height: 4),
          Text(time,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9B96B8))),
        ],
      ),
    );
  }
}

// ── Warm Map Painter ───────────────────────────────────────────────────────
class _WarmMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFF5E6C8));
    final road = Paint()
      ..color = const Color(0xFFE8D5A8)
      ..strokeWidth = 1.5;
    final main = Paint()
      ..color = const Color(0xFFF0C060)
      ..strokeWidth = 5;
    final highway = Paint()
      ..color = const Color(0xFFE8873A)
      ..strokeWidth = 8;
    for (int i = 1; i <= 8; i++) {
      canvas.drawLine(Offset(0, size.height * i / 9),
          Offset(size.width, size.height * i / 9), road);
      canvas.drawLine(Offset(size.width * i / 9, 0),
          Offset(size.width * i / 9, size.height), road);
    }
    canvas.drawLine(Offset(size.width * 0.2, 0),
        Offset(size.width * 0.25, size.height), highway);
    canvas.drawLine(Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.48), main);
    canvas.drawLine(Offset(0, size.height * 0.65),
        Offset(size.width, size.height * 0.70), main);
  }

  @override
  bool shouldRepaint(_) => false;
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
                  child: Icon(icon, color: const Color(0xFFB71C1C), size: 20),
                )
              : Icon(icon, color: const Color(0xFF9B96B8), size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFFB71C1C)
                    : const Color(0xFF9B96B8),
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}
