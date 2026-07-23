import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/parser/html_to_delta.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as html;
import 'package:illinois/ext/Group.dart';
import 'package:illinois/ext/Social.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/messages/MessagesMediaFullscreenPanel.dart';
import 'package:illinois/ui/profile/ProfileVoiceRecordigWidgets.dart';
import 'package:illinois/ui/widgets/AudioPlayerWidget.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/VideoPlayerWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class GroupConversationCard extends StatelessWidget {

  final Conversation conversation;
  final List<Member>? groupAdmins;
  final void Function()? onTap;
  final UniqueKey _avtarKey = UniqueKey();

  GroupConversationCard(this.conversation, { this.groupAdmins, this.onTap });

  List<ConversationMember>? get _participants => this.conversation.members;
  int get _participantsCount => _participants?.length ?? 0;

  @override
  Widget build(BuildContext context) =>
    InkWell(onTap: onTap, child:
      Container(decoration: _cardDecoration, padding: _cardPadding, child:
        Row(children: [
          GroupConversationAvtarWidget(key: _avtarKey, conversation: conversation),
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(horizontal: _horzPadding), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                _titleWidget,
                _updateTimeWidget,
              ],)
            ),
          ),
          Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true) ?? Container(),
        ],)
      )
    );

  Widget get _titleWidget {
    if (conversation.isGroupAll) {
      return _groupChatNameWidget;
    } if (1 < _participantsCount) {
      return _participantsNamesWidget;
    } else if (0 < _participantsCount) {
      return _participantNameWidget;
    } else {
      return Container();
    }
  }

  Widget get _participantNameWidget {
    ConversationMember? member = conversation.members?.firstOrNull;
    String? fullName = (member != null) ? member.name : null;
    Member? groupMember = MemberExt.getMember(groupAdmins, userId: member?.accountId);
    String? memberStatus = groupMemberStatusToDisplayString(groupMember?.status);
    Color? memberColor = groupMemberStatusToColor(groupMember?.status);
    return RichText(textAlign: TextAlign.left, text:
      TextSpan(style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'), children: ((fullName != null) && fullName.isNotEmpty) ? [
        TextSpan(text: fullName),
        if ((memberStatus != null) && memberStatus.isNotEmpty) ...[
          TextSpan(text: ' '),
          TextSpan(text: memberStatus.toUpperCase(), style: Styles().textStyles.getTextStyleEx('widget.card.detail.light.fat', color: memberColor)),
        ]
      ] : []),
    );
  }

  Widget get _participantsNamesWidget => Text(conversation.membersString ?? '',
    style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'),
    textAlign: TextAlign.left,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );

  Widget get _groupChatNameWidget => Text(Localization().getStringEx('', 'All Group Members Chat'),
    style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'),
    textAlign: TextAlign.left,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );

  Widget get _updateTimeWidget {
    String? updateTime = conversation.displayUpdateTime;
    String? semanticsLabel = (updateTime != null) ? sprintf(Localization().getStringEx('', 'Updated %s'), [updateTime]) : null;
    return Semantics(child:
      Text(updateTime ?? '',
        semanticsLabel: semanticsLabel,
        textAlign: TextAlign.left,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: Styles().textStyles.getTextStyle('widget.card.detail.small')
      )
    );

  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.textBackgroundVariant2, width: 2),
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  EdgeInsetsGeometry get _cardPadding =>
    EdgeInsetsGeometry.symmetric(horizontal: _horzPadding, vertical: _vertPadding);

  static const double _horzPadding = 12;
  static const double _vertPadding = 8;
}

class GroupConversationAvtarWidget extends StatelessWidget {
  static const double widgetSize = 48;

  static const double _avtarSize = widgetSize / 2;
  static const double _avtarOffset = _avtarSize * (sqrt2 - 1) / (2 * sqrt2) - 1;

  static const double _avtar2Size = _avtarSize * 2 / 3;
  static const double _avtar2Offset = _avtarOffset + 1.5;

  final Group? group;
  final Conversation? conversation;
  final ConversationMember? conversationMember;

  GroupConversationAvtarWidget({ super.key, this.group, this.conversation, this.conversationMember });

  List<ConversationMember>? get _participants => this.conversation?.members;
  int get _participantsCount => _participants?.length ?? 0;

  @override
  Widget build(BuildContext context) =>
    Container(width: widgetSize, height: widgetSize, decoration: _avtarDecoration, child: _avtarIcon);

  Widget? get _avtarIcon {
    if (conversation != null) {
      if (conversation?.isGroupAll == true) {
        return _groupChatIcon;
      } else if (conversation?.isGroupSubset == true) {
        return (_participantsCount == 1) ? _singleParticipantIcon(_participants?.firstOrNull) : _multipleParticipantsIcon;
      } else {
        return null;
      }
    } else if (conversationMember != null) {
      return _singleParticipantIcon(conversationMember);
    } else if (group != null) {
      return _groupMembersIcon;
    } else {
      return null;
    }
  }

  Widget _singleParticipantIcon(ConversationMember? member) =>
    DirectoryProfilePhoto(
      photoUrl: Content().getUserPhotoUrl(
        type: UserProfileImageType.medium,
        accountId: member?.accountId,
        //params: DirectoryProfilePhotoUtils.tokenUrlParam(_photoImageToken),
      ),
      photoSize: widgetSize,
      photoUrlHeaders: DirectoryProfilePhotoUtils.authHeaders,
    );

  Widget get _multipleParticipantsIcon {
    ConversationMember? participant1 = ListUtils.entry(_participants, 0);
    ConversationMember? participant2 = ListUtils.entry(_participants, 1);
    ConversationMember? participant3 = ListUtils.entry(_participants, 2);

    return Stack(children: [

      if (participant1 != null)
        Positioned.fill(child:
          Align(alignment: Alignment.topLeft, child:
            Padding(padding: EdgeInsets.only(left: _avtarOffset, top: _avtarOffset,), child:
              DirectoryProfilePhoto(
                photoUrl: Content().getUserPhotoUrl(
                  type: UserProfileImageType.small,
                  accountId: participant1.accountId,
                  //params: DirectoryProfilePhotoUtils.tokenUrlParam(_photoImageToken),
                ),
                photoSize: _avtarSize,
                photoUrlHeaders: DirectoryProfilePhotoUtils.authHeaders,
              ),
            )
          )
        ),

      if (participant2 != null)
        Positioned.fill(child:
          Align(alignment: Alignment.bottomRight, child:
            Padding(padding: EdgeInsets.only(right: _avtarOffset, bottom: _avtarOffset,), child:
              DirectoryProfilePhoto(
                photoUrl: Content().getUserPhotoUrl(
                  type: UserProfileImageType.small,
                  accountId: participant2.accountId,
                  //params: DirectoryProfilePhotoUtils.tokenUrlParam(_photoImageToken),
                ),
                photoSize: _avtarSize,
                photoUrlHeaders: DirectoryProfilePhotoUtils.authHeaders,
              ),
            )
          )
        ),

      if (participant3 != null)
        Positioned.fill(child:
          Align(alignment: Alignment.bottomLeft, child:
            Padding(padding: EdgeInsets.only(left: _avtar2Offset, bottom: _avtar2Offset,), child:
              //Container(width: _avtar2Size, height: _avtar2Size, decoration: _participantDecoration(Colors.greenAccent)),
              DirectoryProfilePhoto(
                photoUrl: Content().getUserPhotoUrl(
                  type: UserProfileImageType.small,
                  accountId: participant3.accountId,
                  //params: DirectoryProfilePhotoUtils.tokenUrlParam(_photoImageToken),
                ),
                photoSize: _avtar2Size,
                photoUrlHeaders: DirectoryProfilePhotoUtils.authHeaders,
              ),
            )
          )
        ),
    ],);
  }

  Widget get _groupChatIcon =>
    DirectoryProfilePhoto(placeholderImageKey: 'group-chat', photoSize: widgetSize,);

