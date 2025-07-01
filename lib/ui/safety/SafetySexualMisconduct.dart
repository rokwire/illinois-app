import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

/// Enum for the sexual misconduct support flows.
enum SexualMisconductFlow {
  talkToSomeone,
  fileReport,
  supportFriend,
  notSureYet,
}

class SafetySexualMisconductPanel extends StatefulWidget {
  final SexualMisconductFlow? initialFlow;

  SafetySexualMisconductPanel({Key? key, this.initialFlow}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SafetySexualMisconductPanelState();
}

class _SafetySexualMisconductPanelState extends State<SafetySexualMisconductPanel> {
  SexualMisconductFlow? _selectedFlow;
  bool _dropdownVisible = false;

  @override
  void initState() {
    _selectedFlow = widget.initialFlow ?? SexualMisconductFlow.values.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(
        title: Localization().getStringEx(
            'panel.safety_sexual_misconduct.header.title', 'Sexual Misconduct Support')),
    body: _bodyWidget,
    backgroundColor: Styles().colors.background,
    bottomNavigationBar: uiuc.TabBar(),
  );

  Widget get _bodyWidget => Column(
    children: <Widget>[
      Container(
        color: Styles().colors.background,
        padding: EdgeInsets.only(left: 24, top: 16, right: 24),
        child: Semantics(
          hint: Localization().getStringEx("dropdown.hint", "DropDown"),
          container: true,
          child: RibbonButton(
              textStyle: Styles()
                  .textStyles
                  .getTextStyle("widget.button.title.medium.fat.secondary"),
              backgroundColor: Styles().colors.white,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
              rightIconKey: (_dropdownVisible ? 'chevron-up' : 'chevron-down'),
              label: _flowToDisplayString(_selectedFlow) ?? '',
              onTap: _onTapContentSwitch),
        ),
      ),
      Expanded(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.only(bottom: 16), child: _contentPage),
            ),
            _dropdownContainer
          ],
        ),
      )
    ],
  );

  Widget get _contentPage {
    // We can expand this with actual pages for each flow.
    switch (_selectedFlow) {
      case SexualMisconductFlow.talkToSomeone:
        return _SimpleInfoPage(
            title: "Talk to Someone Confidentially",
            description:
            "Find confidential support and talk to someone who can help you process your experience.");
      case SexualMisconductFlow.fileReport:
        return _SimpleInfoPage(
            title: "File a Report",
            description:
            "Learn how to file a report about sexual misconduct or harassment.");
      case SexualMisconductFlow.supportFriend:
        return _SimpleInfoPage(
            title: "Support a Friend",
            description:
            "Get resources and tips on how to support a friend.");
      case SexualMisconductFlow.notSureYet:
        return _SimpleInfoPage(
            title: "I'm Not Sure Yet",
            description:
            "Explore your options and find guidance if you're unsure what to do next.");
      default:
        return Container();
    }
  }

  Widget get _dropdownContainer => Visibility(
    visible: _dropdownVisible,
    child: Container(
        child: Stack(
          children: <Widget>[
            _dropdownDismissLayer,
            _dropdownList,
          ],
        )),
  );

  Widget get _dropdownDismissLayer => Container(
    child: BlockSemantics(
        child: GestureDetector(
            onTap: _onTapDismissLayer,
            child: Container(
                color: Styles().colors.blackTransparent06,
                height: MediaQuery.of(context).size.height))),
  );

  Widget get _dropdownList {
    List<Widget> flowList = <Widget>[];
    flowList.add(
        Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (SexualMisconductFlow flow in SexualMisconductFlow.values) {
      if (_selectedFlow != flow) {
        flowList.add(RibbonButton(
            backgroundColor: Styles().colors.white,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
            rightIconKey: null,
            label: _flowToDisplayString(flow),
            onTap: () => _onTapDropdownItem(flow)));
      }
    }

    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(child: Column(children: flowList)));
  }

  void _onTapDropdownItem(SexualMisconductFlow flow) {
    Analytics().logSelect(
        target: _flowToDisplayString(flow),
        source: widget.runtimeType.toString());
    setState(() {
      _selectedFlow = flow;
      _dropdownVisible = false;
    });
    // We can add Analytics().logPageWidget(_contentPage); if needed
  }

  void _onTapContentSwitch() {
    setState(() {
      _dropdownVisible = !_dropdownVisible;
    });
  }

  void _onTapDismissLayer() {
    setState(() {
      _dropdownVisible = false;
    });
  }
}

String? _flowToDisplayString(SexualMisconductFlow? flow) {
  switch (flow) {
  case SexualMisconductFlow.talkToSomeone:
  return Localization().getStringEx(
  'panel.safety_sexual_misconduct.flow.talk_to_someone.label',
  'Talk to someone confidentially');
  case SexualMisconductFlow.fileReport:
  return Localization().getStringEx(
  'panel.safety_sexual_misconduct.flow.file_report.label',
  'File a report');
    case SexualMisconductFlow.supportFriend:
      return Localization().getStringEx(
          'panel.safety_sexual_misconduct.flow.support_friend.label',
          'Support a friend');
    case SexualMisconductFlow.notSureYet:
      return Localization().getStringEx(
          'panel.safety_sexual_misconduct.flow.not_sure_yet.label',
          "I'm not sure yet");
    default:
      return null;
  }
}

/// Simple placeholder page for each flow.
/// Replace with detailed widgets as needed.
class _SimpleInfoPage extends StatelessWidget {
  final String title;
  final String description;

  const _SimpleInfoPage({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Styles()
                  .textStyles
                  .getTextStyle('widget.title.large.extra_fat')),
          SizedBox(height: 16),
          Text(description,
              style: Styles().textStyles.getTextStyle('widget.detail.regular')),
        ],
      ),
    );
  }
}
