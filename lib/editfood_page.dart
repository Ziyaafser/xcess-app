import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class EditFoodPage extends StatefulWidget {
  final String foodId;
  final String currentName;
  final String currentDesc;
  final double currentPrice;
  final int currentQty;
  final String currentImageUrl;
  final Timestamp currentExpiry;

  const EditFoodPage({
    super.key,
    required this.foodId,
    required this.currentName,
    required this.currentDesc,
    required this.currentPrice,
    required this.currentQty,
    required this.currentImageUrl,
    required this.currentExpiry,
  });

  @override
  State<EditFoodPage> createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _qtyController;
  DateTime? _expiryTime;
  File? _image;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _descController = TextEditingController(text: widget.currentDesc);
    _qtyController = TextEditingController(text: widget.currentQty.toString());
    _expiryTime = widget.currentExpiry.toDate();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _imageChanged = true;
      });
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    final ref = FirebaseStorage.instance.ref().child('food_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _submitChanges() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(msg: "Please complete all required fields.");
      return;
    }

    try {
      String imageUrl = widget.currentImageUrl;
      if (_imageChanged && _image != null) {
        imageUrl = await _uploadImage(_image!);
      }

      await FirebaseFirestore.instance.collection('food').doc(widget.foodId).update({
        'foodName': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'quantity': int.parse(_qtyController.text.trim()),
        'imageUrl': imageUrl,
      });

      Fluttertoast.showToast(msg: "Food updated successfully!");
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error updating food: $e");
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Food"),
        content: const Text("Are you sure you want to delete this food item?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('food').doc(widget.foodId).delete();
      Fluttertoast.showToast(msg: "Food deleted.");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Food"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: _imageChanged
                            ? FileImage(_image!)
                            : NetworkImage(widget.currentImageUrl) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.black54),
                    onPressed: _pickImage,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField("Food Name", _nameController),
              const SizedBox(height: 12),
              _buildTextField("Description", _descController, maxLines: 3),
              const SizedBox(height: 12),
              _buildTextField("Quantity", _qtyController, isNumber: true),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.currentPrice.toStringAsFixed(2),
                enabled: false,
                decoration: InputDecoration(
                  labelText: "Price (RM)",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: "Expires at: ${_expiryTime!.hour}:${_expiryTime!.minute.toString().padLeft(2, '0')}",
                enabled: false,
                decoration: InputDecoration(
                  labelText: "Expiry Time",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "* Price and expiry time cannot be edited after creation.",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitChanges,
                  child: const Text("Save Changes"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                     foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete Food"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 239, 21, 21),
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

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