  Widget get _groupMembersIcon =>
    DirectoryProfilePhoto(placeholderImageKey: 'profile-placeholder', photoSize: widgetSize,);

  BoxDecoration get _avtarDecoration => BoxDecoration(
    color: Styles().colors.textBackgroundVariant2,
    shape: BoxShape.circle,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
  );

}

class GroupConversationHeader extends StatefulWidget {
  final Group? group;
  final List<Member>? groupAdmins;
  final Conversation? conversation;

  GroupConversationHeader({ this.conversation, this.group, this.groupAdmins });

  @override
  State<StatefulWidget> createState() => _GroupConversationHeaderState();
}

class _GroupConversationHeaderState extends State<GroupConversationHeader> {

  bool _deleteProgress = false;

  bool get _multipleMembers => ((widget.conversation?.isGroupSubset == true) && (1 < (widget.conversation?.members?.length ?? 0)));

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _headingDecoration, child: _contentWidget);

  Widget? get _contentWidget {
    if (widget.conversation != null) {
      if (widget.conversation?.isGroupAll == true) {
        return _groupChatWidget;
      } if (widget.conversation?.isGroupSubset == true) {
        return _multipleMembers ? _multipleMembersDropdown : _singleMemberWidget;
      } else {
        return null;
      }
    }
    else if (widget.group != null) {
      return _groupMembersWidget;
    } else {
      return null;
    }
  }

  Widget get _groupChatWidget => Row(children: [
    _avtarWidget,
    Expanded(child:
      Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        _groupChatNameWidget,
      )
    ),
    _deleteButton,
  ],);

  Widget get _groupMembersWidget => Row(children: [
    _avtarWidget,
    Expanded(child:
      Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        _groupMembersNameWidget,
      )
    ),
    //_deleteButton,
  ],);


  Widget get _singleMemberWidget => Row(children: [
    _avtarWidget,
    Expanded(child:
      Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        _participantNameWidget,
      )
    ),
    _deleteButton,
  ],);


  Widget get _multipleMembersDropdown =>
    DropdownButtonHideUnderline(child:
      DropdownButton2<String>(
        dropdownStyleData: DropdownStyleData(width: _screenWidth, padding: EdgeInsets.zero),
        menuItemStyleData: MenuItemStyleData(height: _dropdownMemberItemHeight, padding: EdgeInsets.zero),
        customButton: _multipleMembersWidget,
        isExpanded: false,
        items: _buildDropdownMembers(),
        onChanged: (_){},
      ),
    );

  Widget get _multipleMembersWidget => Row(children: [
    _avtarWidget,
    Expanded(child:
      Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        _participantNamesWidget,
      )
    ),
    _chevronDownIcon,
    _deleteButton,
  ],);

  // Dropdown

  List<DropdownMenuItem<String>> _buildDropdownMembers() => List.from(widget.conversation?.members?.sorted(ConversationMemberExt.compareNames).map((member) => _buildDropdownMemberItem(member)) ?? []);

  DropdownMenuItem<String> _buildDropdownMemberItem(ConversationMember member) =>
    DropdownMenuItem<String>(value: member.accountId ?? '', child:
      Container(decoration: _dropdownMemberDecoration, child:
        Row(children: [
          _buildAvtarWidget(conversationMember: member),
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
              _buildParticipantNameWidget(member,
                nameTextStyleName: 'widget.card.title.small.fat',
                statusTextStyleName: 'widget.title.light.tiny.fat'
              ),
            )
          ),
        ],)
      ),
    );

  double get _dropdownMemberItemHeight => GroupConversationAvtarWidget.widgetSize + 2 * _avtarSpacing;

  // Avtar

  Widget get _avtarWidget => _buildAvtarWidget(conversation: widget.conversation, group: widget.group);

  Widget _buildAvtarWidget({ Group? group, Conversation? conversation, ConversationMember? conversationMember }) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: _avtarSpacing * 2, vertical: _avtarSpacing), child:
      GroupConversationAvtarWidget(group: group, conversation: conversation, conversationMember: conversationMember),
    );

  double get _avtarSpacing => 8;

  // Name

  Widget get _participantNameWidget => _buildParticipantNameWidget(widget.conversation?.members?.firstOrNull,
    nameTextStyleName: 'widget.title.large.fat',
    statusTextStyleName: 'widget.title.light.tiny.fat'
  );

  Widget _buildParticipantNameWidget(ConversationMember? member, { required String nameTextStyleName, required String statusTextStyleName }) {
    String? fullName = (member != null) ? member.name : null;
    Member? groupMember = MemberExt.getMember(widget.groupAdmins, userId: member?.accountId);
    String? memberStatus = groupMemberStatusToDisplayString(groupMember?.status);
    Color? memberColor = groupMemberStatusToColor(groupMember?.status);
    return RichText(textAlign: TextAlign.left, text:
      TextSpan(style: Styles().textStyles.getTextStyle(nameTextStyleName), children: ((fullName != null) && fullName.isNotEmpty) ? [
        TextSpan(text: fullName),
        if ((memberStatus != null) && memberStatus.isNotEmpty) ...[
          TextSpan(text: ' '),
          TextSpan(text: memberStatus.toUpperCase(), style: Styles().textStyles.getTextStyleEx(statusTextStyleName, color: memberColor)),
        ]
      ] : []),
    );
  }

  Widget get _participantNamesWidget => Text(widget.conversation?.membersString ?? '',
    style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'),
    textAlign: TextAlign.left,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );

  Widget get _groupChatNameWidget => Text(Localization().getStringEx('', 'All Group Members Chat'),
    style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'),
    textAlign: TextAlign.left,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );

  Widget get _groupMembersNameWidget => Text(Localization().getStringEx('', 'All Group Members (Individually)'),
    style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'),
    textAlign: TextAlign.left,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );

  Widget get _chevronDownIcon => Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16), child:
    Styles().images.getImage('chevron-down')
  );

  Widget get _deleteButton => Event2ImageCommandButton(
    _deleteProgress ? _deleteProgressIcon : _deleteButtonIcon,
    label: Localization().getStringEx('', 'Delete'),
    hint: Localization().getStringEx('', 'Tap to delete conversation'),
    contentPadding: _multipleMembers ? EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16) : EdgeInsets.all(16),
    onTap: _onDelete,
  );

  Widget? get _deleteButtonIcon => Styles().images.getImage('trash', size: _deleteIconSize, excludeFromSemantics: true);
  Widget get _deleteProgressIcon => SizedBox.square(dimension: _deleteIconSize - 2, child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 2,));
  double get _deleteIconSize => 20;

  double get _screenWidth => MediaQuery.of(context).size.width;

  BoxDecoration get _dropdownMemberDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
  );

  BoxDecoration get _headingDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
    boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(0, 2))],
  );

  void _onDelete() async {
    if (_deleteProgress == false) {
      bool? deleteConfirmed = await GroupConversationConfirmDeleteDialog.show(context, Localization().getStringEx('', 'Delete this conversation?',));
      if ((deleteConfirmed == true) && mounted) {
        setState(() {
          _deleteProgress = true;
        });
        bool? result = await Social().deleteConverstion(widget.conversation?.id ?? '');
        if (mounted) {
          setState(() {
            _deleteProgress = false;
          });
          if (result == true) {
            Navigator.pop(context);
          } else {
            AppAlert.showDialogResult(context, Localization().getStringEx('', 'Failed to delete messages thread'));
          }
        }
      }
    }
  }
}

class GroupConversationMessageCard extends StatelessWidget {
  final Message message;
  final Conversation? conversation;
  final Group? group;
  final Member? groupMember;
  final void Function()? onCommand;
  final Widget? commandIcon;
  final bool commandProgress;
  final AnalyticsFeature? analyticsFeature;
  final Key _reactionsKey;

