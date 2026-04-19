import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;
  bool _isPressed = false;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Set your goals",
      "description":
      "Your goals will help us recommend the best path for your growth.",
      "image": "assets/images/goal.svg",
    },
    {
      "title": "Track progress",
      "description":
      "Monitor your progress in real time and stay consistent.",
      "image": "assets/images/tracking.svg",
    },
    {
      "title": "Achieve success",
      "description":
      "Stay focused and reach your academic milestones faster.",
      "image": "assets/images/success.svg",
    },
  ];

  /// 🔥 NAVIGATION FIX (IMPORTANT)
  void goToHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          toggleTheme: () {}, // dummy (real handled in main.dart)
          isDark: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Stack(
          children: [

            /// MAIN CONTENT
            Column(
              children: [

                /// SKIP BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: goToHome,
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                /// PAGE VIEW
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: onboardingData.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          double value = 1.0;

                          if (_controller.position.haveDimensions) {
                            value = (_controller.page ?? 0) - index;
                            value =
                                (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                          }

                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(
                                ((_controller.hasClients
                                    ? (_controller.page ?? 0)
                                    : 0) -
                                    index) *
                                    30,
                                50 * (1 - value),
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              SvgPicture.asset(
                                onboardingData[index]["image"]!,
                                height: 260,
                              ),

                              const SizedBox(height: 60),

                              Text(
                                onboardingData[index]["title"]!,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),

                              const SizedBox(height: 16),

                              Text(
                                onboardingData[index]["description"]!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// INDICATOR
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: SmoothPageIndicator(
                    controller: _controller,
                    count: onboardingData.length,
                    effect: WormEffect(
                      activeDotColor: Colors.black,
                      dotColor: Colors.grey.shade300,
                      dotHeight: 6,
                      dotWidth: 6,
                    ),
                  ),
                ),
              ],
            ),

            /// NEXT BUTTON
            Positioned(
              bottom: 80,
              right: 30,
              child: GestureDetector(
                onTapDown: (_) =>
                    setState(() => _isPressed = true),
                onTapUp: (_) =>
                    setState(() => _isPressed = false),
                onTapCancel: () =>
                    setState(() => _isPressed = false),
                onTap: () async {
                  if (currentPage ==
                      onboardingData.length - 1) {
                    goToHome();
                  } else {
                    _controller.nextPage(
                      duration:
                      const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: AnimatedScale(
                  duration:
                  const Duration(milliseconds: 150),
                  scale: _isPressed ? 0.92 : 1,
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}