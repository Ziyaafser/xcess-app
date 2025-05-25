import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // ✅ this is correct
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';


class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _descController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _expiryTime;
  File? _image;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    String fileName = 'food_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _submitFood() async {
    if (!_formKey.currentState!.validate() || _expiryTime == null || _image == null) {
      Fluttertoast.showToast(msg: 'Please complete all fields including image and expiry time.');
      return;
    }

    final now = DateTime.now();
    if (_expiryTime!.difference(now).inMinutes < 120) {
      Fluttertoast.showToast(msg: 'Expiry time must be at least 2 hours from now.');
      return;
    }

    try {
      String imageUrl = await _uploadImage(_image!);
      final vendorID = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('food').add({
        'foodName': _foodNameController.text.trim(),
        'description': _descController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
        'price': double.parse(_priceController.text.trim()),
        'imageUrl': imageUrl,
        'expiryTime': Timestamp.fromDate(_expiryTime!),
        'addedTime': Timestamp.fromDate(now),
        'vendorID': vendorID,
        'isAvailable': true,
      });

      Fluttertoast.showToast(msg: 'Food added successfully!');
      Navigator.pop(context); // Go back after success
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to add food: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.orange,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Add Food",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
          
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_image != null)
                Image.file(_image!, height: 150)
              else
                Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _pickImage,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _foodNameController,
                decoration: _inputDecoration("Food Name"),
                validator: (val) => val!.isEmpty ? 'Enter food name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descController,
                decoration: _inputDecoration("Description"),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _quantityController,
                decoration: _inputDecoration("Quantity"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Enter quantity' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _priceController,
                decoration: _inputDecoration("Price (RM)"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val!.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 12),

           Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.orange,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                            timePickerTheme: const TimePickerThemeData(
                            dialBackgroundColor: Color(0xFFFFF3E0),   // soft orange bg
                            dialHandColor: Colors.orange,
                            dialTextColor: Colors.black,
                            hourMinuteColor: Colors.orange,       // lighter than solid orange
                            hourMinuteTextColor: Colors.black,
                            entryModeIconColor: Colors.orange,
                            helpTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                            dayPeriodTextColor: Colors.black,
                            dayPeriodColor: Colors.orange,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedTime != null) {
                      final now = DateTime.now();
                      final fullDate = DateTime(
                        now.year, now.month, now.day,
                        pickedTime.hour, pickedTime.minute,
                      );
                      setState(() => _expiryTime = fullDate);
                    }
                  },
                  icon: const Icon(Icons.timer, color: Colors.white),
                  label: Text(
                    _expiryTime == null
                        ? 'Select Expiry Time'
                        : 'Expires at: ${_expiryTime!.hour}:${_expiryTime!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ),
            ],
          ),

              const SizedBox(height: 6),
             const Text(
                "* Food expiry time must be at least 2 hours from now.",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
              SizedBox(height: 4),
              const Text(
                "* Price and expiry time cannot be edited after creation.",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),

              const SizedBox(height: 16),

              _dynamicPricingInfoCard(),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitFood,
                  child: const Text("Add Food"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

Widget _dynamicPricingInfoCard() {
  return Card(
    color: Colors.orange.shade50,
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "💡 How Dynamic Pricing Works",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "The system will automatically reduce the food price based on how close it is to the expiry time you set.",
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            "- Price updates every 15 minutes for better accuracy and performance.\n"
            "- Discount increases gradually as time passes.\n"
            "- Max 50% discount is applied exactly 1 hour before expiry.\n"
            "- The price stays at 50% until expiry.\n"
            "- Food will be automatically removed from the listing after expiry.",
            style: TextStyle(fontSize: 13),
          ),
          SizedBox(height: 8),
          Text(
            "Formula: 50 × (1 - (remaining time ÷ total time))\n"
            "• Only applies from time of food creation to 1 hour before expiry.",
            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ),
  );
}
}
