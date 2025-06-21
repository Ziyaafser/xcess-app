import 'package:flutter/material.dart';
import 'vendor_order_management_page.dart';
import 'vendor_order_history.dart';
import 'vendor_review.dart';

class VendorHelpCenterPage extends StatelessWidget {
  const VendorHelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
          backgroundColor: Colors.orange,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Help Centre",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hi, how can we help you?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            _helpTile(
              icon: Icons.manage_accounts_rounded,
              title: "Order Management",
              subtitle: "Manage active orders and update statuses.",
              onTap: () {
                Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendorOrderManagementPage()),
                    );
               },
            ),

            _helpTile(
              icon: Icons.history,
              title: "Order History",
              subtitle: "See all your completed orders.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VendorOrderHistoryPage()),
                );
              },
            ),

            _helpTile(
              icon: Icons.rate_review_outlined,
              title: "Review",
              subtitle: "View ratings and feedback from customers.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VendorReviewPage()),
                );
              },
            ),

            _helpTile(
              icon: Icons.analytics_outlined,
              title: "Impact Tracker",
              subtitle: "Track your sustainability and sales impact.",
              onTap: () {
                // TODO: Navigate to impact tracker page
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
