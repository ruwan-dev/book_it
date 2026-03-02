import 'package:booking_app/core/widgets/custom_loader.dart';
import 'package:booking_app/features/auth/presentation/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/screens/admin_home.dart';
import '../../../home/presentation/screens/customer_home.dart';
import '../../../home/presentation/screens/vendor_home.dart';
import 'welcome_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Color(0xFFF5F5F5), body: SizedBox.shrink());
        }

        // ලොග් වෙලා නැත්නම් විතරයි Welcome Screen එක පෙන්වන්නේ
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final User user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(backgroundColor: Color(0xFFF5F5F5), body: SizedBox.shrink());
            }

            if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
              final String role = roleSnapshot.data!.get('role') ?? 'customer';
              if (role == 'vendor') return  VendorHome();
              if (role == 'admin') return  AdminHome();
              return  CustomerHome();
            }

            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text("Profile not found. Logout"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}