import 'package:flutter/material.dart';
import 'package:illinois/ui/safety/SafetySafeWalkRequestPage.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum SafetyContentType { safeWalkRequest, safetyResources }

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
          SingleChildScrollView(child:
            Padding(padding: EdgeInsets.only(bottom: 16), child:
              _contentPage
            ),
          );

  Widget? get _contentPage {
    if (_selectedContentType == SafetyContentType.safeWalkRequest) {
      return SafetySafeWalkRequestPage(origin: widget.safeWalkRequestOrigin, destination: widget.safeWalkRequestDestination,);
    }
    else {
      return null;
    }
  }
}

mixin class SafetyHomeContentPage {
  Color get safetyPageBackgroundColor => Styles().colors.background;
}