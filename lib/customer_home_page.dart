import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'explore_page.dart';
import 'foodDetails_page.dart';
import 'cart_page.dart';
import 'customer_help_center_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;

  void _onNavTapped(int index) async {
  if (index == 1) {
    // Cart Page
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
    setState(() {
      _selectedIndex = 0;
    });
  } else if (index == 2) {
    // Help Centre Page
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerHelpCentrePage()),
    );
    setState(() {
      _selectedIndex = 0;
    });
  } else if (index == 3) {
    // Profile Page
    await Navigator.push(
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


  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    const R = 6371;
    final lat1 = point1.latitude * pi / 180;
    final lon1 = point1.longitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final lon2 = point2.longitude * pi / 180;

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  void _showNotifications(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final notifSnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('userNotifications')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    for (var doc in notifSnapshot.docs) {
      if (doc['status'] == 'unread') {
        await doc.reference.update({'status': 'read'});
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notifications"),
        content: SizedBox(
          width: double.maxFinite,
          child: notifSnapshot.docs.isEmpty
              ? const Text("No notifications found.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifSnapshot.docs.length,
                  itemBuilder: (context, index) {
                    final doc = notifSnapshot.docs[index];
                    final data = doc.data();
                    final message = data['message'] ?? '';
                    final foodName = data['foodName'] ?? '';

                    return ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(foodName.isNotEmpty ? foodName : "Food Update"),
                      subtitle: Text(message),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () async {
                          await doc.reference.update({'status': 'read'});
                          Navigator.pop(context);
                          _showNotifications(context); // refresh list
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🔔 Real-time notification banner
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection('userNotifications')
                .where('status', isEqualTo: 'unread')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox();
              }

              final notif = snapshot.data!.docs.first;
              final message = notif['message'] ?? '';

              return Container(
                color: Colors.orange[100],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.deepOrange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        notif.reference.update({'status': 'read'});
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final userLocation = userData['userLocation'] != null &&
                        userData['userLocation'] is GeoPoint
                    ? userData['userLocation'] as GeoPoint
                    : null;

                return CustomScrollView(
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

                          // 🔍 Search icon
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

                          // 🔔 Notification icon with badge
                          Positioned(
                            right: 16,
                            top: 90,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('userNotifications')
                                  .where('status', isEqualTo: 'unread')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final unreadCount = snapshot.data?.docs.length ?? 0;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showNotifications(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.notifications, color: Colors.orange),
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 20,
                                            minHeight: 20,
                                          ),
                                          child: Text(
                                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // 📍 Location and heading text
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
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.white, size: 18),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        userData['userAddress'] ?? 'Location not set',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: userData['userAddress'] == null
                                              ? Colors.redAccent
                                              : Colors.white,
                                          fontStyle: userData['userAddress'] == null
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                          decoration: userData['userAddress'] == null
                                              ? TextDecoration.underline
                                              : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final foodItems = snapshot.data!.docs.where((doc) {
                            final expiryTime = doc['expiryTime'] as Timestamp?;
                            if (expiryTime == null) return true;
                            return expiryTime.toDate().isAfter(DateTime.now());
                          }).toList();

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

                              String remainingTimeText = remaining.isNegative
                                  ? "Expired"
                                  : "${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left";

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(vendorID)
                                    .get(),
                                builder: (context, vendorSnapshot) {
                                  if (!vendorSnapshot.hasData || !vendorSnapshot.data!.exists) {
                                    return const SizedBox();
                                  }

                                  final vendorData =
                                      vendorSnapshot.data!.data() as Map<String, dynamic>;
                                  final vendorName = vendorData['userName'] ?? 'Restaurant';
                                
                                  final vendorLocation = vendorData['userLocation'] != null &&
                                          vendorData['userLocation'] is GeoPoint
                                      ? vendorData['userLocation'] as GeoPoint
                                      : null;

                                  double? distanceInKm;
                                  if (userLocation != null && vendorLocation != null) {
                                    distanceInKm = calculateDistance(userLocation, vendorLocation);
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FoodDetailsPage(foodData: food),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.grey.shade200, blurRadius: 6),
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
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(name,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 4),
                                                Text(vendorName,
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black54)),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star,
                                                        size: 16, color: Colors.orange),
                                                    const SizedBox(width: 4),
                                                    const Text("4.9",
                                                        style: TextStyle(fontSize: 13)),
                                                    const SizedBox(width: 12),
                                                    const Icon(Icons.inventory_2_outlined,
                                                        size: 14, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text("$quantity units",
                                                        style:
                                                            const TextStyle(fontSize: 13)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.timer,
                                                        size: 14, color: Colors.redAccent),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      remainingTimeText,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.redAccent),
                                                    ),
                                                    if (distanceInKm != null) ...[
                                                      const SizedBox(width: 10),
                                                      const Icon(Icons.location_on_outlined,
                                                          size: 14, color: Colors.grey),
                                                      const SizedBox(width: 1),
                                                      Text(
                                                        "${distanceInKm.toStringAsFixed(2)} km",
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.black),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Text("RM${price.toStringAsFixed(2)}",
                                                        style: const TextStyle(
                                                            decoration:
                                                                TextDecoration.lineThrough,
                                                            color: Colors.grey,
                                                            fontSize: 13)),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                        "RM${dynamicPrice.toStringAsFixed(2)}",
                                                        style: const TextStyle(
                                                            color: Colors.deepOrange,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14)),
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
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: "Help"),
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
