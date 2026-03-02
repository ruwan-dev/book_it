import 'package:booking_app/core/widgets/custom_loader.dart';
import 'package:booking_app/features/auth/presentation/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import 'shop_details_screen.dart';

// --- State Management ---
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
final selectedLocationProvider = StateProvider<String?>((ref) => null);
final selectedCategoryProvider = StateProvider<String>((ref) => 'Salon');
final searchQueryProvider = StateProvider<String>((ref) => '');

class CustomerHome extends ConsumerWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    final List<Widget> pages = [
      _buildHomeScreen(context, ref),
      _buildCustomerBookingsScreen(),
      _buildProfileScreen(context),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          if (index == 3) {
            _showLogoutDialog(context);
          } else {
            ref.read(bottomNavIndexProvider.notifier).state = index;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(BuildContext context, WidgetRef ref) {
    final selectedLoc = ref.watch(selectedLocationProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Column(
      children: [
        // උඩට කළ Header එක
        _buildHeader(context, ref, selectedLoc, searchQuery),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                  child: Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _buildCategoryGrid(ref, selectedCat),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Available Shops", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _buildShopList(context, selectedLoc, selectedCat, searchQuery),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- [HEADER LOGIC - TOP ADJUSTED] ---
  Widget _buildHeader(BuildContext context, WidgetRef ref, String? currentLoc, String query) {
    return Container(
      // top padding එක 60 සිට 45 දක්වා අඩු කළා
      padding: const EdgeInsets.only(top: 45, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          if (currentLoc == null) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                decoration: const InputDecoration(
                  hintText: "Search your city to explore...",
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            if (query.length >= 3) _buildLocationSuggestions(ref, query),
          ] else ...[
            _buildSelectedLocationCard(ref, currentLoc),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedLocationCard(WidgetRef ref, String city) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              city, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: AppColors.primary),
            onPressed: () {
              ref.read(selectedLocationProvider.notifier).state = null;
              ref.read(searchQueryProvider.notifier).state = '';
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSuggestions(WidgetRef ref, String query) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('locations').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final list = snap.data!.docs.where((d) => 
          d['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
        
        if (list.isEmpty) return const SizedBox();

        return Container(
          margin: const EdgeInsets.only(top: 10),
          constraints: const BoxConstraints(maxHeight: 180),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(15), 
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (c, i) => ListTile(
              leading: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
              title: Text(list[i]['name']),
              onTap: () {
                ref.read(selectedLocationProvider.notifier).state = list[i]['name'];
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopList(BuildContext context, String? location, String category, String query) {
    if (location == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Text("Select your city to see shops", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('shops').where('address', isEqualTo: location).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CustomLoader();
        
        final filteredShops = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['category'] == category;
        }).toList();

        if (filteredShops.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No shops found here.")));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredShops.length,
          itemBuilder: (context, index) {
            final shop = filteredShops[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: const Icon(Icons.storefront, color: AppColors.primary)),
                title: Text(shop['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(shop['category']),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShopDetailsScreen(shopId: filteredShops[index].id, shopData: shop))),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryGrid(WidgetRef ref, String currentCat) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('service_types').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final types = snapshot.data!.docs;
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final name = types[index]['name'];
              bool isSel = currentCat == name;
              return GestureDetector(
                onTap: () => ref.read(selectedCategoryProvider.notifier).state = name,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isSel ? AppColors.primary : Colors.white,
                      child: Icon(Icons.category, color: isSel ? Colors.white : Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    Text(name, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  ]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCustomerBookingsScreen() => const Scaffold(body: Center(child: Text("Appointments")));
  Widget _buildProfileScreen(BuildContext context) => const Scaffold(body: Center(child: Text("Profile")));
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Logout"), actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text("No")),
      TextButton(onPressed: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
      }, child: const Text("Yes"))
    ]));
  }
}