import 'package:flutter/material.dart';
import 'package:illinois/ui/alumni/AlumniOnboardingNotificationsPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class AlumniOnboardingLinkedInPanel extends StatefulWidget {
  @override
  _AlumniOnboardingLinkedInPanelState createState() => _AlumniOnboardingLinkedInPanelState();
}

class _AlumniOnboardingLinkedInPanelState extends State<AlumniOnboardingLinkedInPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.alumni.onboarding.header.title", "Alumni"),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),
      ),
      backgroundColor: Styles().colors.background,
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(step: 3, totalSteps: 4),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  Text(
                    Localization().getStringEx(
                        "panel.alumni.onboarding.linkedin.step",
                        "Get Connected (3/4)"
                    ),
                    style: TextStyle(
                      color: Styles().colors.textSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Title
                  Text(
                    Localization().getStringEx(
                        "panel.alumni.onboarding.linkedin.title",
                        "Connect LinkedIn"
                    ),
                    style: TextStyle(
                      color: Styles().colors.fillColorPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Description
                  Text(
                    Localization().getStringEx(
                        "panel.alumni.onboarding.linkedin.description",
                        "We'll sync headlines, employers, and city to keep your profile fresh. No posts will be shared."
                    ),
                    style: TextStyle(
                      color: Styles().colors.textSurface,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 32),

                  // LinkedIn connect button
                  Container(
                    width: double.infinity,
                    child: RoundedButton(
                      label: Localization().getStringEx(
                          "panel.alumni.onboarding.linkedin.button.connect",
                          "Connect LinkedIn"
                      ),
                      backgroundColor: Color(0xFF0077B5), // LinkedIn blue
                      textColor: Colors.white,
                      borderColor: Color(0xFF0077B5),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      onTap: _onConnectLinkedIn,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Disclaimer text
                  Text(
                    Localization().getStringEx(
                        "panel.alumni.onboarding.linkedin.disclaimer",
                        "You can disconnect anytime in Settings."
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Styles().colors.textSurface?.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Not now button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            child: RoundedButton(
              label: Localization().getStringEx(
                  "panel.alumni.onboarding.linkedin.button.not_now",
                  "Not now"
              ),
              backgroundColor: Colors.transparent,
              textColor: Styles().colors.fillColorPrimary,
              borderColor: Styles().colors.fillColorPrimary,
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              onTap: _onNotNow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator({required int step, required int totalSteps}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(totalSteps, (index) {
          bool isActive = index < step;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _onConnectLinkedIn() {
    // Handle LinkedIn connection logic
    // This would typically involve OAuth flow with LinkedIn API
    // For now, just proceed to next step
    _proceedToNext();
  }

  void _onNotNow() {
    _proceedToNext();
  }

  void _proceedToNext() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AlumniOnboardingNotificationsPanel(),
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