  GroupConversationMessageCard(this.message, { super.key, this.conversation, this.group, this.groupMember, this.onCommand, this.commandIcon, this.commandProgress = false, this.analyticsFeature }) :
    _reactionsKey = ValueKey('social-message-${message.globalId}-reactions' );

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _cardDecoration, child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        GroupConversationMessageHeader(message, conversation: conversation, group: group, groupMember: groupMember, onCommand: onCommand, commandIcon: commandIcon, commandProgress: commandProgress),
        Padding(padding: EdgeInsets.symmetric(horizontal: _horzPadding), child:
          SelectionArea(child:
            _bodyHtmlWidget,
          ),
        ),
        if (message.fileAttachments?.isNotEmpty == true)
          _attachmentsWidget(context),
        Padding(padding: EdgeInsets.symmetric(horizontal: _horzPadding, vertical: _horzPadding), child:
          GroupReactionsLayout(key: _reactionsKey, group: group, entityId: message.globalId, reactionSource: SocialEntityType.message, analyticsFeature: analyticsFeature,)
        ),
      ],)
    );

  /* Widget get _bodyTextWidget => LinkTextEx(
    message.message ?? '',
    textStyle: Styles().textStyles.getTextStyle('widget.detail.regular'),
    linkStyle: Styles().textStyles.getTextStyleEx('widget.detail.regular.underline', decorationColor: Styles().colors.fillColorPrimary),
    onLinkTap: _onTapLink,
  ); */

  Widget get _bodyHtmlWidget => html.HtmlWidget(
      "<div style= $_bodyHtmlStyle> ${message.message ?? ''}</div>",
      onTapUrl : (url) { _onTapLink(url); return true; },
      textStyle:  Styles().textStyles.getTextStyle("widget.detail.regular"),
      customStylesBuilder: (element) => (element.localName == "a") ? { "color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null,
  );

  String get _bodyHtmlStyle => 'white-space: normal'; // 'text-overflow: ellipsis; max-lines: 3'

  Widget _attachmentsWidget(BuildContext context) => Container(height: 300, child:
    ListView.separated(
      padding: EdgeInsets.only(top: _horzPadding, left: _horzPadding, right: _horzPadding),
      separatorBuilder: (context, index) => SizedBox(width: 8),
      itemCount: message.fileAttachments?.length ?? 0,
      itemBuilder: (context, index) => _attachmentCard(context, ListUtils.entry(message.fileAttachments, index)),
      scrollDirection: Axis.horizontal,
    ),
  );

  Widget _attachmentCard(BuildContext context, FileAttachment? attachment) =>
    Center(child:
      Stack(children: [
        _GroupConversationAttachmentCard(attachment,),
        if ((attachment != null) && (attachment.type != AttachmentFileType.audio.name))
          Positioned.fill(child:
            GestureDetector(onTap: () => _onTapAttachment(context, attachment), behavior: HitTestBehavior.opaque, child:
              Container(),
            ),
          ),
      ],)
    );

  void _onTapLink(String url) {
    Uri? uri = Uri.tryParse(url);
    if (url.contains('@')) {
      uri = uri?.fix(scheme: 'mailto');
    } else {
      uri = uri?.fix(scheme: 'https');
    }
    Analytics().logSelect(target: url);
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        AppLaunchUrl.launchExternal(url: url);
      }
    }
  }

/*
  void _onTapImageAttachment(FileAttachment attachment) {}
  void _onTapVideoAttachment(FileAttachment attachment) {}
  void _onTapFileAttachment(FileAttachment attachment) {}

  void Function()? onTap;
  switch(attachment.type) {
    case AttachmentFileType.image: onTap = () => _onTapImageAttachment(attachment); break;
    case AttachmentFileType.video: onTap = () => _onTapVideoAttachment(attachment); break;
    case AttachmentFileType.file: onTap = () => _onTapFileAttachment(attachment); break;
    default: break;
  }
*/

  void _onTapAttachment(BuildContext context, FileAttachment attachment) async {
    if (attachment.type == AttachmentFileType.image.name) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
        MessagesMediaFullscreenPanel(mediaBuilder: (_) => _GroupConversationAttachmentCard._imageAttachmentWidgetImpl(attachment), filename: attachment.name, url: attachment.url),
      ));
    } else if (attachment.type == AttachmentFileType.video.name) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
        MessagesMediaFullscreenPanel(mediaBuilder: (_) => _GroupConversationAttachmentCard._videoAttachmentWidgetImpl(attachment), filename: attachment.name, url: attachment.url),
      ));
    } else if (attachment.type == AttachmentFileType.file.name) {
      _downloadAttachment(context, attachment);
    }
  }

  Future<void> _downloadAttachment(BuildContext context, FileAttachment attachment) async {
    String? attachmentId = attachment.id;
    if (attachmentId != null) {
      Map<String, Uint8List> files = await Content().getFileContentItems([attachmentId], Content.conversationsContentCategory, entityId: conversation?.id);
      Uint8List? attachmentData = files[attachmentId];
      if ((attachmentData != null) && attachmentData.isNotEmpty) {
        AppFile.downloadFile(context: context, fileName: attachment.name ?? 'file.out', fileBytes: attachmentData);
      }
    }
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent),
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  static const double _horzPadding = 8;
  static const double _vertPadding = 8;
}

class GroupConversationMessageHeader extends StatelessWidget {
  final Message message;
  final Conversation? conversation;
  final Group? group;
  final Member? groupMember;
  final void Function()? onCommand;
  final bool commandProgress;
  final Widget? commandIcon;

  GroupConversationMessageHeader(this.message, { this.conversation, this.group, this.groupMember, this.onCommand, this.commandIcon, this.commandProgress = false });

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children:[
    Expanded(child:
      Row(children: [
        Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: _horzPadding, vertical: _vertPadding), child:
          _avtarWidget
        ),

        Expanded(child:
          Padding(padding: EdgeInsetsGeometry.symmetric(vertical: _vertPadding), child:
            _detailsWidget
          ),
        ),
      ],),
    ),

    if (commandProgress)
      _commandProgressIndicator
    else if (commandIcon != null)
      _commandIconIndicator
    else if (onCommand != null)
      _commandButton
  ]);

  Widget get _detailsWidget =>
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _nameWidget,
      _updateTimeWidget,
    ],);

  Widget get _nameWidget {
    String? fullName = message.sender?.name;
    String? memberStatus = groupMemberStatusToDisplayString(groupMember?.status);
    Color? memberColor = groupMemberStatusToColor(groupMember?.status);
    return RichText(textAlign: TextAlign.left, text:
      TextSpan(style: Styles().textStyles.getTextStyle('widget.detail.small.fat'), children: [
        if ((fullName != null) && fullName.isNotEmpty)
          TextSpan(text: fullName),
        if ((fullName != null) && fullName.isNotEmpty && (memberStatus != null) && memberStatus.isNotEmpty)
          TextSpan(text: ' '),
        if ((memberStatus != null) && memberStatus.isNotEmpty)
          TextSpan(text: memberStatus.toUpperCase(), style: Styles().textStyles.getTextStyleEx('widget.detail.tiny.fat', color: memberColor)),
      ]),
    );
  }

  Widget get _updateTimeWidget {
    String? updateTime = message.displayDateTime;
    String? semanticsLabel = (updateTime != null) ? sprintf(Localization().getStringEx('', 'Updated %s'), [updateTime]) : null;
    return Semantics(child:
      Text(updateTime ?? '',
        semanticsLabel: semanticsLabel,
        textAlign: TextAlign.left,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: Styles().textStyles.getTextStyle('widget.card.detail.small')
      )
    );

  }

  Widget get _avtarWidget => DirectoryProfilePhoto(
    photoUrl: _avtarPhotoUrl,
    photoSize: photoSize,
    photoUrlHeaders: DirectoryProfilePhotoUtils.authHeaders,
  );

  String? get _avtarPhotoUrl => (message.sender?.accountId?.isNotEmpty == true) ?
    Content().getUserPhotoUrl(accountId: message.sender?.accountId, type: UserProfileImageType.medium,) : null;

  Widget get _commandButton => Event2ImageCommandButton(
    Styles().images.getImage('more', size: buttonIconSize, excludeFromSemantics: true),
    label: Localization().getStringEx('', 'Commands'),
    hint: Localization().getStringEx('', ''),
    contentPadding: EdgeInsets.all(buttonPadding),
    onTap: onCommand,
  );

  Widget get _commandProgressIndicator => Padding(padding: EdgeInsets.all(buttonPadding + 2), child:
    SizedBox.square(dimension: buttonIconSize - 2, child:
      CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary),
    )
  );

  Widget get _commandIconIndicator => Padding(padding: EdgeInsets.all(buttonPadding), child:
    SizedBox.square(dimension: buttonIconSize, child:
      commandIcon,
    )
  );

  static const double _horzPadding = GroupConversationMessageCard._horzPadding;
  static const double _vertPadding = GroupConversationMessageCard._vertPadding;
  static const double buttonPadding = _vertPadding;
  static const double buttonIconSize = 18;
  static const double photoSize = 36;
}

