import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/gbv/GBVQuickExitWidget.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/gbv/GBVResourceListPanel.dart';
import 'package:illinois/ui/gbv/GBVResourceDetailPanel.dart';
import '../../model/GBV.dart';

const Map<String, Map<String, Object>> stepIcons = {
  'situation':      {'image': 'compass',      'color': 'accentColor4'},
  'whats_happening':{'image': 'ban',          'color': 'diningColor'},
  'involved':       {'image': 'user',         'color': 'accentColor3'},
  'next':           {'image': 'signs-post',   'color': 'accentColor2'},
  'services':       {'image': 'timeline',     'color': 'accentColor4'},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      appBar: HeaderBar(onLeading: _handleBack),
      body: _scaffoldContent,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget get _scaffoldContent {
    if (_loading) {
      return _loadingContent;
    }
    else if (_currentStep == null) {
      return _errorContent;
    }
    else {
      return _surveyContent;
    }
  }

  Widget get _surveyContent  {
    SurveyData? question = _currentStep;
    final opts = (question is SurveyQuestionMultipleChoice) ? question.options : [];

    return SingleChildScrollView(padding: const EdgeInsets.all(20), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GBVQuickExitWidget(),

      if ((question != null) && (question.moreInfo?.isNotEmpty == true))
        _buildMoreInfo(question),

      Text(question?.text ?? '', style: Styles().textStyles.getTextStyle('widget.description.regular'),),

      const SizedBox(height: 12),
      _stepProgressIndicator,
      const SizedBox(height: 24),

      ...opts.map((o) => _buildOption(o.title)),

      if (question?.allowSkip == true)
        _allowSkipButton(question),

      if (_loading)
        _loadingProgressIndicator,
    ],),
    );
  }

  Widget _buildMoreInfo(SurveyData question) {
    Widget? stepIconWidget = _getStepIconWidget(question.key);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        if (stepIconWidget != null)
          Padding(padding: EdgeInsets.only(right: 18), child:
            stepIconWidget
          ),
        Expanded(child:
          Text(question.moreInfo ?? '', style: Styles().textStyles.getTextStyle('widget.description.regular'))),
      ],),
    );
  }

  Widget _allowSkipButton(question) {
    String skipText = question.extras["skip_text"] ?? 'Skip this question';
    return Align(alignment: Alignment.centerRight, child:
      TextButton(onPressed: () => _selectOption('__skipped__'), child:
        Text(skipText, style: Styles().textStyles.getTextStyle('widget.detail.regular.underline'),),
      ),
    );
  }

  Widget get _loadingProgressIndicator => Center(child:
    Padding(padding: const EdgeInsets.only(top: 24.0), child:
      CircularProgressIndicator(color: Styles().colors.fillColorSecondary)
    ),
  );

  Widget get _stepProgressIndicator => LinearProgressIndicator(
    value: (_stepHistory.length) / 5,
    color: Styles().colors.fillColorSecondary,
    backgroundColor: Styles().colors.surface,
  );

  Widget? _getStepIconWidget(String stepKey) {
    // Try extras-defined icon from database
    final stepData = _survey.data[stepKey];
    if (stepData?.extras is Map) {
      final extrasMap = stepData!.extras as Map;
      final iconName = extrasMap['image'] as String?;
      final colorString = extrasMap['color'] as String?;
      if (iconName != null && colorString != null) {
        final iconColor = Styles().colors.getColor(colorString);
        return _buildIconContainer(iconName, iconColor!);
      }
    }
    // Fallback to default icons map
    final fallback = stepIcons[stepKey];
    if (fallback != null) {
      final iconName = fallback['image'] as String;
      final colorString = fallback['color'] as String;
      final iconColor = Styles().colors.getColor(colorString);
      return _buildIconContainer(iconName, iconColor!);
    }
    return null;
  }

  Widget _buildIconContainer(String imageName, Color bgColor) {
    return Container(width: 67, height: 67, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle,), child:
      Center(child:
        Styles().images.getImage(imageName, excludeFromSemantics: true, size: 36, fit: BoxFit.contain, color: Colors.white) ?? Container()
      ),
    );
  }

  Future<void> _selectOption(String title) async {
    if (_currentStep != null) {
      setState(() {_loading = true;});
      _currentStep!.response = title;
      Analytics().logSelect(target: 'selected {$title}');
      await Surveys().evaluate(_survey);
      if (mounted) {
        final next = Surveys().getFollowUp(_survey, _currentStep!);
        if (next != null) {
          setState(() {
            _currentStep = next;
            _stepHistory.add(next.key);
            _loading = false;
          });
        } else {
          await _showResults();
        }
      }
    }
  }

  Future<void> _showResults() async {
    dynamic results = await Surveys().evaluate(
      _survey,
      evalResultRules: true,
      summarizeResultRules: false,
      returnMultiple: true,
    );
    if (mounted) {
      setState(() {
        _loading = false;
      });

      SurveyStats? stats = _survey.stats;
      final lastStepKey = _stepHistory.last;
      final String? resp = stats?.responseData[lastStepKey] as String?;
      final String lookupKey = resp ?? (stats?.responseData['next'] as String? ?? '');
      final Map<String, dynamic>? entryMap = (_survey.data['gbv_resource_map'] as SurveyData).extras?[lookupKey] as Map<String, dynamic>?;

      List<String> resourceIds = results.map<String>((r) => r.key as String).toList();
      if (entryMap != null) {
        entryMap['resource_ids'] = resourceIds;
      }

      if (entryMap == null) {
        _onFileReport(widget.gbvData);
      }
      else if (entryMap['skip_to_report'] == true) {
        _onFileReport(widget.gbvData);
      }
      else {
        _presentResourceList(entryMap);
      }
    }
  }

  void _handleBack() {
    if (_stepHistory.length > 1) {
      _stepHistory.removeLast();
      final previousKey = _stepHistory.last;
      if (mounted) {
        setState(() {
          _currentStep = _survey.data[previousKey];
          _currentStep?.response = null;
          _loading = false;
        });
      }
      Surveys().evaluate(_survey).then((_) {
        if (mounted) {
          setState(() {});
        }});
    } else {
      Navigator.pop(context);}
  }

  Widget _buildOption(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],),
      child: InkWell(onTap: () => _selectOption(title), borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text(title, style: Styles().textStyles.getTextStyle('widget.title.regular'),),),
              Styles().images.getImage('chevron-right', excludeFromSemantics: true, size: 18, color: Styles().colors.fillColorPrimary) ?? Container(),
            ],
          ),
        ),
      ),
    );
  }

  void _onFileReport(GBVData gbvContent) {
    Analytics().logSelect(target: 'File a report');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDetailPanel(resource: gbvContent.resources.firstWhere((r) => r.id == 'filing_a_report'))));
  }

  void _presentResourceList(Map<String, dynamic> entryMap) {
    // Otherwise group resources by category as before
    final List resourceIds = (entryMap['resource_ids'] as List).cast();
    final availableIds = widget.gbvData.resources.map((r) => r.id).toSet();
    final validIds = resourceIds.where(availableIds.contains).toList();

    final Map<String, List<String>> categoryToIds = {};
    final idsToProcess = validIds.isNotEmpty ? validIds : availableIds.take(3).toList();
    for (final id in idsToProcess) {
      final resource = widget.gbvData.resources.firstWhere((r) => r.id == id);
      final String category = resource.categories.first;
      categoryToIds.putIfAbsent(category, () => []).add(id);
    }
    final content = categoryToIds.entries.map((e) => GBVResourceList(title: e.key, resourceIds: e.value)).toList();

    final screen = GBVResourceListScreen(type: 'panel',
      title: _resourceListTitle,
      description: _resourceListDescription,
      content: content,
    );

    Navigator.push(context, CupertinoPageRoute( builder: (ctx) => GBVResourceListPanel(
      gbvData: widget.gbvData,
      resourceListScreen: screen,
      showDirectoryLink: true,
    ),),);
  }

  String get _resourceListTitle =>
    Localization().getStringEx('panel.sexual_misconduct.survey_result.title', 'Your Top Resources');

  String get _resourceListDescription => Localization().getStringEx(
    'panel.sexual_misconduct.survey_result.description',
    'Based on what you shared, here are some options that may help. '
      'You’re in control of what happens next—take your time and explore what feels right. '
      'You’re not alone, and support is available if you need it.'
  );

  Widget get _errorContent => Center(child:
    Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child:
      Text(Localization().getStringEx('panel.sexual_misconduct.survey_result.error', 'Failed to load survey.'),
        textAlign: TextAlign.center,
        style: Styles().textStyles.getTextStyle("widget.message.medium.thin"),
      ),
    ),
  );

  Widget get _loadingContent => Column(children: [
    const Expanded(flex: 1, child: SizedBox()),
    SizedBox(width: 32, height: 32, child:
      CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
    ),
    const Expanded(flex: 2, child: SizedBox())],
  );
}