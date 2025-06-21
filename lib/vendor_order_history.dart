import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VendorOrderHistoryPage extends StatefulWidget {
  const VendorOrderHistoryPage({super.key});

  @override
  State<VendorOrderHistoryPage> createState() => _VendorOrderHistoryPageState();
}

class _VendorOrderHistoryPageState extends State<VendorOrderHistoryPage> {
  String? vendorID;
  List<Map<String, dynamic>> pastOrders = [];
  bool isLoading = true;

  String sortOrder = 'Newest First';
  final List<String> sortOptions = ['Newest First', 'Oldest First'];

  @override
  void initState() {
    super.initState();
    vendorID = FirebaseAuth.instance.currentUser?.uid;
    fetchOrderHistory();
  }

  Future<void> fetchOrderHistory() async {
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
      pastOrders = allOrders;
      applySort();
      isLoading = false;
    });
  }

  void applySort() {
    pastOrders.sort((a, b) {
      final timeA = a['timestamp'] as Timestamp?;
      final timeB = b['timestamp'] as Timestamp?;

      if (timeA == null || timeB == null) return 0;

      if (sortOrder == 'Newest First') {
        return timeB.compareTo(timeA);
      } else {
        return timeA.compareTo(timeB);
      }
    });
  }

  String formatDateTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.grey.shade700;
      case 'Ready for Pickup':
        return Colors.orange;
      case 'Collected':
        return Colors.green;
      default:
        return Colors.black;
    }
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
            title: const Text("Order History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      const Text("Sort by Time: ",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: sortOrder,
                        items: sortOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            sortOrder = value!;
                            applySort();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: pastOrders.isEmpty
                      ? const Center(child: Text("No past orders found."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: pastOrders.length,
                          itemBuilder: (context, index) {
                            final order = pastOrders[index];
                            final status = order['status'] ?? 'Completed';
                            final timestamp = order['timestamp'] as Timestamp?;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text("Order ID: ${order['orderId']}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: statusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: statusColor(status),
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                              color: statusColor(status),
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text("Food: ${order['foodName']}"),
                                  Text("Qty: ${order['quantity']}"),
                                  Text("Price: RM ${order['price'].toStringAsFixed(2)}"),
                                  if (timestamp != null)
                                    Text("Time: ${formatDateTime(timestamp)}",
                                        style: const TextStyle(color: Color.fromARGB(255, 144, 144, 144))),
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