class GroupConversationMessageEditBar extends StatefulWidget {

  final String? title;
  final EdgeInsetsGeometry padding;

  final String? text;
  final String? hint;
  final TextStyle? textStyle;
  final TextStyle? linkTextStyle;

  final int minLines;
  final int maxLines;
  final bool autofocus;
  final FocusNode? focusNode;

  final Iterable<FileAttachment>? attachments;
  final bool canEditAttachments;


  final Future<bool> Function(String message, { Iterable<dynamic>? attachments })? onSubmitMessage;
  final void Function()? onCancelEdit;
  final bool showSubmitProgress;

  GroupConversationMessageEditBar({this.title,
    this.padding = const EdgeInsetsGeometry.only(left: 24, right: 16, top: 8, bottom: 24),
    this.text, this.hint, this.textStyle, this.linkTextStyle,
    this.minLines = 1, this.maxLines = 12, this.autofocus = false, this.focusNode,
    this.attachments, this.canEditAttachments = false,
    required this.onSubmitMessage, this.showSubmitProgress = false, this.onCancelEdit,
  });

  quill.Document createTextDocument() {
    try {
      return quill.Document.fromDelta(HtmlToDelta().convert(text ?? ''));
    }
    catch(e) {
      return quill.Document()..insert(0, text ?? '');
    }
  }

  quill.QuillController createTextController() {
    if (text?.isNotEmpty == true) {
      quill.Document textDocument = createTextDocument();
      TextSelection textSelection = TextSelection.collapsed(offset: max(textDocument.toPlainText().length - 1, 0));
      return quill.QuillController(document: textDocument, selection: textSelection,);
    } else {
      return quill.QuillController.basic();
    }
  }

  @override
  State<StatefulWidget> createState() => _GroupConversationMessageEditBarState();
}

enum _EditBarCommand { bold, italic, underline, link, submit, picture }

class _GroupConversationMessageEditBarState extends State<GroupConversationMessageEditBar> {

  late quill.QuillController _quillController;
  late Delta _initialQuillDelta;
  late TextStyle _textStyle;
  late TextStyle _linkTextStyle;
  Set<_EditBarCommand> _selectedCommands = <_EditBarCommand>{};
  List<dynamic> _attachments = <dynamic>[];
  late ScrollController _attachmentsScrollController;
  bool _submitting = false;


  @override
  void initState() {
    super.initState();
    _quillController = widget.createTextController();
    _quillController.addListener(_onTextChanged);
    _initialQuillDelta = _quillController.document.toDelta();
    _textStyle = widget.textStyle ?? Styles().textStyles.getTextStyle('widget.message.regular') ?? _defaultTextStyle;
    _linkTextStyle = widget.linkTextStyle ?? _textStyle.apply(color: _linkTextColor, decoration: TextDecoration.underline, decorationColor: _linkTextColor);
    _attachmentsScrollController = ScrollController();
    _attachments.addAll(widget.attachments ?? <FileAttachment>[]);
  }

