import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../services/live_location.dart';
import '../services/location_suggestions.dart';
import '../services/trip_monitoring_api.dart';
import '../widgets/maptiler_live_map.dart';

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
  bool _isStartingPassive = false;
  bool _isLocating = false;
  int _selectedNavIndex = 1;
  LiveLocation? _currentLocation;
  LiveLocation? _startLocation;
  LiveLocation? _destinationLocation;
  List<PredefinedRoute> _safeRoutes = [];
  PredefinedRoute? _selectedRoute;

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
    _startLocation = const LiveLocation(latitude: 27.7153, longitude: 85.3123);
    _destinationLocation =
        const LiveLocation(latitude: 27.6726, longitude: 85.3241);
    _loadCurrentLocation();
    _loadSafeRoutes();
  }

  Future<void> _loadSafeRoutes() async {
    try {
      final routes = await TripMonitoringApi.getSafeRoutes();
      if (mounted) setState(() => _safeRoutes = routes);
    } catch (_) {}
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

  Future<void> _loadCurrentLocation({bool showSnack = false}) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final location = await LiveLocationService().current();
      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _startLocation = location;
        _startController.text = 'Current location';
        // Reset map scale to default when pinning
        _scale = 1.0;
        _mapController.value = Matrix4.identity();
      });
      if (showSnack) {
        _showSnack('Your location pinned on the map.');
      }
    } catch (_) {
      if (showSnack) {
        _showSnack('Allow location permission to use your current GPS point.');
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openLocationPicker({required bool isStart}) async {
    final selected = await showModalBottomSheet<LocationSuggestion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RouteSuggestionSheet(
        title: isStart ? 'Choose pickup point' : 'Choose destination',
        initialQuery: isStart ? _startController.text : _destController.text,
        origin: _currentLocation,
      ),
    );
    if (selected == null || !mounted) return;

    setState(() {
      final selectedLocation = LiveLocation(
        latitude: selected.latitude,
        longitude: selected.longitude,
      );
      if (isStart) {
        _startController.text = selected.label;
        _startLocation = selectedLocation;
      } else {
        _destController.text = selected.label;
        _destinationLocation = selectedLocation;
      }
    });
  }

  Future<void> _activatePassiveMode() async {
    if (_isStartingPassive) return;

    setState(() {
      _isButtonPressed = false;
      _isStartingPassive = true;
    });

    try {
      final user = await AppSession.loadUser();
      final userId = user['id'] ?? '';
      if (userId.isEmpty) {
        _showSnack('Please sign up again before starting passive mode.');
        return;
      }

      LiveLocation? location;
      try {
        location = _startLocation ?? await LiveLocationService().current();
      } catch (_) {
        location = _startLocation;
      }

      final started = await TripMonitoringApi.startPassiveTrip(
        userId: userId,
        startLabel: _startController.text.trim(),
        destinationLabel: _destController.text.trim(),
        startLocation: location,
        destinationLocation: _destinationLocation,
        predefinedRouteId: _selectedRoute?.id,
      );
      await AppSession.saveActiveTripId(started.tripId);

      if (!mounted) return;
      setState(() => _isPassiveActivated = true);
      _showSnack(
        'Passive monitoring started. ${started.guardiansNotified} guardians queued.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) Navigator.pushNamed(context, '/passive');
    } catch (_) {
      _showSnack('Could not start passive mode. Check backend connection.');
    } finally {
      if (mounted) setState(() => _isStartingPassive = false);
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
    final screenHeight = MediaQuery.of(context).size.height;
    final mapCenter = _currentLocation ?? _startLocation;

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
                child: MapTilerLiveMap(
                  centerLatitude: mapCenter?.latitude ?? 27.7172,
                  centerLongitude: mapCenter?.longitude ?? 85.324,
                  zoom: 13,
                  overlay: CustomPaint(
                    painter: _RoutePainter(
                      hasCurrentLocation: _currentLocation != null,
                    ),
                  ),
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
                _MapButton(
                  icon: _isLocating ? Icons.sync : Icons.my_location,
                  onTap: () => _loadCurrentLocation(showSnack: true),
                ),
                const SizedBox(height: 4),
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
                            onTap: () => _openLocationPicker(isStart: true),
                            onUseCurrentLocation: () =>
                                _loadCurrentLocation(showSnack: true),
                          ),
                          const SizedBox(height: 10),
                          _RouteInputCard(
                            label: 'DESTINATION',
                            controller: _destController,
                            isDot: false,
                            onTap: () => _openLocationPicker(isStart: false),
                          ),
                          const SizedBox(height: 14),

                          // ── Safe Routes Selection ────────────────────
                          if (_safeRoutes.isNotEmpty) ...[
                            const Text('VERIFIED SAFE ROUTES',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B5FE6),
                                  letterSpacing: 1.2,
                                )),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 64,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _safeRoutes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final route = _safeRoutes[index];
                                  final isSelected =
                                      _selectedRoute?.id == route.id;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedRoute =
                                            isSelected ? null : route;
                                      });
                                    },
                                    child: Container(
                                      width: 140,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF6B5FE6)
                                            : const Color(0xFFF5F3FF),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF6B5FE6)
                                              : const Color(0xFFE4DEFF),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            route.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF1A1A2E),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${route.waypoints.length} checkpoints',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSelected
                                                  ? Colors.white70
                                                  : const Color(0xFF9B96B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

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
                            onTapUp: (_) => _activatePassiveMode(),
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
                                      _isStartingPassive
                                          ? Icons.sync
                                          : _isPassiveActivated
                                              ? Icons.check_circle
                                              : Icons.shield,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isStartingPassive
                                          ? 'Starting Passive Mode...'
                                          : _isPassiveActivated
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
  final VoidCallback onTap;
  final VoidCallback? onUseCurrentLocation;

  const _RouteInputCard({
    required this.label,
    required this.controller,
    required this.isDot,
    required this.onTap,
    this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                : const Icon(Icons.flag, color: Color(0xFF6B5FE6), size: 18),
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
                  Text(
                    controller.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
            if (onUseCurrentLocation != null)
              IconButton(
                tooltip: 'Use current location',
                onPressed: onUseCurrentLocation,
                icon: const Icon(Icons.my_location,
                    color: Color(0xFF6B5FE6), size: 20),
              )
            else
              const Icon(Icons.search, color: Color(0xFF9B96B8), size: 20),
          ],
        ),
      ),
    );
  }
}

