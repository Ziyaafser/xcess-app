import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_page.dart';
import 'account_management_page.dart';
import 'admin_food_management_page.dart';
import 'admin_view_orders_page.dart'; // <-- Add this import

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int totalUsers = 0;
  int totalVendors = 0;
  int totalCustomers = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchUserCounts();
  }

  Future<void> fetchUserCounts() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    int vendors = 0;
    int customers = 0;

    for (var doc in snapshot.docs) {
      final role = doc['role'];
      if (role == 'vendor') {
        vendors++;
      } else if (role == 'customer') {
        customers++;
      }
    }

    setState(() {
      totalVendors = vendors;
      totalCustomers = customers;
      totalUsers = vendors + customers;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditProfilePage()),
      );
    }
  }

  Widget _buildStatBox(String label, int count) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/images/admin.jpg',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 45,
                right: 20,
                child: Image.asset(
                  'assets/images/xcess_logo.png',
                  height: 100,
                ),
              ),
              Positioned(
                top: 45,
                left: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Welcome, Admin", style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                    SizedBox(height: 0),
                    Text("Xcess", style: TextStyle(color: Colors.orange, fontSize: 45, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                _buildStatBox("Users", totalUsers),
                _buildStatBox("Vendors", totalVendors),
                _buildStatBox("Customers", totalCustomers),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                _buildMenuTile("Account Management", Icons.manage_accounts, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountManagementPage()),
                  );
                }),
                _buildMenuTile("Food Management", Icons.fastfood, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminFoodManagementPage()),
                  );
                }),
                _buildMenuTile("View Orders", Icons.receipt_long, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminViewOrdersPage()), // <== New navigation
                  );
                }),
                _buildMenuTile("View Analytics", Icons.bar_chart, () {
                  // TODO: Navigate to Analytics Page
                }),
                _buildMenuTile("Send Notification", Icons.notifications_active, () {
                  // TODO: Navigate to Notification Page
                }),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
