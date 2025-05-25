import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditUserPage extends StatefulWidget {
  final String userId;
  final String name;
  final String email;
  final String role;

  const EditUserPage({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  String _selectedRole = 'customer';
  final List<String> _roles = ['customer', 'vendor', 'admin'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _selectedRole = widget.role;
    _addressController = TextEditingController();

    // Load user address from Firestore
    FirebaseFirestore.instance.collection('users').doc(widget.userId).get().then((doc) {
      if (doc.exists) {
        setState(() {
          _addressController.text = doc.data()?['userAddress'] ?? '';
        });
      }
    });
  }

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'userName': _nameController.text.trim(),
        'userEmail': _emailController.text.trim(),
        'role': _selectedRole,
        'userAddress': _addressController.text.trim(),
      });
      Fluttertoast.showToast(msg: "User updated successfully");
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  void _cancelChanges() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit User",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email Address"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: "Address"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: _roles.map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              decoration: const InputDecoration(labelText: "Role"),
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelChanges,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
