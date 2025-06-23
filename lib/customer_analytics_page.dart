import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerAnalyticsPage extends StatefulWidget {
  const CustomerAnalyticsPage({super.key});

  @override
  State<CustomerAnalyticsPage> createState() => _CustomerAnalyticsPageState();
}

class _CustomerAnalyticsPageState extends State<CustomerAnalyticsPage> {
  double totalSpend = 0.0;
  double todaySpend = 0.0;
  int totalOrders = 0;
  double estimatedKgSaved = 0.0;

  final String customerId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    fetchCustomerOrderData();
  }

  Future<void> fetchCustomerOrderData() async {
    double spendTodayTemp = 0.0;
    double spendTotalTemp = 0.0;
    int ordersCount = 0;
    int totalQty = 0;
    final now = DateTime.now();

    final completedOrders = await FirebaseFirestore.instance
        .collection('orders')
        .doc(customerId)
        .collection('completed')
        .get();


    print("Fetched ${completedOrders.docs.length} completed orders for userID: $customerId");

    for (var doc in completedOrders.docs) {
      final data = doc.data();
      final qty = int.tryParse(data['quantity'].toString()) ?? 0;
      final price = double.tryParse(data['price'].toString()) ?? 0.0;
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

      print("Document: quantity=$qty, price=$price, timestamp=$timestamp");

      totalQty += qty;
      spendTotalTemp += price * qty;
      ordersCount++;

      if (timestamp != null &&
          timestamp.year == now.year &&
          timestamp.month == now.month &&
          timestamp.day == now.day) {
        spendTodayTemp += price * qty;
      }
    }

    setState(() {
      todaySpend = spendTodayTemp;
      totalSpend = spendTotalTemp;
      totalOrders = ordersCount;
      estimatedKgSaved = totalQty * 0.5;
    });

    print("Today Spend: $todaySpend, Total Spend: $totalSpend, Total Orders: $totalOrders, Estimated KG Saved: $estimatedKgSaved");
  }

  Widget buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget buildImpactCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6F1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withOpacity(0.15),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 170,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTodaySpend = NumberFormat.currency(symbol: "RM ").format(todaySpend);
    final formattedTotalSpend = NumberFormat.currency(symbol: "RM ").format(totalSpend);

    // Sustainability calculations
    double totalWaterSaved = estimatedKgSaved * 100; // in liters
    int showerMinutes = (totalWaterSaved / 17).round(); // based on 17L/min
    int smartphoneCharges = (estimatedKgSaved * 1126).round();
    double peopleFed = estimatedKgSaved; // 1kg feeds 1 person

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Customer Analytics",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Customer Performance", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              buildMetricCard("YOUR SPEND TODAY", formattedTodaySpend, Colors.orange.shade500),
              buildMetricCard("TOTAL AMOUNT SPENT", formattedTotalSpend, const Color(0xFFeec280)),
              buildMetricCard("TOTAL ORDERS", '$totalOrders orders', Colors.orange.shade500),
              const SizedBox(height: 32),
              const Text("Sustainability Impact Tracker", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 16),
              buildMetricCard("ESTIMATED AMOUNT (KG) SAVED", '${estimatedKgSaved.toStringAsFixed(1)} KG', Colors.orange.shade500),
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  "  Note: Estimated based on 0.5KG saved per unit of food purchased.",
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
              buildImpactCard("Total water saved through surplus redirection", "${totalWaterSaved.toStringAsFixed(0)} L", Icons.water_drop_rounded, Colors.blue),
              buildImpactCard("Equivalent shower minutes saved", "$showerMinutes minutes", Icons.shower, const Color.fromARGB(255, 182, 88, 22)),
              buildImpactCard("How many people that food could feed", "${peopleFed.toStringAsFixed(1)} people", Icons.restaurant, Colors.pink),
              buildImpactCard("Equivalent smartphone charges (CO₂)", "$smartphoneCharges charges", Icons.battery_charging_full, Colors.green),
              const SizedBox(height: 32),
              Center(
                child: Image.asset(
                  'assets/images/xcess_logo.png',
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
