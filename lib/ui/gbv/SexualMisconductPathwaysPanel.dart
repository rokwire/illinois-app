import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/SurveyTracker.dart';
import 'package:illinois/ui/gbv/GBVResourceListPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:illinois/ui/gbv/SituationStepPanel.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:illinois/ui/gbv/QuickExitWidget.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import '../../model/GBV.dart';

class SexualMisconductPathwaysPanel extends StatefulWidget {

  SexualMisconductPathwaysPanel({ super.key });

  @override
  State<StatefulWidget> createState() => _SexualMisconductPathwaysPanelState();

}

class _SexualMisconductPathwaysPanelState extends State<SexualMisconductPathwaysPanel> {
  List<GBVResource> _resources = [];
  bool _loading = true;

  @override
  void initState() {
    _loadResources().then((resources) {
      setStateIfMounted(() {
        _loading = false;
        _resources = resources;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.sexual_misconduct.header.title', 'Inappropriate Sexual Behavior')),
      body: (_loading) ? _buildLoadingContent() : _buildContent(context),
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildLoadingContent() {
    return Column(children: <Widget>[
      Expanded(flex: 1, child: Container()),
      SizedBox(width: 32, height: 32, child:
      CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
      ),
      Expanded(flex: 2, child: Container()),
    ]);
  }

  Widget _buildContent(BuildContext context) {
    return SectionSlantHeader(
      headerWidget: _buildHeader(context),
      slantColor: Styles().colors.gradientColorPrimary,
      slantPainterHeadingHeight: 0,
      backgroundColor: Styles().colors.background,
      children: [
      ],
      childrenPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      allowOverlap: false,
    );
  }

  Widget _buildHeader(BuildContext context) {
    Widget content;
    content = Padding(padding: EdgeInsets.symmetric(horizontal: 12), child:
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Localization().getStringEx('', 'A Path Forward'),
          style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.get_started.header'), textAlign: TextAlign.left,
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        Text(Localization().getStringEx('', 'If you think you or a friend has experienced inappropriate sexual behavior or an unhealthy relationship, help is available.'),
          style: Styles().textStyles.getTextStyle('widget.description.regular.highlight'), textAlign: TextAlign.left,
        )
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        Text(Localization().getStringEx('', 'Choose one of the below pathways or view a list of resources.'),
          style: Styles().textStyles.getTextStyle('widget.description.regular.highlight'), textAlign: TextAlign.left,
        )
        ),
        _buildPathwayButton(context, 'Talk to someone confidentially', () => _onTalkToSomeone(context)),
        _buildPathwayButton(context, 'File a report', () => _onFileReport(context)),
        _buildPathwayButton(context, 'Support a friend', () => _onSupportFriend(context)),
        _buildPathwayButton(context, "I'm not sure yet", () => _onNotSure(context)),
        Padding(padding: EdgeInsets.symmetric(vertical: 8)),
        _buildQuickExit(context),
        // ),

      ])
    );
    return Container(
      padding: EdgeInsets.only(top: 8, bottom: 32),
      child: Padding(padding: EdgeInsets.only(left: 24, right: 8), child: content,),
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Styles().colors.fillColorPrimaryVariant,
                Styles().colors.gradientColorPrimary,
              ]
          )
      ),
    );
  }

  Widget _buildQuickExit(BuildContext context) {
    return Container(child:
      Row(crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(padding: EdgeInsets.only(right: 8), child:
            GestureDetector(onTap: () => _onQuickExitInfo(context), child:
              Styles().images.getImage('info', excludeFromSemantics: true) ?? Container(),
            )
          ),
          Expanded(child:
            RichText(text:
              TextSpan(children: [
                TextSpan(text: Localization().getStringEx('', 'Privacy: '),
                  style: Styles().textStyles.getTextStyle('widget.item.small.fat.highlight')),
                TextSpan(text: Localization().getStringEx('', 'your app activity is not shared with others. Use the quick exit icon to return Home.'),
                style: Styles().textStyles.getTextStyle('widget.item.small.thin.highlight')),
              ])
            )
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 8)),
          Container(height: 50, width: 50, decoration: BoxDecoration(
              color: Styles().colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                ),
              ]), child:
            GestureDetector(onTap: () => _onQuickExit(context), child:
              Styles().images.getImage('person-to-door', excludeFromSemantics: true, width: 25) ?? Container()
            )
          )
        ],
      )
    );
  }

  Widget _buildPathwayButton(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: RoundedButton(
        label: label,
        textStyle: Styles().textStyles.getTextStyle('widget.title.regular.fat'),
        onTap: onTap,
        backgroundColor: Styles().colors.white,
      ),
    );
  }


  void _onQuickExit(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
  
  void _onQuickExitInfo(BuildContext context) {
    showDialog(context: context, builder: (_) => InfoPopup(
      backColor: Styles().colors.surface,
      padding: EdgeInsets.only(left: 32, right: 32, top: 40, bottom: 32),
      alignment: Alignment.center,
      infoTextWidget: Column(children: [
        Container(height: 50, width: 50, decoration: BoxDecoration(
            color: Styles().colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
              ),
            ]), child:
          Styles().images.getImage('person-to-door', excludeFromSemantics: true, width: 25) ?? Container()
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 8)),
        Text(Localization().getStringEx('', 'Use the quick exit icon at any time to be routed to the Illinois app home screen.'),
          style: Styles().textStyles.getTextStyle('widget.description.regular'), textAlign: TextAlign.left,
        )
      ]
      ),
      closeIcon: Styles().images.getImage('close-circle', excludeFromSemantics: true),
    ),);
  }
  
  void _onTalkToSomeone(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceListPanel(id: 'confidential_resources', resources: _resources)));
  }
  void _onFileReport(BuildContext context) {
    // Navigate to Filing a Report flow
  }
  void _onSupportFriend(BuildContext context) {
    // Navigate to Supporting a Friend Resources
  }
  void _onNotSure(BuildContext context) async {
    Survey? survey = await Surveys().loadSurvey("cabb1338-48df-4299-8c2a-563e021f82ca");

    if (survey != null) {
      final SurveyTracker responseTracker = SurveyTracker();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SituationStepPanel(
            stepKey: 'situation',     
            responseTracker: responseTracker,
            surveyData: survey.data,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to load the survey.")),
      );
    }
  }

  Future<List<GBVResource>> _loadResources() async {
    // temporary json load from assets
    String? GBVjson = await AppBundle.loadString('assets/extra/gbv/gbv.json');
    GBV? gbv = (GBVjson != null)
        ? GBV.fromJson(JsonUtils.decodeMap(GBVjson))
        : null;
    List<GBVResource> allResources = (gbv != null) ? gbv.resources : [];
    await Future.delayed(Duration(seconds: 1));
    return allResources;
  }

}
