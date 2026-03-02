import 'package:booking_app/core/widgets/custom_loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'booking_screen.dart';

class ShopDetailsScreen extends StatelessWidget {
  final String shopId;
  final Map<String, dynamic> shopData;

  const ShopDetailsScreen({super.key, required this.shopId, required this.shopData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shopData['name'])),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shopData['description'] ?? "Professional service provider", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Row(children: [const Icon(Icons.location_on, size: 16, color: AppColors.primary), const SizedBox(width: 5), Text(shopData['address'], style: const TextStyle(fontWeight: FontWeight.bold))]),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.all(20), child: Text("Our Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('shops').doc(shopId).collection('services').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CustomLoader();
                final services = snapshot.data!.docs;
                if (services.isEmpty) return const Center(child: Text("No services available right now."));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        title: Text(service['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${service['durationInMinutes']} mins"),
                        trailing: Text("Rs. ${service['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BookingScreen(shopId: shopId, shopName: shopData['name'], serviceData: service)),
                          );
                        },
                      ),
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