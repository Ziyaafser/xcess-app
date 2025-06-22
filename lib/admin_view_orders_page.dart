import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminViewOrdersPage extends StatefulWidget {
  const AdminViewOrdersPage({super.key});

  @override
  State<AdminViewOrdersPage> createState() => _AdminViewOrdersPageState();
}

class _AdminViewOrdersPageState extends State<AdminViewOrdersPage> {
  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  Map<String, Map<String, dynamic>> allReviews = {};
  Map<String, String> userNames = {};
  bool isLoading = true;
  bool sortDescending = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAllOrdersAndReviews();
    searchController.addListener(applySearchFilter);
  }

  Future<void> fetchAllOrdersAndReviews() async {
    setState(() => isLoading = true);

    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    for (var doc in usersSnapshot.docs) {
      userNames[doc.id] = doc.data()['userName'] ?? 'Unknown';
    }

    List<Map<String, dynamic>> tempOrders = [];
    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final completedSnap = await FirebaseFirestore.instance
          .collection('orders')
          .doc(userId)
          .collection('completed')
          .orderBy('timestamp', descending: sortDescending)
          .get();

      for (var doc in completedSnap.docs) {
        tempOrders.add({
          ...doc.data(),
          'orderId': doc.id,
          'userID': userId,
          'userName': userNames[userId] ?? 'Unknown',
        });
      }
    }

    final reviewsSnap = await FirebaseFirestore.instance.collection('reviews').get();
    Map<String, Map<String, dynamic>> tempReviews = {};
    for (var doc in reviewsSnap.docs) {
      final data = doc.data();
      final key = '${data['foodName']}|${data['vendorID']}|${data['orderID']}';
      tempReviews[key] = data;
    }

    setState(() {
      allOrders = tempOrders;
      allReviews = tempReviews;
      filteredOrders = List.from(tempOrders);
      isLoading = false;
    });
  }

  void applySearchFilter() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredOrders = allOrders.where((order) {
        return order['userName'].toString().toLowerCase().contains(query) ||
            order['vendorName'].toString().toLowerCase().contains(query) ||
            order['foodName'].toString().toLowerCase().contains(query) ||
            order['orderId'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  Map<String, Color> getStatusColors(String status) {
    switch (status) {
      case 'Collected':
        return {'bg': const Color(0xFFDFF5E3), 'text': const Color(0xFF388E3C)};
      case 'Completed':
        return {'bg': const Color(0xFFD6E4FF), 'text': const Color(0xFF2962FF)};
      case 'Ready for Pickup':
        return {'bg': const Color(0xFFFFF3E0), 'text': const Color(0xFFFF9800)};
      default:
        return {'bg': Colors.grey[300]!, 'text': Colors.grey[800]!};
    }
  }

  String formatDateTime(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
        title: const Text(
          "All Orders Overview",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<bool>(
            onSelected: (value) {
              setState(() => sortDescending = value);
              fetchAllOrdersAndReviews();
            },
            itemBuilder: (context) => [
              const PopupMenuItem<bool>(
                value: true,
                child: Text("Sort: Newest First"),
              ),
              const PopupMenuItem<bool>(
                value: false,
                child: Text("Sort: Oldest First"),
              ),
            ],
            icon: const Icon(Icons.sort, color: Colors.black),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchController,
                 decoration: InputDecoration(
                      hintText: "Search by customer, vendor, food, or order ID",
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.orange, width: 2),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredOrders.isEmpty
                      ? const Center(child: Text("No orders match your search."))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            final reviewKey =
                                '${order['foodName']}|${order['vendorID']}|${order['orderId']}';
                            final review = allReviews[reviewKey];
                            final colors = getStatusColors(order['status'] ?? 'Completed');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Order ID: ${order['orderId']}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text("Customer: ${order['userName']}"),
                                  Text("Vendor: ${order['vendorName']}"),
                                  Text("Food: ${order['foodName']}"),
                                  Text("Quantity: ${order['quantity']}"),
                                  Text("Price: RM ${order['price'].toStringAsFixed(2)}"),
                                  if (order['timestamp'] != null)
                                    Text("Date: ${formatDateTime(order['timestamp'])}"),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors['bg'],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(order['status'] ?? 'Completed',
                                        style: TextStyle(
                                            color: colors['text'], fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(height: 6),
                                  if (review != null) ...[
                                    const Divider(),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.orange),
                                        const SizedBox(width: 6),
                                        Text("Rating: ${review['rating']}"),
                                      ],
                                    ),
                                    Text("Review: ${review['review']}"),
                                    if (review['reply'] != null &&
                                        review['reply'].toString().isNotEmpty)
                                      Text("Vendor Reply: ${review['reply']}"),
                                  ],
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