class _RouteSuggestionSheet extends StatefulWidget {
  final String title;
  final String initialQuery;
  final LiveLocation? origin;

  const _RouteSuggestionSheet({
    required this.title,
    required this.initialQuery,
    required this.origin,
  });

  @override
  State<_RouteSuggestionSheet> createState() => _RouteSuggestionSheetState();
}

class _RouteSuggestionSheetState extends State<_RouteSuggestionSheet> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(
      text:
          widget.initialQuery == 'Current location' ? '' : widget.initialQuery,
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = searchLocationSuggestions(
      _queryController.text,
      origin: widget.origin,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF555555),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F5F5F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search nearby places',
                          hintStyle: TextStyle(color: Color(0xFFD0D0D0)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _SuggestionChip(label: 'Search Results', isSelected: true),
                  const SizedBox(width: 10),
                  _SuggestionChip(label: 'Suggested'),
                  const SizedBox(width: 10),
                  _SuggestionChip(label: 'Saved'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final item = suggestions[index];
                    final distance = widget.origin == null
                        ? null
                        : distanceInKm(
                            widget.origin!.latitude,
                            widget.origin!.longitude,
                            item.latitude,
                            item.longitude,
                          );
                    return _SuggestionTile(
                      item: item,
                      distanceKm: distance,
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _SuggestionChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : const Color(0xFF555555),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final LocationSuggestion item;
  final double? distanceKm;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.item,
    required this.distanceKm,
    required this.onTap,
  });

  IconData _getIconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('airport')) return Icons.airplanemode_active;
    if (n.contains('durbar') || n.contains('square')) return Icons.account_balance;
    if (n.contains('stupa') || n.contains('temple')) return Icons.temple_buddhist;
    if (n.contains('mall')) return Icons.shopping_bag;
    if (n.contains('college') || n.contains('school')) return Icons.school;
    if (n.contains('bus')) return Icons.directions_bus;
    return Icons.location_on_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_getIconFor(item.name), color: Colors.white, size: 24),
      ),
      title: Text(
        item.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        item.address,
        style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (distanceKm != null)
            Text(
              '${distanceKm!.toStringAsFixed(1)}km',
              style: const TextStyle(
                color: Color(0xFF6B5FE6),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          const Icon(Icons.chevron_right, color: Color(0xFF555555), size: 18),
        ],
      ),
    );
  }
}

// ── Map Background Painter ─────────────────────────────────────────────────
// ── Route Painter ──────────────────────────────────────────────────────────
class _RoutePainter extends CustomPainter {
  final bool hasCurrentLocation;

  const _RoutePainter({required this.hasCurrentLocation});

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

    if (hasCurrentLocation) {
      final current = Offset(size.width * 0.50, size.height * 0.50);
      canvas.drawCircle(
        current,
        22,
        Paint()..color = const Color(0xFF2196F3).withOpacity(0.22),
      );
      canvas.drawCircle(current, 10, Paint()..color = Colors.white);
      canvas.drawCircle(current, 7, Paint()..color = const Color(0xFF2196F3));
    }
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
