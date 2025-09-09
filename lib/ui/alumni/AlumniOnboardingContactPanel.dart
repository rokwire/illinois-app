import 'package:flutter/material.dart';
import 'package:illinois/ui/alumni/AlumniOnboardingReviewPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart'; // RootHeaderBar
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
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Styles().colors;

    return Scaffold(
      // Match Home top bar
      appBar: RootHeaderBar(title: Localization().getStringEx('', 'Alumni')),
      backgroundColor: colors.background,
      body: Column(
        children: [
          // Thicker progress bar tight to top
          _buildProgressIndicator(step: 1, totalSteps: 4),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), // tight to progress
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step label close to bar
                  Text(
                    Localization().getStringEx(
                      "panel.alumni.onboarding.contact.step",
                      "Verify Contact Information (1/4)",
                    ),
                    style: TextStyle(
                      color: colors.textSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title – orange
                  Text(
                    Localization().getStringEx(
                      "panel.alumni.onboarding.contact.title",
                      "Keep in touch",
                    ),
                    style: TextStyle(
                      color: colors.fillColorSecondary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    Localization().getStringEx(
                      "panel.alumni.onboarding.contact.description",
                      "Use a personal email so you don’t miss receipts, RSVPs, or alumni news.",
                    ),
                    style: TextStyle(
                      color: colors.textSurface,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Personal Email
                  _buildInputField(
                    label: Localization().getStringEx(
                      "panel.alumni.onboarding.contact.email.label",
                      "Personal Email",
                    ),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    hint: "you@personalemail.com",
                    isRequired: true,
                  ),
                  const SizedBox(height: 20),

                  // Mobile
                  _buildInputField(
                    label: Localization().getStringEx(
                      "panel.alumni.onboarding.contact.phone.label",
                      "Mobile (optional)",
                    ),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    hint: "+1 217-555-5555",
                    isRequired: false,
                  ),
                ],
              ),
            ),
          ),

          // Bottom CTA – white pill, orange border, navy text (disabled = dim)
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: RoundedButton(
                label: Localization().getStringEx(
                  "panel.alumni.onboarding.contact.button.next",
                  "Next",
                ),
                onTap: _isFormValid() ? _onNext : null,
                backgroundColor: Colors.white,
                borderColor: _isFormValid()
                    ? colors.fillColorSecondary
                    : (colors.surfaceAccent ?? Colors.grey.shade300),
                textColor: _isFormValid()
                    ? colors.fillColorPrimary
                    : (colors.textSurface?.withOpacity(0.6) ?? Colors.black54),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator({required int step, required int totalSteps}) {
    final colors = Styles().colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final bool isActive = index < step;
          return Expanded(
            child: Container(
              height: 8, // thicker
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 10 : 0),
              decoration: BoxDecoration(
                color: isActive
                    ? colors.fillColorSecondary
                    : (colors.surfaceAccent ?? Colors.black12),
                borderRadius: BorderRadius.circular(4),
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
    String? hint,
  }) {
    final colors = Styles().colors;

    final bool isEmailField = keyboardType == TextInputType.emailAddress;
    final String text = controller.text.trim();
    final bool showError = isEmailField && text.isNotEmpty && !_isEmail(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.fillColorPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: colors.textSurface,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: isRequired ? hint : (hint ?? Localization().getStringEx(
              "panel.alumni.onboarding.contact.field.optional",
              "Optional",
            )),
            hintStyle: TextStyle(
              color: colors.textSurface?.withOpacity(0.6),
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.surfaceAccent ?? Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.surfaceAccent ?? Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.fillColorSecondary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (showError) ...[
          const SizedBox(height: 6),
          Text(
            Localization().getStringEx(
              "panel.alumni.onboarding.contact.email.error",
              "Enter a valid email address.",
            ),
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        ],
      ],
    );
  }

  bool _isFormValid() {
    final text = _emailController.text.trim();
    return _isEmail(text);
  }

  bool _isEmail(String value) {
    // simple, permissive email check
    final emailRx = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    return emailRx.hasMatch(value);
  }

  void _onNext() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => AlumniOnboardingReviewPanel(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1, 0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.ease)),
            ),
            child: child,
          );
        },
      ),
    );
  }
}
