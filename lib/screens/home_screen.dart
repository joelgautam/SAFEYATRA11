import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/app_session.dart';
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
                                shape: BoxShape.circle,
                                color: Color(0xFFE05555)),
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

                    const _RecentTripsPanel(),

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

class _RecentTripsPanel extends StatefulWidget {
  const _RecentTripsPanel();

  @override
  State<_RecentTripsPanel> createState() => _RecentTripsPanelState();
}

class _RecentTripsPanelState extends State<_RecentTripsPanel> {
  bool _isLoading = true;
  final List<_TripHistoryItem> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final user = await AppSession.loadUser();
    final userId = user['id'] ?? '';
    if (userId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppSession.apiBaseUrl}/trips/?user=$userId'),
      );
      if (response.statusCode != 200) {
        throw StateError('Could not load trips.');
      }
      final decoded = jsonDecode(response.body);
      final items = decoded is Map<String, dynamic>
          ? decoded['results'] as List<dynamic>? ?? <dynamic>[]
          : decoded as List<dynamic>;
      final trips = items
          .map(
              (item) => _TripHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _trips
            ..clear()
            ..addAll(trips);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_trips.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'No saved trips yet. Plan a new trip to start history.',
          style: TextStyle(color: Color(0xFF9B96B8), fontSize: 13),
        ),
      );
    }

    return Column(
      children: _trips.take(6).map((trip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _TripCard(
            from: trip.from,
            to: trip.to,
            date: trip.dateLabel,
            duration: trip.durationLabel,
            status: trip.statusLabel,
            statusColor: trip.statusColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TripDetailScreen(
                  from: trip.from,
                  to: trip.to,
                  date: trip.dateLabel,
                  status: trip.statusLabel,
                  statusColor: trip.statusColor,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TripHistoryItem {
  final String from;
  final String to;
  final String status;
  final int? durationSeconds;
  final DateTime? startedAt;

  const _TripHistoryItem({
    required this.from,
    required this.to,
    required this.status,
    required this.durationSeconds,
    required this.startedAt,
  });

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active';
      case 'safe':
        return 'Safe';
      case 'deviation':
        return 'Deviation';
      case 'sos':
        return 'SOS';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Planned';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'safe':
        return const Color(0xFF4CAF50);
      case 'deviation':
      case 'sos':
        return const Color(0xFFE05555);
      case 'active':
        return const Color(0xFF6B5FE6);
      default:
        return const Color(0xFF9B96B8);
    }
  }

  String get durationLabel {
    final seconds = durationSeconds;
    if (seconds == null || seconds <= 0) return 'Monitoring';
    final minutes = (seconds / 60).round().clamp(1, 999);
    return '$minutes min';
  }

  String get dateLabel {
    final date = startedAt;
    if (date == null) return 'Not started';
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute';
  }

  factory _TripHistoryItem.fromJson(Map<String, dynamic> json) {
    return _TripHistoryItem(
      from: json['start_label']?.toString().isNotEmpty == true
          ? json['start_label'].toString()
          : 'Current location',
      to: json['destination_label']?.toString().isNotEmpty == true
          ? json['destination_label'].toString()
          : 'Destination',
      status: json['status']?.toString() ?? 'planned',
      durationSeconds: json['duration_seconds'] is int
          ? json['duration_seconds'] as int
          : int.tryParse(json['duration_seconds']?.toString() ?? ''),
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
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
