import 'package:flutter/material.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class GroupAdvancedSettingsPanel extends StatefulWidget{
  final Group? group;

  const GroupAdvancedSettingsPanel({Key? key, this.group}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupAdvancedSettingsPanelState();
}

class _GroupAdvancedSettingsPanelState extends State<GroupAdvancedSettingsPanel>{
  GroupSettings? _settings;

  @override
  void initState() {
    super.initState();
    _settings = GroupSettings.fromOther(widget.group?.settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                color: Styles().colors!.background,
                child: CustomScrollView(
                    scrollDirection: Axis.vertical,
                    slivers: <Widget>[
                      SliverHeaderBar(title: "Advanced Settings"),
                      SliverList(
                        delegate: SliverChildListDelegate([
                        Container(
                          color: Styles().colors!.background,
                          child: Column(children: <Widget>[
                            Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                child: GroupMemberSettingsLayout(
                                    settings: _settings,
                                    onChanged: () {
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    }
                                )
                            )
                          ]))
                        ]))
                ])
            )),
            _buildButtonsLayout(),
    ]));
  }

  //Buttons
  Widget _buildButtonsLayout() {
    return SafeArea(child: Container( color: Styles().colors!.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child:
        Stack(children: <Widget>[
          Row(children: [
            Expanded(
              child: RoundedButton(
                label: Localization().getStringEx("dialog.ok.title", "Ok"),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorSecondary,
                textColor: Styles().colors!.fillColorPrimary,
                onTap: onTapSave,
              ),
            ),
            Container(width: 16,),
            Expanded(
              child: RoundedButton(
                label: Localization().getStringEx( "dialog.cancel.title","Cancel"),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorSecondary,
                textColor: Styles().colors!.fillColorPrimary,
                onTap: onTapCancel,
              ),
            ),
          ],)
        ],),
      )
      ,),);
  }

  void onTapCancel(){
    Navigator.of(context).pop();
  }

  void onTapSave(){
   // if(widget.group!=null && _settings!=null) {
   //   widget.group!.settings = _settings;
   // }
   Navigator.of(context).pop(_settings);
  }

}