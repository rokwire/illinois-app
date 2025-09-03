import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/widgets/survey.dart';
import 'package:rokwire_plugin/model/options.dart';
import 'package:illinois/ui/gbv/GBVQuickExitWidget.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/ui/gbv/GBVResourceDetailPanel.dart';
import '../../model/GBV.dart';

const Map<String, Map<String, dynamic>> stepIcons = {
  'situation': {
    'image': 'compass',
    'color': Color(0xFF9318BB),
  },
  'whats_happening': {
    'image': 'ban',
    'color': Color(0xFFF09842),
  },
  'involved': {
    'image': 'user',
    'color': Color(0xFF5182CF),
  },
  'next': {
    'image': 'signs-post',
    'color': Color(0xFF5FA7A3),
  },
  'prioritize': {
    'image': 'timeline',
    'color': Color(0xFF9318BB),
  },
};

class SituationStepPanel extends StatefulWidget {
  final Survey survey;
  final List<GBVResource> resources;

  const SituationStepPanel({
    Key? key,
    required this.survey,
    required this.resources,
  }) : super(key: key);

  @override
  _SituationStepPanelState createState() => _SituationStepPanelState();
}

class _SituationStepPanelState extends State<SituationStepPanel> {
  late Survey _survey;
  SurveyData? _currentStepData;
  bool _showingResult = false;
  bool _loading = false;
  List<String> _stepHistory = [];
  List<GBVResource> _filteredResources = [];
  SurveyWidgetController? _surveyController;

  @override
  void initState() {
    super.initState();
    _survey = Survey.fromOther(widget.survey);
    _initializeSurvey();
  }

  void _initializeSurvey() {
    // Get the first question using the survey framework
    _currentStepData = Surveys().getFirstQuestion(_survey);

    // Evaluate the survey at the start
    if (_currentStepData != null) {
      Surveys().evaluate(_survey);
      _stepHistory.add(_currentStepData!.key);
    }
  }

  void _onOptionSelected(String selectedOption) async {
    if (_currentStepData == null) return;

    // Update the current step's response using the survey framework
    _currentStepData!.response = selectedOption;

    // Evaluate the survey after response change
    await Surveys().evaluate(_survey);

    // Handle special Q4 cases before using getFollowUp
    if (_currentStepData!.key == "next") {
      await _handleNextStepSpecialCases(selectedOption);
      return;
    }

    // Handle Q5 prioritize logic
    if (_currentStepData!.key == "prioritize") {
      await _handlePrioritizeStep(selectedOption);
      return;
    }

    // Use the survey lib service to get the next step
    SurveyData? nextStepData = Surveys().getFollowUp(_survey, _currentStepData!);

    if (nextStepData != null) {
      setState(() {
        _currentStepData = nextStepData;
        _stepHistory.add(_currentStepData!.key);
      });
    } else {
      // End of survey - evaluate with result rules
      await _finishSurvey();
    }
  }

  Future<void> _handleNextStepSpecialCases(String selectedOption) async {
    switch (selectedOption) {
      case "Talk to someone confidentially":
      // Proceed to Q5 (prioritize)
        SurveyData? prioritizeStep = _survey.data["prioritize"];
        if (prioritizeStep != null) {
          setState(() {
            _currentStepData = prioritizeStep;
            _stepHistory.add(_currentStepData!.key);
          });
        }
        return;
      case "Find out more about reporting options":
        await _setFilteredResults(['filing_a_report'], 'set_B');
        return;
      case "Seek medical help":
        await _setFilteredResults([
          'emergencies_911',
          'mckinley_health_center_medical',
          'university_emergency_dean',
          'carle_foundation_hospital',
          'osf_medical_center'
        ], 'set_C');
        return;
      case "Access educational materials on my own":
        await _setFilteredResults([
          'we_care_at_illinois_website',
          'we_care_brochure',
          'rights_and_options',
          'womens_resource_center',
          'supporting_a_friend'
        ], 'set_D');
        return;
    }
  }

  Future<void> _handlePrioritizeStep(String selectedOption) async {
    List<String> filteredIds = [];
    switch (selectedOption) {
      case "On-campus services":
        filteredIds = ["confidential_advisors", "counseling_center", "mckinley_health_center_mental"];
        break;
      case "Off-campus community services":
        filteredIds = ["rape_advocacy_and_counseling", "courage_connection"];
        break;
      case "24-7 options":
        filteredIds = ["rosecrance_hotline", "rape_crisis_hotline", "ui_police_department",
          "courage_connection_hotline", "national_sexual_assault_hotline"];
        break;
    }
    await _setFilteredResults(filteredIds, 'set_A');
  }

  Future<void> _setFilteredResults(List<String> resourceIds, String resultKey) async {
    // Filter resources based on IDs
    _filteredResources = widget.resources.where((resource) =>
        resourceIds.contains(resource.id)).toList();

    // Get the result data from survey
    SurveyData? resultResource = _survey.data[resultKey];

    setState(() {
      _loading = false;
      _showingResult = true;
      _currentStepData = resultResource;
    });
  }

  Future<void> _finishSurvey() async {
    setState(() {
      _loading = true;
    });

    // Evaluate survey with result rules
    dynamic result = await Surveys().evaluate(_survey, evalResultRules: true, summarizeResultRules: false);

    if (result != null) {
      // Handle the survey result
      _handleSurveyResult(result);
    } else {
      setState(() {
        _loading = false;
      });
      _showNoResultDialog();
    }
  }

