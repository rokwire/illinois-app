import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/gbv/GBVQuickExitWidget.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/gbv/GBVResourceListPanel.dart';
import 'package:illinois/ui/gbv/GBVResourceDetailPanel.dart';
import '../../model/GBV.dart';

const Map<String, Map<String, Object>> stepIcons = <String, Map<String, Object>>{
  'situation': <String, Object>{'image': 'compass', 'color': 0xFF9318BB},
  'whats_happening': <String, Object>{'image': 'ban', 'color': 0xFFF09842},
  'involved': <String, Object>{'image': 'user', 'color': 0xFF5182CF},
  'next': <String, Object>{'image': 'signs-post', 'color': 0xFF5FA7A3},
  'services': <String, Object>{'image': 'timeline', 'color': 0xFF9318BB},
};

class GBVSituationStepPanel extends StatefulWidget {
  final Survey survey;
  final GBVData gbvData;

  const GBVSituationStepPanel({
    Key? key,
    required this.survey,
    required this.gbvData,
  }) : super(key: key);

  @override
  _GBVSituationStepPanelState createState() => _GBVSituationStepPanelState();
}

class _GBVSituationStepPanelState extends State<GBVSituationStepPanel> {
  late Survey _survey;
  SurveyData? _currentStep;
  bool _loading = false;
  final List<String> _stepHistory = <String>[];

  @override
  void initState() {
    super.initState();
    _survey = Survey.fromOther(widget.survey);
    _currentStep = Surveys().getFirstQuestion(_survey);
    if (_currentStep != null) _stepHistory.add(_currentStep!.key);
  }

  Future<void> _selectOption(String title) async {
    if (_currentStep == null) return;
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    _currentStep!.response = title;

    await Surveys().evaluate(_survey);
    if (!mounted) return;

    final next = Surveys().getFollowUp(_survey, _currentStep!);
    if (next != null) {
      if (!mounted) return;
      setState(() {
        _currentStep = next;
        _stepHistory.add(next.key);
        _loading = false;
      });
    } else {
      await _showResults();
    }
  }

