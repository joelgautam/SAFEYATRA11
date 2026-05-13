import 'package:flutter/material.dart';
import 'trip_detail_screen.dart';
import 'buttom_navigation_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showNotificationPlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No notifications yet'),
        behavior: SnackBarBehavior.floating,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.menu, color: Color(0xFF1A1A2E), size: 24),
                  const SizedBox(width: 12),
                  const Text('SafeYatra',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3D2FC4),
                      )),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showNotificationPlaceholder(context),
                    child: Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8)
                            ],
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: Color(0xFF6B5FE6), size: 20),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Color(0xFFE05555)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/faq-info'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B5FE6),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B5FE6).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.white, size: 30),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FAQs & Information',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap to view rules, regulations, and safety FAQs.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                            child: _StatCard(
                                icon: Icons.directions_walk,
                                value: '24',
                                label: 'Safe Trips',
                                color: const Color(0xFF6B5FE6))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _StatCard(
                                icon: Icons.shield,
                                value: '98%',
                                label: 'Safety Score',
                                color: const Color(0xFF4CAF50))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _StatCard(
                                icon: Icons.people,
                                value: '3',
                                label: 'Guardians',
                                color: const Color(0xFFE05555))),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent Trips header
                    Row(
                      children: [
                        const Text('Recent Trips',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E))),
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/trip'),
                          child: const Text('Plan new trip',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B5FE6))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Trip 1
                    _TripCard(
                      from: 'Thamel',
                      to: 'Patan Durbar Square',
                      date: 'Today, 4:30 PM',
                      duration: '42 min',
                      status: 'Safe',
                      statusColor: const Color(0xFF4CAF50),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailScreen(
                              from: 'Thamel',
                              to: 'Patan Durbar Square',
                              date: 'Today, 4:30 PM',
                              status: 'Safe',
                              statusColor: const Color(0xFF4CAF50),
                            ),
                          )),
                    ),
                    const SizedBox(height: 10),

                    // Trip 2
                    _TripCard(
                      from: 'Boudhanath',
                      to: 'Thamel',
                      date: 'Yesterday, 7:15 PM',
                      duration: '35 min',
                      status: 'Safe',
                      statusColor: const Color(0xFF4CAF50),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailScreen(
                              from: 'Boudhanath',
                              to: 'Thamel',
                              date: 'Yesterday, 7:15 PM',
                              status: 'Safe',
                              statusColor: const Color(0xFF4CAF50),
                            ),
                          )),
                    ),
                    const SizedBox(height: 10),

                    // Trip 3
                    _TripCard(
                      from: 'Lazimpat',
                      to: 'Koteshwor',
                      date: '2 days ago',
                      duration: '58 min',
                      status: 'Deviation',
                      statusColor: const Color(0xFFE05555),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailScreen(
                              from: 'Lazimpat',
                              to: 'Koteshwor',
                              date: '2 days ago',
                              status: 'Deviation',
                              statusColor: const Color(0xFFE05555),
                            ),
                          )),
                    ),

                    const SizedBox(height: 24),

                    // Safety Tips
                    const Text('Safety Tips',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 14),
                    _TipCard(
                      tip:
                          'Always share your live location with at least one guardian before starting a trip.',
                      icon: Icons.lightbulb_outline,
                    ),
                    const SizedBox(height: 10),
                    _TipCard(
                      tip:
                          'Use well-lit and busy roads especially during evening hours in Kathmandu.',
                      icon: Icons.wb_sunny_outlined,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeYatraBottomNav(currentRoute: 'home'),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9B96B8)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final String from, to, date, duration, status;
  final Color statusColor;
  final VoidCallback onTap;
  const _TripCard(
      {required this.from,
      required this.to,
      required this.date,
      required this.duration,
      required this.status,
      required this.statusColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFE4DEFF)),
              child:
                  const Icon(Icons.route, color: Color(0xFF6B5FE6), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$from → $to',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 3),
                  Text('$date • $duration',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9B96B8))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.arrow_forward_ios,
                    color: Color(0xFF9B96B8), size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String tip;
  final IconData icon;
  const _TipCard({required this.tip, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFE4DEFF),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B5FE6), size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(tip,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF3D2FC4), height: 1.4))),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final String currentRoute;
  const _BottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2))
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
                  isSelected: currentRoute == 'home',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/home')),
              _NavItem(
                  icon: Icons.book_outlined,
                  label: 'EXPLORE',
                  isSelected: currentRoute == 'explore',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/explore')),
              _NavItem(
                  icon: Icons.warning_outlined,
                  label: 'ALERTS',
                  isSelected: currentRoute == 'alerts',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/alerts')),
              _NavItem(
                  icon: Icons.person_outline,
                  label: 'PROFILE',
                  isSelected: currentRoute == 'profile',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/profile')),
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
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.isSelected,
      required this.onTap});

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
                      borderRadius: BorderRadius.circular(12)),
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
