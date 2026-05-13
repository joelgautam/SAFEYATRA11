import 'package:flutter/material.dart';

class GuardianContactsScreen extends StatefulWidget {
  const GuardianContactsScreen({super.key});

  @override
  State<GuardianContactsScreen> createState() => _GuardianContactsScreenState();
}

class _GuardianContactsScreenState extends State<GuardianContactsScreen> {
  final List<_GuardianContact> _contacts = [
    _GuardianContact(name: 'Mom', phone: '+977 98XXXXXXXX', relation: 'Mother'),
    _GuardianContact(name: 'Sister', phone: '+977 97XXXXXXXX', relation: 'Sister'),
    _GuardianContact(
      name: 'Best Friend',
      phone: '+977 96XXXXXXXX',
      relation: 'Friend',
    ),
  ];

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
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9B96B8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final relation = relationController.text.trim();

              if (name.isEmpty || phone.isEmpty || relation.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              setState(() {
                if (index == null) {
                  _contacts.add(
                    _GuardianContact(
                      name: name,
                      phone: phone,
                      relation: relation,
                    ),
                  );
                } else {
                  _contacts[index] = _GuardianContact(
                    name: name,
                    phone: phone,
                    relation: relation,
                  );
                }
              });
              Navigator.pop(ctx);
            },
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
        content: Text('Delete ${_contacts[index].name} from guardian contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _contacts.removeAt(index));
              Navigator.pop(ctx);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            child: ListView.builder(
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
                        child: const Icon(Icons.person, color: Color(0xFF6B5FE6)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              '${contact.relation} • ${contact.phone}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9B96B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showContactEditor(index: index),
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
  final String name;
  final String phone;
  final String relation;

  const _GuardianContact({
    required this.name,
    required this.phone,
    required this.relation,
  });
}
