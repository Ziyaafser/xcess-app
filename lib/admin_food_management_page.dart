import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_food_details_page.dart';

class AdminFoodManagementPage extends StatefulWidget {
  const AdminFoodManagementPage({super.key});

  @override
  State<AdminFoodManagementPage> createState() => _AdminFoodManagementPageState();
}

class _AdminFoodManagementPageState extends State<AdminFoodManagementPage> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
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
        ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by food or vendor name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('food')
                  .where('isAvailable', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allFoods = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: allFoods.length,
                  itemBuilder: (context, index) {
                    final food = allFoods[index];
                    final foodName = food['foodName'].toString().toLowerCase();
                    final vendorID = food['vendorID'];
                    final matchesSearch = _searchQuery.isEmpty || foodName.contains(_searchQuery);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(vendorID).get(),
                      builder: (context, userSnapshot) {
                        String vendorName = "Vendor";
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          vendorName = userSnapshot.data!.get('userName').toString().toLowerCase();
                        }

                        final matchesVendor = vendorName.contains(_searchQuery);
                        if (!matchesSearch && !matchesVendor) return const SizedBox.shrink();

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              food['imageUrl'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(food['foodName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Vendor: $vendorName"),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminFoodDetailsPage(foodData: food),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
