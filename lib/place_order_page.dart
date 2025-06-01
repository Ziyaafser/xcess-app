import 'package:flutter/material.dart';

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
          "Checkout",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("You deserve better meal",
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 12),

            const Text("Item Ordered",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            ...items.map((item) => _buildItemRow(item)).toList(),

            const SizedBox(height: 20),
            const Divider(thickness: 0.8),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Price",
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text("RM${totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 0.8),

            const SizedBox(height: 12),
            const Text("Pickup Address",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            _detailRow("Name", vendorData['userName'] ?? "-"),
            _detailRow("Address", vendorData['userAddress'] ?? "-"),
            _detailRow("City", vendorData['city'] ?? "Johor Bahru"),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Payment integration here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
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
    double totalForItem = item['price'] * item['quantity'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['imageUrl'],
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
                Text(item['foodName'],
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("RM${item['price'].toStringAsFixed(2)}",
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${item['quantity']} items",
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text("RM${totalForItem.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
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
          Text("$title:",
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