  @override
  void dispose() {
    _quillController.removeListener(_onTextChanged);
    _quillController.dispose();
    _attachmentsScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GroupConversationMessageEditBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (mounted) {
      if (widget.text != oldWidget.text) {
        _quillUpdate();
      }
      if (!DeepCollectionEquality().equals(widget.attachments, oldWidget.attachments)) {
        _updateAttachments();
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
    Padding(padding: widget.padding, child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        _commandBar,
        Padding(padding: EdgeInsetsGeometry.only(right: 8), child:
          _textBar
        ),
        if (widget.canEditAttachments && _attachments.isNotEmpty)
          Padding(padding: EdgeInsetsGeometry.only(right: 8), child:
            _attachmentsList,
          ),
      ],),
    );

  Widget get _textBar =>
      Container(decoration: _textDecoration, child:
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child:
            Padding(padding: _textPadding, child:
              quill.QuillEditor.basic(
                controller: _quillController,
                focusNode: widget.focusNode,
                config: quill.QuillEditorConfig(
                  autoFocus: widget.autofocus,
                  placeholder: widget.hint,
                  expands: false,
                  scrollable: true,
                  minHeight: _textMinHeight,
                  maxHeight: _textMaxHeight,
                  padding: EdgeInsets.zero,
                  customStyles: quill.DefaultStyles(
                    paragraph: quill.DefaultTextBlockStyle(
                      _textStyle,
                      const quill.HorizontalSpacing(0, 0),
                      const quill.VerticalSpacing(0, 0),
                      const quill.VerticalSpacing(0, 0),
                      null,
                    ),
                    link: _linkTextStyle,
                  ),
                ),
              ),
            ),
          ),
          (widget.showSubmitProgress && _submitting) ? _submittingProgress : _submitButton,
          if (_hasCancelEdit)
            _cancelEditButton,
        ],)
      );

  BoxDecoration get _textDecoration => BoxDecoration(
      color: Styles().colors.surface,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Styles().colors.surfaceAccent)
  );

  static const EdgeInsetsGeometry _textPadding = const EdgeInsets.only(left: 12, top: 8, bottom: 8);

  double get _textMinHeight => widget.minLines * _textLineHeight;
  double get _textMaxHeight => widget.maxLines * _textLineHeight;
  double get _textLineHeight => MediaQuery.of(context).textScaler.scale(_textFontSize * 1.25);
  double get _textFontSize => _textStyle.fontSize ?? _defaultTextSize;

  TextStyle get _defaultTextStyle => TextStyle(fontFamily: _defaultFontFamily, fontSize: _defaultTextSize, color: _defaultTextColor,);
  String? get _defaultFontFamily => Styles().fontFamilies.regular;
  Color? get _defaultTextColor => Styles().colors.fillColorPrimary;
  Color? get _linkTextColor => Styles().colors.fillColorSecondary;
  static const double _defaultTextSize = 16;


  Widget get _commandBar => Row(children: [
    if (widget.title?.isNotEmpty == true)
      Text(widget.title ?? '', style: Styles().textStyles.getTextStyleEx('widget.detail.small.fat'),),
    Expanded(child:
      Wrap(alignment: WrapAlignment.end, children: [
        _formatButton(_EditBarCommand.bold, onTap: _onBold),
        _formatButton(_EditBarCommand.italic, onTap: _onItalic),
        _formatButton(_EditBarCommand.underline, onTap: _onUnderline),
        _formatButton(_EditBarCommand.link, onTap: _onLink),
        if (widget.canEditAttachments)
          _formatButton(_EditBarCommand.picture, onTap: _onPicture),
      ],),
    )
  ],);

  Widget _formatButton(_EditBarCommand command, { void Function()? onTap }) =>
      Event2ImageCommandButton(
        _formatButtonImage(command),
        label: command.accLabel,
        hint: command.accHint,
        contentPadding: _singleButtonPadding,
        onTap: onTap,
      );

  Widget? _formatButtonImage(_EditBarCommand command) =>
      Styles().images.getImage(command.iconKey,
        color: _formatButtonColor(command),
        size: _buttonIconSize,
        excludeFromSemantics: true
      );

  Color _formatButtonColor(_EditBarCommand? command) =>
    ((command != null) && _selectedCommands.contains(command)) ? Styles().colors.fillColorSecondary : Styles().colors.fillColorPrimary;

  bool _hasTextFormat(quill.Attribute attribute) =>
    _quillController.getSelectionStyle().attributes.containsKey(attribute.key);

  void _toggleTextFormat(quill.Attribute attribute) =>
    _quillController.formatSelection(
      _hasTextFormat(attribute) ? quill.Attribute.clone(attribute, null) : attribute,
    );

  String get _quillHtml {
    final deltaOps = _quillController.document.toDelta().toJson();
    final converter = QuillDeltaToHtmlConverter(
      deltaOps,
      ConverterOptions(
        converterOptions: OpConverterOptions(
          inlineStylesFlag: true,
        ),
      ),
    );
    return converter.convert();
  }

  void _quillReset() {
    _quillController.removeListener(_onTextChanged);
    _quillController.dispose();

    quill.QuillController quillController = quill.QuillController.basic();
    quillController.addListener(_onTextChanged);

    setState(() {
      _quillController = quillController;
      _initialQuillDelta = _quillController.document.toDelta();
    });

    _onTextChanged();
  }

  void _quillUpdate() {
    _quillController.removeListener(_onTextChanged);
    _quillController.dispose();

    quill.QuillController quillController = widget.createTextController();
    quillController.addListener(_onTextChanged);

    setState(() {
      _quillController = quillController;
      _initialQuillDelta = _quillController.document.toDelta();
    });

    _onTextChanged();
  }

  void _onTextChanged() {
    Set<_EditBarCommand> selectedCommands = Set<_EditBarCommand>.from(_selectedCommands);

    quill.Style style = _quillController.getSelectionStyle();
    SetUtils.set(selectedCommands, _EditBarCommand.bold, style.attributes.containsKey(quill.Attribute.bold.key));
    SetUtils.set(selectedCommands, _EditBarCommand.italic, style.attributes.containsKey(quill.Attribute.italic.key));
    SetUtils.set(selectedCommands, _EditBarCommand.underline, style.attributes.containsKey(quill.Attribute.underline.key));

    SetUtils.set(selectedCommands, _EditBarCommand.submit, (_initialQuillDelta != _quillController.document.toDelta()));

    if ((DeepCollectionEquality().equals(_selectedCommands, selectedCommands) != true) && mounted) {
      setState(() {
        _selectedCommands = selectedCommands;
      });
    }
  }

  void _onBold() {
    Analytics().logSelect(target: 'Bold');
    _toggleTextFormat(quill.Attribute.bold);
  }

  void _onItalic() {
    Analytics().logSelect(target: 'Italic');
    _toggleTextFormat(quill.Attribute.italic);
  }

  void _onUnderline() {
    Analytics().logSelect(target: 'Underline');
    _toggleTextFormat(quill.Attribute.underline);
  }

  void _onLink() async {
    Analytics().logSelect(target: 'Link');

    TextSelection selection = _quillController.selection;
    String selectedText = _quillController.document.getPlainText(selection.start, selection.end - selection.start,).trim();
    quill.Style selectedStyle = _quillController.document.collectStyle(selection.start, selection.end - selection.start);
    quill.Attribute? selectedLink = selectedStyle.attributes['link'];

    TextEditingController linkTextCtrl = TextEditingController(text: selectedText);
    TextEditingController linkUrlCtrl = TextEditingController(text: selectedLink?.value);

    bool? linkConfirmed = await GroupConversationLinkDialog.show(context, linkTextController: linkTextCtrl, linkUrlController: linkUrlCtrl);

    final linkText = linkTextCtrl.text;
    String linkSourceUrl = linkUrlCtrl.text.trim();
    if ((linkConfirmed == true) && linkText.isNotEmpty && linkSourceUrl.isNotEmpty)  {
      String linkUrl = UrlUtils.fixUrl(linkSourceUrl, scheme: 'https') ?? linkSourceUrl;
      if (selectedText != linkText) {
        _quillController.replaceText(selection.start, selection.end - selection.start, linkText, TextSelection(baseOffset: selection.start, extentOffset: selection.start + linkText.length));
      }
      _quillController.formatText(selection.start, linkText.length, quill.LinkAttribute(linkUrl),);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      linkTextCtrl.dispose();
      linkUrlCtrl.dispose();
    });
  }

  void _onPicture() async {
    Analytics().logSelect(target: 'Picture');
    if (_submitting == false) {
      _GroupConversationAttachmentType? attType = await _GroupConversationAttachSheet.showModal(context,
          availableTypes: <_GroupConversationAttachmentType>{ _GroupConversationAttachmentType.photoOrVideo, _GroupConversationAttachmentType.newPhoto, _GroupConversationAttachmentType.newVideo }
      );

      dynamic media;
      List<dynamic>? mediaList;
      switch (attType) {
        case _GroupConversationAttachmentType.photoOrVideo: mediaList = await ImagePicker().pickMultipleMedia(limit: 10, imageQuality: 60, maxHeight: 1080, maxWidth: 1080); break;
        case _GroupConversationAttachmentType.newPhoto: media = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 60, maxHeight: 1080, maxWidth: 1080); break;
        case _GroupConversationAttachmentType.newVideo: media = await ImagePicker().pickVideo(source: ImageSource.camera); break;
        case _GroupConversationAttachmentType.newAudio: media = await _GroupConversationSoundRecorderDialog.show(context); break;
        case _GroupConversationAttachmentType.file: mediaList = await _GroupConversationFilePicker.pick();
        default: break;
      }
      if (media != null) {
        if (mediaList != null) {
          mediaList.add(media);
        } else {
          mediaList = <dynamic>[media];
        }
      }
      if (mediaList != null) {
        setState(() {
          _attachments.addAll(mediaList ?? []);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) =>
          _attachmentsScrollController.animateTo(_attachmentsScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.linear)
        );
      }
    }
  }


  Widget get _attachmentsList => Container(height: 150, child:
    ListView.separated(
      padding: EdgeInsets.only(top: 16, left: 0, right: 0),
      separatorBuilder: (context, index) => SizedBox(width: 8),
      itemCount: _attachments.length,
      itemBuilder: (context, index) => _attachmentCard(index),
      scrollDirection: Axis.horizontal,
      controller: _attachmentsScrollController,
    ),
  );

  Widget _attachmentCard(int index) => Center(child:
    Stack(children: [
      _GroupConversationAttachmentCard(ListUtils.entry(_attachments, index),),
      if (_submitting == false)
        Positioned.fill(child:
          Align(alignment: Alignment.topRight, child:
            _deleteAttachmentButton(ListUtils.entry(_attachments, index), index)
          ),
        ),
    ],)
  );

  Widget _deleteAttachmentButton(dynamic attachment, int index) =>
    InkWell(onTap: () => _onDeleteAttachment(index), child:
      _deleteAttachmentImage(attachment)
    );

  Widget _deleteAttachmentImage(dynamic attachment) {
    switch(AttachmentFileTypeImpl.fromAttachment(attachment)) {
      case AttachmentFileType.image: return _deletePhotoOrVideoAttachmentImage;
      case AttachmentFileType.video: return _deletePhotoOrVideoAttachmentImage;
      case AttachmentFileType.audio: return _deleteAudioOrFileAttachmentImage;
      case AttachmentFileType.file: return _deleteAudioOrFileAttachmentImage;
      default: return Container();
    }
  }

  Widget get _deletePhotoOrVideoAttachmentImage =>
      Stack(children: [
        Padding(padding: EdgeInsets.only(left: 18, right: 6, top: 10, bottom: 14), child:
          Styles().images.getImage('close-circle', size: 16, color: Styles().colors.black, excludeFromSemantics: true,)
        ),
        Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 16), child:
          Styles().images.getImage('close-circle', size: 16, color: Styles().colors.white, excludeFromSemantics: true,)
        ),
      ],);

  Widget get _deleteAudioOrFileAttachmentImage =>
    Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 16), child:
      Styles().images.getImage('close-circle', size: 16, color: Styles().colors.fillColorSecondary, excludeFromSemantics: true,)
    );

  void _onDeleteAttachment(int index) {
    Analytics().logSelect(target: 'Delete Attachment');
    setState(() {
      ListUtils.remove(_attachments, index);
    });
  }

  void _resetAttachments() {
    setState(() {
      _attachments.clear();
    });
  }

  void _updateAttachments() {
    setState(() {
      _attachments.clear();
      _attachments.addAll(widget.attachments ?? <FileAttachment>[]);
    });
  }

  bool get _canSubmit => (_selectedCommands.contains(_EditBarCommand.submit) || !DeepCollectionEquality().equals(_attachments, widget.attachments?.toList() ?? [])) && (widget.onSubmitMessage != null);
  bool get _hasCancelEdit => (widget.onCancelEdit != null);

  Widget get _submitButton => Event2ImageCommandButton(
    Styles().images.getImage('paper-plane',
      color: _canSubmit ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
      size: _buttonIconSize,
      excludeFromSemantics: true
    ),
    label: Localization().getStringEx('', 'Send'),
    hint: Localization().getStringEx('', 'Tap to send message'),
    contentPadding: _hasCancelEdit ? _firstButtonPadding : _singleButtonPadding,
    onTap: _canSubmit ? _onSubmit : null,
  );

  Widget get _submittingProgress =>
    Padding(padding: _hasCancelEdit ? _firstButtonPadding : _singleButtonPadding, child:
      SizedBox.square(dimension: _buttonIconSize, child:
        CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary),
      )
    );

  Widget get _cancelEditButton => Event2ImageCommandButton(
    Styles().images.getImage('close-circle',
      color: Styles().colors.fillColorSecondary,
      size: _buttonIconSize,
      excludeFromSemantics: true
    ),
    label: Localization().getStringEx('', 'Cancel'),
    hint: Localization().getStringEx('', 'Tap to cancel edit'),
    contentPadding: _lastButtonPadding,
    onTap: _onCancel,
  );

  static const double _buttonIconSize = 16;
  static const double _buttonPaddingH = 12;
  static const double _buttonPaddingV = 8;
  static const EdgeInsetsGeometry _singleButtonPadding = const EdgeInsetsGeometry.symmetric(horizontal: _buttonPaddingH, vertical: _buttonPaddingV);
  static const EdgeInsetsGeometry _firstButtonPadding = const EdgeInsetsGeometry.only(left: _buttonPaddingH, right: _buttonPaddingH / 2, top: _buttonPaddingV, bottom: _buttonPaddingV);
  static const EdgeInsetsGeometry _lastButtonPadding = const EdgeInsetsGeometry.only(left: _buttonPaddingH / 2, right: _buttonPaddingH, top: _buttonPaddingV, bottom: _buttonPaddingV);

  void _onSubmit() async {
    Analytics().logSelect(target: 'Submit');
    if (_canSubmit && !_submitting)
    setState(() {
      _submitting = true;
    });

    bool? succeeded = await widget.onSubmitMessage?.call(_quillHtml, attachments: _attachments);

    if (mounted) {
      setState(() {
        _submitting = false;
      });
      if (succeeded == true) {
        FocusScope.of(context).unfocus();
        _quillReset();
        _resetAttachments();
      }
    }
  }

  void _onCancel() {
    Analytics().logSelect(target: 'Submit');
    widget.onCancelEdit?.call();
  }
}



