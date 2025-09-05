import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/model/options.dart';
import 'package:illinois/ui/gbv/GBVQuickExitWidget.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/gbv/GBVResourceDetailPanel.dart';
import 'package:illinois/ui/gbv/GBVResourceListPanel.dart';
import '../../model/GBV.dart';

const Map<String, Map<String, dynamic>> stepIcons = {
  'situation':      {'image':'compass',     'color':Color(0xFF9318BB)},
  'whats_happening':{'image':'ban',         'color':Color(0xFFF09842)},
  'involved':       {'image':'user',        'color':Color(0xFF5182CF)},
  'next':           {'image':'signs-post',  'color':Color(0xFF5FA7A3)},
  'prioritize':     {'image':'timeline',    'color':Color(0xFF9318BB)},
};

class SituationStepPanel extends StatefulWidget {
  final Survey survey;
  final GBVData gbvData;

  const SituationStepPanel({
    Key? key,
    required this.survey,
    required this.gbvData,
  }) : super(key: key);

  @override
  _SituationStepPanelState createState() => _SituationStepPanelState();
}

class _SituationStepPanelState extends State<SituationStepPanel> {
  late Survey _survey;
  SurveyData? _currentStep;
  bool _loading = false;
  bool _navigated = false;
  final List<String> _stepHistory = [];

  @override
  void initState() {
    super.initState();
    _survey = Survey.fromOther(widget.survey);
    _currentStep = Surveys().getFirstQuestion(_survey);
    if (_currentStep != null) _stepHistory.add(_currentStep!.key);
  }

  Future<void> _selectOption(String title) async {
    if (_currentStep == null) return;
    setState(() => _loading = true);

    _currentStep!.response = title;
    await Surveys().evaluate(_survey);

    final next = Surveys().getFollowUp(_survey, _currentStep!);
    if (next != null && !_navigated) {
      setState(() {
        _currentStep = next;
        _stepHistory.add(next.key);
        _loading = false;
      });
    }
    else if (!_navigated) {
      await _showResults();
    }
  }

  Future<void> _showResults() async {
    // Evaluate with result rules
    final resultActions = await Surveys().evaluate(
      _survey,
      evalResultRules: true,
      summarizeResultRules: false,
    );

    // Debug: Print what the survey evaluate actually returned
    print('Survey evaluation result: $resultActions');

    List<String> resourceIds = [];

    if (resultActions is List) {
      resourceIds = resultActions
          .where((action) => action is String)
          .cast<String>()
          .toList();
    } else if (resultActions is String) {
      resourceIds = [resultActions];
    }

    // Fallback: if no results, use available resource IDs from gbvData
    if (resourceIds.isEmpty) {
      print('No resource IDs from survey, using available resources');
      resourceIds = widget.gbvData.resources
          .take(3) // Take first 3 resources as fallback
          .map((r) => r.id)
          .toList();
    }

    print('Using resource IDs: $resourceIds');

    // Verify these IDs exist in gbvData
    final availableIds = widget.gbvData.resources.map((r) => r.id).toSet();
    print('There are all these resource IDs available: ${availableIds}');

    final validIds = resourceIds.where((id) => availableIds.contains(id)).toList();

    print('Valid resource IDs found: $validIds');

    final content = <GBVResourceList>[
      GBVResourceList(
        title: 'On Campus', //make dynamic with Filing a Report flow
        resourceIds: validIds.isNotEmpty ? validIds : availableIds.take(3).toList(),
      )
    ];

    final screen = GBVResourceListScreen(
      type: 'panel',
      title: 'Your Top Resources',
      description: 'Based on what you shared, here are some options that may help. '
          'You\'re in control of what happens next—take your time and explore what feels right. '
          'You\'re not alone, and support is available if you need it.',
      content: content,
    );

    if (!_navigated) {
      _navigated = true;
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (ctx) => GBVResourceListPanel(
            gbvData: widget.gbvData,
            resourceListScreen: screen,
          ),
        ),
      );
    }
    setState(() => _loading = false);
  }


  void _onTapResource(GBVResource res) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => GBVResourceDetailPanel(resource: res),
      ),
    );
  }

  void _goBack() {
    if (_stepHistory.length > 1) {
      _stepHistory.removeLast();
      final key = _stepHistory.last;
      setState(() {
        _currentStep = _survey.data[key];
        _currentStep?.response = null;
      });
    }
    else {
      Navigator.pop(context);
    }
  }

  Widget _buildOption(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical:6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color:Colors.black12, blurRadius:2)],
      ),
      child: InkWell(
        onTap: ()=>_selectOption(title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical:18,horizontal:18),
          child: Row(
            children:[
              Expanded(child:Text(title,style:TextStyle(fontSize:16.5,fontWeight:FontWeight.w500))),
              Icon(Icons.arrow_forward_ios, size:18, color:Color(0xFFED6647)),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildContent(BuildContext context) {
    if (_currentStep == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(color:Colors.white),
        ),
        body: Center(child:Text('No survey data')),
      );
    }

    final question = _currentStep!;
    final opts = (question is SurveyQuestionMultipleChoice) ? question.options : <OptionData>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon:Icon(Icons.arrow_back,color:Colors.white), onPressed:_goBack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            GBVQuickExitWidget(),
            if (question.moreInfo?.isNotEmpty==true)
              Container(
                margin: const EdgeInsets.only(top:12,bottom:24),
                padding: const EdgeInsets.all(18),
                decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14)),
                child:Text(question.moreInfo!,style:TextStyle(fontSize:14)),
              ),
            Text(question.text,style:TextStyle(fontSize:14)),
            SizedBox(height:12),
            LinearProgressIndicator(
              value: (_stepHistory.length)/5,
              backgroundColor:Colors.grey[300],
              valueColor:AlwaysStoppedAnimation(Color(0xFFED6647)),
            ),
            SizedBox(height:24),
            ...opts.map((o)=>_buildOption(o.title)),
            if (question.allowSkip)
              Align(
                alignment:Alignment.centerRight,
                child:TextButton(
                    onPressed:()=>_selectOption('__skipped__'),
                    child:Text('Skip this question')
                ),
              ),
            if (_loading)
              Center(child:Padding(
                padding: const EdgeInsets.only(top:24.0),
                child:CircularProgressIndicator(),
              )),
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
