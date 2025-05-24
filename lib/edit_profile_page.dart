import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'login_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _editName = false;
  bool _editEmail = false;
  bool _editPassword = false;

  String _initialName = '';
  String _initialEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  void _loadUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _initialName = doc.get('userName');
          _initialEmail = doc.get('userEmail');
          _nameController.text = _initialName;
          _emailController.text = _initialEmail;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: "User not logged in.");
      return;
    }

    try {
      if (_editEmail && _emailController.text.trim() != user.email) {
        await user.updateEmail(_emailController.text.trim());
      }

      if (_editPassword &&
          _currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty) {
        final cred = EmailAuthProvider.credential(
            email: user.email!, password: _currentPasswordController.text.trim());
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(_newPasswordController.text.trim());
      }

      if (_editName) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'userName': _nameController.text.trim(),
        });
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'userEmail': _emailController.text.trim(),
      });

      setState(() {
        _initialName = _nameController.text.trim();
        _initialEmail = _emailController.text.trim();
        _editName = false;
        _editEmail = false;
        _editPassword = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
      });

      Fluttertoast.showToast(msg: 'Profile updated successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    }
  }

  void _cancelChanges() {
    setState(() {
      _nameController.text = _initialName;
      _emailController.text = _initialEmail;
      _editName = false;
      _editEmail = false;
      _editPassword = false;
      _currentPasswordController.clear();
      _newPasswordController.clear();
    });
  }

  Future<void> _logoutUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Logout")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

Future<void> _deleteAccount() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Delete Account"),
      content: const Text("This will permanently delete your account."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Reauthenticate first
        final email = user.email!;
        final password = await _askPassword(context); // Ask the user to input current password
        if (password == null || password.isEmpty) return;

        final credential = EmailAuthProvider.credential(email: email, password: password);
        await user.reauthenticateWithCredential(credential);

        // Now delete from Firebase Auth and Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        await user.delete();

        Fluttertoast.showToast(msg: 'Account deleted');
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error deleting account: $e');
      }
    }
  }
}

// Helper to show a password prompt dialog
Future<String?> _askPassword(BuildContext context) async {
  final controller = TextEditingController();
  return await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reauthenticate'),
      content: TextField(
        controller: controller,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Enter your password'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text("Continue"),
        ),
      ],
    ),
  );
}

  Widget _editableField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required VoidCallback onTapEdit,
    bool obscure = false,
    bool isMasked = false,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(5),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.edit, color: Colors.black),
          onPressed: () => setState(onTapEdit),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSave = _editName || _editEmail || _editPassword;

    return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "User Profile",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      centerTitle: true,
      
    ),
        body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            _editableField(
              label: "Full Name",
              controller: _nameController,
              enabled: _editName,
              onTapEdit: () => _editName = true,
            ),
            const SizedBox(height: 16),
            _editableField(
              label: "Email Address",
              controller: _emailController,
              enabled: _editEmail,
              onTapEdit: () => _editEmail = true,
            ),
            const SizedBox(height: 16),
            !_editPassword
                ? _editableField(
                    label: "Password",
                    controller: TextEditingController(text: "********"),
                    enabled: false,
                    obscure: true,
                    onTapEdit: () => _editPassword = true,
                  )
                : Column(
                    children: [
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Current Password",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "New Password",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 30),
            if (showSave)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Save Changes", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logoutUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _deleteAccount,
                child: const Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
