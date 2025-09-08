import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/alumni/AlumniOnboardingContactPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class AlumniOnboardingWelcomePanel extends StatefulWidget {
  @override
  _AlumniOnboardingWelcomePanelState createState() => _AlumniOnboardingWelcomePanelState();
}

class _AlumniOnboardingWelcomePanelState extends State<AlumniOnboardingWelcomePanel> {
  ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    // Start confetti animation after a brief delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.alumni.onboarding.header.title", "Alumni"),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),
      ),
      backgroundColor: Styles().colors.fillColorPrimary, // Dark blue background
      body: Stack(
        children: [
          // Confetti animation
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                Colors.orange,
                Colors.white,
                Colors.yellow,
                Styles().colors.fillColorSecondary ?? Colors.orange,
              ],
              numberOfParticles: 200,
            ),
          ),
          // Main content
          Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Illinois logo
                      Container(
                        width: 80,
                        height: 80,
                        child: Styles().images.getImage('university-logo') ??
                            Icon(Icons.school, size: 80, color: Colors.white),
                      ),
                      SizedBox(height: 32),

                      // Welcome title
                      Text(
                        Localization().getStringEx(
                            "panel.alumni.onboarding.welcome.title",
                            "Welcome to\nAlumni Mode"
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 24),

                      // Description text
                      Text(
                        Localization().getStringEx(
                            "panel.alumni.onboarding.welcome.description",
                            "Congrats! Your Illinois App now has an Alumni view. Keep your info fresh, connect with fellow Illini, and get perks."
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Continue button
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                child: RoundedButton(
                  label: Localization().getStringEx(
                      "panel.alumni.onboarding.welcome.button.continue",
                      "Continue"
                  ),
                  backgroundColor: Colors.white,
                  textColor: Styles().colors.fillColorPrimary,
                  borderColor: Colors.white,
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: _onContinue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onContinue() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AlumniOnboardingContactPanel(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.ease)),
            ),
            child: child,
          );
        },
      ),
    );
  }
}