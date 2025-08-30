import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:illinois/service/GBVRules.dart';
import 'package:illinois/model/SurveyTracker.dart';
import 'package:illinois/ui/gbv/QuickExitWidget.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/ui/gbv/ResourceDetailPanel.dart';
import '../../model/GBV.dart';
//TODO: Use Styles, localize texts, check all state mounting, fix back button

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
  final Map<String, SurveyData> surveyData;
  final SurveyTracker responseTracker;
  final String stepKey;
  final List<GBVResource> resources;

  const SituationStepPanel({
    Key? key,
    required this.surveyData,
    required this.responseTracker,
    required this.stepKey,
    required this.resources,
  }) : super(key: key);

  @override
  _SituationStepPanelState createState() => _SituationStepPanelState();
}

class _SituationStepPanelState extends State<SituationStepPanel> {
  late String _currentStepKey;
  bool _showingResult = false;
  SurveyData? _resultResource;
  bool _loading = false;
  List<String> _stepHistory = [];
  List<GBVResource> _allResources = [];

  @override
  void initState() {
    super.initState();
    _currentStepKey = widget.stepKey;
  }

  void _onOptionSelected(String stepKey, String selectedOption) async {
    widget.responseTracker.setResponse('data.$stepKey.response', selectedOption);

    // Handle Q4 cases explicitly before default flow:
    if (stepKey == "next") {
      switch (selectedOption) {
        case "Talk to someone confidentially":
        // Proceed to Q5 (prioritize)
          setState(() {
            _currentStepKey = "prioritize";
            _stepHistory.add(_currentStepKey);
          });
          return;

        case "Find out more about reporting options":
          _setFilteredResults(['filing_a_report']);
          return;

        case "Seek medical help":
          _setFilteredResults([
            'emergencies_911',
            'mckinley_health_center_medical',
            'university_emergency_dean',
            'carle_foundation_hospital',
            'osf_medical_center'
          ]);
          return;

        case "Access educational materials on my own":
          _setFilteredResults([
            'we_care_at_illinois_website',
            'we_care_brochure',
            'rights_and_options',
            'womens_resource_center',
            'supporting_a_friend'
          ]);
          return;
      }
    }

    // Q5 prioritize logic:
    if (stepKey == "prioritize") {
      List<String> filteredIds = [];
      switch (selectedOption) {
        case "On-campus services":
          filteredIds = ["confidential_advisors", "counseling_center", "mckinley_health_center_mental"];
          break;
        case "Off-campus community services":
          filteredIds = ["rape_advocacy_and_counseling", "courage_connection"];
          break;
        case "24-7 options":
          filteredIds = ["rosecrance_hotline","rape_crisis_hotline","ui_police_department","courage_connection_hotline","national_sexual_assault_hotline"];
          break;
      }
      _setFilteredResults(filteredIds);
      return;
    }

    // Default fallback
    SurveyData? currentStepData = widget.surveyData[stepKey];
    String? nextStepKey = currentStepData?.defaultFollowUpKey;
    const questionKeys = [
      'situation', 'whats_happening', 'involved', 'next', 'prioritize'
    ];
    if (nextStepKey != null && questionKeys.contains(nextStepKey)) {
      setState(() {
        _currentStepKey = nextStepKey;
        _stepHistory.add(_currentStepKey);
      });
    } else {
      setState(() {
        _loading = true;
      });
      List rules = await GBVResultRulesService.loadRules();
      dynamic matchResult = getMatchingResult(rules, widget.responseTracker.responses);
      if (matchResult != null && matchResult['action'] == 'alert') {
        String dataKey = (matchResult['data'] as String).replaceFirst('data.', '');
        SurveyData? resource = widget.surveyData[dataKey];
        setState(() {
          _loading = false;
          _showingResult = true;
          _resultResource = resource;
        });
      } else {
        setState(() {
          _loading = false;
          _showingResult = false;
          _resultResource = null;
        });
        _showNoResultDialog();
      }
    }
  }

// Helper to set filtered results from resource ids and show the survey_data.result panel
  void _setFilteredResults(List<String> resourceIds) {

    // Clear any previous filtered ids in tracker
    widget.responseTracker.responses.remove('data.prioritize.filtered_ids');
    widget.responseTracker.setResponse('data.prioritize.filtered_ids', resourceIds.join(","));

    SurveyData? resultResource;

    // Helper mapping from resourceId lists to surveyData keys for special Q4 sets
    if (resourceIds.length == 1 && resourceIds.contains('filing_a_report')) {
      // Q4: "Find out more about reporting options"
      resultResource = widget.surveyData['set_B'];
    } else if (resourceIds.contains('emergencies_911')) {
      resultResource = widget.surveyData['set_C'];
    } else if (resourceIds.contains('we_care_at_illinois_website')) {
      resultResource = widget.surveyData['set_D'];
    } else {
      // Default to set_A for Q5 filtering
      resultResource = widget.surveyData['set_A'];
    }

    setState(() {
      _loading = false;
      _showingResult = true;
      _resultResource = resultResource;
    });
  }

