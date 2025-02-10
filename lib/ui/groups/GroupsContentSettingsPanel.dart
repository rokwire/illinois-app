import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class GroupContentSettingsPanel extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _GroupContentSettingsState();

}

class _GroupContentSettingsState extends State<GroupContentSettingsPanel> {

  @override
  Widget build(BuildContext context) =>
      Scaffold(
          appBar: HeaderBar(
            title: Localization().getStringEx("", "Group Content"), //TBD
          ),
        backgroundColor: Styles().colors.background,
        body: SingleChildScrollView(
          child: _content
        )
      );

  Widget get _content =>
    Column(
      children: [
        Container(
            child: Center(
            child: Text("TBD"),)
        )
      ],);

}