import 'package:flutter/material.dart';
import 'package:illinois/ui/alumni/AlumniOnboardingReviewPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class AlumniOnboardingContactPanel extends StatefulWidget {
  @override
  _AlumniOnboardingContactPanelState createState() => _AlumniOnboardingContactPanelState();
}

class _AlumniOnboardingContactPanelState extends State<AlumniOnboardingContactPanel> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing user data if available
    // _emailController.text = Auth2().profile?.email ?? '';
    // _phoneController.text = Auth2().profile?.phone ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

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
          _buildProgressIndicator(step: 1, totalSteps: 4),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  Text(
                    Localization().getStringEx(
                        "panel.alumni.onboarding.contact.step",
                        "Verify Contact Information (1/4)"
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
                        "panel.alumni.onboarding.contact.title",
                        "Keep in touch"
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
                        "panel.alumni.onboarding.contact.description",
                        "Use a personal email so you don't miss important UIUC, and only fill out fields that you'd like to share with fellow illini."
                    ),
                    style: TextStyle(
                      color: Styles().colors.textSurface,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 32),

                  // Personal Email field
                  _buildInputField(
                    label: Localization().getStringEx(
                        "panel.alumni.onboarding.contact.email.label",
                        "Personal Email"
                    ),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    isRequired: true,
                  ),
                  SizedBox(height: 24),

                  // Mobile Number field
                  _buildInputField(
                    label: Localization().getStringEx(
                        "panel.alumni.onboarding.contact.phone.label",
                        "Mobile (optional)"
                    ),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    isRequired: false,
                  ),
                ],
              ),
            ),
          ),

          // Next button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            child: RoundedButton(
              label: Localization().getStringEx(
                  "panel.alumni.onboarding.contact.button.next",
                  "Next"
              ),
              backgroundColor: _isFormValid() ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
              textColor: _isFormValid() ? Colors.white : Styles().colors.textSurface,
              borderColor: _isFormValid() ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              onTap: _isFormValid() ? _onNext : null,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Styles().colors.fillColorPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: Styles().colors.textSurface,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: isRequired ? null : Localization().getStringEx(
                "panel.alumni.onboarding.contact.field.optional",
                "Optional"
            ),
            hintStyle: TextStyle(
              color: Styles().colors.textSurface?.withOpacity(0.6),
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Styles().colors.surfaceAccent ?? Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Styles().colors.surfaceAccent ?? Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Styles().colors.fillColorSecondary ?? Colors.orange, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  bool _isFormValid() {
    return _emailController.text.trim().isNotEmpty &&
        _emailController.text.contains('@');
  }

  void _onNext() {
    // Save the contact information
    // Auth2().updateProfile(email: _emailController.text.trim(), phone: _phoneController.text.trim());

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AlumniOnboardingReviewPanel(),
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