import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/app_session.dart';
import 'buttom_navigation_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userId = '';
  String _profileName = 'SafeYatra User';
  String _profilePhone = '';
  String _profileEmail = '';
  String _bloodGroup = '';
  int? _age;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final sessionUser = await AppSession.loadUser();
    _userId = sessionUser['id'] ?? '';

    if (_userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppSession.apiBaseUrl}/users/$_userId/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _applyUser(data);
        await AppSession.saveUser(data);
      }
    } catch (_) {
      _profileName = sessionUser['full_name']?.isNotEmpty == true
          ? sessionUser['full_name']!
          : 'SafeYatra User';
      _profilePhone = sessionUser['phone'] ?? '';
      _profileEmail = sessionUser['email'] ?? '';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyUser(Map<String, dynamic> data) {
    _userId = data['id']?.toString() ?? _userId;
    _profileName = data['full_name']?.toString().isNotEmpty == true
        ? data['full_name'].toString()
        : 'SafeYatra User';
    _profilePhone = data['phone']?.toString() ?? '';
    _profileEmail = data['email']?.toString() ?? '';
    _bloodGroup = data['blood_group']?.toString() ?? '';
    _age = data['age'] is int ? data['age'] as int : null;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF5F3FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _saveProfile({
    required String name,
    required String phone,
    required String email,
    required String ageText,
    required String bloodGroup,
  }) async {
    if (_userId.isEmpty) {
      _showSnack('Please sign up again before editing your profile.');
      return;
    }
    if (name.isEmpty || phone.isEmpty) {
      _showSnack('Name and phone number are required.');
      return;
    }

    final parsedAge = ageText.trim().isEmpty ? null : int.tryParse(ageText);
    if (ageText.trim().isNotEmpty && parsedAge == null) {
      _showSnack('Age must be a number.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await http.patch(
        Uri.parse('${AppSession.apiBaseUrl}/users/$_userId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': name,
          'phone': phone,
          'email': email,
          'age': parsedAge,
          'blood_group': bloodGroup,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        _showSnack(data.values.first.toString());
        return;
      }

      setState(() => _applyUser(data));
      await AppSession.saveUser(data);
      if (mounted) Navigator.pop(context);
      _showSnack('Profile saved to database.');
    } catch (_) {
      _showSnack('Could not save profile. Check backend connection.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _profileName);
    final phoneController = TextEditingController(text: _profilePhone);
    final emailController = TextEditingController(text: _profileEmail);
    final ageController = TextEditingController(text: _age?.toString() ?? '');
    final bloodController = TextEditingController(text: _bloodGroup);

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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _fieldDecoration('Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: _fieldDecoration('Phone Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration('Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('Age'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bloodController,
                textCapitalization: TextCapitalization.characters,
                decoration: _fieldDecoration('Blood Group'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9B96B8)),
            ),
          ),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () => _saveProfile(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      email: emailController.text.trim(),
                      ageText: ageController.text.trim(),
                      bloodGroup: bloodController.text.trim(),
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5FE6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPersonalInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.person_outline, color: Color(0xFF6B5FE6), size: 22),
            SizedBox(width: 10),
            Text(
              'Personal Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoLine('Name', _profileName),
            _InfoLine('Phone', _profilePhone),
            _InfoLine('Email',
                _profileEmail.isEmpty ? 'Not added yet' : _profileEmail),
            _InfoLine('Age', _age?.toString() ?? 'Not added yet'),
            _InfoLine('Blood Group',
                _bloodGroup.isEmpty ? 'Not added yet' : _bloodGroup),
          ],
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

  Future<void> _signOut() async {
    await AppSession.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/otp');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/home'),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            color: Color(0xFF1A1A2E),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showEditProfileDialog,
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF6B5FE6),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
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
                                Container(
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
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF6B5FE6),
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _profileName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _profilePhone.isEmpty
                                      ? 'No phone saved'
                                      : _profilePhone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF9B96B8),
                                  ),
                                ),
                                if (_profileEmail.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _profileEmail,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9B96B8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _SettingsSection(
                            title: 'Account',
                            items: [
                              _SettingsItem(
                                icon: Icons.person_outline,
                                title: 'Personal Info',
                                subtitle: 'Saved to database',
                                onTap: _showPersonalInfo,
                              ),
                              _SettingsItem(
                                icon: Icons.shield_outlined,
                                title: 'Guardian Contacts',
                                subtitle: 'Add trusted contacts',
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/guardian-contacts',
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
                                onTap: () =>
                                    Navigator.pushNamed(context, '/faq-info'),
                              ),
                              _SettingsItem(
                                icon: Icons.logout,
                                title: 'Sign Out',
                                subtitle: 'Log out from current account',
                                isDestructive: true,
                                onTap: _signOut,
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
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      ),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9B96B8),
            letterSpacing: 1,
          ),
        ),
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
            Icon(
              icon,
              color: isDestructive
                  ? const Color(0xFFE05555)
                  : const Color(0xFF6B5FE6),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? const Color(0xFFE05555)
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
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
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF9B96B8),
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}
