import 'package:flutter/material.dart';
import 'package:illinois/ui/alumni/AlumniOnboardingLinkedInPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
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
  void initState() {
    super.initState();
    // Pre-populate with existing user data if available
    // _loadUserData();
  }

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
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.alumni.onboarding.header.title", "Alumni"),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),
      ),
      backgroundColor: Styles().colors.background,
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(step: 2, totalSteps: 4),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  Text(
                    Localization().getStringEx(
                        "panel.alumni.onboarding.review.step",
                        "Review Your Information (2/4)"
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
                        "panel.alumni.onboarding.review.title",
                        "Is this correct?"
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
                        "panel.alumni.onboarding.review.description",
                        "We pulled this from your student profile. Edit anything that has changed."
                    ),
                    style: TextStyle(
                      color: Styles().colors.textSurface,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 32),

                  // Name fields
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: Localization().getStringEx(
                              "panel.alumni.onboarding.review.first_name.label",
                              "First Name"
                          ),
                          controller: _firstNameController,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          label: Localization().getStringEx(
                              "panel.alumni.onboarding.review.last_name.label",
                              "Last Name"
                          ),
                          controller: _lastNameController,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Location fields
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: Localization().getStringEx(
                              "panel.alumni.onboarding.review.city.label",
                              "Current City"
                          ),
                          controller: _cityController,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          label: Localization().getStringEx(
                              "panel.alumni.onboarding.review.country.label",
                              "Country"
                          ),
                          controller: _countryController,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Employment fields
                  _buildInputField(
                    label: Localization().getStringEx(
                        "panel.alumni.onboarding.review.employer.label",
                        "Employer"
                    ),
                    controller: _employerController,
                  ),
                  SizedBox(height: 24),

                  _buildInputField(
                    label: Localization().getStringEx(
                        "panel.alumni.onboarding.review.title.label",
                        "Title"
                    ),
                    controller: _titleController,
                  ),
                  SizedBox(height: 24),

                  // Education fields
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: Localization().getStringEx(
                              "panel.alumni.onboarding.review.graduation_year.label",
                              "Graduation Year"
                          ),
                          controller: _graduationYearController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          label: Localization().getStringEx(
                              "panel.alumni.onboarding.review.college.label",
                              "College"
                          ),
                          controller: _collegeController,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Looks good button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            child: RoundedButton(
              label: Localization().getStringEx(
                  "panel.alumni.onboarding.review.button.looks_good",
                  "Looks good!"
              ),
              backgroundColor: Styles().colors.fillColorSecondary,
              textColor: Colors.white,
              borderColor: Styles().colors.fillColorSecondary,
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              onTap: _onLooksGood,
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Styles().colors.fillColorPrimary,
            fontSize: 14,
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
        ),
      ],
    );
  }

  void _onLooksGood() {
    // Save the updated information
    // _saveUserData();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AlumniOnboardingLinkedInPanel(),
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

// void _loadUserData() {
//   // Load user data from Auth2 profile
//   final profile = Auth2().profile;
//   if (profile != null) {
//     _firstNameController.text = profile.firstName ?? '';
//     _lastNameController.text = profile.lastName ?? '';
//     // Add other fields as needed
//   }
// }

// void _saveUserData() {
//   // Save updated profile data
//   // Auth2().updateProfile(...);
// }
}