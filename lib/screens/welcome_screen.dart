import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔹 Image + Text Section
                Column(
                  children: [
                    Animate(
                      onPlay: (controller) =>
                          controller.repeat(), // 🔁 infinite
                      effects: [
                        FadeEffect(duration: 800.ms),
                        CustomEffect(
                          duration: 8000.ms,
                          builder: (context, value, child) {
                            double phase = (value * 4) % 4;
                            double dx = 0;
                            double dy = 0;

                            if (phase < 1) {
                              dx = 0.05 * phase;
                            } else if (phase < 2) {
                              dx = 0.05;
                              dy = 0.05 * (phase - 1);
                            } else if (phase < 3) {
                              dx = 0.05 - 0.05 * (phase - 2);
                              dy = 0.05;
                            } else {
                              dx = 0;
                              dy = 0.05 - 0.05 * (phase - 3);
                            }

                            return Transform.translate(
                              offset: Offset(
                                dx * MediaQuery.of(context).size.width,
                                dy * MediaQuery.of(context).size.height,
                              ),
                              child: child,
                            );
                          },
                        ),
                      ],
                      child: Image.asset(
                        'assets/images/welcome_image.png',
                        height: 260,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ✅ Title with premium font
                    Text(
                          "Welcome to Expensio",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            letterSpacing: 1.2,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 300.ms)
                        .slideY(begin: 0.2, curve: Curves.easeOut),

                    const SizedBox(height: 16),

                    // ✅ Subtitle
                    RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: colorScheme.onBackground.withOpacity(0.7),
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: "Track, "),
                              TextSpan(
                                text: "manage ",
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: "and "),
                              TextSpan(
                                text: "grow ",
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: "your "),
                              TextSpan(
                                text: "money ",
                                style: TextStyle(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(
                                text: "effortlessly.\nYour journey to ",
                              ),
                              TextSpan(
                                text: "financial freedom ",
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: "starts here."),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 600.ms)
                        .slideY(begin: 0.2, curve: Curves.easeOut),
                  ],
                ),

                // 🔹 Premium Animated Button
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child:
                      Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              "Get Started",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 1000.ms)
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            curve: Curves.easeOut,
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
