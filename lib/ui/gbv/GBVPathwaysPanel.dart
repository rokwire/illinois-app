import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/gbv/GBVResourceListPanel.dart';
import 'package:illinois/ui/gbv/GBVResourceDetailPanel.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
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
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/service/Config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:illinois/service/Analytics.dart';


class GBVPathwaysPanel extends StatefulWidget {

  GBVPathwaysPanel({ super.key });

  @override
  State<StatefulWidget> createState() => _GBVPathwaysPanelState();

}

class _GBVPathwaysPanelState extends State<GBVPathwaysPanel> {
  GBVData? _gbv;
  bool _loadingGbv = true;
  GestureRecognizer? _resourceDirectoryRecognizer;

  Survey? _survey;
  bool _loadingSurvey = false;

  @override
  void initState() {
    _loadResources().then((gbv) {
      if (mounted) {
        setState(() {
          _gbv = gbv;
          _loadingGbv = false;
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
      body: (_loadingGbv) ? _buildLoadingContent() : (_gbv != null && _gbv!.resources.isNotEmpty) ? _buildContent(context, _gbv!) : _buildErrorContent(),
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
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.sexual_misconduct.error', 'Failed to load resources.'),
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
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child:
          Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Text(Localization().getStringEx('panel.sexual_misconduct.title', 'A Path Forward'), style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.get_started.header'),)
          ),
          ),
          InkWell(onTap: () => _onTapOptions(context), child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child:
          Styles().images.getImage('more-white', excludeFromSemantics: true)
          )
          )
        ],),
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        Text(Localization().getStringEx('panel.sexual_misconduct.description', 'If you think you or a friend has experienced inappropriate sexual behavior or an unhealthy relationship, help is available.'),
          style: Styles().textStyles.getTextStyle('widget.description.regular.highlight'), textAlign: TextAlign.left,
        )
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          RichText(text: TextSpan(children: [
            TextSpan(
              text: Localization().getStringEx('panel.sexual_misconduct.choose_pathways', 'Choose one of the below pathways or '),
              style: Styles().textStyles.getTextStyle('widget.description.regular.highlight')
            ),
            TextSpan(
                text: Localization().getStringEx('panel.sexual_misconduct.view_resources', 'view a list of resources.'),
                style: Styles().textStyles.getTextStyle('widget.description.regular.highlight.underline'),
                recognizer: _resourceDirectoryRecognizer,
            )
          ]))
        ),
        if (gbvContent.resourceListScreens?.confidentialResources != null) _buildPathwayButton(context, label: 'Talk to someone confidentially', onTap: () => _onTalkToSomeone(context, gbvContent)),
        if (gbvContent.resources.any((resource) => resource.id == 'filing_a_report')) _buildPathwayButton(context, label: 'File a report', onTap: () => _onFileReport(context, gbvContent)),
        if (gbvContent.resourceListScreens?.supportingAFriend != null) _buildPathwayButton(context, label: 'Support a friend', onTap: () => _onSupportFriend(context, gbvContent)),
        if (gbvContent.resources.isNotEmpty && (Config().gbvSurveyId?.isNotEmpty == true)) _buildPathwayButton(context, label: "I'm not sure yet", progress: _loadingSurvey, onTap: () => _onNotSure(context, gbvContent)),

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
                TextSpan(text: Localization().getStringEx('panel.sexual_misconduct.quick_exit.privacy', 'Privacy: '),
                  style: Styles().textStyles.getTextStyle('widget.item.small.fat.highlight')),
                TextSpan(text: Localization().getStringEx('panel.sexual_misconduct.quick_exit.app_activity', 'your personal app activity is not shared with others. Use the quick exit icon to return Home.'),
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

  Widget _buildPathwayButton(BuildContext context, {required String label, VoidCallback? onTap, bool progress = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: RoundedButton(
        label: label,
        textStyle: Styles().textStyles.getTextStyle('widget.title.regular.fat'),
        onTap: onTap,
        backgroundColor: Styles().colors.white,
        progress: progress,
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
        Text(Localization().getStringEx('widget.sexual_misconduct.quick_exit.dialog.description', 'Use the quick exit icon at any time to be routed to the Illinois app home screen.'),
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
    Analytics().logSelect(target: 'Resource Directory');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDirectoryPanel(gbvData: gbvContent)));
  }

  void _onTalkToSomeone(BuildContext context, GBVData gbvContent) {
    Analytics().logSelect(target: 'Talk to someone confidentially');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceListPanel(resourceListScreen: _gbv!.resourceListScreens!.confidentialResources!, gbvData: gbvContent)));
  }
  void _onFileReport(BuildContext context, GBVData gbvContent) {
    Analytics().logSelect(target: 'File a report');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDetailPanel(resource: gbvContent.resources.firstWhere((r) => r.id == 'filing_a_report'))));
  }
  void _onSupportFriend(BuildContext context, GBVData gbvContent) {
    Analytics().logSelect(target: 'Support a friend');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceListPanel(resourceListScreen: gbvContent.resourceListScreens!.supportingAFriend!, gbvData: gbvContent)));
    // Navigate to Supporting a Friend Resources
  }
  void _onNotSure(BuildContext context, GBVData gbvContent) {
    Analytics().logSelect(target: 'I\'m not sure yet');
    String? gbvSurveyId = Config().gbvSurveyId;
    if (_survey != null) {
      _navigateToSituationStep(_survey!, gbvContent);
    }
    else if ((gbvSurveyId != null) && (_loadingSurvey == false)) {
      setState(() {
        _loadingSurvey = true;
      });
      Surveys().loadSurvey(gbvSurveyId).then((Survey? survey){
        if (mounted) {
          setState(() {
            _loadingSurvey = false;
            _survey = survey;
          });

          if (survey != null) {
            _navigateToSituationStep(survey, gbvContent);
          }
          else {
            AppAlert.showDialogResult(context, Localization().getStringEx('panel.sexual_misconduct.error', 'Failed to load resources.'));
          }
        }
      });
    }
  }

  void _navigateToSituationStep(Survey survey, GBVData gbvContent) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVSituationStepPanel(survey: survey, gbvData: gbvContent)));
  }


  Future<GBVData?> _loadResources() async {
    String? contentCategory = Config().gbvContentCategory;
    dynamic contentItem = (contentCategory != null) ? await Content().loadContentItem(contentCategory) : null;
    return GBVData.fromJson(JsonUtils.mapValue(contentItem));
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

  void _onTapOptions(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16 + bottomPadding), child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        RibbonButton(title: Localization().getStringEx('panel.sexual_misconduct.options.we_care', 'We Care at Illinois website'), rightIconKey: 'external-link', onTap: () => _onTapWeCare(context)),
        RibbonButton(title: Localization().getStringEx('panel.sexual_misconduct.options.resource_directory', 'Resource Directory'), onTap: () => _onResourceDirectory(context, _gbv!))
      ])
      ),
    );
  }

  void _onTapWeCare(BuildContext context) {
    Navigator.pop(context);
    String? weCareUrl = Config().gbvWeCareUrl;
    Uri? weCareUri = (weCareUrl != null) ? Uri.tryParse(weCareUrl) : null;
    if (weCareUri != null) {
      launchUrl(weCareUri);
    }

  }

}
