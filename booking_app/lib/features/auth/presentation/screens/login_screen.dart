import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

final authModeProvider = StateProvider<bool>((ref) => true);
final userRoleProvider = StateProvider<String>((ref) => 'customer');

// ConsumerWidget එක ConsumerStatefulWidget එකක් කළා
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // 1. Controllers ටික build එකෙන් පිටතට ගත්තා
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    // Memory ඉතිරි කරගන්න මේවා අයින් කරනවා
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = ref.watch(authModeProvider);
    final userRole = ref.watch(userRoleProvider);
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLogin ? "Hello," : "I am a",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                if (!isLogin) ...[
                  Row(
                    children: [
                      _buildRoleSelector('customer', "Customer", userRole == 'customer'),
                      const SizedBox(width: 10),
                      _buildRoleSelector('vendor', "Vendor", userRole == 'vendor'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    hintText: "Full Name / Business Name", 
                    prefixIcon: Icons.person, 
                    controller: nameController
                  ),
                ],

                CustomTextField(hintText: "Email", prefixIcon: Icons.email, controller: emailController),
                CustomTextField(hintText: "Password", prefixIcon: Icons.lock, isPassword: true, controller: passwordController),

                const SizedBox(height: 32),

                PrimaryButton(
                  text: isLogin ? "Sign In" : "Sign Up",
                  isLoading: isLoading,
                  onPressed: () {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();
                    final name = nameController.text.trim();

                    if (isLogin) {
                      ref.read(authControllerProvider.notifier).login(context, email, password);
                    } else {
                      ref.read(authControllerProvider.notifier).register(context, email, password, name, userRole);
                    }
                  },
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isLogin ? "New here? " : "Have an account? "),
                    GestureDetector(
                      onTap: () => ref.read(authModeProvider.notifier).state = !isLogin,
                      child: Text(
                        isLogin ? "Register" : "Login", 
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(String role, String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(userRoleProvider.notifier).state = role,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}