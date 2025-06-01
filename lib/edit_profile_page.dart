import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
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
  final _addressController = TextEditingController();

  bool _isEditing = false;
  double? _latitude;
  double? _longitude;

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
      final data = doc.data();
      final geoPoint = data?['userLocation'];
      if (geoPoint is GeoPoint) {
        _latitude = geoPoint.latitude;
        _longitude = geoPoint.longitude;
      }

      setState(() {
        _initialName = data?['userName'] ?? '';
        _initialEmail = data?['userEmail'] ?? '';
        _nameController.text = _initialName;
        _emailController.text = _initialEmail;
        _addressController.text = data?['userAddress'] ?? '';
      });
    }
  }
}


  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (_emailController.text.trim() != user.email) {
        await user.updateEmail(_emailController.text.trim());
      }

      if (_currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text.trim(),
        );
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(_newPasswordController.text.trim());
      }

      if (_addressController.text.trim().isNotEmpty) {
        List<geocoding.Location> locations = await geocoding.locationFromAddress(_addressController.text.trim());
        _latitude = locations.first.latitude;
        _longitude = locations.first.longitude;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'userName': _nameController.text.trim(),
        'userEmail': _emailController.text.trim(),
        'userAddress': _addressController.text.trim(),
        'userLocation': GeoPoint(_latitude!, _longitude!),
      });

      setState(() {
        _isEditing = false;
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
      _isEditing = false;
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
          final controller = TextEditingController();
          final password = await showDialog<String>(
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

          if (password == null || password.isEmpty) return;

          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );

          await user.reauthenticateWithCredential(credential);
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

  InputDecoration _inputBoxDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      filled: _isEditing,
      fillColor: _isEditing ? Colors.grey[200] : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black54),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black54),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSave = _isEditing;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("User Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.black),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            TextField(controller: _nameController, enabled: _isEditing, decoration: _inputBoxDecoration("Full Name")),
            const SizedBox(height: 16),
            TextField(controller: _emailController, enabled: _isEditing, decoration: _inputBoxDecoration("Email Address")),
            const SizedBox(height: 16),
           Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _addressController,
                  enabled: _isEditing,
                  decoration: _inputBoxDecoration("Enter Your Address (Street Name, City)"),
                ),
                if (_addressController.text.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text("* Location not set. Please update your address.", style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            !_isEditing
                ? TextField(
                    controller: TextEditingController(text: "********"),
                    enabled: false,
                    obscureText: true,
                    decoration: _inputBoxDecoration("Password"),
                  )
                : Column(
                    children: [
                      TextField(controller: _currentPasswordController, obscureText: true, decoration: _inputBoxDecoration("Current Password")),
                      const SizedBox(height: 16),
                      TextField(controller: _newPasswordController, obscureText: true, decoration: _inputBoxDecoration("New Password")),
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
                        backgroundColor: Colors.orange,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
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
                child: const Text("Delete Account", style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
