import 'package:flutter/material.dart';
import 'buttom_navigation_screen.dart';

class TripDetailScreen extends StatelessWidget {
  final String from;
  final String to;
  final String date;
  final String status;
  final Color statusColor;

  const TripDetailScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Color(0xFF1A1A2E), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$from → $to',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            )),
                        Text(date,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9B96B8),
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        )),
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
                    // ── Trip Summary Card ─────────────────────────────────
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
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SummaryItem(
                                icon: Icons.timer_outlined,
                                value: '42 min',
                                label: 'Duration',
                                color: const Color(0xFF6B5FE6),
                              ),
                              _SummaryItem(
                                icon: Icons.route,
                                value: '8.2 km',
                                label: 'Distance',
                                color: const Color(0xFF4CAF50),
                              ),
                              _SummaryItem(
                                icon: Icons.speed,
                                value: '24 km/h',
                                label: 'Avg Speed',
                                color: const Color(0xFFE05555),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF6B5FE6),
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 30,
                                    color: const Color(0xFFE4DEFF),
                                  ),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFE05555),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(from,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A2E),
                                      )),
                                  const SizedBox(height: 16),
                                  Text(to,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A2E),
                                      )),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Timeline ──────────────────────────────────────────
                    const Text('Trip Timeline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        )),
                    const SizedBox(height: 16),

                    _TimelineItem(
                      time: '4:30 PM',
                      title: 'Trip Started',
                      description: 'Departed from $from',
                      icon: Icons.play_circle_outline,
                      color: const Color(0xFF6B5FE6),
                    ),
                    _TimelineItem(
                      time: '4:38 PM',
                      title: 'Checkpoint 1',
                      description: 'Passed through Lazimpat — on route ✓',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF4CAF50),
                    ),
                    _TimelineItem(
                      time: '4:45 PM',
                      title: 'Guardian Notified',
                      description: 'Mom was notified of your departure',
                      icon: Icons.people_outline,
                      color: const Color(0xFF6B5FE6),
                    ),
                    _TimelineItem(
                      time: '4:52 PM',
                      title: 'Checkpoint 2',
                      description: 'Passed through Kupondole — on route ✓',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF4CAF50),
                    ),
                    if (status == 'Deviation') ...[
                      _TimelineItem(
                        time: '4:58 PM',
                        title: '⚠️ Route Deviation',
                        description:
                            'Moved 150m off the planned corridor near Koteshwor',
                        icon: Icons.warning_outlined,
                        color: const Color(0xFFE05555),
                      ),
                      _TimelineItem(
                        time: '5:01 PM',
                        title: 'You Responded Safe',
                        description: 'Tapped "I\'m Safe" — alert cancelled',
                        icon: Icons.check_circle,
                        color: const Color(0xFF4CAF50),
                      ),
                    ],
                    _TimelineItem(
                      time: '5:12 PM',
                      title: 'Trip Completed',
                      description: 'Arrived safely at $to',
                      icon: Icons.flag_outlined,
                      color: const Color(0xFF4CAF50),
                    ),

                    const SizedBox(height: 24),

                    // ── Location Pings ────────────────────────────────────
                    const Text('Location Pings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        )),
                    const SizedBox(height: 4),
                    const Text(
                      'GPS location recorded every 30 seconds',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9B96B8),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _PingCard(
                        time: '4:30:00 PM',
                        location: 'Thamel Chowk',
                        lat: '27.7153',
                        lng: '85.3123'),
                    const SizedBox(height: 8),
                    _PingCard(
                        time: '4:30:30 PM',
                        location: 'Tridevi Marg',
                        lat: '27.7148',
                        lng: '85.3115'),
                    const SizedBox(height: 8),
                    _PingCard(
                        time: '4:31:00 PM',
                        location: 'Lazimpat Rd',
                        lat: '27.7139',
                        lng: '85.3108'),
                    const SizedBox(height: 8),
                    _PingCard(
                        time: '4:45:00 PM',
                        location: 'Kupondole',
                        lat: '27.6892',
                        lng: '85.3162'),
                    const SizedBox(height: 8),
                    _PingCard(
                        time: '5:12:00 PM',
                        location: to,
                        lat: '27.6726',
                        lng: '85.3241'),

                    const SizedBox(height: 24),

                    // ── Safety Report ─────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: status == 'Safe'
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            status == 'Safe' ? Icons.shield : Icons.warning,
                            color: statusColor,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status == 'Safe'
                                      ? 'Trip completed safely!'
                                      : 'Deviation detected',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status == 'Safe'
                                      ? 'No deviations. All guardians were notified on arrival.'
                                      : 'You deviated from route but responded safe.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9B96B8),
            )),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String time;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _TimelineItem({
    required this.time,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(time,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9B96B8),
                fontWeight: FontWeight.w500,
              )),
        ),
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            Container(
              width: 2,
              height: 40,
              color: const Color(0xFFE4DEFF),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    )),
                const SizedBox(height: 3),
                Text(description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9B96B8),
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PingCard extends StatelessWidget {
  final String time;
  final String location;
  final String lat;
  final String lng;

  const _PingCard({
    required this.time,
    required this.location,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF6B5FE6), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    )),
                Text('$lat, $lng',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9B96B8),
                    )),
              ],
            ),
          ),
          Text(time,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9B96B8),
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