  void _onTapResource(GBVResource resource) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResourceDetailPanel(resource: resource)));
  }

  void _onBackPressed() {
    if (_stepHistory.length > 1) {
      setState(() {
        _stepHistory.removeLast();
        _currentStepKey = _stepHistory.last;
        // Remove the last response for this step, so user can re-answer
        widget.responseTracker.responses.remove('data.$_currentStepKey.response');
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onSkipSelected(String stepKey) async {
    // Save a skip marker
    widget.responseTracker.setResponse('data.$stepKey.response', '__skipped__');

    SurveyData? currentStepData = widget.surveyData[stepKey];
    String? nextStepKey = currentStepData?.defaultFollowUpKey;

    // Now advance as if a normal answer was selected:
    if (nextStepKey != null && nextStepKey.isNotEmpty) {
      setState(() {
        _currentStepKey = nextStepKey;
        _stepHistory.add(_currentStepKey);
      });
    } else {
      // End of survey, show results or other resource
      setState(() {
        _loading = true;
      });
      List rules = await GBVResultRulesService.loadRules();
      dynamic matchResult = getMatchingResult(rules, widget.responseTracker.responses);
      if (matchResult != null && matchResult['action'] == 'alert') {
        String dataKey = (matchResult['data'] as String).replaceFirst('data.', '');
        SurveyData? resource = widget.surveyData[dataKey];
        setState(() {
          _loading = false;
          _showingResult = true;
          _resultResource = resource;
        });
      } else {
        setState(() {
          _loading = false;
          _showingResult = false;
          _resultResource = null;
        });
        _showNoResultDialog();
      }
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

  Widget _buildOptionCard(String stepKey, String title, VoidCallback onTap) {
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

  Widget _buildQuestionView(SurveyData stepData) {
    const questionKeys = [
      'situation',
      'whats_happening',
      'involved',
      'next',
      'prioritize',
    ];
    final totalSteps = questionKeys.length;
    int currentStepNumber = questionKeys.indexOf(_currentStepKey) + 1;

    List? options;
    if (stepData is SurveyQuestionMultipleChoice) {
      options = stepData.options;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuickExitWidget(),
            // Helper/More Info Textbox
            if (stepData.moreInfo != null && stepData.moreInfo!.isNotEmpty) ...[
              // Determine which icon/color to use based on current step
              Builder(
                builder: (_) {
                  final iconData = stepIcons[_currentStepKey] ?? {
                    'image': 'compass',//fallback
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
                            stepData.moreInfo!,
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
                stepData.text,
                style: TextStyle(fontSize: 14),
              ),
            ),
            // Progress Bar
            LinearProgressIndicator(
              value: currentStepNumber > 0 ? currentStepNumber / totalSteps : 0,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFED6647)),
            ),
            SizedBox(height: 24),
            // Option Buttons
            ...options.map((opt) => _buildOptionCard(
              _currentStepKey,
              opt.title ?? '',
                  () => _onOptionSelected(_currentStepKey, opt.title ?? ''),
            )),
            if (stepData.allowSkip == true)
              Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _onSkipSelected(_currentStepKey),
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

    return Container();
  }

  Widget _buildResultView(SurveyData resourceData) {
    List<String>? topResource_ids;

    if (resourceData.moreInfo != null && resourceData.moreInfo!.isNotEmpty) {
      topResource_ids = List<String>.from(JsonUtils.decodeList(resourceData.moreInfo!) ?? []);
    }
    if (widget.responseTracker.responses.containsKey("data.prioritize.filtered_ids")) {
      final filtered = widget.responseTracker.responses["data.prioritize.filtered_ids"]?.split(",") ?? [];
      // Override topResource_ids only if filtered list is not empty
      if (filtered.isNotEmpty) {
        topResource_ids = filtered;
      }
    }

    if (topResource_ids == null || topResource_ids.isEmpty) {
      // Defensive fallback: no resources matched, show empty list
      _allResources = [];
    } else {
      _allResources = List.from(widget.resources.where((resource) => topResource_ids!.contains(resource.id)));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            setState(() {
              _showingResult = false;
              _resultResource = null;
              _currentStepKey = widget.stepKey;
              widget.responseTracker.responses.clear();
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
          QuickExitWidget(),
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
              'Here are resources based on your answers:',
              style: Styles().textStyles.getTextStyle("widget.detail.regular"),
            ),
          ),
          ..._allResources.map((res) => _resourceWidget(res)).toList(),
        ],
      ),
    );
  }

  Widget _resourceWidget (GBVResource resource) {
    Widget descriptionWidget = (resource.directoryContent.isNotEmpty)
        ? Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8), child:
    Column(children:
    // Map different directory content types here
    resource.directoryContent.map((detail) => Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.regular"))).toList()
    )
    )
        : Container();
    return
      Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
      Container(decoration:
      BoxDecoration(
        color: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ), child:
      Padding(padding: EdgeInsets.symmetric(vertical: 20), child:
      Row(children: [
        Expanded(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: EdgeInsets.only(left: 16), child:
          Text(resource.title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"))
          ),
          descriptionWidget
        ])
        ),
        GestureDetector(onTap: () => _onTapResource(resource), child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
        Styles().images.getImage((resource.type == GBVResourceType.external_link) ? 'external-link' : 'chevron-right', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
        )
        )
      ])
      )
      )
      );
  }

  Widget _buildContent(BuildContext context){
    if (_showingResult && _resultResource != null) {
      return _buildResultView(_resultResource!);
    }

    SurveyData? stepData = widget.surveyData[_currentStepKey];

    if (stepData == null) {
      // If step data missing for current step, show error
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Column(
          children: [
            QuickExitWidget(),
            Center(
              child: Text('Survey step data not found for key: $_currentStepKey'),
            )
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
      body: _buildQuestionView(stepData), bottomNavigationBar: uiuc.TabBar()
    );

  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }
}
