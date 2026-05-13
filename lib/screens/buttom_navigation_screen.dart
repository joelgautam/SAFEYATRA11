import 'package:flutter/material.dart';

class SafeYatraBottomNav extends StatelessWidget {
  final String currentRoute;

  const SafeYatraBottomNav({super.key, required this.currentRoute});

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
                isSelected: currentRoute == 'home',
                onTap: () {
                  if (currentRoute != 'home') {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                label: 'EXPLORE',
                isSelected: currentRoute == 'explore',
                onTap: () {
                  if (currentRoute != 'explore') {
                    Navigator.pushReplacementNamed(context, '/explore');
                  }
                },
              ),
              _NavItem(
                icon: Icons.warning_outlined,
                label: 'ALERTS',
                isSelected: currentRoute == 'alerts',
                onTap: () {
                  if (currentRoute != 'alerts') {
                    Navigator.pushReplacementNamed(context, '/alerts');
                  }
                },
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'PROFILE',
                isSelected: currentRoute == 'profile',
                onTap: () {
                  if (currentRoute != 'profile') {
                    Navigator.pushReplacementNamed(context, '/profile');
                  }
                },
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
