import 'dart:math';

import 'package:collection/collection.dart';
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
import 'package:rokwire_plugin/service/styles.dart';
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
  static const double _widgetSize = 48;

  static const double _avtarSize = _widgetSize / 2;
  static const double _avtarOffset = _avtarSize * (sqrt2 - 1) / (2 * sqrt2) - 1;

  static const double _avtar2Size = _avtarSize * 2 / 3;
  static const double _avtar2Offset = _avtarOffset + 1.5;

  final List<ConversationMember>? participants;

  GroupConversationAvtarWidget(this.participants);

  int get _participantsCount => participants?.length ?? 0;

  @override
  Widget build(BuildContext context) =>
    Container(width: _widgetSize, height: _widgetSize, decoration: _avtarDecoration, child: _participantsIcon);

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
      photoSize: _widgetSize,
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

class GroupConversationHeader extends StatelessWidget {
  final Group? group;
  final List<Member>? groupAdmins;
  final Conversation conversation;
  final void Function()? onDelete;

  GroupConversationHeader(this.conversation, {this.group, this.groupAdmins, this.onDelete});

  @override
  Widget build(BuildContext context) => Container(decoration: _headingDecoration, child:
    Row(children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
        GroupConversationAvtarWidget(conversation.members),
      ),

      Expanded(child:
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          _titleWidget,
        )
      ),

      _deleteButton,
    ],),
  );

  Widget get _titleWidget {
    int participantsCount = conversation.members?.length ?? 0;
    if (1 < participantsCount) {
      return _participantNamesWidget;
    }
    else if (0 < participantsCount) {
      return _participantNameWidget;
    }
    else {
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
      TextSpan(style: Styles().textStyles.getTextStyle('widget.title.large.fat'), children: ((fullName != null) && fullName.isNotEmpty) ? [
        TextSpan(text: fullName),
        if ((memberStatus != null) && memberStatus.isNotEmpty) ...[
          TextSpan(text: ' '),
          TextSpan(text: memberStatus.toUpperCase(), style: Styles().textStyles.getTextStyleEx('widget.title.light.tiny.fat', color: memberColor)),
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

  Widget get _deleteButton => Event2ImageCommandButton(
    Styles().images.getImage('trash', excludeFromSemantics: true),
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

class GroupConversationMessageCard extends StatelessWidget {
  final Message message;
  final Conversation? conversation;
  final Group? group;
  final Member? groupMember;
  final AnalyticsFeature? analyticsFeature;

  GroupConversationMessageCard(this.message, { this.conversation, this.group, this.groupMember, this.analyticsFeature });

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _cardDecoration, child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        GroupConversationMessageHeader(message, conversation: conversation, group: group, groupMember: groupMember, onCommands: null,),
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
  final void Function()? onCommands;

  GroupConversationMessageHeader(this.message, { this.conversation, this.group, this.groupMember, this.onCommands });

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
    _commandsButton,
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

  Widget get _commandsButton => Event2ImageCommandButton(
    Styles().images.getImage('more', excludeFromSemantics: true),
    label: Localization().getStringEx('', 'Commands'),
    hint: Localization().getStringEx('', ''),
    contentPadding: EdgeInsets.all(_vertPadding),
    onTap: onCommands,
  );

  static const double _horzPadding = GroupConversationMessageCard._horzPadding;
  static const double _vertPadding = GroupConversationMessageCard._vertPadding;
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
    this.padding = const EdgeInsetsGeometry.only(left: 24, right: 16, bottom: 24), // ignore: unused_element_parameter
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

  void _onLink() {
    Analytics().logSelect(target: 'Link');
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