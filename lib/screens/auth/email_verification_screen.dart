import 'package:animationandcharts/providers/auth_provider.dart';
import 'package:animationandcharts/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmailVerificationScreen extends ConsumerWidget {
  final String email;
  const EmailVerificationScreen({super.key,required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    bool checkVerifyEmail=false;

    Future<void> checkVerification() async {
      checkVerifyEmail=true;
      try {
        final isVerified = await ref
            .read(authServiceProvider)
            .isEmailVerified();

        if (isVerified) {
          // ✅ Navigate to home if verified
          if (context.mounted) {
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              checkVerifyEmail=false;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen(userId: user.uid)),
              );
            }
          }
        } else {
          // ❌ Show a message if not verified yet
          if (context.mounted) {
            checkVerifyEmail=false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Email is not verified yet. Please check mail list or check spam."),
              ),
            );
          }
        }
      } catch (e) {
        checkVerifyEmail=false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    Future<void> _resendVerification() async {
      try {
        await ref.read(authServiceProvider).sendEmailVerification();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Verification email sent again ✅")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to resend: $e")));
      }
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.08),
              colorScheme.secondary.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 📩 Illustration / SVG
                  Image.asset(
                    'assets/images/welcome_image.png',
                    height: 200,
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),

                  const SizedBox(height: 40),

                  // ✉️ Title
                  Text(
                        "Verify Your Email 📬",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 300.ms)
                      .slideY(begin: 0.2),

                  const SizedBox(height: 16),

                  // 🪩 Description
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "We’ve sent a verification link to ",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: colorScheme.onBackground.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                        TextSpan(
                          text: email,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        TextSpan(
                          text:
                              ". Please check your inbox and click the link to verify your account.",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: colorScheme.onBackground.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 800.ms, delay: 600.ms),

                  const SizedBox(height: 40),

                  // ✅ I've Verified Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: checkVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: colorScheme.primary.withOpacity(0.4),
                      ),
                      child: checkVerifyEmail? CircularProgressIndicator():Text(
                        "I’ve Verified",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 800.ms),

                  const SizedBox(height: 20),

                  // 🔁 Resend Email Button
                  GestureDetector(
                    onTap: _resendVerification,
                    child: Text(
                      "Didn’t receive an email? Resend",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 1000.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
