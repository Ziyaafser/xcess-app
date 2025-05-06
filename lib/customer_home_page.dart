import 'package:flutter/material.dart';
import 'edit_profile_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/images/dashboard.jpg',
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 25,
                top: 35,
                right: 25,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Your Location", style: TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.location_on, color: Colors.white, size: 18),
                        SizedBox(width: 5),
                        Text("Johor Bahru", style: TextStyle(fontSize: 16, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Provides the best\nfood for you",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Center(
            child: Text("No food available yet", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: _onNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
