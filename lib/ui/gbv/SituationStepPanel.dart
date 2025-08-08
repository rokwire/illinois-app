import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:illinois/service/GBVRules.dart';
import 'package:illinois/model/SurveyTracker.dart';

class SituationStepPanel extends StatefulWidget {
  final Map<String, SurveyData> surveyData;
  final SurveyTracker responseTracker;
  final String stepKey;

  const SituationStepPanel({
    Key? key,
    required this.surveyData,
    required this.responseTracker,
    required this.stepKey,
  }) : super(key: key);

  @override
  _SituationStepPanelState createState() => _SituationStepPanelState();
}

class _SituationStepPanelState extends State<SituationStepPanel> {
  late String _currentStepKey;
  bool _showingResult = false;
  SurveyData? _resultResource;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _currentStepKey = widget.stepKey;
  }

  void _onOptionSelected(String stepKey, String selectedOption) async {
    // Save response in tracker keyed by the full key pattern matching rules JSON
    widget.responseTracker.setResponse('data.$stepKey.response', selectedOption);

    // Find current step data to see if there is a follow-up step
    SurveyData? currentStepData = widget.surveyData[stepKey];
    String? nextStepKey = currentStepData?.defaultFollowUpKey;

    if (nextStepKey != null && nextStepKey.isNotEmpty) {
      // Move to next step
      setState(() {
        _currentStepKey = nextStepKey;
      });
    } else {
      // No more follow-up steps: evaluate rules for results
      setState(() {
        _loading = true;
      });

      List<dynamic> rules = await GBVResultRulesService.loadRules();

      dynamic matchResult = getMatchingResult(rules, widget.responseTracker.responses);

      if (matchResult != null && matchResult['action'] == 'alert') {
        // Extract key after "data."
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
        // Optionally show a default message if no matching result
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

  Widget _buildOptionButton(String stepKey, String optionTitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical:8.0),
      child: ElevatedButton(
        onPressed: () => _onOptionSelected(stepKey, optionTitle),
        child: Text(optionTitle),
      ),
    );
  }

  Widget _buildQuestionView(SurveyData stepData) {
    List? options;
    if (stepData is SurveyQuestionMultipleChoice) {
      options = stepData.options;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stepData.text,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (stepData.moreInfo != null && stepData.moreInfo!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 24),
              child: Text(
                stepData.moreInfo!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          if (options != null)
            ...options.map((opt) => _buildOptionButton(_currentStepKey, opt.title ?? '')),
          if (_loading)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildResultView(SurveyData resourceData) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommended Resource'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            // Allow user to restart survey or pop back
            setState(() {
              _showingResult = false;
              _resultResource = null;
              _currentStepKey = widget.stepKey;
              widget.responseTracker.responses.clear();
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resourceData.text,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (resourceData.moreInfo != null && resourceData.moreInfo!.isNotEmpty)
              Text(resourceData.moreInfo!),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                // Restart the survey
                setState(() {
                  _showingResult = false;
                  _resultResource = null;
                  _currentStepKey = widget.stepKey;
                  widget.responseTracker.responses.clear();
                });
              },
              child: Text("Start Over"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showingResult && _resultResource != null) {
      return _buildResultView(_resultResource!);
    }

    SurveyData? stepData = widget.surveyData[_currentStepKey];

    if (stepData == null) {
      // If step data missing for current step, show error
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Text('Survey step data not found for key: $_currentStepKey'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Step $_currentStepKey')),
      body: _buildQuestionView(stepData),
    );
  }
}
