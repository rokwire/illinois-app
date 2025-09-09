import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class AlumniOnboardingNotificationsPanel extends StatefulWidget {
  @override
  _AlumniOnboardingNotificationsPanelState createState() => _AlumniOnboardingNotificationsPanelState();
}

class _AlumniOnboardingNotificationsPanelState extends State<AlumniOnboardingNotificationsPanel> {
  bool _eventsNearMe = true;
  bool _mentorRequests = true;
  bool _weeklyNewsDigest = true;
  bool _perksAndDiscounts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('', 'Alumni')),
      backgroundColor: Styles().colors.background,
      body: Column(
        children: [
          _buildProgressIndicator(step: 4, totalSteps: 4),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step label (closer to the bar)
                  Text(
                    Localization().getStringEx("panel.alumni.onboarding.notifications.step", "Notifications (4/4)"),
                    style: TextStyle(
                      color: Styles().colors.textSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title (orange)
                  Text(
                    Localization().getStringEx("panel.alumni.onboarding.notifications.title", "Stay in the Loop"),
                    style: TextStyle(
                      color: Styles().colors.fillColorSecondary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    Localization().getStringEx(
                      "panel.alumni.onboarding.notifications.description",
                      "Choose what you want to hear about. You can change this later in Preferences.",
                    ),
                    style: TextStyle(
                      color: Styles().colors.textSurface,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Options
                  ToggleRibbonButton(
                    label: Localization().getStringEx("panel.alumni.onboarding.notifications.events_near_me", "Events near me"),
                    toggled: _eventsNearMe,
                    onTap: () => setState(() => _eventsNearMe = !_eventsNearMe),
                  ),
                  ToggleRibbonButton(
                    label: Localization().getStringEx("panel.alumni.onboarding.notifications.mentor_requests", "Mentor requests"),
                    toggled: _mentorRequests,
                    onTap: () => setState(() => _mentorRequests = !_mentorRequests),
                  ),
                  ToggleRibbonButton(
                    label: Localization().getStringEx("panel.alumni.onboarding.notifications.weekly_news_digest", "Weekly news digest"),
                    toggled: _weeklyNewsDigest,
                    onTap: () => setState(() => _weeklyNewsDigest = !_weeklyNewsDigest),
                  ),
                  ToggleRibbonButton(
                    label: Localization().getStringEx("panel.alumni.onboarding.notifications.perks_and_discounts", "Perks & discounts"),
                    toggled: _perksAndDiscounts,
                    onTap: () => setState(() => _perksAndDiscounts = !_perksAndDiscounts),
                  ),
                ],
              ),
            ),
          ),

          // Primary CTA (white + orange outline, navy text)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: RoundedButton(
              label: Localization().getStringEx("panel.alumni.onboarding.notifications.button.allow", "Allow Notifications"),
              backgroundColor: Styles().colors.white,
              textColor: Styles().colors.fillColorPrimary,
              borderColor: Styles().colors.fillColorSecondary,
              fontSize: 18.0,
              onTap: _onAllowNotifications,
            ),
          ),

          // Not now (underlined navy link)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: TextButton(
              onPressed: _onNotNow,
              child: Text(
                Localization().getStringEx("panel.alumni.onboarding.notifications.button.not_now", "Not now"),
                style: TextStyle(
                  color: Styles().colors.fillColorPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator({required int step, required int totalSteps}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final bool isActive = index < step;
          return Expanded(
            child: Container(
              height: 8, // thicker
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _onAllowNotifications() {
    _saveNotificationPreferences();
    _requestNotificationPermissions();
    _completeOnboarding();
  }

  void _onNotNow() {
    _completeOnboarding();
  }

  void _saveNotificationPreferences() {
    // Persist preferences if needed.
  }

  void _requestNotificationPermissions() {
    // Trigger OS permission flow if wired up.
  }

  void _completeOnboarding() {
    Navigator.popUntil(context, (route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Localization().getStringEx(
          "panel.alumni.onboarding.complete.message",
          "Welcome to Alumni Mode! Your profile has been updated.",
        )),
        backgroundColor: Styles().colors.fillColorSecondary,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
