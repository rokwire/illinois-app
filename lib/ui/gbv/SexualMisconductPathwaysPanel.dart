import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/gbv/GBVResourceListPanel.dart';
import 'package:illinois/ui/gbv/ResourceDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:illinois/ui/gbv/QuickExitWidget.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import '../../model/GBV.dart';
import 'ResourceDirectoryPanel.dart';

class SexualMisconductPathwaysPanel extends StatefulWidget {

  SexualMisconductPathwaysPanel({ super.key });

  @override
  State<StatefulWidget> createState() => _SexualMisconductPathwaysPanelState();

}

class _SexualMisconductPathwaysPanelState extends State<SexualMisconductPathwaysPanel> {
  List<String> _categories = [];
  List<GBVResource> _resources = [];
  GBVResourceListScreens? _resourceListScreens;
  bool _loading = true;
  GestureRecognizer? _resourceDirectoryRecognizer;

  @override
  void initState() {
    _resourceDirectoryRecognizer = TapGestureRecognizer()..onTap = () => _onResourceDirectory(context);

    _loadResources().then((gbv) {
      setStateIfMounted(() {
        _loading = false;
        _resources = gbv?.resources ?? [];
        _categories = gbv?.directoryCategories ?? [];
        _resourceListScreens = gbv?.resourceListScreens;
      });
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
    return SingleChildScrollView(scrollDirection: Axis.vertical, child:
      SectionSlantHeader(
        headerWidget: _buildHeader(context),
        slantColor: Styles().colors.gradientColorPrimary,
        slantPainterHeadingHeight: 0,
        backgroundColor: Styles().colors.background,
        children: [
        ],
        childrenPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        allowOverlap: false,
      )
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
        Visibility(visible: (_resourceListScreens?.confidentialResources != null), child:
          _buildPathwayButton(context, 'Talk to someone confidentially', () => _onTalkToSomeone(context)),
        ),
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
          QuickExitWidget().quickExitButton(context)
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
    ),);
  }

  void _onResourceDirectory(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResourceDirectoryPanel(categories: _categories, resources: _resources)));
  }

  void _onTalkToSomeone(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceListPanel(resourceListScreen: _resourceListScreens!.confidentialResources!, resources: _resources, categories: _categories)));
  }
  void _onFileReport(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResourceDetailPanel(resource: _resources.firstWhere((r) => r.id == 'filing_a_report'))));
  }
  void _onSupportFriend(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceListPanel(resourceListScreen: _resourceListScreens!.supportingAFriend!, resources: _resources, categories: _categories)));
    // Navigate to Supporting a Friend Resources
  }
  void _onNotSure(BuildContext context) async {
  }

  Future<GBV?> _loadResources() async {
    // temporary json load from assets
    String? GBVjson = await AppBundle.loadString('assets/extra/gbv/gbv.json');
    GBV? gbv = (GBVjson != null)
        ? GBV.fromJson(JsonUtils.decodeMap(GBVjson))
        : null;
    await Future.delayed(Duration(seconds: 1));
    return gbv;
  }

}
