import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'customer_home_page.dart';

class PlaceOrderPage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double totalPrice;
  final Map<String, dynamic> vendorData;

  const PlaceOrderPage({
    super.key,
    required this.items,
    required this.totalPrice,
    required this.vendorData,
  });

  Future<void> handlePayment(BuildContext context) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createPaymentIntent');
      final response = await callable.call(<String, dynamic>{
        'amount': (totalPrice * 100).toInt(),
      });

      final clientSecret = response.data['clientSecret'];
      final nextAction = response.data['nextAction'];

      if (nextAction != null && nextAction['type'] == 'redirect_to_url') {
        // Handle GrabPay redirect
        final url = nextAction['redirect_to_url']['url'];
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch GrabPay URL');
        }

        // You might want to wait or check webhook status for completion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Redirected to GrabPay. Complete payment there.")),
        );

      } else {
        // Handle Card flow via PaymentSheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Xcess',
            style: ThemeMode.light,
          ),
        );

        await Stripe.instance.presentPaymentSheet();

        // After successful payment
        await saveOrder();
        await updateFoodQuantities();
        await clearCartFromVendor();

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                const SizedBox(height: 16),
                const Text("Payment Successful!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Your order has been placed successfully.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 12),
                const Text("Pickup Address:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  vendorData['userAddress']?.toString() ?? "Address not found",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerHomePage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Back to Home",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: $e")),
      );
    }
  }

  Future<void> saveOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final completedOrderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(user.uid)
        .collection('completed');

    final vendorId = vendorData['userID'];

  final notificationRef = FirebaseFirestore.instance
      .collection('notifications')
      .doc(vendorId)
      .collection('userNotifications');

    for (var item in items) {
      // Save completed order
      await completedOrderRef.add({
        'userId': user.uid,
        'vendorID': vendorData['userID']?.toString() ?? "",
        'vendorName': vendorData['userName']?.toString() ?? "",
        'vendorAddress': vendorData['userAddress']?.toString() ?? "",
        'city': vendorData['city']?.toString() ?? 'Johor Bahru',
        'foodName': item['foodName']?.toString() ?? "",
        'imageUrl': item['imageUrl']?.toString() ?? "",
        'price': item['price'] ?? 0.0,
        'quantity': item['quantity'] ?? 1,
        'timestamp': Timestamp.now(),
        'status': 'Pending',
        'foodId': item['foodId'] ?? "",
      });

      await notificationRef.add({
        'userId': vendorId,
        'role': 'vendor',
        'title': 'New Order Received',
        'foodName': item['foodName'] ?? "",
        'quantity': item['quantity'] ?? 1,
        'timestamp': Timestamp.now(),
        'seen': false,
      });
    }
  }




  Future<void> updateFoodQuantities() async {
    final batch = FirebaseFirestore.instance.batch();

    for (var item in items) {
      final foodId = item['id']; 
      final orderQty = item['quantity'] ?? 1;

      if (foodId == null) continue;

      final foodRef = FirebaseFirestore.instance.collection('food').doc(foodId);
      final foodSnap = await foodRef.get();

      if (!foodSnap.exists) continue;

      final currentQty = foodSnap.data()?['quantity'] ?? 0;
      final newQty = currentQty - orderQty;

      if (newQty <= 0) {
        batch.delete(foodRef);
      } else {
        batch.update(foodRef, {'quantity': newQty});
      }
    }

    await batch.commit();
  }


  Future<void> clearCartFromVendor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(user.uid)
        .collection('cart');

    final cartDocs = await cartRef.get();

    for (var doc in cartDocs.docs) {
      final data = doc.data();
      if (data['vendorID'] == vendorData['userID']) {
        await doc.reference.delete();
      }
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
        title: const Text("Checkout",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Saving food, serving purpose.",
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 12),
            const Text("Item Ordered", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...items.map((item) => _buildItemRow(item)).toList(),
            const SizedBox(height: 20),
            const Divider(thickness: 0.8),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Price",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text("RM${totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(thickness: 0.8),
            const SizedBox(height: 12),
            const Text("Pickup Address", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _detailRow("Name", vendorData['userName']?.toString() ?? "-"),
            _detailRow("Address", vendorData['userAddress']?.toString() ?? "-"),
            _detailRow("City", vendorData['city']?.toString() ?? "Johor Bahru"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (totalPrice <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Total price must be greater than RM0")),
                    );
                    return;
                  }
                  handlePayment(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Place Order",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    double price = item['price'] ?? 0.0;
    int qty = item['quantity'] ?? 1;
    double totalForItem = price * qty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['imageUrl']?.toString() ?? "",
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['foodName']?.toString() ?? "",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("RM${price.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$qty items",
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text("RM${totalForItem.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$title:", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right, style: const TextStyle(color: Colors.black))),
        ],
      ),
    );
  }
}
