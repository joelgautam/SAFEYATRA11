import 'package:flutter/material.dart';
import 'buttom_navigation_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _profileName = 'Anjali Sharma';
  String _profilePhone = '+977 98XXXXXXXX';

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showDetailDialog({
    required String title,
    required IconData icon,
    required List<String> details,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(icon, color: const Color(0xFF6B5FE6), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B5FE6),
                          )),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5FE6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _profileName);
    final phoneController = TextEditingController(text: _profilePhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name',
                filled: true,
                fillColor: const Color(0xFFF5F3FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                filled: true,
                fillColor: const Color(0xFFF5F3FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9B96B8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedName = nameController.text.trim();
              final updatedPhone = phoneController.text.trim();

              if (updatedName.isEmpty || updatedPhone.isEmpty) {
                _showInfoSnackBar(
                  context,
                  'Please enter both name and phone number.',
                );
                return;
              }

              setState(() {
                _profileName = updatedName;
                _profilePhone = updatedPhone;
              });
              Navigator.pop(ctx);
              _showInfoSnackBar(context, 'Profile updated successfully.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5FE6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
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
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Color(0xFF1A1A2E), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      )),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    child: const Icon(Icons.edit_outlined,
                        color: Color(0xFF6B5FE6), size: 22),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Profile Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
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
                          GestureDetector(
                            onTap: () => _showInfoSnackBar(
                              context,
                              'Profile photo tapped. Upload/change coming soon.',
                            ),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE4DEFF),
                                border: Border.all(
                                  color: const Color(0xFF6B5FE6),
                                  width: 3,
                                ),
                              ),
                              child: const Icon(Icons.person,
                                  color: Color(0xFF6B5FE6), size: 40),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(_profileName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              )),
                          const SizedBox(height: 4),
                          Text(_profilePhone,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9B96B8),
                              )),
                          const SizedBox(height: 16),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(value: '24', label: 'Safe Trips'),
                              _StatItem(value: '3', label: 'Guardians'),
                              _StatItem(value: '98%', label: 'Safety Score'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Settings List
                    _SettingsSection(
                      title: 'Account',
                      items: [
                        _SettingsItem(
                          icon: Icons.person_outline,
                          title: 'Personal Info',
                          subtitle: '$_profileName • anjali@safeyatra.app',
                          onTap: () => _showDetailDialog(
                            title: 'Personal Info',
                            icon: Icons.person_outline,
                            details: [
                              'Name: $_profileName',
                              'Phone: $_profilePhone',
                              'Email: anjali@safeyatra.app',
                              'Age: 26 • Blood Group: O+',
                            ],
                          ),
                        ),
                        _SettingsItem(
                          icon: Icons.shield_outlined,
                          title: 'Guardian Contacts',
                          subtitle: '3 trusted guardians added',
                          onTap: () =>
                              Navigator.pushNamed(context, '/guardian-contacts'),
                        ),
                        _SettingsItem(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'SOS alerts ON • Weekly reports ON',
                          onTap: () => _showDetailDialog(
                            title: 'Notifications',
                            icon: Icons.notifications_outlined,
                            details: const [
                              'SOS alerts: Enabled',
                              'Trip completion reports: Enabled',
                              'Weekly safety summary: Every Sunday',
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _SettingsSection(
                      title: 'Safety',
                      items: [
                        _SettingsItem(
                          icon: Icons.history,
                          title: 'Trip History',
                          subtitle: '24 trips • Last trip: Kathmandu to Bhaktapur',
                          onTap: () => _showDetailDialog(
                            title: 'Trip History',
                            icon: Icons.history,
                            details: const [
                              '24 total completed trips',
                              'Last trip: Kathmandu to Bhaktapur',
                              'No safety incidents reported',
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _SettingsSection(
                      title: 'App',
                      items: [
                        _SettingsItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'FAQs, contact, and emergency help',
                          onTap: () => Navigator.pushNamed(context, '/faq-info'),
                        ),
                        _SettingsItem(
                          icon: Icons.info_outline,
                          title: 'About SafeYatra',
                          subtitle: 'Version 1.0.0 • Privacy-first safety app',
                          onTap: () => _showDetailDialog(
                            title: 'About SafeYatra',
                            icon: Icons.info_outline,
                            details: const [
                              'Version: 1.0.0',
                              'SafeYatra is a privacy-first travel safety app.',
                              'Built for safer daily travel in Nepal.',
                            ],
                          ),
                        ),
                        _SettingsItem(
                          icon: Icons.logout,
                          title: 'Sign Out',
                          subtitle: 'Log out from current account',
                          isDestructive: true,
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/otp'),
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
      bottomNavigationBar: const SafeYatraBottomNav(currentRoute: 'profile'),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
                isSelected: false,
                onTap: () => Navigator.pushReplacementNamed(context, '/alerts'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'PROFILE',
                isSelected: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B5FE6),
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9B96B8),
              letterSpacing: 1,
            )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Column(
                children: [
                  item,
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            IconButton(
              onPressed: onTap,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              icon: Icon(
                icon,
                color: isDestructive
                    ? const Color(0xFFE05555)
                    : const Color(0xFF6B5FE6),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDestructive
                            ? const Color(0xFFE05555)
                            : const Color(0xFF1A1A2E),
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9B96B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isDestructive)
              const Icon(Icons.arrow_forward_ios,
                  color: Color(0xFF9B96B8), size: 14),
          ],
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
