import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:illinois/ui/safety/SafetySafeWalkRequestPage.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum SafetyContentType { safeWalkRequest, safeRides, safetyResources }

class ConfidentialResourcesPanel extends StatefulWidget {
  final SafetyContentType? contentType;
  final Map<String, dynamic>? safeWalkRequestOrigin;
  final Map<String, dynamic>? safeWalkRequestDestination;

  ConfidentialResourcesPanel({ super.key, this.contentType, this.safeWalkRequestOrigin, this. safeWalkRequestDestination});

  @override
  State<StatefulWidget> createState() => _ConfidentialResourcesPanelState();

}

class _ConfidentialResourcesPanelState extends State<ConfidentialResourcesPanel>  {
  SafetyContentType? _selectedContentType;
  bool _contentValuesVisible = false;

  @override
  void initState() {
    _selectedContentType = widget.contentType ?? SafetyContentType.values.first;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx('panel.safety.header.title', 'Safety')),
        body: _bodyWidget,
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: uiuc.TabBar(),
      );

  Widget get _bodyWidget =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.only(top: 32, left: 16), child:(
          Text(Localization().getStringEx('', 'Confidential Resources'), style: Styles().textStyles.getTextStyle("widget.button.title.large.fat"))
        )),
        Padding(padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16,), child:
          Container(height: 1, color: Styles().colors.surfaceAccent,),
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:(
            Text(Localization().getStringEx('', 'A confidential resource is an individual who is not required to disclose reports of sexual misconduct to the university or law enforcement.'), style: Styles().textStyles.getTextStyle("widget.detail.regular"))
        )),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:(
            Text(Localization().getStringEx('', 'ON CAMPUS'), style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"))
        )),
        Expanded(child:
        Stack(children: [
          SingleChildScrollView(child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
          ResourceBox(_contentPage)
          ),
          ),
          _dropdownContainer
        ]),
        )
      ]);

  Widget? ResourceBox (Widget? child) {
    Decoration _cardDecoration =
        BoxDecoration(
          color: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(color: Styles().colors.blackTransparent018,
                spreadRadius: 1.0,
                blurRadius: 3.0,
                offset: Offset(1, 1))
          ],
        );
    return Container(decoration: _cardDecoration, child: child);
  }

  Color? get _bodyColor =>
      Styles().colors.background;

  Widget? get _contentPage {
    if (_selectedContentType == SafetyContentType.safeWalkRequest) {
      // return SafetySafeWalkRequestPage(origin: widget.safeWalkRequestOrigin, destination: widget.safeWalkRequestDestination,);
      // return Text(Localization().getStringEx('panel.profile.info.directory_visibility.command.toggle.title', 'Directory Visibility'));
      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child:
          Padding(padding: EdgeInsets.only(left: 16, top: 12), child:
            Text(Localization().getStringEx('', 'Confidential Advisors at WRC'), style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"))
          ),
          ),
          Styles().images.getImage('chevron-right') ?? Container()
        ],),
        Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16), child:
          Text(Localization().getStringEx('', 'Available to students and employees of ALL genders'), style: Styles().textStyles.getTextStyle("widget.detail.regular"),)
        )
      ]);
    }
    else {
      return null;
    }
  }

  Widget get _dropdownContainer => Visibility(visible: _contentValuesVisible, child:
  Container(child:
  Stack(children: <Widget>[
    _dropdownDismissLayer,
    _dropdownList,
  ])
  )
  );

  Widget get _dropdownDismissLayer => Container(child:
  BlockSemantics(child:
  GestureDetector(onTap: _onTapDismissLayer, child:
  Container(color: Styles().colors.blackTransparent06, height: MediaQuery.of(context).size.height)
  )
  )
  );

  Widget get _dropdownList {
    List<Widget> contentList = <Widget>[];
    contentList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (SafetyContentType contentType in SafetyContentType.values) {
      if (_selectedContentType != contentType) {
        contentList.add(RibbonButton(
            backgroundColor: Styles().colors.white,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
            rightIconKey: null,
            label: '',
            onTap: () => {}
        ));
      }
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 24), child:
    SingleChildScrollView(child:
    Column(children: contentList)
    )
    );
  }

  void _onTapContentSwitch() {
    setState(() {
      _contentValuesVisible = !_contentValuesVisible;
    });
  }

  void _onTapDismissLayer() {
    setState(() {
      _contentValuesVisible = false;
    });
  }
}

