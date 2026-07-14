import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/parser/html_to_delta.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/ext/Social.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
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

  GroupConversationCard(this.conversation, { this.groupAdmins, this.onTap });

  @override
  Widget build(BuildContext context) =>
    InkWell(onTap: onTap, child:
      Container(decoration: _cardDecoration, padding: _cardPadding, child:
        Row(children: [
          GroupConversationAvtarWidget(conversation.members),
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
    int participantsCount = conversation.members?.length ?? 0;
    if (1 < participantsCount) {
      return _participantNamesWidget;
    } else if (0 < participantsCount) {
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

  Widget get _participantNamesWidget => Text(conversation.membersString ?? '',
    textAlign: TextAlign.left,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    style: Styles().textStyles.getTextStyle('widget.card.title.small.fat')
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

  final List<ConversationMember>? participants;

  GroupConversationAvtarWidget(this.participants);

  int get _participantsCount => participants?.length ?? 0;

  @override
  Widget build(BuildContext context) =>
    Container(width: widgetSize, height: widgetSize, decoration: _avtarDecoration, child: _participantsIcon);

  /*Widget build(BuildContext context) {
    return Container(width: _widgetSize, height: _widgetSize, decoration: _avtarDecoration, child:
      Stack(children: [
        Positioned.fill(child:
          Align(alignment: Alignment.topLeft, child:
            Padding(padding: EdgeInsets.only(left: _avtarOffset, top: _avtarOffset,), child:
              Container(width: _avtarSize, height: _avtarSize, decoration: _participantDecoration(Colors.blueAccent)),
            )
          )
        ),
        Positioned.fill(child:
          Align(alignment: Alignment.bottomRight, child:
            Padding(padding: EdgeInsets.only(right: _avtarOffset, bottom: _avtarOffset,), child:
              Container(width: _avtarSize, height: _avtarSize, decoration: _participantDecoration(Colors.yellowAccent)),
            )
          )
        ),
        Positioned.fill(child:
          Align(alignment: Alignment.bottomLeft, child:
            Padding(padding: EdgeInsets.only(left: _avtar2Offset, bottom: _avtar2Offset,), child:
              Container(width: _avtar2Size, height: _avtar2Size, decoration: _participantDecoration(Colors.greenAccent)),
            )
          )
        ),
      ],)
    );
  }*/

  Widget? get _participantsIcon {
    if (_participantsCount > 1) {
      return _multipleParticipantsIcon;
    } else if (_participantsCount == 1) {
      return _singleParticipantIcon;
    } else {
      return null;
    }
  }

  Widget get _singleParticipantIcon =>
    DirectoryProfilePhoto(
      photoUrl: Content().getUserPhotoUrl(
        type: UserProfileImageType.medium,
        accountId: participants?.firstOrNull?.accountId,
        //params: DirectoryProfilePhotoUtils.tokenUrlParam(_photoImageToken),
      ),
      photoSize: widgetSize,
      photoUrlHeaders: DirectoryProfilePhotoUtils.authHeaders,
    );

  Widget get _multipleParticipantsIcon {
    ConversationMember? participant1 = ListUtils.entry(participants, 0);
    ConversationMember? participant2 = ListUtils.entry(participants, 1);
    ConversationMember? participant3 = ListUtils.entry(participants, 2);

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

  BoxDecoration get _avtarDecoration => BoxDecoration(
    color: Styles().colors.textBackgroundVariant2,
    shape: BoxShape.circle,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
  );

}

class GroupConversationHeader extends StatefulWidget {
  final Group? group;
  final List<Member>? groupAdmins;
  final Conversation conversation;

  GroupConversationHeader(this.conversation, {this.group, this.groupAdmins});

  @override
  State<StatefulWidget> createState() => _GroupConversationHeaderState();
}

class _GroupConversationHeaderState extends State<GroupConversationHeader> {

  bool _deleteProgress = false;

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _headingDecoration, child: _multipleMembers ?
      _multipleMembersDropdown : _singleMemberWidget
    );

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

  List<DropdownMenuItem<String>> _buildDropdownMembers() => List.from(widget.conversation.members?.sorted(ConversationMemberExt.compareNames).map((member) => _buildDropdownMemberItem(member)) ?? []);

  DropdownMenuItem<String> _buildDropdownMemberItem(ConversationMember member) =>
    DropdownMenuItem<String>(value: member.accountId ?? '', child:
      Container(decoration: _dropdownMemberDecoration, child:
        Row(children: [
          _buildAvtarWidget([member]),
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

  Widget get _avtarWidget => _buildAvtarWidget(widget.conversation.members);

  Widget _buildAvtarWidget(List<ConversationMember>? members) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: _avtarSpacing * 2, vertical: _avtarSpacing), child:
      GroupConversationAvtarWidget(members),
    );

  double get _avtarSpacing => 8;

  // Name

  Widget get _participantNameWidget => _buildParticipantNameWidget(widget.conversation.members?.firstOrNull,
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

  Widget get _participantNamesWidget => Text(widget.conversation.membersString ?? '',
    textAlign: TextAlign.left,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    style: Styles().textStyles.getTextStyle('widget.card.title.small.fat')
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

  bool get _multipleMembers => (1 < (widget.conversation.members?.length ?? 0));
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
        bool? result = await Social().deleteConverstion(conversationId: widget.conversation.id ?? '');
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
  final bool commandProgress;
  final AnalyticsFeature? analyticsFeature;

  GroupConversationMessageCard(this.message, { this.conversation, this.group, this.groupMember, this.onCommand, this.commandProgress = false, this.analyticsFeature });

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _cardDecoration, child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        GroupConversationMessageHeader(message, conversation: conversation, group: group, groupMember: groupMember, onCommand: onCommand, commandProgress: commandProgress),
        Padding(padding: EdgeInsets.symmetric(horizontal: _horzPadding), child:
          SelectionArea(child:
            _bodyHtmlWidget,
          ),
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: _horzPadding, vertical: _horzPadding), child:
          GroupReactionsLayout(group: group, entityId: message.id, reactionSource: SocialEntityType.post, analyticsFeature: analyticsFeature,)
        ),
      ],)
    );

  /* Widget get _bodyTextWidget => LinkTextEx(
    message.message ?? '',
    textStyle: Styles().textStyles.getTextStyle('widget.detail.regular'),
    linkStyle: Styles().textStyles.getTextStyleEx('widget.detail.regular.underline', decorationColor: Styles().colors.fillColorPrimary),
    onLinkTap: _onTapLink,
  ); */

  Widget get _bodyHtmlWidget => HtmlWidget(
      "<div style= $_bodyHtmlStyle> ${message.message ?? ''}</div>",
      onTapUrl : (url) { _onTapLink(url); return true; },
      textStyle:  Styles().textStyles.getTextStyle("widget.detail.regular"),
      customStylesBuilder: (element) => (element.localName == "a") ? { "color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null,
  );

  String get _bodyHtmlStyle => 'white-space: normal'; // 'text-overflow: ellipsis; max-lines: 3'

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

  GroupConversationMessageHeader(this.message, { this.conversation, this.group, this.groupMember, this.onCommand, this.commandProgress = false });

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
    photoSize: _photoSize,
    photoUrlHeaders: DirectoryProfilePhotoUtils.authHeaders,
  );

  String? get _avtarPhotoUrl => (message.sender?.accountId?.isNotEmpty == true) ?
    Content().getUserPhotoUrl(accountId: message.sender?.accountId, type: UserProfileImageType.medium,) : null;

  Widget get _commandButton => Event2ImageCommandButton(
    Styles().images.getImage('more', size: _buttonIconSize, excludeFromSemantics: true),
    label: Localization().getStringEx('', 'Commands'),
    hint: Localization().getStringEx('', ''),
    contentPadding: EdgeInsets.all(_buttonPadding),
    onTap: onCommand,
  );

  Widget get _commandProgressIndicator => Padding(padding: EdgeInsets.all(_buttonPadding + 2), child:
    SizedBox.square(dimension: _buttonIconSize - 2, child:
      CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary),
    )
  );

  static const double _horzPadding = GroupConversationMessageCard._horzPadding;
  static const double _vertPadding = GroupConversationMessageCard._vertPadding;
  static const double _buttonPadding = _vertPadding;
  static const double _buttonIconSize = 18;
  static const double _photoSize = 36;
}

class GroupConversationMessageEditBar extends StatefulWidget {
  final Future<bool> Function(String message)? onSendMessage;

  final String? title;

  final String? text;
  final String? hint;
  final TextStyle? textStyle;
  final TextStyle? linkTextStyle;

  final int minLines;
  final int maxLines;
  final bool autofocus;

  final EdgeInsetsGeometry padding;

  GroupConversationMessageEditBar({ required this.onSendMessage,
    this.title,
    this.text, this.hint, this.textStyle, this.linkTextStyle, // ignore: unused_element_parameter
    this.minLines = 1, this.maxLines = 12, this.autofocus = false, // ignore: unused_element_parameter
    this.padding = const EdgeInsetsGeometry.only(left: 24, right: 16, top: 8, bottom: 24), // ignore: unused_element_parameter
  });

  quill.Document get textDocument {
    try { return quill.Document.fromDelta(HtmlToDelta().convert(text ?? '')); }
    catch(e) { return quill.Document()..insert(0, text ?? ''); }
  }

  @override
  State<StatefulWidget> createState() => _GroupConversationMessageEditBarState();
}

enum _EditBarCommand { bold, italic, underline, link, submit, picture }

class _GroupConversationMessageEditBarState extends State<GroupConversationMessageEditBar> {

  late quill.QuillController _quillController;
  late Delta _initialQuillDelta;
  late FocusNode _focusNode;
  late TextStyle _textStyle;
  late TextStyle _linkTextStyle;
  Set<_EditBarCommand> _selectedCommands = <_EditBarCommand>{};
  bool _submitting = false;

  @override
  void initState() {
    _quillController = (widget.text?.isNotEmpty == true) ? quill.QuillController(
      document: widget.textDocument,
      selection: const TextSelection.collapsed(offset: 0),
    ) : quill.QuillController.basic();
    _quillController.addListener(_onTextChanged);
    _initialQuillDelta = _quillController.document.toDelta();
    _focusNode = FocusNode();
    _textStyle = widget.textStyle ?? Styles().textStyles.getTextStyle('widget.message.regular') ?? _defaultTextStyle;
    _linkTextStyle = widget.linkTextStyle ?? _textStyle.apply(color: _linkTextColor, decoration: TextDecoration.underline, decorationColor: _linkTextColor);
    super.initState();
  }

  @override
  void dispose() {
    _quillController.removeListener(_onTextChanged);
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    Padding(padding: widget.padding, child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        _commandBar,
        Padding(padding: EdgeInsetsGeometry.only(right: 8), child: _textBar),
      ],),
    );

  Widget get _textBar =>
      Container(decoration: _textDecoration, child:
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child:
            Padding(padding: _textPadding, child:
              quill.QuillEditor.basic(
                controller: _quillController,
                focusNode: _focusNode,
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
          _submitButton,
          // _submitting ? _submittingProgress : _submitButton,
        ],)
      );

  Widget get _submitButton => Event2ImageCommandButton(
    Styles().images.getImage('paper-plane',
      color: _canSubmit ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
      size: _buttonIconSize,
      excludeFromSemantics: true
    ),
    label: Localization().getStringEx('', 'Send'),
    hint: Localization().getStringEx('', 'Tap to send message'),
    contentPadding: _buttonPadding,
    onTap: _canSubmit ? _onSubmit : null,
  );

  /* Widget get _submittingProgress => Padding(padding: _buttonPadding, child:
    SizedBox.square(dimension: 18, child:
      CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary),
    )
  ); */

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
        _formatButton(_EditBarCommand.picture, onTap: _onPicture),
      ],),
    )
  ],);

  Widget _formatButton(_EditBarCommand command, { void Function()? onTap }) =>
      Event2ImageCommandButton(
        _formatButtonImage(command),
        label: command.accLabel,
        hint: command.accHint,
        contentPadding: _buttonPadding,
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

  static const double _buttonIconSize = 16;
  static const EdgeInsetsGeometry _buttonPadding = const EdgeInsetsGeometry.symmetric(horizontal: 12, vertical: 8);

  bool _hasTextFormat(quill.Attribute attribute) =>
    _quillController.getSelectionStyle().attributes.containsKey(attribute.key);

  void _toggleTextFormat(quill.Attribute attribute) =>
    _quillController.formatSelection(
      _hasTextFormat(attribute) ? quill.Attribute.clone(attribute, null) : attribute,
    );

  bool get _canSubmit => _selectedCommands.contains(_EditBarCommand.submit) && (widget.onSendMessage != null);

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
    setState(() {
      _quillController.removeListener(_onTextChanged);
      _quillController.dispose();

      _quillController = quill.QuillController.basic();
      _quillController.addListener(_onTextChanged);

      _initialQuillDelta = _quillController.document.toDelta();
    });
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

  void _onPicture() {
    Analytics().logSelect(target: 'Picture');
  }

  void _onSubmit() async {
    Analytics().logSelect(target: 'Submit');
    if (_canSubmit && !_submitting)
    setState(() {
      _submitting = true;
    });

    bool? succeeded = await widget.onSendMessage?.call(_quillHtml);

    if (mounted && (succeeded == true)) {
      _quillReset();
    }
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