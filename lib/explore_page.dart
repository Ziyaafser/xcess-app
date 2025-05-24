import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Food"),
        backgroundColor: Colors.white
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Food',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Color.fromARGB(255, 247, 218, 184),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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

                final allFoods = snapshot.data!.docs.where((doc) {
                  final name = doc['foodName'].toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (allFoods.isEmpty) {
                  return const Center(
                    child: Text("No matching food found", style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  itemCount: allFoods.length,
                  itemBuilder: (context, index) {
                    final food = allFoods[index];
                    final name = food['foodName'];
                    final imageUrl = food['imageUrl'];
                    final price = food['price'].toDouble();
                    final vendorID = food['vendorID'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(vendorID).get(),
                      builder: (context, userSnapshot) {
                        final vendorName = userSnapshot.hasData && userSnapshot.data!.exists
                            ? userSnapshot.data!.get('userName')
                            : "Vendor";

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("by $vendorName"),
                      
                          onTap: () {
                            // TODO: Navigate to foodDetails_page.dart
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
