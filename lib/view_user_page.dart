import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewUserPage extends StatefulWidget {
  final String name;
  final String email;
  final String role;

  const ViewUserPage({
    super.key,
    required this.name,
    required this.email,
    required this.role,
  });

  @override
  State<ViewUserPage> createState() => _ViewUserPageState();
}

class _ViewUserPageState extends State<ViewUserPage> {
  String? address;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  void _loadUserAddress() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userEmail', isEqualTo: widget.email)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      setState(() {
        address = doc.data()['userAddress'] ?? 'Not set';
      });
    } else {
      setState(() {
        address = 'Not found';
      });
    }
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
          "User Details",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.name),
            const SizedBox(height: 16),
            const Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.email),
            const SizedBox(height: 16),
            const Text("Role", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.role),
            const SizedBox(height: 16),
            const Text("Address", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(address ?? 'Loading...'),
          ],
        ),
      ),
    );
  }
}
