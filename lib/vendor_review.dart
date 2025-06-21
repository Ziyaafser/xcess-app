import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class VendorReviewPage extends StatefulWidget {
  const VendorReviewPage({super.key});

  @override
  State<VendorReviewPage> createState() => _VendorReviewPageState();
}

class _VendorReviewPageState extends State<VendorReviewPage> {
  String? vendorId;
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    vendorId = FirebaseAuth.instance.currentUser?.uid;
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    if (vendorId == null) return;
    final query = await FirebaseFirestore.instance
        .collection('reviews')
        .where('vendorID', isEqualTo: vendorId)
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      reviews = query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      isLoading = false;
    });
  }

  void showReplyDialog(String reviewId, String currentReply) {
    final controller = TextEditingController(text: currentReply);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reply to Review'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write your reply...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .doc(reviewId)
                  .update({'reply': controller.text});
              Navigator.pop(context);
              fetchReviews();
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
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
        title: const Text("Customer Reviews",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reviews.isEmpty
              ? const Center(child: Text("No reviews received yet."))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Note: Customer identities are kept anonymous to ensure privacy.",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    ...reviews.map((review) {
                      final foodName = review['foodName'] ?? 'Unknown';
                      final rating = review['rating']?.toDouble() ?? 0.0;
                      final comment = review['review'] ?? '';
                      final reply = review['reply'] ?? '';
                      final quantity = review['quantity']?.toString() ?? '-';
                      final timestamp = review['timestamp'] as Timestamp?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                            Text("Food: $foodName", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Qty: $quantity"),
                            const SizedBox(height: 4),
                            RatingBarIndicator(
                              rating: rating,
                              itemCount: 5,
                              itemSize: 20.0,
                              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                            ),
                            const SizedBox(height: 4),
                            Text("“$comment”", style: const TextStyle(fontStyle: FontStyle.italic)),
                            if (reply.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text("Vendor reply: $reply",
                                    style: const TextStyle(color: Colors.green)),
                              ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.reply, size: 18),
                                label: Text(reply.isEmpty ? "Reply" : "Edit Reply"),
                                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                                onPressed: () {
                                  showReplyDialog(review['id'], reply);
                                },
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
    );
  }
}
