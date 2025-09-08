import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
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
  bool _pensAndFeathers = false;

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
          _buildProgressIndicator(step: 4, totalSteps: 4),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  Text(
                    Localization().getStringEx(
                        "panel.alumni.onboarding.notifications.step",
                        "Notifications (4/4)"
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
                        "panel.alumni.onboarding.notifications.title",
                        "Stay in the Loop"
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
                        "panel.alumni.onboarding.notifications.description",
                        "Choose what you want to hear about. You can change this later in Preferences."
                    ),
                    style: TextStyle(
                      color: Styles().colors.textSurface,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 32),

                  // Notification options
                  _buildNotificationOption(
                    title: Localization().getStringEx(
                        "panel.alumni.onboarding.notifications.events_near_me",
                        "Events near me"
                    ),
                    value: _eventsNearMe,
                    onChanged: (value) => setState(() => _eventsNearMe = value),
                  ),

                  _buildNotificationOption(
                    title: Localization().getStringEx(
                        "panel.alumni.onboarding.notifications.mentor_requests",
                        "Mentor requests"
                    ),
                    value: _mentorRequests,
                    onChanged: (value) => setState(() => _mentorRequests = value),
                  ),

                  _buildNotificationOption(
                    title: Localization().getStringEx(
                        "panel.alumni.onboarding.notifications.weekly_news_digest",
                        "Weekly news digest"
                    ),
                    value: _weeklyNewsDigest,
                    onChanged: (value) => setState(() => _weeklyNewsDigest = value),
                  ),

                  _buildNotificationOption(
                    title: Localization().getStringEx(
                        "panel.alumni.onboarding.notifications.pens_and_feathers",
                        "Pens and Feathers"
                    ),
                    value: _pensAndFeathers,
                    onChanged: (value) => setState(() => _pensAndFeathers = value),
                  ),
                ],
              ),
            ),
          ),

          // Allow Notifications button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            child: RoundedButton(
              label: Localization().getStringEx(
                  "panel.alumni.onboarding.notifications.button.allow",
                  "Allow Notifications"
              ),
              backgroundColor: Styles().colors.fillColorSecondary,
              textColor: Colors.white,
              borderColor: Styles().colors.fillColorSecondary,
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              onTap: _onAllowNotifications,
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

  Widget _buildNotificationOption({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Styles().colors.surfaceAccent ?? Colors.grey),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Styles().colors.textSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Styles().colors.fillColorSecondary,
            activeTrackColor: Styles().colors.fillColorSecondary?.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  void _onAllowNotifications() {
    // Save notification preferences
    _saveNotificationPreferences();

    // Request system notification permissions
    _requestNotificationPermissions();

    // Complete onboarding
    _completeOnboarding();
  }

  void _saveNotificationPreferences() {
    // Save the notification preferences to storage
    // Storage().alumniNotificationPreferences = {
    //   'eventsNearMe': _eventsNearMe,
    //   'mentorRequests': _mentorRequests,
    //   'weeklyNewsDigest': _weeklyNewsDigest,
    //   'pensAndFeathers': _pensAndFeathers,
    // };
  }

  void _requestNotificationPermissions() {
    // Request system notification permissions
    // NotificationService().requestPermission();
  }

  void _completeOnboarding() {
    // Mark alumni onboarding as complete
    // Storage().alumniOnboardingCompleted = true;

    // Navigate back to main app or show completion screen
    Navigator.popUntil(context, (route) => route.isFirst);

    // Optionally show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localization().getStringEx(
              "panel.alumni.onboarding.complete.message",
              "Welcome to Alumni Mode! Your profile has been updated."
          ),
        ),
        backgroundColor: Styles().colors.fillColorSecondary,
        duration: Duration(seconds: 3),
      ),
    );
  }
}