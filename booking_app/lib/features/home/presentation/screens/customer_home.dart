import 'package:booking_app/features/auth/presentation/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import 'shop_details_screen.dart';


// --- State Management Providers ---
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
final selectedLocationProvider = StateProvider<String?>((ref) => null);
final selectedCategoryProvider = StateProvider<String>((ref) => 'Salon');

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
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "My Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }

  // --- [HOME SCREEN] ---
  Widget _buildHomeScreen(BuildContext context, WidgetRef ref) {
    final selectedLoc = ref.watch(selectedLocationProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);

    return SafeArea(
      child: Column(
        children: [
          _buildLocationHeader(context, ref, selectedLoc),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.all(20), child: Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  _buildCategoryGrid(ref, selectedCat),
                  const Padding(padding: EdgeInsets.all(20), child: Text("Available Shops", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  _buildShopList(context, selectedLoc, selectedCat),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- [MY BOOKINGS SCREEN] ---
  Widget _buildCustomerBookingsScreen() {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("My Appointments"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('customerId', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final bookings = snapshot.data!.docs;
          if (bookings.isEmpty) return const Center(child: Text("No bookings yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(b['serviceName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${b['shopName']} \n${b['date']} at ${b['time']}"),
                  trailing: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                    child: Text(b['status'].toString().toUpperCase(), style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- [UI HELPERS] ---
  Widget _buildLocationHeader(BuildContext context, WidgetRef ref, String? currentLoc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
      child: GestureDetector(
        onTap: () => _openLocationSearch(context, ref),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Text(currentLoc ?? "Explore your area", style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildShopList(BuildContext context, String? location, String category) {
    if (location == null) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Select a location first.")));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('shops').where('address', isEqualTo: location).where('category', isEqualTo: category).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final shops = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: shops.length,
          itemBuilder: (context, index) {
            final shop = shops[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(shop['name']),
                subtitle: Text(shop['address']),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShopDetailsScreen(shopId: shops[index].id, shopData: shop))),
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
            itemCount: types.length,
            itemBuilder: (context, index) {
              final name = types[index]['name'];
              bool isSel = currentCat == name;
              return GestureDetector(
                onTap: () => ref.read(selectedCategoryProvider.notifier).state = name,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      CircleAvatar(backgroundColor: isSel ? AppColors.primary : Colors.grey[100], child: Icon(_getIcon(name), color: isSel ? Colors.white : Colors.grey)),
                      Text(name),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getIcon(String name) {
    if (name.toLowerCase().contains('salon')) return Icons.content_cut;
    return Icons.category;
  }

  void _openLocationSearch(BuildContext context, WidgetRef ref) async {
    final snap = await FirebaseFirestore.instance.collection('locations').get();
    final cities = snap.docs.map((d) => d['name'] as String).toList();
    if (context.mounted) {
      final res = await showSearch(context: context, delegate: LocationSearchDelegate(cities));
      if (res != null) ref.read(selectedLocationProvider.notifier).state = res;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
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

  Widget _buildProfileScreen(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Center(child: Text(user?.email ?? "User Profile"));
  }
}

// --- [SEARCH DELEGATE WITH FIX] ---
class LocationSearchDelegate extends SearchDelegate<String> {
  final List<String> cities;
  LocationSearchDelegate(this.cities);

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = "")];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ""));

  @override
  Widget buildResults(BuildContext context) => _buildSuggestions(context); // context එක pass කළා

  @override
  Widget buildSuggestions(BuildContext context) => _buildSuggestions(context); // context එක pass කළා

  Widget _buildSuggestions(BuildContext context) { // මෙතනට BuildContext context එකතු කළා
    final list = cities.where((c) => c.toLowerCase().contains(query.toLowerCase())).toList();
    
    return ListView.builder(
      itemCount: list.length, 
      itemBuilder: (c, i) => ListTile(
        leading: const Icon(Icons.location_city),
        title: Text(list[i]), 
        onTap: () => close(context, list[i]) // දැන් මෙතන 'context' එක අඳුරගන්න පුළුවන්
      )
    );
  }
}