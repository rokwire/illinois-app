import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/gbv/GBVResourceListPanel.dart';
import 'package:illinois/ui/gbv/GBVResourceDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:illinois/ui/gbv/GBVQuickExitWidget.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:illinois/ui/gbv/GBVSituationStepPanel.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/model/survey.dart';

import '../../model/GBV.dart';
import 'GBVResourceDirectoryPanel.dart';

class GBVPathwaysPanel extends StatefulWidget {

  GBVPathwaysPanel({ super.key });

  @override
  State<StatefulWidget> createState() => _GBVPathwaysPanelState();

}

class _GBVPathwaysPanelState extends State<GBVPathwaysPanel> {
  GBVData? _gbv;
  bool _loading = true;
  GestureRecognizer? _resourceDirectoryRecognizer;

  @override
  void initState() {

    _loadResources().then((gbv) {
      if (mounted) {
        setState(() {
          _gbv = gbv;
          _loading = false;
        });

        if (_gbv != null) {
          _resourceDirectoryRecognizer = TapGestureRecognizer()..onTap = () => _onResourceDirectory(context, _gbv!);
          if (Storage().gbvQuickExitPrompted != true) _onQuickExitInfo(context);
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _resourceDirectoryRecognizer?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.sexual_misconduct.header.title', 'Inappropriate Sexual Behavior')),
      body: (_loading) ? _buildLoadingContent() : (_gbv != null && _gbv!.resources.isNotEmpty) ? _buildContent(context, _gbv!) : _buildErrorContent(),
      bottomNavigationBar: uiuc.TabBar(),
      backgroundColor: Styles().colors.background
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

  Widget _buildErrorContent() {
    return Center(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('', 'Failed to load resources.'),
            textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildContent(BuildContext context, GBVData gbvContent) {
    return SingleChildScrollView(scrollDirection: Axis.vertical, child:
      SectionSlantHeader(
        headerWidget: _buildHeader(context, gbvContent),
        slantColor: Styles().colors.gradientColorPrimary,
        slantPainterHeadingHeight: 0,
        backgroundColor: Styles().colors.background,
        children: [
          _buildLinkDetail('Browsing History Settings')
        ],
        childrenPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 38),
        allowOverlap: false,
      )
    );
  }

  Widget _buildHeader(BuildContext context, GBVData gbvContent) {
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
          RichText(text: TextSpan(children: [
            TextSpan(
              text: Localization().getStringEx('', 'Choose one of the below pathways or '),
              style: Styles().textStyles.getTextStyle('widget.description.regular.highlight')
            ),
            TextSpan(
                text: Localization().getStringEx('', 'view a list of resources.'),
                style: Styles().textStyles.getTextStyle('widget.description.regular.highlight.underline'),
                recognizer: _resourceDirectoryRecognizer,
            )
          ]))
        ),
        if (gbvContent.resourceListScreens?.confidentialResources != null) _buildPathwayButton(context, 'Talk to someone confidentially', () => _onTalkToSomeone(context, gbvContent)),
        if (gbvContent.resources.any((resource) => resource.id == 'filing_a_report')) _buildPathwayButton(context, 'File a report', () => _onFileReport(context, gbvContent)),
        if (gbvContent.resourceListScreens?.supportingAFriend != null) _buildPathwayButton(context, 'Support a friend', () => _onSupportFriend(context, gbvContent)),
        //Do a conditional variable check to make sure the survey came back or failed and add a flag check to _buildPathwayButton
        if (gbvContent.resources.isNotEmpty) _buildPathwayButton(context, "I'm not sure yet", () => _onNotSure(context, gbvContent)),
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
          GBVQuickExitWidget().quickExitButton(context)
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

  void _onQuickExitInfo(BuildContext context) {
    showDialog(context: context, builder: (_) => InfoPopup(
      backColor: Styles().colors.surface,
      padding: EdgeInsets.only(left: 32, right: 32, top: 40, bottom: 32),
      alignment: Alignment.center,
      infoTextWidget: Column(children: [
        GBVQuickExitIcon(),
        Padding(padding: EdgeInsets.symmetric(vertical: 8)),
        Text(Localization().getStringEx('', 'Use the quick exit icon at any time to be routed to the Illinois app home screen.'),
          style: Styles().textStyles.getTextStyle('widget.description.regular'), textAlign: TextAlign.left,
        )
      ]
      ),
      closeIcon: Styles().images.getImage('close-circle', excludeFromSemantics: true),
    ),).then((_) => {
      if (Storage().gbvQuickExitPrompted != true) Storage().gbvQuickExitPrompted = true
    });
  }

  void _onResourceDirectory(BuildContext context, GBVData gbvContent) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDirectoryPanel(gbvData: gbvContent)));
  }

  void _onTalkToSomeone(BuildContext context, GBVData gbvContent) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceListPanel(resourceListScreen: _gbv!.resourceListScreens!.confidentialResources!, gbvData: gbvContent)));
  }
  void _onFileReport(BuildContext context, GBVData gbvContent) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDetailPanel(resource: gbvContent.resources.firstWhere((r) => r.id == 'filing_a_report'))));
  }
  void _onSupportFriend(BuildContext context, GBVData gbvContent) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceListPanel(resourceListScreen: gbvContent.resourceListScreens!.supportingAFriend!, gbvData: gbvContent)));
    // Navigate to Supporting a Friend Resources
  }
  void _onNotSure(BuildContext context, GBVData gbvContent) async {
    Survey? survey = await Surveys().loadSurvey("cabb1338-48df-4299-8c2a-563e021f82ca");
    if (survey != null) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => GBVSituationStepPanel(
            survey: survey,
            gbvData: gbvContent,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to load the survey.")),
      );
    }
  }

  Future<GBVData?> _loadResources() async {
    // temporary json load from assets
    String? GBVjson = await AppBundle.loadString('assets/extra/gbv/gbv.json');
    GBVData? gbv = (GBVjson != null)
        ? GBVData.fromJson(JsonUtils.decodeMap(GBVjson))
        : null;
    await Future.delayed(Duration(seconds: 1));
    return gbv;
  }

  Widget _buildLinkDetail(String? text) =>
      Semantics(label: text, button: true, child:
        InkWell(onTap: _onTapDisplaySettings, child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: EdgeInsets.only(right: 5, top: 12, bottom: 12), child:
              Styles().images.getImage('settings', excludeFromSemantics: true)),
            Expanded(child:
              Padding(padding: EdgeInsets.only(top: 8), child:
                Text(text ?? '', style: Styles().textStyles.getTextStyle('widget.button.title.medium.underline'), semanticsLabel: "",)
              )
            )
          ])
        ),
      );

  void _onTapDisplaySettings() {
    SettingsHomePanel.present(context, content: SettingsContentType.recent_items);
  }

}
