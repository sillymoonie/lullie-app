import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lullie_app/home_screen.dart';

class OnBoarding extends StatefulWidget {
  const OnBoarding({super.key});

  @override
  State<OnBoarding> createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Container for contents
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF330000),
              Color(0xFF000000),
            ],
          ),
        ),

        // Column starts here
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // First expanded
            Expanded(
              flex: 3,

              // Padding around the stack for image container
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0),
                // stack starts here
                child: Stack(
                  children: [
                    // Container for image
                    Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            "assets/images/sonnet.png",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Padding for container stacked at the botttom of image
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Align(
                        alignment: Alignment.bottomCenter,

                        // Container stacked at bottom of image
                        child: Container(
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFFFFFFF),
                              width: 0.4,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            height: 110.0,
                            width: 110.0,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFFFF),
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(
                                  "assets/images/login/lullie-logo.png",
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // stack ends here
              ),
            ),

            // Second expanded
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 15.0),
                // Column starts here
                child: Column(
                  children: [
                    // Richtext here
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          height: 1.3,
                        ),
                        children: const <TextSpan>[
                          TextSpan(
                            text:
                                'AI curated music playlist just for your mood \n',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                          TextSpan(
                            text: 'Get Started Now!',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Richtext ends here

                    // Container for arrow forward in a padding
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),

                      // Container for arrow forward
                      child: GestureDetector(
                        onTap: _navigateToHome,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCCCC).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            height: 50.0,
                            width: 50.0,
                            padding: const EdgeInsets.all(2.0),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFFFF),
                              shape: BoxShape.circle,
                            ),

                            // Arrow forward centered
                            child: const Center(
                              // Arrow forward
                              child: Icon(
                                Icons.arrow_forward,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Column ends here
              ),
            ),
          ],
        ),

        // Column ends here
      ),
    );
  }
} 