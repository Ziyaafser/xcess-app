import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'place_order_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, bool> selectedItems = {};
  String? selectedVendor;
  Map<String, String> _vendorNameCache = {};
  bool _vendorNamesLoaded = false;

  Future<void> updateQuantity(String cartId, int quantity, int availableQty) async {
    if (quantity > availableQty) {
      Fluttertoast.showToast(msg: "Quantity exceeds stock");
      return;
    }
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(user!.uid)
        .collection('cart')
        .doc(cartId)
        .update({'quantity': quantity});
  }

  Future<void> deleteItem(String cartId) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(user!.uid)
        .collection('cart')
        .doc(cartId)
        .delete();
  }

  void toggleSelection(String cartId, String vendorID) {
    setState(() {
      bool isSelected = selectedItems[cartId] ?? false;

      if (!isSelected) {
        if (selectedVendor == null) {
          selectedVendor = vendorID;
        } else if (selectedVendor != vendorID) {
          Fluttertoast.showToast(msg: "Cannot select items from different vendors");
          return;
        }
      }

      selectedItems[cartId] = !isSelected;

      if (!selectedItems.containsValue(true)) {
        selectedVendor = null;
      }
    });
  }

  double calculateSelectedTotal(List<QueryDocumentSnapshot> cartItems) {
    double total = 0.0;
    for (var item in cartItems) {
      final data = item.data() as Map<String, dynamic>;
      if (selectedItems[item.id] ?? false) {
        total += data['price'] * data['quantity'];
      }
    }
    return total;
  }

  Future<void> _loadVendorNames(Set<String> vendorIDs) async {
    if (_vendorNamesLoaded) return;
    for (var id in vendorIDs) {
      if (!_vendorNameCache.containsKey(id)) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
        _vendorNameCache[id] = doc.exists ? doc.get('userName') ?? 'Unknown Vendor' : 'Unknown Vendor';
      }
    }
    _vendorNamesLoaded = true;
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
          "My Cart",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(user!.uid)
            .collection('cart')
            .snapshots(),
        builder: (context, cartSnapshot) {
          if (cartSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!cartSnapshot.hasData || cartSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Your cart is empty"));
          }

          final cartItems = cartSnapshot.data!.docs;
          final vendorIDs = cartItems.map((item) => (item.data() as Map)['vendorID'] as String).toSet();

          return FutureBuilder<void>(
            future: _loadVendorNames(vendorIDs),
            builder: (context, vendorSnapshot) {
              if (!_vendorNamesLoaded && vendorSnapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final groupedByVendorName = <String, List<QueryDocumentSnapshot>>{};
              for (var item in cartItems) {
                final data = item.data() as Map<String, dynamic>;
                final vendorID = data['vendorID'];
                final vendorName = _vendorNameCache[vendorID] ?? 'Unknown Vendor';

                groupedByVendorName.putIfAbsent(vendorName, () => []);
                groupedByVendorName[vendorName]!.add(item);
              }

              final selectedTotal = calculateSelectedTotal(cartItems);

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: groupedByVendorName.entries.map((entry) {
                        final vendorName = entry.key;
                        final items = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Vendor: $vendorName", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ...items.map((cart) {
                              final food = cart.data() as Map<String, dynamic>;
                              final cartId = cart.id;
                              final name = food['foodName'];
                              final imageUrl = food['imageUrl'];
                              final quantity = food['quantity'];
                              final available = food['available'];
                              final price = food['price'].toDouble();
                              final isSelected = selectedItems[cartId] ?? false;
                              final vendorID = food['vendorID'];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Checkbox left
                                     Checkbox(
                                      value: isSelected,
                                      onChanged: (_) => toggleSelection(cartId, vendorID),
                                      checkColor: Colors.white, 
                                      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                        if (states.contains(MaterialState.selected)) {
                                          return Colors.orange;
                                        }
                                        return Colors.grey.shade300;
                                      }),
                                    ),

                                      const SizedBox(width: 8),

                                      // Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                                      ),
                                      const SizedBox(width: 12),

                                      // Text info + quantity controls
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text("RM${price.toStringAsFixed(2)}"),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline),
                                                  onPressed: () {
                                                    if (quantity > 1) {
                                                      updateQuantity(cartId, quantity - 1, available);
                                                    }
                                                  },
                                                ),
                                                Text('$quantity'),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline),
                                                  onPressed: () {
                                                    updateQuantity(cartId, quantity + 1, available);
                                                  },
                                                ),
                                              ],
                                            ),
                                            if (quantity > available)
                                              const Text("Exceeds available stock!", style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),

                                      // Delete icon
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_outlined),
                                        onPressed: () => deleteItem(cartId),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            const Divider(thickness: 1),
                            const SizedBox(height: 10),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("RM${selectedTotal.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                )),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                       onPressed: selectedItems.containsValue(true)
                        ? () async {
                            final selectedDocs = cartItems
                                .where((doc) => selectedItems[doc.id] == true)
                                .toList();

                            if (selectedDocs.isEmpty) {
                              Fluttertoast.showToast(msg: "No items selected.");
                              return;
                            }

                            final vendorIDs = selectedDocs
                                .map((doc) => (doc.data() as Map<String, dynamic>)['vendorID'])
                                .toSet();

                            if (vendorIDs.length > 1) {
                              Fluttertoast.showToast(
                                  msg: "You can only checkout items from the same vendor.");
                              return;
                            }

                            final foodList = selectedDocs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return {
                                'foodName': data['foodName'],
                                'imageUrl': data['imageUrl'],
                                'price': data['price'],
                                'quantity': data['quantity'],
                              };
                            }).toList();

                            final vendorID = vendorIDs.first;
                            final vendorDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(vendorID)
                                .get();

                            if (!vendorDoc.exists) {
                              Fluttertoast.showToast(msg: "Vendor not found.");
                              return;
                            }

                            final vendorData = vendorDoc.data() as Map<String, dynamic>;

                            final total = foodList.fold<double>(
                                0.0, (sum, item) => sum + item['price'] * item['quantity']);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaceOrderPage(
                                  items: foodList,
                                  totalPrice: total,
                                  vendorData: vendorData,
                                ),
                              ),
                            );
                          }
                        : null,

                          child: const Text("Review Payment", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
