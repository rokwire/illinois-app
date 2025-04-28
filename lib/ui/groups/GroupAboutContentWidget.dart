
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/ExpandableText.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/ext/Group.dart';

class GroupAboutContentWidget extends StatefulWidget {
  final Group? group;
  final List<Member>?   admins;

  const GroupAboutContentWidget({super.key, this.group, this.admins});

  @override
  State<StatefulWidget> createState() => _GroupAboutContentState();

  static Future showPanel({Group? group, List<Member>? admins, required BuildContext context}) =>
      Navigator.push(context, CupertinoPageRoute(builder: (context) =>
          Scaffold(
            appBar: HeaderBar(
              title: Localization().getStringEx("", "About"), //TBD localize
            ),
            backgroundColor: Styles().colors.background,
            body: Column(children: <Widget>[
              Expanded(child:
              SingleChildScrollView(
                  child: Container(
                    child: GroupAboutContentWidget(group: group, admins: admins,),
                  )
              )
              ),
            ]),
          )
      ));
}

class _GroupAboutContentState extends State<GroupAboutContentWidget> {
  List<Member>?   _groupAdmins;

  bool _loading = false;

  @override
  void initState() {
    _groupAdmins = widget.admins;
    if(CollectionUtils.isEmpty(_groupAdmins)){
      _loadGroupAdmins();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
      Container(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAbout(),
            _buildPrivacyDescription(),
            _buildAdmins()
        ],),
      );


  Widget _buildAbout() {
    List<Widget> contentList = <Widget>[];

    if (!_isResearchProject) {
      contentList.add(Padding(padding: EdgeInsets.only(bottom: 4), child:
      Text(Localization().getStringEx("panel.group_detail.label.about_us",  'About us'), style: Styles().textStyles.getTextStyle('panel.group.detail.fat'), ),),
      );
    }

    if (StringUtils.isNotEmpty(_group?.description)) {
      contentList.add(ExpandableText(_group?.description ?? '',
        textStyle: Styles().textStyles.getTextStyle('panel.group.detail.regular'),
        trimLinesCount: 4,
        readMoreIcon: Styles().images.getImage('chevron-down', excludeFromSemantics: true),),
      );
    }

    /*if (StringUtils.isNotEmpty(_group?.researchConsentDetails)) {
      contentList.add(Padding(padding: EdgeInsets.only(top: 8), child:
      ExpandableText(_group?.researchConsentDetails ?? '',
        textStyle: Styles().textStyles.getTextStyle('panel.group.detail.regular'),
        trimLinesCount: 12,
        readMoreIcon: Styles().images.getImage('chevron-down', excludeFromSemantics: true),
        footerWidget: (_isResearchProject && StringUtils.isNotEmpty(_group?.webURL)) ? Padding(padding: EdgeInsets.only(top: _group?.researchConsentDetails?.endsWith('\n') ?? false ? 0 : 8), child: _buildWebsiteLinkButton())  : null,
      ),
      ),);
    }*/

    if (_isResearchProject && StringUtils.isNotEmpty(_group?.webURL)) {
      contentList.add(Padding(padding: EdgeInsets.only(top: 8), child:
        _buildWebsiteLinkButton()
      ));
    }

    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList,),
    );
  }

  Widget _buildPrivacyDescription() {
    String? title, description;
    if (_group?.privacy == GroupPrivacy.private) {
      title = Localization().getStringEx("panel.group_detail.label.title.private", 'This is a Private Group');
      description = Localization().getStringEx("panel.group_detail.label.description.private", '\u2022 This group is only visible to members.\n\u2022 Anyone can search for the group with the exact name.\n\u2022 Only admins can see members.\n\u2022 Only members can see posts and group events.\n\u2022 All users can see group events if they are marked public.\n\u2022 All users can see admins.');
    }
    else if (_group?.privacy == GroupPrivacy.public) {
      title = Localization().getStringEx("panel.group_detail.label.title.public", 'This is a Public Group');
      description = Localization().getStringEx("panel.group_detail.label.description.public", '\u2022 Only admins can see members.\n\u2022 Only members can see posts.\n\u2022 All users can see group events, unless they are marked private.\n\u2022 All users can see admins.');
    }

    return (StringUtils.isNotEmpty(title) && StringUtils.isNotEmpty(description) && !_isResearchProject) ?
    Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 4), child:
        Text(title!, style:  Styles().textStyles.getTextStyle('panel.group.detail.fat'), ),),
        Text(description!, style: Styles().textStyles.getTextStyle('panel.group.detail.regular'), ),
      ],),) :
    Container(width: 0, height: 0);
  }


  Widget _buildAdmins() {
    if(_loading == true){
      return _buildProgress;
    }
    if (CollectionUtils.isEmpty(_groupAdmins)) {
      return Container();
    }

    List<Widget> content = [];
    content.add(Padding(padding: EdgeInsets.only(left: 16), child: Container()));
    for (Member? officer in _groupAdmins!) {
      if (1 < content.length) {
        content.add(Padding(padding: EdgeInsets.only(left: 8), child: Container()));
      }
      content.add(_OfficerCard(groupMember: officer));
    }
    content.add(Padding(padding: EdgeInsets.only(left: 16), child: Container()));

    String headingText = _isResearchProject ? Localization().getStringEx('panel.group_detail.label.project.admins', 'Research Team') : Localization().getStringEx("panel.group_detail.label.admins", 'Admins');

    return Stack(children: [
      Container(
          height: 112,
          color: Styles().colors.backgroundVariant,
          child: Column(children: [
            Container(height: 80),
            Container(height: 32, child: CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background), child: Container()))
          ])),
      Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(headingText,
                    style:   Styles().textStyles.getTextStyle('widget.title.large.extra_fat'))),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: content))
          ]))
    ]);
  }

  Widget _buildWebsiteLinkButton() {
    return RibbonButton(
        label: Localization().getStringEx("panel.group_detail.button.more_info.title", 'More Info'),
        textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
        rightIconKey: 'external-link',
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        onTap: _onWebsite
    );
  }

  Widget get _buildProgress =>
  Center(
    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary), ),
  );

  void _loadGroupAdmins() {
    setStateIfMounted(() => _loading = true);
    Groups().loadMembers(groupId: _group?.id, statuses: [GroupMemberStatus.admin] ).then((admins) {
      _groupAdmins = admins;
      setStateIfMounted(() => _loading = false);
    });
  }

  void _onWebsite() {
    Analytics().logSelect(target: 'Group url', attributes: _group?.analyticsAttributes);
    UrlUtils.launchExternal(_group?.webURL);
  }

  Group? get _group => widget.group;

  bool get _isResearchProject => _group?.researchProject == true;
}

class _OfficerCard extends StatelessWidget {
  final Member? groupMember;

  _OfficerCard({this.groupMember});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Container(height: 144, width: 128, child: GroupMemberProfileImage(userId: groupMember?.userId)),
        Padding(padding: EdgeInsets.only(top: 4),
          child: Text(groupMember?.name ?? "", style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'),),),
        Text(groupMember?.officerTitle ?? "", style:  Styles().textStyles.getTextStyle('widget.card.detail.regular')),
      ],),
    );
  }
}