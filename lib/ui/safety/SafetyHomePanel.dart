
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/Guide.dart';
import 'package:neom/ui/guide/GuideDetailPanel.dart';
import 'package:neom/ui/guide/GuideListPanel.dart';
import 'package:neom/ui/safety/SafetySafeWalkRequestPage.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum SafetyContentType { safeWalkRequest, safeRides, safetyResources }

class SafetyHomePanel extends StatefulWidget {
  final SafetyContentType? contentType;
  final Map<String, dynamic>? safeWalkRequestOrigin;
  final Map<String, dynamic>? safeWalkRequestDestination;

  SafetyHomePanel({ super.key, this.contentType, this.safeWalkRequestOrigin, this. safeWalkRequestDestination});

  @override
  State<StatefulWidget> createState() => _SafetyHomePanelState();

}

class _SafetyHomePanelState extends State<SafetyHomePanel>  {
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
    Column(children: <Widget>[
      Container(
        color: _bodyColor,
        padding: EdgeInsets.only(left: 16, top: 16, right: 16),
        child: Semantics(
          hint:  Localization().getStringEx("dropdown.hint", "DropDown"),
          container: true,
          child: RibbonButton(
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
            backgroundColor: Styles().colors.white,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
            rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
            label: _safetyContentTypeToDisplayString(_selectedContentType) ?? '',
            onTap: _onTapContentSwitch
          ),
        ),
      ),
      Expanded(child:
        Stack(children: [
          SingleChildScrollView(child:
            Padding(padding: EdgeInsets.only(bottom: 16), child:
              _contentPage
            ),
          ),
          _dropdownContainer
        ]),
      )
    ]);

  Color? get _bodyColor =>
    (_contentPage is SafetyHomeContentPage) ? (_contentPage as SafetyHomeContentPage).safetyPageBackgroundColor : Styles().colors.background;

  Widget? get _contentPage {
    if (_selectedContentType == SafetyContentType.safeWalkRequest) {
      return SafetySafeWalkRequestPage(origin: widget.safeWalkRequestOrigin, destination: widget.safeWalkRequestDestination,);
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
          label: _safetyContentTypeToDisplayString(contentType),
          onTap: () => _onTapDropdownItem(contentType)
        ));
      }
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: contentList)
      )
    );
  }

  void _onTapDropdownItem(SafetyContentType contentType) {
    Analytics().logSelect(target: _safetyContentTypeToDisplayString(contentType), source: widget.runtimeType.toString());
    if (_preprocessContentType(contentType)) {
      setState(() {
        _contentValuesVisible = false;
      });
    }
    else {
      setState(() {
        _selectedContentType = contentType;
        _contentValuesVisible = false;
      });
      Analytics().logPageWidget(_contentPage);
    }
  }

  bool _preprocessContentType(SafetyContentType contentType) {
    if (contentType == SafetyContentType.safeRides) {
      Map<String, dynamic>? safeRidesGuideEntry = Guide().entryById(Config().safeRidesGuideId);
      if (safeRidesGuideEntry != null) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntry: safeRidesGuideEntry)));
      }
      return true;
    }
    else if (contentType == SafetyContentType.safetyResources) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
        contentList: Guide().safetyResourcesList,
        contentTitle: Localization().getStringEx('panel.guide_list.label.campus_safety_resources.section', 'Safety Resources'),
        contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.campus_safety_resources.empty", "There are no active Campus Safety Resources."),
        favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusSafetyResourceContentType),
      )));
      return true;
    }
    else {
      return false;
    }
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

String? _safetyContentTypeToDisplayString(SafetyContentType? contentType) {
  switch (contentType) {
    case SafetyContentType.safeWalkRequest: return Localization().getStringEx('panel.safety.content_type.safe_walk_request.label', 'Request a SafeWalk');
    case SafetyContentType.safeRides: return Localization().getStringEx('panel.safety.content_type.safe_rides.label', 'SafeRides (MTD)');
    case SafetyContentType.safetyResources: return Localization().getStringEx('panel.safety.content_type.safety_resources.label', 'Safety Resources');
    default: return null;
  }
}

class SafetyHomeContentPage {
  Color get safetyPageBackgroundColor => Styles().colors.background;
}