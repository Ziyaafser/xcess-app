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
  bool isLoading = true;

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
          });
        }
      }
    }

    setState(() {
      vendorOrders = allOrders;
      isLoading = false;
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
          : vendorOrders.isEmpty
              ? const Center(child: Text("No active orders."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vendorOrders.length,
                  itemBuilder: (context, index) {
                    final data = vendorOrders[index];
                    final status = data['status'] ?? 'Completed';
                    final userId = data['userId'];
                    final orderId = data['orderId'];
                    final foodName = data['foodName'] ?? '';

                    Widget actionButton = const SizedBox.shrink();

                    if (status == 'Completed') {
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                          Text("Qty: ${data['quantity']}"),
                          Text("Status: $status"),
                          const SizedBox(height: 6),
                          actionButton,
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
