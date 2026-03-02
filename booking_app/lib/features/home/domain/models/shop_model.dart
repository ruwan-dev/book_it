import 'package:booking_app/core/widgets/custom_loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/widgets/primary_button.dart';

class VendorHome extends StatefulWidget {
  const VendorHome({super.key});

  @override
  State<VendorHome> createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  // Form Controllers (විස්තර ටයිප් කරන කොටු)
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final descController = TextEditingController();
  String selectedCategory = 'Salon'; // Default category එක

  bool isLoading = false;

  // --- කඩේ හදන Function එක ---
  Future<void> createShop() async {
    if (nameController.text.isEmpty || addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final shopData = {
        'ownerId': currentUser!.uid,
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'description': descController.text.trim(),
        'category': selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Database එකේ 'shops' කියන තැන මේ විස්තර Save කරනවා
      await FirebaseFirestore.instance.collection('shops').doc(currentUser!.uid).set(shopData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shop Created Successfully!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Business"),
        centerTitle: false,
        actions: [
          // Logout Button
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          )
        ],
      ),
      // Real-time Data බලන්න StreamBuilder පාවිච්චි කරනවා
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('shops').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          
          // 1. Loading...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoader();
          }

          // 2. කඩයක් හදලා තියෙනවා නම් -> විස්තර පෙන්වන්න (Dashboard)
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.storefront, size: 48, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          data['name'],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          data['category'],
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(data['address'], style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Services Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("My Services", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () {
                          // Service එකක් Add කරන තැනට යන්න (පස්සේ හදමු)
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add Service Feature coming next!")));
                        },
                        icon: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.add, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Empty State for Services
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.spa_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("No services added yet", style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // 3. කඩයක් නෑ -> Create Shop Form එක පෙන්වන්න
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.add_business_rounded, size: 60, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  "Setup your Business",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                ),
                const Text(
                  "Enter your shop details to allow customers to book appointments.",
                  style: TextStyle(fontSize: 15, color: AppColors.textGrey),
                ),
                const SizedBox(height: 32),

                CustomTextField(hintText: "Shop Name (e.g. Ruwan Salon)", prefixIcon: Icons.store, controller: nameController),
                CustomTextField(hintText: "Location / Address", prefixIcon: Icons.location_on, controller: addressController),
                CustomTextField(hintText: "Description (Optional)", prefixIcon: Icons.description, controller: descController),

                const SizedBox(height: 10),
                const Text("Select Category", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Category Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                      items: ['Salon', 'Dental', 'Spa', 'Clinic', 'Car Wash']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => selectedCategory = val!),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                PrimaryButton(
                  text: "Create My Shop",
                  isLoading: isLoading,
                  onPressed: createShop,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}