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
    final colors = Styles().colors;

    return Scaffold(
      // Top bar matches Home
      appBar: RootHeaderBar(title: Localization().getStringEx('', 'Alumni')),
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Progress(step: 3, totalSteps: 4),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step label (tight to progress bar)
                    const SizedBox(height: 8),
                    Text(
                      Localization().getStringEx("panel.alumni.onboarding.linkedin.step", "Get Connected (3/4)"),
                      style: TextStyle(
                        color: colors.fillColorPrimary, // navy
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Orange title
                    Text(
                      Localization().getStringEx("panel.alumni.onboarding.linkedin.title", "Connect LinkedIn"),
                      style: TextStyle(
                        color: colors.fillColorSecondary, // orange
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description (includes the Settings line, so we don't duplicate it later)
                    Text(
                      Localization().getStringEx(
                        "panel.alumni.onboarding.linkedin.description",
                        "We’ll sync headline, employer, and city to keep your profile fresh. No posts will be made. You can disconnect anytime in Settings.",
                      ),
                      style: TextStyle(
                        color: colors.textSurface,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom actions pinned
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary pill: white, orange border, navy text
                  SizedBox(
                    width: double.infinity,
                    child: RoundedButton(
                      label: Localization().getStringEx("panel.alumni.onboarding.linkedin.button.connect", "Connect LinkedIn"),
                      backgroundColor: colors.white,
                      textColor: colors.fillColorPrimary,
                      borderColor: colors.fillColorSecondary,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      onTap: _onConnectLinkedIn,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Link-style secondary action
                  Center(
                    child: InkWell(
                      onTap: _onNotNow,
                      child: Text(
                        Localization().getStringEx("panel.alumni.onboarding.linkedin.button.not_now", "Maybe later"),
                        style: TextStyle(
                          color: colors.fillColorPrimary,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onConnectLinkedIn() {
    // TODO: start LinkedIn OAuth; for now, proceed
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
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.ease)),
            ),
            child: child,
          );
        },
      ),
    );
  }
}

/// Thicker progress row used across onboarding
class _Progress extends StatelessWidget {
  final int step;
  final int totalSteps;

  const _Progress({required this.step, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final colors = Styles().colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final bool isActive = index < step;
          return Expanded(
            child: Container(
              height: 6, // thicker
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive ? colors.fillColorSecondary : colors.surfaceAccent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}
