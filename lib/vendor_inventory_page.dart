import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'addfood_page.dart';
import 'editfood_page.dart';
import 'vendor_help_center_page.dart';


class VendorInventoryPage extends StatefulWidget {
  const VendorInventoryPage({super.key});

  @override
  State<VendorInventoryPage> createState() => _VendorInventoryPageState();
}

class _VendorInventoryPageState extends State<VendorInventoryPage> {
  String vendorName = '';
  int _selectedIndex = 0;
  List<DocumentSnapshot> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchVendorName();
    listenToNotifications();
  }

  void fetchVendorName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          vendorName = doc.get('userName');
        });
      }
    }
  }

    Future<double> fetchVendorRating(String vendorId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('vendorID', isEqualTo: vendorId)
        .get();

    if (snapshot.docs.isEmpty) return 0.0;

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final rating = double.tryParse(doc['rating'].toString()) ?? 0.0;
      total += rating;
    }

    return total / snapshot.docs.length;
  }


    void listenToNotifications() {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .where('seen', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            notifications = snapshot.docs;
          });
        } else {
          setState(() {
            notifications = [];
          });
        }
      });
    }


      void markNotificationAsSeen(String docId) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(user.uid)
            .collection('userNotifications')
            .doc(docId)
            .update({'seen': true});

        setState(() {
          notifications.removeWhere((n) => n.id == docId);
        });
      }



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

     if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFoodPage()),
    );
    setState(() {
      _selectedIndex = 0;
    });
  } else if (index == 2) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VendorHelpCenterPage()),
    );
    setState(() {
      _selectedIndex = 0;
    });
  } else if (index == 3) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
    setState(() {
      _selectedIndex = 0;
    });
  } else {
    setState(() {
      _selectedIndex = index;
    });
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
                'assets/images/inventory.jpg',
                width: double.infinity,
                height: 225,
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 25,
                top: 30,
                right: 25,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName.isNotEmpty ? vendorName : "Loading...",
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .get(),
                      builder: (context, snapshot) {
                        String location = "Loading...";
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data?.data() as Map<String, dynamic>?;
                          location = (data != null &&
                                  data.containsKey('userAddress') &&
                                  data['userAddress'] != null &&
                                  data['userAddress'].toString().trim().isNotEmpty)
                              ? data['userAddress']
                              : "Location not set";
                        }

                        final isUnset = location == "Location not set";

                        return GestureDetector(
                          onTap: () {
                            if (isUnset) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfilePage()),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.orange, size: 17),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    color: isUnset ? Colors.redAccent : Colors.orange,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Your Inventory",
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddFoodPage()),
                            );
                          },
                          child: Row(
                            children: const [
                              Icon(Icons.add_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text("Add food",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: notifications.map((notification) {
                  final data = notification.data() as Map<String, dynamic>;
                  return Card(
                    color: Colors.yellow[100],
                    elevation: 3,
                    child: ListTile(
                      title: Text(
                        "New Order: ${data['foodName']} x${data['quantity']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          markNotificationAsSeen(notification.id);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 30),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('food')
                  .where('vendorID', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .where('isAvailable', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No food listed yet", style: TextStyle(color: Colors.grey)));
                }

                final foodItems = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.78,
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
                    final dynamicPrice = getStepBasedDynamicPrice(price, addedTime, expiryTime);

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

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  imageUrl,
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditFoodPage(
                                          foodId: food.id,
                                          currentName: name,
                                          currentDesc: food['description'],
                                          currentPrice: price,
                                          currentQty: quantity,
                                          currentImageUrl: imageUrl,
                                          currentExpiry: expiryTime,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white70,
                                    child: Icon(Icons.edit, size: 16, color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                               FutureBuilder<double>(
                                future: fetchVendorRating(food['vendorID']),
                                builder: (context, ratingSnapshot) {
                                  final rating = ratingSnapshot.data ?? 0.0;
                                  final ratingText = rating == 0.0 ? "N/A" : rating.toStringAsFixed(1);

                                  return Row(
                                    children: [
                                      const Icon(Icons.star, size: 16, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text(ratingText, style: const TextStyle(fontSize: 13)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text("$quantity units", style: const TextStyle(fontSize: 13)),
                                    ],
                                  );
                                },
                              ),
                              
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.timer, size: 14, color: Colors.redAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      remainingTimeText,
                                      style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      "RM${price.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "RM${dynamicPrice.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  double getStepBasedDynamicPrice(double originalPrice, Timestamp addedTime, Timestamp expiryTime) {
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