import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FoodDetailsPage extends StatefulWidget {
  final DocumentSnapshot foodData;

  const FoodDetailsPage({super.key, required this.foodData});

  @override
  State<FoodDetailsPage> createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  int _quantity = 1;

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

  @override
  Widget build(BuildContext context) {
    final name = widget.foodData['foodName'];
    final imageUrl = widget.foodData['imageUrl'];
    final price = widget.foodData['price'].toDouble();
    final quantity = widget.foodData['quantity'];
    final description = widget.foodData['description'];
    final vendorID = widget.foodData['vendorID'];
    final addedTime = widget.foodData['addedTime'] as Timestamp;
    final expiryTime = widget.foodData['expiryTime'] as Timestamp;

    final dynamicPrice = getStepBasedDynamicPrice(price, addedTime, expiryTime);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(vendorID).get(),
      builder: (context, vendorSnapshot) {
        String vendorName = "Vendor";
        if (vendorSnapshot.hasData && vendorSnapshot.data!.exists) {
          vendorName = vendorSnapshot.data!.get('userName');
        }

        bool exceedsStock = _quantity > quantity;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Food Details", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold, color: Colors.black)),
            centerTitle: true,
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.share, color: Colors.black),
              )
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(imageUrl, height: 220, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 20),
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                        const SizedBox(width: 8),
                        Text(
                          "RM${dynamicPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.storefront, color: Colors.orange, size: 18),
                        const SizedBox(width: 6),
                        Text(vendorName, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 20),
                        const Icon(Icons.inventory_2_outlined, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text("$quantity pcs left", style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 20),
                        const Icon(Icons.star, color: Colors.orange, size: 18),
                        const Text(" 4.9", style: TextStyle(fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(thickness: 1.2),
                    const SizedBox(height: 10),
                    const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(description, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 20),
                    const Divider(thickness: 1.2),
                    const SizedBox(height: 10),
                    const Text("Vendor Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text("Taman Universiti, Skudai, Johor Bahru, Malaysia",
                        style: TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                            ),
                            Text('$_quantity', style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() => _quantity++);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: exceedsStock
                              ? null
                              : () {
                                  // add to cart logic
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: exceedsStock ? Colors.grey : Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Add to Cart", style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (exceedsStock)
                Positioned(
                  bottom: 70,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Selected quantity exceeds available stock",
                      style: TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