extension _EditBarCommandImpl on _EditBarCommand {
  String get iconKey {
    switch(this) {
      case _EditBarCommand.bold: return 'bold';
      case _EditBarCommand.italic: return 'italic';
      case _EditBarCommand.underline: return 'underline';
      case _EditBarCommand.link: return 'link-simple';
      case _EditBarCommand.picture: return 'landscape';
      case _EditBarCommand.submit: return 'paper-plane';
    }
  }

  String get accLabel {
    switch(this) {
      case _EditBarCommand.bold: return Localization().getStringEx('', 'Bold');
      case _EditBarCommand.italic: return Localization().getStringEx('', 'Italic');
      case _EditBarCommand.underline: return Localization().getStringEx('', 'Underline');
      case _EditBarCommand.link: return Localization().getStringEx('', 'Link');
      case _EditBarCommand.picture: return Localization().getStringEx('', 'Picture');
      case _EditBarCommand.submit: return Localization().getStringEx('', 'Submit');
    }
  }

  String get accHint {
    switch(this) {
      case _EditBarCommand.bold: return Localization().getStringEx('', 'Tap to toggle bold text style on text selection');
      case _EditBarCommand.italic: return Localization().getStringEx('', 'Tap to toggle italic text style on text selection');
      case _EditBarCommand.underline: return Localization().getStringEx('', 'Tap to toggle underline text style on text selection');
      case _EditBarCommand.link: return Localization().getStringEx('', 'Tap to add or edit hyperlink');
      case _EditBarCommand.picture: return Localization().getStringEx('', 'Tap to add or Picture');
      case _EditBarCommand.submit: return Localization().getStringEx('', 'Tap to send message');
    }
  }
}

class GroupConversationLinkDialog extends StatelessWidget {
  final TextEditingController? linkTextController;
  final TextEditingController? linkUrlController;

  GroupConversationLinkDialog({this.linkTextController, this.linkUrlController});

  static Future<bool?>show(BuildContext context, {TextEditingController? linkTextController, final TextEditingController? linkUrlController}) =>
    showDialog(context: context, builder: (_) => AlertDialog(
      contentPadding: const EdgeInsets.all(24),
      content: GroupConversationLinkDialog(linkTextController: linkTextController, linkUrlController: linkUrlController),
    ));

  @override
  Widget build(BuildContext context) =>
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Localization().getStringEx('panel.group.detail.post.create.dialog.link.edit.header', 'Edit Link',),
        style: Styles().textStyles.getTextStyle('widget.group.input_field.heading'),
      ),
      Padding(padding: const EdgeInsets.only(top: 16), child:
        Text(Localization().getStringEx('panel.group.detail.post.create.dialog.link.text.label', 'Link Text:',),
          style: Styles().textStyles.getTextStyle('widget.group.input_field.detail'),
        ),
      ),
      Padding(padding: const EdgeInsets.only(top: 6), child:
        TextField(controller: linkTextController, maxLines: 1, decoration: _textInputDecoration,
          style: Styles().textStyles.getTextStyle('widget.input_field.text.regular'),
        ),
      ),
      Padding(padding: const EdgeInsets.only(top: 16), child:
        Text(Localization().getStringEx('panel.group.detail.post.create.dialog.link.url.label', 'Link URL:', ),
          style: Styles().textStyles.getTextStyle('widget.group.input_field.detail'),
        ),
      ),
      Padding(padding: const EdgeInsets.only(top: 6), child:
        TextField(controller: linkUrlController, maxLines: 1, decoration: _textInputDecoration,
          style: Styles().textStyles.getTextStyle('widget.input_field.text.regular'),
        ),
      ),
      Padding(padding: const EdgeInsets.only(top: 24), child:
        Row(children: [
          Expanded(flex: 1, child: Container()),
          Expanded(flex: 10, child:
            CompactRoundedButton(label: Localization().getStringEx('dialog.cancel.title', 'Cancel'), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), onTap: () {
              Analytics().logSelect(target: 'Cancel');
              Navigator.of(context).pop(false);
            },),
          ),
          Expanded(flex: 2, child: Container()),
          Expanded(flex: 10, child:
            CompactRoundedButton(label: Localization().getStringEx('dialog.ok.title', 'OK'), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), onTap: () {
              Analytics().logSelect(target: 'Set Link Url');
              Navigator.of(context).pop(true);
            },),
          ),
          Expanded(flex: 1, child: Container()),
        ],)
      )
    ],);

  InputDecoration get _textInputDecoration => InputDecoration(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Styles().colors.mediumGray, width: 0.0,),
      ),
  );
}