  Future<void> _showResults() async {
    await Surveys().evaluate(
      _survey,
      evalResultRules: true,
      summarizeResultRules: false,
      returnMultiple: true,
    );
    if (!mounted) return;

    SurveyStats? stats = _survey.stats;
    final lastStepKey = _stepHistory.last;

    final String? resp = stats?.responseData[lastStepKey] as String?;
    final String lookupKey = resp ?? (stats?.responseData['next'] as String? ?? '');

    final Map<String, dynamic>? entryMap =
    (_survey.data['gbv_resource_map'] as SurveyData).extras?[lookupKey] as Map<String, dynamic>?;

    if (entryMap == null) {
      setState(() { _loading = false; });
      _onFileReport(context, widget.gbvData);
    }

    // If skip_to_report flag in survey is true, go straight to the report page
    if (entryMap?['skip_to_report'] == true) {
      setState(() { _loading = false; });
      _onFileReport(context, widget.gbvData);
    }

    // Otherwise group resources by category as before
    final List<String> resourceIds =
    (entryMap?['resource_ids'] as List<dynamic>).cast<String>();
    final availableIds = widget.gbvData.resources.map((r) => r.id).toSet();
    final validIds = resourceIds.where(availableIds.contains).toList();

    final Map<String, List<String>> categoryToIds = {};
    final idsToProcess =
    validIds.isNotEmpty ? validIds : availableIds.take(3).toList();
    for (final id in idsToProcess) {
      final resource =
      widget.gbvData.resources.firstWhere((r) => r.id == id);
      final String category = resource.categories.first;
      categoryToIds.putIfAbsent(category, () => []).add(id);
    }

    final content = categoryToIds.entries
        .map((e) => GBVResourceList(title: e.key, resourceIds: e.value))
        .toList();

    // final screen = GBVResourceListScreen(
    //   type: 'panel',
    //   title: 'Your Top Resources',
    //   description: 'Based on what you shared, here are some options that may help. '
    //       'You’re in control of what happens next—take your time and explore what feels right. '
    //       'You’re not alone, and support is available if you need it.',
    //   content: content,
    // );
    final screen = GBVResourceListScreen(
      type: 'panel',
      title: Localization().getStringEx('panel.sexual_misconduct.survey_result.title', 'Your Top Resources'),
      description: Localization().getStringEx(
          'panel.sexual_misconduct.survey_result.description',
          'Based on what you shared, here are some options that may help. '
              'You’re in control of what happens next—take your time and explore what feels right. '
              'You’re not alone, and support is available if you need it.'),
      content: content,
    );

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (ctx) => GBVResourceListPanel(
          gbvData: widget.gbvData,
          resourceListScreen: screen,
          showDirectoryLink: true,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  void _handleBack() {
    if (_stepHistory.length > 1) {
      _stepHistory.removeLast();
      final previousKey = _stepHistory.last;
      setState(() {
        _currentStep = _survey.data[previousKey];
        _currentStep?.response = null;
        _loading = false;
      });

      Surveys().evaluate(_survey).then((_) {
        if (!mounted) return;
        setState(() {});
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _onFileReport(BuildContext context, GBVData gbvContent) {
    Analytics().logSelect(target: 'File a report');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDetailPanel(resource: gbvContent.resources.firstWhere((r) => r.id == 'filing_a_report'))));
  }

  Widget _buildScaffold(Widget body) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      appBar: HeaderBar(onLeading: _handleBack),
      body: body,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }


  Widget _buildOption(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: InkWell(
        onTap: () => _selectOption(title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Styles().textStyles.getTextStyle('widget.title.regular'),
                ),
              ),
              Styles().images.getImage(
                'chevron-right',
                excludeFromSemantics: true,
                size: 18,
                color: Styles().colors.fillColorPrimary,
              ) ?? Container(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: [
        const Expanded(flex: 1, child: SizedBox()),
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: Styles().colors.fillColorSecondary,
            strokeWidth: 3,
          ),
        ),
        const Expanded(flex: 2, child: SizedBox()),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          Localization().getStringEx('panel.sexual_misconduct.survey_result.error', 'Failed to load survey.'),
          textAlign: TextAlign.center,
          style: Styles().textStyles.getTextStyle("widget.message.medium.thin"),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return _buildScaffold(_buildLoadingContent());
    }
    if (_currentStep == null) {
      return _buildScaffold(_buildErrorContent());
    }
    final question = _currentStep!;
    final opts = (question is SurveyQuestionMultipleChoice) ? question.options : [];

    Widget? stepIconWidget;
    try {
      final currentStepKey = _currentStep!.key;
      final stepData = _survey.data[currentStepKey];
      if (stepData != null && stepData.extras != null && stepData.extras is Map) {
        final extrasMap = stepData.extras as Map<String, dynamic>;
        final iconName = extrasMap['image'] as String?;
        final colorString = extrasMap['color'] as String?;

        Color iconColor = const Color(0xFF9318BB);
        if (colorString != null && colorString.startsWith('0x')) {
          iconColor = Color(int.parse(colorString));
        }

        if (iconName != null) {
          stepIconWidget = Container(
            width: 67,
            height: 67,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Styles().images.getImage(
                iconName,
                excludeFromSemantics: true,
                size: 36,
                fit: BoxFit.contain,
                color: Colors.white,
              ) ?? Container(),
            ),
          );
        }
      }

      if (stepIconWidget == null) {
        final fallbackIconData = stepIcons[currentStepKey];
        if (fallbackIconData != null) {
          stepIconWidget = Container(
            width: 67,
            height: 67,
            decoration: BoxDecoration(
              color: Color(fallbackIconData['color'] as int),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Styles().images.getImage(
                fallbackIconData['image'] as String,
                excludeFromSemantics: true,
                size: 36,
                fit: BoxFit.contain,
                color: Colors.white,
              ) ?? Container(),
            ),
          );
        }
      }
    } catch (e) {
      final fallbackIconData = stepIcons[_currentStep!.key];
      if (fallbackIconData != null) {
        stepIconWidget = Container(
          width: 67,
          height: 67,
          decoration: BoxDecoration(
            color: Color(fallbackIconData['color'] as int),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Styles().images.getImage(
              fallbackIconData['image'] as String,
              excludeFromSemantics: true,
              size: 36,
              fit: BoxFit.contain,
              color: Colors.white,
            ) ?? Container(),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Styles().colors.background,
      appBar: HeaderBar(
        onLeading: _handleBack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GBVQuickExitWidget(),
            if (question.moreInfo?.isNotEmpty == true)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (stepIconWidget != null) ...[
                      stepIconWidget,
                      const SizedBox(width: 18),
                    ],
                    Expanded(
                      child: Text(
                        question.moreInfo!,
                        style: Styles().textStyles.getTextStyle('widget.description.regular'),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              question.text,
              style: Styles().textStyles.getTextStyle('widget.description.regular'),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_stepHistory.length) / 5,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Color(0xFFED6647)),
            ),
            const SizedBox(height: 24),
            ...opts.map((o) => _buildOption(o.title)),
            if (question.allowSkip)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _selectOption('__skipped__'),
                  child: Text(
                    Localization().getStringEx('panel.sexual_misconduct.survey.skip', 'Skip this question'),
                    style: Styles().textStyles.getTextStyle('widget.detail.regular'),
                  ),
                ),
              ),
            if (_loading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: CircularProgressIndicator(
                    color: Styles().colors.fillColorSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }
}