  void _handleSurveyResult(dynamic result) {
    // Process the result to show appropriate resources
    setState(() {
      _loading = false;
      _showingResult = true;
    });
  }

  void _onTapResource(GBVResource resource) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDetailPanel(resource: resource)));
  }

  void _onBackPressed() {
    if (_stepHistory.length > 1) {
      setState(() {
        _stepHistory.removeLast();
        String previousKey = _stepHistory.last;
        _currentStepData = _survey.data[previousKey];

        // Clear the response for the current step so user can re-answer
        if (_currentStepData != null) {
          _currentStepData!.response = null;
        }
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onSkipSelected() async {
    if (_currentStepData == null) return;

    // Mark as skipped
    _currentStepData!.response = '__skipped__';

    // Evaluate survey
    await Surveys().evaluate(_survey);

    // Get next question
    SurveyData? nextStepData = Surveys().getFollowUp(_survey, _currentStepData!);

    if (nextStepData != null) {
      setState(() {
        _currentStepData = nextStepData;
        _stepHistory.add(_currentStepData!.key);
      });
    } else {
      // End of survey
      await _finishSurvey();
    }
  }

  void _showNoResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("No matching result"),
        content: Text("No resources matched your responses."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  Widget _buildOptionCard(String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFFED6647)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionView() {
    if (_currentStepData == null) return Container();

    const questionKeys = [
      'situation',
      'whats_happening',
      'involved',
      'next',
      'prioritize',
    ];

    final totalSteps = questionKeys.length;
    int currentStepNumber = questionKeys.indexOf(_currentStepData!.key) + 1;

    List<OptionData>? options;
    if (_currentStepData is SurveyQuestionMultipleChoice) {
      options = (_currentStepData as SurveyQuestionMultipleChoice).options;
    }

    if (options == null) return Container();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GBVQuickExitWidget(),

          // Helper/More Info Textbox
          if (StringUtils.isNotEmpty(_currentStepData!.moreInfo)) ...[
            Builder(
              builder: (_) {
                final iconData = stepIcons[_currentStepData!.key] ?? {
                  'image': 'compass',
                  'color': Color(0xFF9318BB),
                };
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12.0, bottom: 24),
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 67,
                        height: 67,
                        decoration: BoxDecoration(
                          color: iconData['color'],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Styles().images.getImage(
                            iconData['image'],
                            excludeFromSemantics: true,
                            size: 36,
                            fit: BoxFit.contain,
                            color: Colors.white,
                          ) ?? Container(),
                        ),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          _currentStepData!.moreInfo!,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          // Question Text
          Padding(
            padding: const EdgeInsets.only(bottom: 18.0),
            child: Text(
              _currentStepData!.text,
              style: TextStyle(fontSize: 14),
            ),
          ),

          // Progress Bar
          LinearProgressIndicator(
            value: currentStepNumber > 0 ? currentStepNumber / totalSteps : 0,
            minHeight: 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(Color(0xFFED6647)),
          ),
          SizedBox(height: 24),

          // Option Buttons
          ...options.map((opt) => _buildOptionCard(
            opt.title,
                () => _onOptionSelected(opt.title),
          )),

          if (_currentStepData!.allowSkip == true)
            Padding(
              padding: const EdgeInsets.only(top: 18.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _onSkipSelected,
                  child: Text(
                    "Skip this question",
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),

          // Loading Indicator
          if (_loading)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            setState(() {
              _showingResult = false;
              _currentStepData = Surveys().getFirstQuestion(_survey);
              // Reset survey responses
              for (var data in _survey.data.values) {
                data.response = null;
              }
              Surveys().evaluate(_survey);
            });
          },
        ),
      ),
      body: _bodyWidget(),
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _bodyWidget() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GBVQuickExitWidget(),
          Padding(
            padding: EdgeInsets.only(top: 16, left: 16),
            child: Text(
              'Your Top Resources',
              style: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Container(height: 1, color: Styles().colors.surfaceAccent),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16, left: 16, bottom: 32),
            child: Text(
              'Based on what you shared, here are some options that may help. You\'re in control of what happens next—take your time and explore what feels right. You\'re not alone, and support is available if you need it.',
              style: Styles().textStyles.getTextStyle("widget.detail.regular"),
            ),
          ),
          ..._filteredResources.map((res) => _resourceWidget(res)).toList(),
        ],
      ),
    );
  }

  Widget _resourceWidget(GBVResource resource) {
    Widget descriptionWidget = (resource.directoryContent.isNotEmpty)
        ? Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Column(
        children: resource.directoryContent
            .map((detail) => Text(
            detail.content ?? '',
            style: Styles().textStyles.getTextStyle("widget.detail.regular")))
            .toList(),
      ),
    )
        : Container();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Text(resource.title,
                          style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat")),
                    ),
                    descriptionWidget
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _onTapResource(resource),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Styles().images.getImage(
                    (resource.type == GBVResourceType.external_link)
                        ? 'external-link'
                        : 'chevron-right',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ) ?? Container(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_showingResult) {
      return _buildResultView();
    }

    if (_currentStepData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Column(
          children: [
            GBVQuickExitWidget(),
            Center(
              child: Text('Survey step data not found'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _onBackPressed,
        ),
      ),
      body: _buildQuestionView(),
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }
}