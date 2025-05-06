import 'package:flutter/material.dart';

class ViewUserPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Details")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(name),
            const SizedBox(height: 16),
            const Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(email),
            const SizedBox(height: 16),
            const Text("Role", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(role),
          ],
        ),
      ),
    );
  }
}
