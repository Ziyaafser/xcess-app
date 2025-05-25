import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'explore_page.dart';
import 'foodDetails_page.dart';

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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/dashboard.jpg',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  right: 16,
                  top: 30,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExplorePage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search, color: Colors.orange),
                    ),
                  ),
                ),
                Positioned(
                  left: 25,
                  top: 35,
                  right: 25,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Your Location",
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 4),
                      FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .get(),
                      builder: (context, snapshot) {
                        String displayAddress = "Loading...";
                        if (snapshot.hasData && snapshot.data!.exists) {
                          displayAddress = snapshot.data!.get('userAddress') ?? "No location set";
                        }

                        final isUnset = displayAddress == "No location set";

                        return Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 18),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                displayAddress,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isUnset ? Colors.redAccent : Colors.white,
                                  fontStyle: isUnset ? FontStyle.italic : FontStyle.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                      const SizedBox(height: 20),
                      const Text(
                        "Provides the best\nfood for you",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('food')
                  .where('isAvailable', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No food available yet",
                          style: TextStyle(color: Colors.grey)));
                }

                final foodItems = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: foodItems.length,
                  itemBuilder: (context, index) {
                    final food = foodItems[index];
                    final name = food['foodName'];
                    final imageUrl = food['imageUrl'];
                    final quantity = food['quantity'];
                    final price = food['price'].toDouble();
                    final addedTime = food['addedTime'] as Timestamp;
                    final expiryTime = food['expiryTime'] as Timestamp;
                    final vendorID = food['vendorID'];
                    final dynamicPrice =
                        getStepBasedDynamicPrice(price, addedTime, expiryTime);

                    final now = DateTime.now();
                    final expiry = expiryTime.toDate();
                    Duration remaining = expiry.difference(now);

                    String remainingTimeText;
                    if (remaining.isNegative) {
                      remainingTimeText = "Expired";
                    } else {
                      final hours = remaining.inHours;
                      final minutes = remaining.inMinutes.remainder(60);
                      remainingTimeText = "${hours}h ${minutes}m left";
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(vendorID)
                          .get(),
                      builder: (context, vendorSnapshot) {
                        String vendorName = "Restaurant";
                        if (vendorSnapshot.hasData &&
                            vendorSnapshot.data!.exists) {
                          vendorName =
                              vendorSnapshot.data!.get('userName') ?? vendorName;
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FoodDetailsPage(foodData: food),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 6)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.network(
                                    imageUrl,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        vendorName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              size: 16,
                                              color: Colors.orange),
                                          const SizedBox(width: 4),
                                          const Text("4.9",
                                              style:
                                                  TextStyle(fontSize: 13)),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.inventory_2_outlined,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text("$quantity units",
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.timer,
                                              size: 14,
                                              color: Colors.redAccent),
                                          const SizedBox(width: 4),
                                          Text(
                                            remainingTimeText,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.redAccent),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            "RM${price.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "RM${dynamicPrice.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              color: Colors.deepOrange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
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

  double getStepBasedDynamicPrice(
      double originalPrice, Timestamp addedTime, Timestamp expiryTime) {
    final now = DateTime.now();
    final expiry = expiryTime.toDate();
    final added = addedTime.toDate();
    final discountEnd = expiry.subtract(const Duration(hours: 1));

    if (now.isAfter(expiry)) return 0.0;
    if (now.isAfter(discountEnd)) return originalPrice * 0.5;

    final roundedNow = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      (now.minute ~/ 15) * 15,
    );

    final totalWindow = discountEnd.difference(added).inMinutes;
    final timeRemaining = discountEnd.difference(roundedNow).inMinutes;

    final progress = 1 - (timeRemaining / totalWindow);
    final discountPercent = (progress * 50).clamp(0, 50);
    return originalPrice * (1 - (discountPercent / 100));
  }
}
