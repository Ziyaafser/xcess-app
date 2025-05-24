import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdminFoodDetailsPage extends StatefulWidget {
  final DocumentSnapshot foodData;

  const AdminFoodDetailsPage({super.key, required this.foodData});

  @override
  State<AdminFoodDetailsPage> createState() => _AdminFoodDetailsPageState();
}

class _AdminFoodDetailsPageState extends State<AdminFoodDetailsPage> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.foodData['foodName']);
    _descController = TextEditingController(text: widget.foodData['description']);
    _quantityController = TextEditingController(text: widget.foodData['quantity'].toString());
  }

  double getDynamicPrice(double originalPrice, Timestamp addedTime, Timestamp expiryTime) {
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

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance.collection('food').doc(widget.foodData.id).update({
        'foodName': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
      });
      Fluttertoast.showToast(msg: "Food updated successfully");
      setState(() => _isEditing = false);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  Future<void> _deleteFood() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Food"),
        content: const Text("Are you sure you want to delete this food item?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('food').doc(widget.foodData.id).delete();
      Fluttertoast.showToast(msg: "Food deleted successfully");
      Navigator.pop(context);
    }
  }

  InputDecoration _decoration(String label) {
    return _isEditing
        ? InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black54),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
          )
        : InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black87),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.foodData['imageUrl'];
    final vendorID = widget.foodData['vendorID'];
    final price = widget.foodData['price'].toDouble();
    final expiryTime = (widget.foodData['expiryTime'] as Timestamp).toDate();
    final addedTime = widget.foodData['addedTime'] as Timestamp;
    final dynamicPrice = getDynamicPrice(price, addedTime, Timestamp.fromDate(expiryTime));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(vendorID).get(),
      builder: (context, snapshot) {
        final vendorName = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.get('userName')
            : "Vendor";

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Food Management",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.black),
                onPressed: () => setState(() => _isEditing = !_isEditing),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  enabled: _isEditing,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _decoration("Food Name"),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Original Price: RM${price.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        Text("Discounted Price: RM${dynamicPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange)),
                      ],
                    ),
                    Text("Expiry: ${expiryTime.hour}:${expiryTime.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  enabled: _isEditing,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _decoration("Description"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _quantityController,
                  enabled: _isEditing,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _decoration("Quantity"),
                ),
                const SizedBox(height: 16),
                Text("Vendor: $vendorName", style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 5),
                if (_isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _deleteFood,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text("Delete Food", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