class _GroupConversationAttachmentCard extends StatelessWidget {
  final dynamic attachment;
  _GroupConversationAttachmentCard(this.attachment, );

  @override
  Widget build(BuildContext context) =>
    Stack(children: [
      _attachmentWidget
    ],);

  Widget get _attachmentWidget {
    switch(AttachmentFileTypeImpl.fromAttachment(attachment)) {
      case AttachmentFileType.image: return AspectRatio(aspectRatio: 1/1, child: _imageAttachmentWidget);
      case AttachmentFileType.video: return AspectRatio(aspectRatio: 1/1, child: _videoAttachmentWidget);
      case AttachmentFileType.audio: return _GroupConversationAttachmentContainer(child:_audioAttachmentWidget);
      case AttachmentFileType.file: return _GroupConversationAttachmentContainer(child:_fileAttachmentWidget);
      default: return Container();
    }
  }

  Widget get _imageAttachmentWidget =>
    _imageAttachmentWidgetImpl(attachment);

  static Widget _imageAttachmentWidgetImpl(dynamic attachment) {
    AttachmentDetails? details =  AttachmentDetails.fromAttachment(attachment);
    if (details?.data != null) {
      return Image.memory(details?.data ?? Uint8List(0), fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageErrorBuilder,
      );
    } else if (details?.url != null) {
      return Image.network(details?.url ?? '', fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) => (loadingProgress != null) ?
          _imageProgressBuilder(loadingProgress) : child,
        errorBuilder: (context, error, stackTrace) => _imageErrorBuilder,
      );
    } else if (details?.path != null) {
      if (kIsWeb) {
        return Image.network(details?.path ?? '', fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) => (loadingProgress != null) ?
            _imageProgressBuilder(loadingProgress) : child,
          errorBuilder: (context, error, stackTrace) => _imageErrorBuilder,
        );
      } else {
        return Image.file(File(details?.path ?? ''), fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _imageErrorBuilder,
        );
      }
    } else {
      return const SizedBox();
    }
  }

  Widget get _videoAttachmentWidget => _videoAttachmentWidgetImpl(attachment);

  static Widget _videoAttachmentWidgetImpl(dynamic attachment) {
    AttachmentDetails? details =  AttachmentDetails.fromAttachment(attachment);
    return VideoPlayerWidget(key: ValueKey(details?.path ?? details?.url),
      filePath: details?.path, url: details?.url, showControls: false, muted: true, fill: true, interactive: false);
  }

  Widget get _audioAttachmentWidget {
    AttachmentDetails? details = AttachmentDetails.fromAttachment(attachment);
    return AudioPlayerWidget(url: details?.url, bytes: details?.data);
  }

  Widget get _fileAttachmentWidget {
    String? textStyleKey = 'widget.title.dark.small'; // 'widget.title.small' inMessage: 'widget.title.dark.small';
    AttachmentDetails? details = AttachmentDetails.fromAttachment(attachment);
    return Center(child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsetsGeometry.only(top: 4), child:
          Styles().images.getImage('file', size: 24) ?? Container(height: 24),
        ),
        SizedBox(width: 8),
        Expanded(child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(details?.name ?? '', style: Styles().textStyles.getTextStyle(textStyleKey), overflow: TextOverflow.ellipsis,),
            if ((details?.extension != null) && (details?.extension?.isNotEmpty == true))
              Text(details?.extension?.toUpperCase() ?? '', style: Styles().textStyles.getTextStyle(textStyleKey),),
          ],),
        ),
      ]),);
  }

  static Widget get _imageErrorBuilder => AspectRatio(aspectRatio: 16/9, child:
    Container(color: Styles().colors.surfaceAccent, child:
      Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child:
        Center(child: Styles().images.getImage('exclamation', size: 48),
          // Text(Localization().getStringEx('', 'This image type is not supported'),
          //     style: Styles().textStyles.getTextStyle('widget.title.dark.small')),
        ),
      ),
    )
  );

  static Widget _imageProgressBuilder(ImageChunkEvent loadingProgress) =>
    Container(color: Styles().colors.surfaceAccent, child:
      Center(child:
        CircularProgressIndicator(
          color: Styles().colors.fillColorSecondary,
          value: (loadingProgress.expectedTotalBytes != null) ? (loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!) : null,
        ),
      ),
    );

}

class _GroupConversationAttachmentContainer extends StatelessWidget {
  final Widget? child;
  final Size size;

  _GroupConversationAttachmentContainer({this.child, this.size = const Size(200, 80)}); // ignore: unused_element_parameter

  @override
  Widget build(BuildContext context) =>
    Container(width: size.width, height: size.height, padding: _widgetPadding, decoration: _widgetDecoration, child:
      child,
    );

  EdgeInsetsGeometry get _widgetPadding => EdgeInsets.all(8);

  BoxDecoration get _widgetDecoration => BoxDecoration(
    color: Styles().colors.background, //Styles().colors.backgroundVariant, // inMessage: Styles().colors.surfaceAccent
    border: Border.all(color: Styles().colors.mediumGray, width: 1),
    borderRadius: BorderRadius.circular(8),
  );
}


enum _GroupConversationAttachmentType { photoOrVideo, newPhoto, newVideo, newAudio, file}

class _GroupConversationAttachSheet extends StatelessWidget {

  final Set<_GroupConversationAttachmentType>? availableTypes;

  _GroupConversationAttachSheet({this.availableTypes});
  
  static Future<_GroupConversationAttachmentType?> showModal(BuildContext context, { Set<_GroupConversationAttachmentType>? availableTypes }) =>
    showModalBottomSheet(
    context: context,
    backgroundColor: Styles().colors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),),
    isScrollControlled: true,
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    //constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9, minHeight: MediaQuery.of(context).size.height * 0.3),
    builder: (context) => _GroupConversationAttachSheet(availableTypes: availableTypes,),
  );

  @override
  Widget build(BuildContext context) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      _headerBar(context),
      Padding(padding: EdgeInsets.only(left: 16.0, right: 16, bottom: 16), child:
        _commandsList(context),
      ),
    ],);

  Widget _headerBar(BuildContext context) => Row(children: [
    Expanded(child:
      Padding(padding: EdgeInsets.only(left: 16), child:
        Text(Localization().getStringEx('panel.messages.conversation.attach_files.header.label', 'Attach Files'),
          style: Styles().textStyles.getTextStyle("widget.label.medium.fat"),
        ),
      ),
    ),
    Semantics(
      label: Localization().getStringEx('dialog.close.title', 'Close'),
      hint: Localization().getStringEx('dialog.close.hint', ''),
      inMutuallyExclusiveGroup: true,
      button: true,
      child: InkWell(onTap: () => _onTapClose(context), child:
        Padding(padding: EdgeInsets.all(16), child:
          Styles().images.getImage('close-circle', excludeFromSemantics: true),
        ),
      ),
    ),
  ],);

  Widget _commandsList(BuildContext context) => Column(children:
    List.from(_GroupConversationAttachmentType.values.where((type) => (availableTypes?.contains(type) != false)).map((attType) => _commandListEntry(context, attType)))
  );

  Widget _commandListEntry(BuildContext context, _GroupConversationAttachmentType attType) =>
    Padding(padding: EdgeInsetsGeometry.only(top: 4), child:
      RibbonButton(
        title: attType.commandTitle,
        leftIconKey: attType.commandIconKey,
        onTap: () => _onTapCommand(context, attType)
      )
    );

  void _onTapCommand(BuildContext context, _GroupConversationAttachmentType command) {
    Analytics().logSelect(target: 'Close');
    Navigator.of(context).pop(command);
  }

  void _onTapClose(BuildContext context) {
    Analytics().logSelect(target: 'Close');
    Navigator.of(context).pop(null);
  }
}

