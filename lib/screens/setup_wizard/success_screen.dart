import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SetupSuccessScreen extends StatelessWidget {
  const SetupSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎉 Success Emoji / Icon
              Text(
                "🎉",
                style: const TextStyle(fontSize: 64),
              )
                  .animate()
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.elasticOut)
                  .fadeIn(duration: 800.ms),

              const SizedBox(height: 24),

              // 🌟 Success Message
              Text(
                "Great! Your expense tracker is ready.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 400.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),

              const SizedBox(height: 40),

              // ✅ Go to Dashboard Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    backgroundColor: colorScheme.primary,
                    shadowColor: colorScheme.primary.withOpacity(0.5),
                  ),
                  child: Text(
                    "Go to Dashboard",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ).animate()
                    .fadeIn(duration: 800.ms, delay: 600.ms)
                    .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
