import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VendorOrderManagementPage extends StatefulWidget {
  const VendorOrderManagementPage({super.key});

  @override
  State<VendorOrderManagementPage> createState() => _VendorOrderManagementPageState();
}

class _VendorOrderManagementPageState extends State<VendorOrderManagementPage> {
  String? vendorID;
  List<Map<String, dynamic>> vendorOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  bool isLoading = true;
  String searchQuery = '';
  String sortOrder = 'Newest First'; // New state for sorting

  @override
  void initState() {
    super.initState();
    vendorID = FirebaseAuth.instance.currentUser?.uid;
    fetchVendorOrders();
  }

  Future<void> fetchVendorOrders() async {
    List<Map<String, dynamic>> allOrders = [];
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in usersSnap.docs) {
      final userId = userDoc.id;
      final userName = userDoc['userName'] ?? 'Unknown';

      final completedSnap = await FirebaseFirestore.instance
          .collection('orders')
          .doc(userId)
          .collection('completed')
          .get();

      for (var orderDoc in completedSnap.docs) {
        final data = orderDoc.data();
        if (data['vendorID'] == vendorID) {
          allOrders.add({
            ...data,
            'userId': userId,
            'orderId': orderDoc.id,
            'userName': userName,
          });
        }
      }
    }

    setState(() {
      vendorOrders = allOrders;
      applySearchFilter(searchQuery);
      isLoading = false;
    });
  }

  void applySearchFilter(String query) {
    searchQuery = query.toLowerCase();

    List<Map<String, dynamic>> results = vendorOrders.where((order) {
      final customerName = order['userName']?.toLowerCase() ?? '';
      final foodName = order['foodName']?.toLowerCase() ?? '';
      return customerName.contains(searchQuery) || foodName.contains(searchQuery);
    }).toList();

    results.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return sortOrder == 'Newest First'
          ? bTime.compareTo(aTime)
          : aTime.compareTo(bTime);
    });

    setState(() {
      filteredOrders = results;
    });
  }

  Future<void> updateOrderStatus(
    String userId,
    String orderId,
    String newStatus,
    String notificationMsg,
    String foodName,
  ) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(userId)
        .collection('completed')
        .doc(orderId)
        .update({'status': newStatus});

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('userNotifications')
        .add({
      'title': 'Order Update',
      'message': notificationMsg,
      'foodName': foodName,
      'timestamp': Timestamp.now(),
      'status': 'unread',
    });

    await fetchVendorOrders();
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

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
        title: const Text("Order Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by customer or food name',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: const Icon(Icons.search),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: applySearchFilter,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text("Sort: "),
                      DropdownButton<String>(
                        value: sortOrder,
                        items: ['Newest First', 'Oldest First'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              sortOrder = newValue;
                              applySearchFilter(searchQuery);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredOrders.isEmpty
                      ? const Center(child: Text("No active orders."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final data = filteredOrders[index];
                            final status = data['status'] ?? 'Completed';
                            final userId = data['userId'];
                            final orderId = data['orderId'];
                            final foodName = data['foodName'] ?? '';
                            final userName = data['userName'] ?? 'Unknown';
                            final timestamp = formatTimestamp(data['timestamp']);

                            Widget actionButton = const SizedBox.shrink();
                            if (status == 'Pending' || status == 'Completed') {
                              actionButton = ElevatedButton(
                                onPressed: () {
                                  updateOrderStatus(
                                    userId,
                                    orderId,
                                    'Ready for Pickup',
                                    'Your order is ready for pickup!',
                                    foodName,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("Mark as Ready", style: TextStyle(color: Colors.white)),
                              );
                            } else if (status == 'Ready for Pickup') {
                              actionButton = ElevatedButton(
                                onPressed: () {
                                  updateOrderStatus(
                                    userId,
                                    orderId,
                                    'Collected',
                                    'Thank you! Your order has been collected.',
                                    foodName,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("Mark as Collected", style: TextStyle(color: Colors.white)),
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(foodName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text("Order ID: $orderId"),
                                  Text("Customer: $userName"),
                                  Text("Qty: ${data['quantity']}"),
                                  Text("Status: $status"),
                                  Text("Time: $timestamp"),
                                  const SizedBox(height: 6),
                                  actionButton,
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
