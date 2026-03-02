import 'package:booking_app/core/widgets/custom_loader.dart';
import 'package:booking_app/features/auth/presentation/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/widgets/primary_button.dart';
import 'add_service_screen.dart';

class VendorHome extends StatefulWidget {
  const VendorHome({super.key});

  @override
  State<VendorHome> createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  // --- [SHOP CREATE FORM CONTROLLERS] ---
  final nameController = TextEditingController();
  final descController = TextEditingController();
  String? selectedCity;
  String? selectedCategory;
  bool isLoading = false;

  // --- [CREATE SHOP FUNCTION] ---
  Future<void> createShop() async {
    if (nameController.text.isEmpty || selectedCity == null || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('shops').doc(currentUser!.uid).set({
        'ownerId': currentUser!.uid,
        'name': nameController.text.trim(),
        'description': descController.text.trim(),
        'address': selectedCity,
        'category': selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- [STATUS UPDATE FUNCTION] ---
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Booking $newStatus successfully!")));
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildMainContent(),
      _buildBookingsScreen(),
      _buildProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) {
            _showLogoutDialog();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: "My Shop"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }

  // --- [MAIN CONTENT (Form or Dashboard)] ---
  Widget _buildMainContent() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('shops').doc(currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const CustomLoader();
        
        // Shop එකක් දැනටමත් හදලා නැත්නම් Form එක පෙන්වන්න
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildCreateShopForm();
        }
        
        // Shop එක හදලා නම් Dashboard එක පෙන්වන්න
        final data = snapshot.data!.data() as Map<String, dynamic>;
        return _buildDashboard(data);
      },
    );
  }

  // --- [SHOP CREATION FORM] ---
  Widget _buildCreateShopForm() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Text("Setup Your Business", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            CustomTextField(hintText: "Shop Name", prefixIcon: Icons.store, controller: nameController),
            const SizedBox(height: 15),
            
            // City Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('locations').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                var items = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select City", 
                    filled: true, 
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                  ),
                  items: items.map((doc) => DropdownMenuItem(value: doc['name'] as String, child: Text(doc['name']))).toList(),
                  onChanged: (val) => setState(() => selectedCity = val),
                );
              },
            ),
            const SizedBox(height: 15),

            // Category Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('service_types').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                var items = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Category", 
                    filled: true, 
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                  ),
                  items: items.map((doc) => DropdownMenuItem(value: doc['name'] as String, child: Text(doc['name']))).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val),
                );
              },
            ),
            const SizedBox(height: 15),
            CustomTextField(hintText: "Short Description (Optional)", prefixIcon: Icons.description, controller: descController),
            const SizedBox(height: 40),
            
            PrimaryButton(text: "Create Shop Profile", isLoading: isLoading, onPressed: createShop),
          ],
        ),
      ),
    );
  }

  // --- [DASHBOARD] ---
  Widget _buildDashboard(Map<String, dynamic> data) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF8E88FF)]), borderRadius: BorderRadius.circular(25)),
              child: Column(
                children: [
                  const Icon(Icons.storefront, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text(data['name'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("${data['category']} • ${data['address']}", style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("My Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddServiceScreen())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildServiceList(),
          ],
        ),
      ),
    );
  }

  // --- [SERVICE LIST] ---
  Widget _buildServiceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('shops').doc(currentUser!.uid).collection('services').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CustomLoader();
        final services = snapshot.data!.docs;
        if (services.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("No services added yet."));
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          itemBuilder: (context, index) => Card(
            child: ListTile(
              title: Text(services[index]['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text("Rs. ${services[index]['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ),
        );
      },
    );
  }

  // --- [BOOKINGS SCREEN] ---
  Widget _buildBookingsScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointments"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('vendorId', isEqualTo: currentUser!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text("No bookings yet."));

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final String bookingId = docs[index].id;
                final booking = docs[index].data() as Map<String, dynamic>;
                final String status = booking['status'] ?? 'pending';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(booking['customerName'] ?? "Customer", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${booking['serviceName']} \n${booking['date']} at ${booking['time']}"),
                          trailing: _buildStatusBadge(status),
                        ),
                        if (status == 'pending')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => updateBookingStatus(bookingId, 'rejected'),
                                child: const Text("Reject", style: TextStyle(color: Colors.red)),
                              ),
                              ElevatedButton(
                                onPressed: () => updateBookingStatus(bookingId, 'approved'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text("Approve", style: TextStyle(color: Colors.white)),
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
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          return const CustomLoader();
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProfileScreen() => const Center(child: Text("Vendor Profile Settings"));

 void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c), // Dialog එක close කරයි
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Firebase එකෙන් අයින් වෙයි
              if (mounted) {
                // පරණ පේජ් ඔක්කොම අයින් කරලා Login Page එකට යවයි
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}