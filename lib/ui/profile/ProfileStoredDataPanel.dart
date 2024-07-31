
import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ProfileStoredDataPanel extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _ProfileStoredDataPanelState();
}

class _ProfileStoredDataPanelState extends State<ProfileStoredDataPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx("panel.profile.stored_data.header.title", "My Stored Data"),),
    body: _panelContent,
    backgroundColor: Styles().colors.background,
  );

  Widget get _panelContent => Container();
}