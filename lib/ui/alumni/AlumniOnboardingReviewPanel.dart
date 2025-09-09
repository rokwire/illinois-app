import 'package:flutter/material.dart';
import 'package:illinois/ui/alumni/AlumniOnboardingLinkedInPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart'; // RootHeaderBar lives here
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class AlumniOnboardingReviewPanel extends StatefulWidget {
  @override
  _AlumniOnboardingReviewPanelState createState() => _AlumniOnboardingReviewPanelState();
}

class _AlumniOnboardingReviewPanelState extends State<AlumniOnboardingReviewPanel> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _employerController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _graduationYearController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _employerController.dispose();
    _titleController.dispose();
    _graduationYearController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final styles = Styles();
    final colors = styles.colors;

    return Scaffold(
      // Match the HomePanel top bar
      appBar: RootHeaderBar(title: Localization().getStringEx('', 'Alumni')),
      backgroundColor: colors.background,
      body: Column(
        children: [
          // Progress
          _OnboardingProgress(step: 2, totalSteps: 4),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step label — tight to progress bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      Localization().getStringEx(
                        "panel.alumni.onboarding.review.step",
                        "Review Your Information (2/4)",
                      ),
                      style: TextStyle(
                        color: colors.textSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title — orange
                  Text(
                    Localization().getStringEx(
                      "panel.alumni.onboarding.review.title",
                      "Is this correct?",
                    ),
                    style: TextStyle(
                      color: colors.fillColorSecondary, // Illini Orange
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    Localization().getStringEx(
                      "panel.alumni.onboarding.review.description",
                      "We pulled this from your student profile. Edit anything that has changed.",
                    ),
                    style: TextStyle(
                      color: colors.textSurface,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Single-column fields (match design)
                  _buildInputField(
                    label: Localization().getStringEx("panel.alumni.onboarding.review.first_name.label", "First Name"),
                    controller: _firstNameController,
                  ),
                  const SizedBox(height: 24),

                  _buildInputField(
                    label: Localization().getStringEx("panel.alumni.onboarding.review.last_name.label", "Last Name"),
                    controller: _lastNameController,
                  ),
                  const SizedBox(height: 24),

                  _buildInputField(
                    label: Localization().getStringEx("panel.alumni.onboarding.review.city.label", "Current City"),
                    controller: _cityController,
                  ),
                  const SizedBox(height: 24),

                  _buildInputField(
                    label: Localization().getStringEx("panel.alumni.onboarding.review.country.label", "Country"),
                    controller: _countryController,
                  ),
                  const SizedBox(height: 24),

                  _buildInputField(
                    label: Localization().getStringEx("panel.alumni.onboarding.review.employer.label", "Employer"),
                    controller: _employerController,
                  ),
                  const SizedBox(height: 24),

                  _buildInputField(
                    label: Localization().getStringEx("panel.alumni.onboarding.review.title.label", "Title"),
                    controller: _titleController,
                  ),
                  const SizedBox(height: 24),

                  _buildInputField(
                    label: Localization().getStringEx("panel.alumni.onboarding.review.graduation_year.label", "Graduation Year"),
                    controller: _graduationYearController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  _buildInputField(
                    label: Localization().getStringEx("panel.alumni.onboarding.review.college.label", "College"),
                    controller: _collegeController,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // White pill CTA with orange outline + navy text
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: RoundedButton(
              label: Localization().getStringEx(
                "panel.alumni.onboarding.review.button.looks_good",
                "Looks good! →",
              ),
              backgroundColor: colors.white,
              textColor: colors.fillColorPrimary, // navy
              borderColor: colors.fillColorSecondary, // orange outline
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              onTap: _onLooksGood,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final colors = Styles().colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.fillColorPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: colors.textSurface, fontSize: 16),
          decoration: InputDecoration(
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
              borderSide: BorderSide(color: colors.fillColorSecondary ?? Colors.orange, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _onLooksGood() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AlumniOnboardingLinkedInPanel(),
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

/// Thicker progress bar, Home spacing
class _OnboardingProgress extends StatelessWidget {
  final int step;
  final int totalSteps;
  const _OnboardingProgress({required this.step, required this.totalSteps});

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
              height: 8, // thicker
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 12 : 0),
              decoration: BoxDecoration(
                color: isActive ? colors.fillColorSecondary : (colors.surfaceAccent ?? const Color(0xFFE6E6E6)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}
