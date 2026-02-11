
import 'package:flutter/material.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class GroupConversationMessagesPanel extends StatefulWidget {


  final Group? group;
  final Conversation conversation;
  final AnalyticsFeature? analyticsFeature;

  GroupConversationMessagesPanel(this.conversation, { super.key, this.group, this.analyticsFeature });

  @override
  State<StatefulWidget> createState() => _GroupConversationMessagesPanelState();
}

class _GroupConversationMessagesPanelState extends State<GroupConversationMessagesPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>  Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx('', 'Message')),
    body: _bodyWidget,
    backgroundColor: Styles().colors.background,
  );

  Widget get _bodyWidget => Column(children: [
    _GroupConversationAvtarHeading(widget.conversation, group: widget.group, onDelete: _onDeleteConversation,),
    Expanded(child: Container())
,
  ],);

  void _onDeleteConversation() {
    Analytics().logSelect(target: 'Delete Conversation');

  }
}

class _GroupConversationAvtarHeading extends StatelessWidget {
  final Group? group;
  final Conversation conversation;
  final void Function()? onDelete;

  static const double _photoSize = 48;

  _GroupConversationAvtarHeading(this.conversation, {this.group, this.onDelete});

  @override
  Widget build(BuildContext context) => Container(decoration: _headingDecoration, child:
    Row(children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
        _avtarWidget,
      ),

      Expanded(child:
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          _nameWidget
        )
      ),

      _deleteButton,
    ],),
  );

  Widget get _nameWidget {
    String? fullName = Auth2().profile?.fullName;
    String? memberStatus = groupMemberStatusToDisplayString(group?.currentMember?.status);
    Color? memberColor = groupMemberStatusToColor(group?.currentMember?.status);
    return RichText(textAlign: TextAlign.left, text:
      TextSpan(style: Styles().textStyles.getTextStyle('widget.title.large.fat'), children: [
        if ((fullName != null) && fullName.isNotEmpty)
          TextSpan(text: fullName),
        if ((fullName != null) && fullName.isNotEmpty && (memberStatus != null) && memberStatus.isNotEmpty)
          TextSpan(text: ' '),
        if ((memberStatus != null) && memberStatus.isNotEmpty)
          TextSpan(text: memberStatus.toUpperCase(), style: Styles().textStyles.getTextStyleEx('widget.title.tiny.fat', color: memberColor)),
      ]),
    );
  }




  Widget get _avtarWidget => DirectoryProfilePhoto(
    photoUrl: Content().getUserPhotoUrl(type: UserProfileImageType.medium,),
    photoSize: _photoSize,
    photoUrlHeaders: DirectoryProfilePhotoUtils.authHeaders,
  );

  Widget get _deleteButton => Event2ImageCommandButton(
    Styles().images.getImage('trash'),
    label: Localization().getStringEx('', 'Delete'),
    hint: Localization().getStringEx('', 'Tap to delete conversation'),
    onTap: () => onDelete?.call(),
  );


  BoxDecoration get _headingDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
    boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(0, 2))],
  );
}