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
  bool _settingCanJoinAutomatically = false;
  bool _settingOnlyAdminCanCreatePolls= false;

  @override
  void initState() {
    super.initState();
    _settings = GroupSettings.fromOther(widget.group?.settings);
    _settingCanJoinAutomatically = widget.group?.canJoinAutomatically == true;
    _settingOnlyAdminCanCreatePolls = widget.group?.onlyAdminsCanCreatePolls == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: "Advanced Settings"),
      body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                color: Styles().colors!.background,
                child: CustomScrollView(
                    scrollDirection: Axis.vertical,
                    slivers: <Widget>[
                      //SliverHeaderBar(title: "Advanced Settings"),
                      SliverList(
                        delegate: SliverChildListDelegate([
                        Container(
                          color: Styles().colors!.background,
                          child: Column(children: <Widget>[
                            Padding(padding: EdgeInsets.only(top: 16),
                              child: _buildCanAutoJoinLayout(),),
                            Padding(padding: EdgeInsets.only(top: 8),
                              child: _buildPollsLayout(),),
                            Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorSecondary,
                onTap: onTapSave,
              ),
            ),
            Container(width: 16,),
            Expanded(
              child: RoundedButton(
                label: Localization().getStringEx( "dialog.cancel.title","Cancel"),
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorSecondary,
                onTap: onTapCancel,
              ),
            ),
          ],)
        ],),
      )
      ,),);
  }

  //Auto Join
  //Autojoin
  Widget _buildCanAutoJoinLayout(){
    return Container( color: Styles().colors!.background,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: EnabledToggleButton(
          label:_isResearchProject? Localization().getStringEx('panel.groups_settings.auto_join.project.enabled.label', 'Does not require my screening of potential participants') : Localization().getStringEx("panel.groups_settings.auto_join.enabled.label", "Group can be joined automatically?"),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
          enabled: true,
          toggled: _settingCanJoinAutomatically,
          onTap: () {
            if(mounted){
              setState(() {
                _settingCanJoinAutomatically = !_settingCanJoinAutomatically;
              });
            }
          }
      ),
    );
  }

  Widget _buildPollsLayout(){
    return Container(
      color: Styles().colors!.background,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: EnabledToggleButton(
          label: Localization().getStringEx("panel.groups_settings.only_admins_create_polls.enabled.label", "Only admins can create Polls"),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
          enabled: true,
          toggled: _settingOnlyAdminCanCreatePolls,
          onTap: () {
            if(mounted){
              setState(() {
                _settingOnlyAdminCanCreatePolls = !_settingOnlyAdminCanCreatePolls;
              });
            }
          }
      ),
    );
  }

  void onTapCancel(){
    Navigator.of(context).pop();
  }

  void onTapSave(){
   if(widget.group!=null && _settings!=null) {
     widget.group!.settings = _settings;
     widget.group!.canJoinAutomatically = _settingCanJoinAutomatically;
     widget.group!.onlyAdminsCanCreatePolls = _settingOnlyAdminCanCreatePolls;
   }
   Navigator.of(context).pop(_settings);
  }

  bool get _isResearchProject {
    return widget.group?.researchProject ?? false;
  }
}