extension _GroupConversationAttachmentTypeImpl on _GroupConversationAttachmentType {
  String get commandTitle {
    switch (this) {
      case _GroupConversationAttachmentType.photoOrVideo: return Localization().getStringEx('panel.messages.conversation.select.image_video.button.label', 'Upload an image or video');
      case _GroupConversationAttachmentType.newPhoto: return Localization().getStringEx('panel.messages.conversation.select.image.button.label', 'Take a photo');
      case _GroupConversationAttachmentType.newVideo: return Localization().getStringEx('panel.messages.conversation.select.video.button.label', 'Record a video');
      case _GroupConversationAttachmentType.newAudio: return Localization().getStringEx('panel.messages.conversation.select.audio.button.label', 'Record an audio clip');
      case _GroupConversationAttachmentType.file: return Localization().getStringEx('panel.messages.conversation.select.file.button.label', 'Upload a file');
    }
  }

  String get commandIconKey {
    switch (this) {
      case _GroupConversationAttachmentType.photoOrVideo: return 'image';
      case _GroupConversationAttachmentType.newPhoto: return 'camera';
      case _GroupConversationAttachmentType.newVideo: return 'video-camera';
      case _GroupConversationAttachmentType.newAudio: return 'microphone';
      case _GroupConversationAttachmentType.file: return 'file';
    }
  }
}

class _GroupConversationSoundRecorderDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Material(type: MaterialType.transparency, borderRadius: BorderRadius.all(Radius.circular(5)), child:
      ProfileSoundRecorderDialog(onSave: (audio, extension) async => ((audio != null) && audio.isNotEmpty) ?
        AudioResult.succeed(audioData: audio, extension: extension) : AudioResult.error(AudioErrorType.fileNameNotSupplied, 'Missing file.')),
    );

  static Future<AudioResult?> show(BuildContext context) =>
    showDialog<AudioResult?>(context: context, builder: (_) => _GroupConversationSoundRecorderDialog());
}

class _GroupConversationFilePicker {
  static Future<List<PlatformFile>?> pick() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
      dialogTitle: Localization().getStringEx("panel.messages.conversation.attach_files.message", "Select file(s) to upload"),
    );
    return result?.files;
  }

}

class GroupConversationConfirmDeleteDialog extends StatelessWidget {
  final String? statement1;
  final String? statement2;

  GroupConversationConfirmDeleteDialog({this.statement1, this.statement2});

  static Future<bool?>show(BuildContext context, [String? statement1, String? statement2]) =>
    showDialog(context: context, builder: (_) => AlertDialog(
      contentPadding: const EdgeInsets.all(24),
      content: GroupConversationConfirmDeleteDialog(statement1: statement1, statement2: statement2),
    ));

  @override
  Widget build(BuildContext context) =>
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
      if (statement1?.isNotEmpty == true)
        Text(statement1 ?? '', style: Styles().textStyles.getTextStyle('widget.detail.regular'),),
      if (statement2?.isNotEmpty == true)
        Text(statement2 ?? '', style: Styles().textStyles.getTextStyle('widget.detail.regular'),),
      Padding(padding: const EdgeInsets.only(top: 24), child:
        Row(children: [
          Expanded(flex: 1, child: Container()),
          Expanded(flex: 10, child:
            CompactRoundedButton(label: Localization().getStringEx('dialog.cancel.title', 'Cancel'), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), onTap: () {
              Analytics().logSelect(target: 'Cancel');
              Navigator.of(context).pop(false);
            },),
          ),
          Expanded(flex: 2, child: Container()),
          Expanded(flex: 10, child:
            CompactRoundedButton(label: Localization().getStringEx('dialog.delete.title', 'Delete'), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), onTap: () {
              Analytics().logSelect(target: 'Delete');
              Navigator.of(context).pop(true);
            },),
          ),
          Expanded(flex: 1, child: Container()),
        ],)
      )
    ],);

}

enum GroupConversationCreateOption { groupMessage, individualMessages }

class GroupConversationCreateOptionsDialog extends StatelessWidget {

  GroupConversationCreateOptionsDialog();

  static Future<GroupConversationCreateOption?>show(BuildContext context, ) =>
    showDialog(context: context, builder: (_) => AlertDialog(
      content: GroupConversationCreateOptionsDialog(),
      contentPadding: const EdgeInsets.only(bottom: 24),
    ));

  @override
  Widget build(BuildContext context) =>
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Align(alignment: Alignment.centerRight, child:
        _closeButton(context),
      ),
      Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 32), child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(Localization().getStringEx('', 'How would you like to send this message?'), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.detail.regular'),),
          SizedBox(height: 24,),
          RoundedButton(
            label: Localization().getStringEx('', 'Send as a Group Message'),
            textStyle: Styles().textStyles.getTextStyle('widget.button.title.medium.fat'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            borderWidth: 1.5,
            onTap: () {
              Analytics().logAlert(text: 'How would you like to send this message?', selection: 'Send as a Group Message');
              Navigator.of(context).pop(GroupConversationCreateOption.groupMessage);
            },),
          SizedBox(height: 8,),
          RoundedButton(
            label: Localization().getStringEx('', 'Send as Individual Messages'),
            textStyle: Styles().textStyles.getTextStyle('widget.button.title.medium.fat'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            borderWidth: 1.5,
            onTap: () {
              Analytics().logAlert(text: 'How would you like to send this message?', selection: 'Send as Individual Messages');
              Navigator.of(context).pop(GroupConversationCreateOption.individualMessages);
          },),
        ],)
      )
    ],);

  Widget _closeButton(BuildContext context) =>
    Semantics(label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
      InkWell(onTap : () => _onTapClose(context), child:
        Padding(padding: EdgeInsets.all(16), child:
          Styles().images.getImage('close-circle', excludeFromSemantics: true),
        ),
      ),
    );

  void _onTapClose(BuildContext context) {
    Analytics().logAlert(text: 'How would you like to send this message?', selection: 'Close');
    Navigator.of(context).pop();
  }
}

class GroupConversationReportBroadcastIndividualDialog extends StatelessWidget {

  GroupConversationReportBroadcastIndividualDialog();

  static Future<GroupConversationCreateOption?>show(BuildContext context, ) =>
    showDialog(context: context, builder: (_) => AlertDialog(
      content: GroupConversationReportBroadcastIndividualDialog(),
      contentPadding: const EdgeInsets.only(bottom: 48),
    ));

  @override
  Widget build(BuildContext context) =>
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Align(alignment: Alignment.centerRight, child:
        _closeButton(context),
      ),
      Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 32), child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Styles().images.getImage('paper-plane') ?? Container(),
          SizedBox(height: 8,),
          Text(Localization().getStringEx('', 'Your message has been sent to each group member individually.'), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.detail.regular'),),
        ],)
      )
    ],);

  Widget _closeButton(BuildContext context) =>
    Semantics(label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
      InkWell(onTap : () => _onTapClose(context), child:
        Padding(padding: EdgeInsets.all(16), child:
          Styles().images.getImage('close-circle', excludeFromSemantics: true),
        ),
      ),
    );

  void _onTapClose(BuildContext context) {
    Analytics().logAlert(text: 'How would you like to send this message?', selection: 'Close');
    Navigator.of(context).pop();
  }
}