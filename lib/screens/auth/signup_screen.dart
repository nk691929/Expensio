import 'package:animationandcharts/models/account_model.dart';
import 'package:animationandcharts/models/category_model.dart';
import 'package:animationandcharts/providers/account_provider.dart';
import 'package:animationandcharts/providers/auth_provider.dart';
import 'package:animationandcharts/providers/category_provider.dart';
import 'package:animationandcharts/routes/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeTerms = false;
  bool _isLoading = false;

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack("Please fill all fields");
      return;
    }
    if (password != confirmPassword) {
      _showSnack("Passwords do not match");
      return;
    }
    if (!_agreeTerms) {
      _showSnack("You must agree to Terms & Conditions");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user=await ref.read(
        signUpProvider({
          "name": name,
          "email": email,
          "password": password,
        }).future,
      );
      

      _showSnack("Sign up successful! Verify email.");
       if (mounted) {
        await createDefaultCategories(user.id,ref);
        await createDefaultAccount(user.id, ref);
          // ✅ Go to home if email verified
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.splash,
          );
                }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> createDefaultCategories(String userId, WidgetRef ref) async {
  final notifier = ref.read(categoryNotifierProvider(userId).notifier);
  final now = DateTime.now();

  final defaultCategories = [
    {"name": "Food & Groceries", "budget": 10000, "icon": Icons.restaurant, "color": Colors.orange},
    {"name": "Transportation", "budget": 5000, "icon": Icons.directions_car, "color": Colors.blue},
    {"name": "Utilities", "budget": 3000, "icon": Icons.lightbulb, "color": Colors.yellow},
  ];

  for (var cat in defaultCategories) {
    final category = CategoryModel(
      id: "cat_${DateTime.now().microsecondsSinceEpoch}_${cat['name']}",
      userId: userId,
      accountId: null,
      name: cat["name"] as String,
      budget: cat["budget"] as int,
      color: cat["color"] as Color,
      icon: cat["icon"] as IconData,
      createdAt: now,
      updatedAt: now,
    );

    await notifier.addCategory(category);
  }
}


Future<void> createDefaultAccount(String userId, WidgetRef ref) async {
  final notifier = ref.read(accountNotifierProvider.notifier);
  final now = DateTime.now();

  final defaultAccount = Account(
    id: "acc_${now.microsecondsSinceEpoch}",
    userId: userId,
    name: "Default",
    holder: "Self",
    number: "0000",
    balance: 0.0,
    colorValue: Colors.indigo.value,
    logo: "account_balance_wallet",
    createdAt: now,
    updatedAt: now,
  );

  await notifier.createAccount(defaultAccount);
}


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🪩 Logo or illustration
                Image.asset(
                  'assets/images/welcome_image.png',
                  height: 120,
                ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),

                const SizedBox(height: 20),

                // ✨ Title
                Text(
                  "Create Account 🚀",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 8),

                Text(
                  "Sign up and take control of your finances today",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 40),

                // 🌟 Glass Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // 👤 Full Name
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          labelText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 20),

                      // 📩 Email
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 20),

                      // 🔐 Password
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _showPassword = !_showPassword);
                            },
                          ),
                        ),
                      ).animate().fadeIn(delay: 700.ms),

                      const SizedBox(height: 20),

                      // 🔐 Confirm Password
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_showConfirmPassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_person_outlined),
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(
                                () => _showConfirmPassword =
                                    !_showConfirmPassword,
                              );
                            },
                          ),
                        ),
                      ).animate().fadeIn(delay: 800.ms),
                      const SizedBox(height: 20),

                      // ✅ Terms & Conditions
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeTerms,
                            onChanged: (val) {
                              setState(() => _agreeTerms = val ?? false);
                            },
                          ),
                          Expanded(
                            child: Text(
                              "I agree to the Terms & Conditions",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colorScheme.onBackground.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 850.ms),

                      const SizedBox(height: 20),

                      // 🚀 Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  "Sign Up",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 900.ms),

                      const SizedBox(height: 20),

                      // 🔑 Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: GoogleFonts.inter(
                              color: colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context,AppRoutes.emailVerification);
                            },
                            child: Text(
                              "Log In",
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 1000.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
