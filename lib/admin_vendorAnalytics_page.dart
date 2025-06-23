import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';

class AdminVendorAnalyticsPage extends StatefulWidget {
  const AdminVendorAnalyticsPage({super.key});

  @override
  State<AdminVendorAnalyticsPage> createState() =>
      _AdminVendorAnalyticsPageState();
}

class _AdminVendorAnalyticsPageState extends State<AdminVendorAnalyticsPage> {
  String? selectedVendorId;
  String? selectedVendorName;
  double totalRevenue = 0.0;
  double todayRevenue = 0.0;
  int totalUnitsSold = 0;
  double estimatedKgSaved = 0.0;
  Map<String, double> bestSellingItems = {};
  List<Map<String, dynamic>> vendors = [];

  @override
  void initState() {
    super.initState();
    fetchVendors();
  }

  Future<void> fetchVendors() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'vendor').get();
    setState(() {
        vendors = snapshot.docs
        .map((doc) => {
              'id': doc['userID'],
              'name': doc['userName'] ?? 'Unknown',
            })
        .toList();
    });
  }

  Future<void> fetchVendorSalesData(String vendorId) async {
    double totalRevenueTemp = 0.0;
    double todayRevenueTemp = 0.0;
    int totalQty = 0;
    Map<String, double> itemSales = {};
    final now = DateTime.now();

    final completedOrders = await FirebaseFirestore.instance
        .collectionGroup('completed')
        .where('vendorID', isEqualTo: vendorId)
        .get();

    for (var doc in completedOrders.docs) {
      final data = doc.data();
      final qty = int.tryParse(data['quantity'].toString()) ?? 0;
      final price = double.tryParse(data['price'].toString()) ?? 0.0;
      final foodName = data['foodName'] ?? 'Unknown';
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

      totalRevenueTemp += price * qty;
      totalQty += qty;
      itemSales[foodName] = (itemSales[foodName] ?? 0) + qty.toDouble();

      if (timestamp != null &&
          timestamp.year == now.year &&
          timestamp.month == now.month &&
          timestamp.day == now.day) {
        todayRevenueTemp += price * qty;
      }
    }

    setState(() {
      totalRevenue = totalRevenueTemp;
      todayRevenue = todayRevenueTemp;
      totalUnitsSold = totalQty;
      estimatedKgSaved = totalQty * 0.5;
      bestSellingItems = itemSales;
    });
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
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
              child: Icon(icon, color: iconColor, size: 20),
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
    final formattedTodayRevenue =
        NumberFormat.currency(symbol: "RM ").format(todayRevenue);
    final formattedTotalRevenue =
        NumberFormat.currency(symbol: "RM ").format(totalRevenue);
    double totalWaterSaved = estimatedKgSaved * 100;
    int showerMinutes = (totalWaterSaved / 17).round();
    int smartphoneCharges = (estimatedKgSaved * 1126).round();
    double peopleFed = estimatedKgSaved;

    return Scaffold(
        appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Vendor Analytics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
        
         DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedVendorId,
                decoration: InputDecoration(
                  labelText: 'Select Vendor',
                  labelStyle: const TextStyle(color: Colors.orange),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                hint: const Text("Choose a vendor"),
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.orange,
                items: vendors.map((vendor) {
                  return DropdownMenuItem<String>(
                    value: vendor['id'],
                    child: Text(vendor['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  final vendor = vendors.firstWhere((v) => v['id'] == value);
                  setState(() {
                    selectedVendorId = value;
                    selectedVendorName = vendor['name'];
                  });
                  fetchVendorSalesData(value!);
                },
              ),

              const SizedBox(height: 20),

              if (selectedVendorId != null) ...[
                const Text("Sales Performance",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                buildMetricCard("TOTAL SALES (TODAY)", formattedTodayRevenue,
                    Colors.orange.shade500),
                buildMetricCard("TOTAL SALES (ALL TIME)", formattedTotalRevenue,
                    const Color(0xFFeec280)),
                buildMetricCard("TOTAL UNITS SOLD", '$totalUnitsSold items',
                    Colors.orange.shade500),
                const SizedBox(height: 29),
                const Text("Best Selling Items",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 29),
                bestSellingItems.isEmpty
                    ? const Text("No sales data available.")
                    : SizedBox(
                        height: 350,
                        child: PieChart(
                          dataMap: bestSellingItems,
                          chartType: ChartType.ring,
                          ringStrokeWidth: 38,
                          chartValuesOptions: const ChartValuesOptions(
                            showChartValuesInPercentage: true,
                            showChartValuesOutside: true,
                          ),
                          legendOptions: const LegendOptions(
                            showLegends: true,
                            legendPosition: LegendPosition.bottom,
                          ),
                        ),
                      ),
                const SizedBox(height: 32),
                const Text("Sustainability Impact Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 16),
                buildMetricCard("ESTIMATED AMOUNT (KG) SAVED",
                    '${estimatedKgSaved.toStringAsFixed(1)} KG', Colors.orange.shade500),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "  Note: Estimated based on 0.5KG saved per unit of food sold.",
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
                buildImpactCard("Total water saved through surplus redirection",
                    "${totalWaterSaved.toStringAsFixed(0)} L", Icons.water_drop_rounded, Colors.blue),
                buildImpactCard("Equivalent shower minutes saved", "$showerMinutes minutes",
                    Icons.shower, const Color.fromARGB(255, 182, 88, 22)),
                buildImpactCard("How many people that food could feed",
                    "${peopleFed.toStringAsFixed(1)} people", Icons.restaurant, Colors.pink),
                buildImpactCard("Equivalent smartphone charges (CO₂)",
                    "$smartphoneCharges charges", Icons.battery_charging_full, Colors.green),
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
            ],
          ),
        ),
      ),
    );
  }
}
