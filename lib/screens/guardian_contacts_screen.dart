import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/app_session.dart';

class GuardianContactsScreen extends StatefulWidget {
  const GuardianContactsScreen({super.key});

  @override
  State<GuardianContactsScreen> createState() => _GuardianContactsScreenState();
}

class _GuardianContactsScreenState extends State<GuardianContactsScreen> {
  final List<_GuardianContact> _contacts = [];
  String _userId = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final sessionUser = await AppSession.loadUser();
    _userId = sessionUser['id'] ?? '';

    if (_userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppSession.apiBaseUrl}/guardian-contacts/?user=$_userId'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = decoded is Map<String, dynamic>
            ? decoded['results'] as List<dynamic>
            : decoded as List<dynamic>;
        setState(() {
          _contacts
            ..clear()
            ..addAll(items.map((item) {
              return _GuardianContact.fromJson(item as Map<String, dynamic>);
            }));
        });
      }
    } catch (_) {
      _showSnack('Could not load guardian contacts.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _saveContact({
    int? index,
    required String name,
    required String phone,
    required String relation,
  }) async {
    if (_userId.isEmpty) {
      _showSnack('Please sign up again before adding contacts.');
      return;
    }
    if (name.isEmpty || phone.isEmpty || relation.isEmpty) {
      _showSnack('Please fill all fields.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final existing = index != null ? _contacts[index] : null;
      final isNew = existing == null;
      final uri = isNew
          ? Uri.parse('${AppSession.apiBaseUrl}/guardian-contacts/')
          : Uri.parse(
              '${AppSession.apiBaseUrl}/guardian-contacts/${existing.id}/');
      final body = jsonEncode({
        'user': _userId,
        'name': name,
        'phone': phone,
        'relation': relation,
        'priority': (index ?? _contacts.length) + 1,
        'is_active': true,
      });
      final response = isNew
          ? await http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
          : await http.patch(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 && response.statusCode != 201) {
        _showSnack(data.values.first.toString());
        return;
      }

      final saved = _GuardianContact.fromJson(data);
      setState(() {
        if (isNew) {
          _contacts.add(saved);
        } else {
          _contacts[index!] = saved;
        }
      });
      if (mounted) Navigator.pop(context);
      _showSnack('Guardian contact saved to database.');
    } catch (_) {
      _showSnack('Could not save contact. Check backend connection.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showContactEditor({int? index}) {
    final existing = index != null ? _contacts[index] : null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final relationController =
        TextEditingController(text: existing?.relation ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          index == null ? 'Add Guardian Contact' : 'Edit Guardian Contact',
          style: const TextStyle(
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
              decoration: _fieldDecoration('Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: _fieldDecoration('Phone Number'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: relationController,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration('Relation'),
            ),
          ],
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
                : () => _saveContact(
                      index: index,
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      relation: relationController.text.trim(),
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5FE6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              index == null ? 'Add' : 'Save',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteContact(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove contact?'),
        content:
            Text('Delete ${_contacts[index].name} from guardian contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final contact = _contacts[index];
              Navigator.pop(ctx);
              try {
                final response = await http.delete(
                  Uri.parse(
                    '${AppSession.apiBaseUrl}/guardian-contacts/${contact.id}/',
                  ),
                );
                if (response.statusCode == 204) {
                  setState(() => _contacts.removeAt(index));
                  _showSnack('Guardian contact deleted from database.');
                } else {
                  _showSnack('Could not delete contact.');
                }
              } catch (_) {
                _showSnack(
                    'Could not delete contact. Check backend connection.');
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFE05555)),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3FF),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A2E)),
        ),
        title: const Text(
          'Guardian Contacts',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Trusted contacts: ${_contacts.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B5FE6),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _contacts.isEmpty
                      ? const Center(
                          child: Text(
                            'No guardian contacts yet.',
                            style: TextStyle(color: Color(0xFF9B96B8)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                  ),
                                ],
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
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF6B5FE6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          contact.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                        ),
                                        Text(
                                          '${contact.relation} - ${contact.phone}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9B96B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _showContactEditor(index: index),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Color(0xFF6B5FE6),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteContact(index),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFE05555),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactEditor(),
        backgroundColor: const Color(0xFF6B5FE6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Contact',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _GuardianContact {
  final String id;
  final String name;
  final String phone;
  final String relation;

  const _GuardianContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
  });

  factory _GuardianContact.fromJson(Map<String, dynamic> json) {
    return _GuardianContact(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
    );
  }
}
