import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class CustomerRatingReviewPage extends StatefulWidget {
  const CustomerRatingReviewPage({super.key});

  @override
  State<CustomerRatingReviewPage> createState() => _CustomerRatingReviewPageState();
}

class _CustomerRatingReviewPageState extends State<CustomerRatingReviewPage> {
  List<Map<String, dynamic>> pastOrders = [];
  bool isLoading = true;
  String? userId;
  bool sortDescending = true;
  Map<String, Map<String, dynamic>> userReviews = {};

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    fetchOrderHistory();
    fetchUserReviews();
  }

  Future<void> fetchUserReviews() async {
    if (userId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userID', isEqualTo: userId)
        .get();

    Map<String, Map<String, dynamic>> reviewMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final foodName = data['foodName'];
      final vendorID = data['vendorID'];
      final orderId = data['orderID'];
      reviewMap['$foodName|$vendorID|$orderId'] = data;
    }

    setState(() {
      userReviews = reviewMap;
    });
  }

  Future<void> fetchOrderHistory() async {
    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> orders = [];
    final completedSnap = await FirebaseFirestore.instance
        .collection('orders')
        .doc(userId)
        .collection('completed')
        .orderBy('timestamp', descending: sortDescending)
        .get();

    for (var doc in completedSnap.docs) {
      orders.add({
        ...doc.data(),
        'orderId': doc.id,
      });
    }

    setState(() {
      pastOrders = orders;
      isLoading = false;
    });
  }

void showRatingDialog(String vendorId, String vendorName, String foodName, String orderId) {
    double rating = 3.0;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rate $foodName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
              onRatingUpdate: (value) {
                rating = value;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reviewController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Write a review',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
           await FirebaseFirestore.instance.collection('reviews').add({
                'vendorID': vendorId,
                'vendorName': vendorName,
                'userID': userId,
                'foodName': foodName,
                'rating': rating,
                'review': reviewController.text,
                'timestamp': Timestamp.now(),
                'orderID': orderId,
                'reply': null,
              });

              Navigator.pop(context);
              await fetchUserReviews();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  String formatDateTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
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
        title: const Text("Rating & Review",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        actions: [
          PopupMenuButton<bool>(
            onSelected: (value) {
              setState(() {
                sortDescending = value;
              });
              fetchOrderHistory();
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
          : pastOrders.isEmpty
              ? const Center(child: Text("No orders found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pastOrders.length,
                  itemBuilder: (context, index) {
                    final order = pastOrders[index];
                    final status = order['status'] ?? 'Completed';
                    final foodName = order['foodName'] ?? '';
                    final vendorName = order['vendorName'] ?? '';
                    final vendorId = order['vendorID'] ?? '';
                    final orderId = order['orderId'] ?? '';
                    final timestamp = order['timestamp'] as Timestamp?;
                    final colors = getStatusColors(status);
                    final reviewKey = '$foodName|$vendorId|$orderId';
                    final reviewData = userReviews[reviewKey];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Order ID: $orderId",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text("Food: $foodName"),
                          Text("Vendor: $vendorName"),
                          Text("Qty: ${order['quantity']}"),
                          Text("Price: RM ${order['price'].toStringAsFixed(2)}"),
                          Text("Date: ${timestamp != null ? formatDateTime(timestamp) : 'Unknown'}"),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors['bg'],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(status,
                                    style: TextStyle(
                                        color: colors['text'], fontWeight: FontWeight.w600)),
                              ),
                              if (status == 'Completed' && reviewData == null)
                                Text(" - waiting for vendor response",
                                    style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (reviewData != null) ...[
                            const Divider(),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.orange, size: 18),
                                const SizedBox(width: 6),
                                Text("Your Rating: ${reviewData['rating'].toString()}"),
                              ],
                            ),
                            Text("Your Review: ${reviewData['review']}"),
                            if (reviewData['reply'] != null && reviewData['reply'].toString().trim().isNotEmpty)
                              Text("Vendor Reply: ${reviewData['reply']}"),
                          ],
                          if (status == 'Collected' && reviewData == null)
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                icon: const Icon(Icons.star, size: 18, color: Colors.white),
                                label: const Text("Rate Now", style: TextStyle(color: Colors.white)),
                               onPressed: () {
                                  showRatingDialog(vendorId, vendorName, foodName, orderId);
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
