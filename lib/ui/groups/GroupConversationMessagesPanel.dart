
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/parser/html_to_delta.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/ext/Social.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkTextEx.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class GroupConversationMessagesPanel extends StatefulWidget {
  final Group? group;
  final List<Member>? groupAdmins;
  final Conversation conversation;
  final AnalyticsFeature? analyticsFeature;

  GroupConversationMessagesPanel(this.conversation, { super.key, this.group, this.groupAdmins, this.analyticsFeature });

  @override
  State<StatefulWidget> createState() => _GroupConversationMessagesPanelState();
}

class _GroupConversationMessagesPanelState extends State<GroupConversationMessagesPanel> {

  ScrollController _scrollController = ScrollController();

  List<Message>? _contentList;
  ContentActivity? _contentActivity;
  bool? _lastPageLoadedAll;
  static const int _contentPageLength = 8;

  @override
  void initState() {
    _scrollController.addListener(_scrollListener);
    _reloadContent();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>  Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx('', 'Message')),
    body: _bodyWidget,
    backgroundColor: Styles().colors.background,
  );

  Widget get _bodyWidget {
    if (_contentActivity == ContentActivity.reload) {
      return _loadingContent;
    }
    else if (_contentActivity == ContentActivity.refresh) {
      return Container();
    }
    else if (_contentList == null) {
      return _buildMessageContent(Localization().getStringEx('', 'Failed to load messages'),
        title: Localization().getStringEx('common.label.failed', 'Failed')
      );
    }
    else {
      return _messagesContent;
    }
  }

  Widget get _messagesContent => Column(children: [
    _GroupConversationHeader(widget.conversation, group: widget.group, onDelete: _onDeleteConversation,),
    Expanded(child:
      RefreshIndicator(onRefresh: _onRefresh, child:
        SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
          _listContent,
        )
      )
    ),
    _GroupConversationMessageEditBar(
      title: Localization().getStringEx('', 'REPLY'),
    ),
  ],);

  Widget get _listContent {
    List<Widget> cardsList = <Widget>[];

    if (_contentActivity == ContentActivity.extend) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 16 : 0), child:
        _extendingIndicator
      ));
    }

    int messagesStart = cardsList.length;
    List<Message> messages = ListUtils.from(_contentList?.reversed) ?? [];
    for (Message message in messages) {
      bool isCurrentUserSender = message.sender?.accountId == Auth2().accountId;
      EdgeInsetsGeometry cardPadding = EdgeInsets.only(top: (cardsList.length > messagesStart) ? 16 : 0, left: isCurrentUserSender ? 0 : _cardOffset, right: isCurrentUserSender ? _cardOffset : 0);
      cardsList.add(Padding(padding: cardPadding, child:
        _GroupConversationMessageCard(message,
          conversation: widget.conversation,
          group: widget.group,
          adminSender: MemberExt.getMember(widget.groupAdmins, userId: message.sender?.accountId),
          analyticsFeature: widget.analyticsFeature,
        ),
      ),);
    }

    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child:
      Column(children:  cardsList,)
    );
  }

  Widget _buildMessageContent(String message, { String? title }) => Center(child:
    Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
          Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
      ],),
    )
  );

  Widget get _loadingContent => Center(child:
    Padding(padding: EdgeInsets.symmetric(vertical: _screenHeight / 4), child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary,)
      )
    )
  );

  Widget get _extendingIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        CircularProgressIndicator(strokeWidth: 3, color: Styles().colors.fillColorSecondary),
      ),
    ),
  );

  double get _screenHeight => MediaQuery.of(context).size.height;
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _cardOffset => (_screenWidth - 32) / 8;

  // Content Management

  bool? get _hasMoreContent => (_lastPageLoadedAll != false);
  int get _listSafeContentLength => _contentList?.length ?? 0;
  int get _refreshContentLength => max(_listSafeContentLength, _contentPageLength);

  Future<void> _reloadContent({ int limit = _contentPageLength }) async {
    if ((_contentActivity != ContentActivity.reload) && mounted) {
      setState(() {
        _contentActivity = ContentActivity.reload;
      });

      List<Message>? contentList = await Social().loadConversationMessages(
        conversationId: widget.conversation.id ?? '',
        offset: 0, limit: limit,
      );

      if (mounted && (_contentActivity == ContentActivity.reload)) {
        setState(() {
          _contentList = (contentList != null) ? List<Message>.from(contentList) : null;
          _lastPageLoadedAll = (contentList != null) ? (contentList.length >= limit) : null;
          _contentActivity = null;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLast());
      }
    }
  }

  Future<void> _refreshContent() async {
    if (((_contentActivity != ContentActivity.reload) && (_contentActivity != ContentActivity.refresh)) && mounted) {
      setState(() {
        _contentActivity = ContentActivity.refresh;
      });

      int contentLength = _refreshContentLength;
      List<Message>? contentList = await Social().loadConversationMessages(
        conversationId: widget.conversation.id ?? '',
        offset: 0, limit: contentLength,
      );

      if (mounted && (_contentActivity == ContentActivity.refresh)) {
        setState(() {
          if (contentList != null) {
            _contentList = List<Message>.from(contentList);
            _lastPageLoadedAll = (contentList.length >= contentLength);
          }
          _contentActivity = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLast());
      }
    }
  }

  Future<void> _extendContent() async {
    if ((_contentActivity == null) && mounted) {
      setState(() {
        _contentActivity = ContentActivity.extend;
      });

      int contentOffset = _contentList?.length ?? 0;
      int contentLength = _contentPageLength;
      List<Message>? contentList = await Social().loadConversationMessages(
        conversationId: widget.conversation.id ?? '',
        offset: contentOffset, limit: contentLength,
      );

      if (mounted && (_contentActivity == ContentActivity.extend)) {
        setState(() {
          if (contentList != null) {
            if (_contentList != null) {
              _contentList?.addAll(contentList);
            } else {
              _contentList = List<Message>.from(contentList);
            }
            _lastPageLoadedAll = (contentList.length >= contentLength);
          }
          _contentActivity = null;
        });
      }
    }
  }

  void _scrollListener() {
    double scrollOffset = _scrollController.offset;
    if ((scrollOffset <= 0) && (_hasMoreContent != false) && (_contentActivity == null)) {
      _extendContent();
    }
  }

  void _scrollToLast() {
    double scrollMaxExtent = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(scrollMaxExtent);
  }

  /*Widget get _lastContentAnchor =>
    Container(key: _lastContentAnchorKey, height: 0);

  Future<void> _scrollToLastAnimated() async {
    BuildContext? scrollToContext = _lastContentAnchorKey.currentContext;
    if ((scrollToContext != null) && scrollToContext.mounted) {
      await Scrollable.ensureVisible(scrollToContext, duration: _scrollDuration);
    }
  }*/

  Future<void> _onRefresh() async {
    Analytics().logSelect(target: 'Refresh');
    return _refreshContent();
  }

  void _onDeleteConversation() {
    Analytics().logSelect(target: 'Delete Conversation');

  }
}

class _GroupConversationHeader extends StatelessWidget {
  final Group? group;
  final Conversation conversation;
  final void Function()? onDelete;

  static const double _photoSize = 42;

  _GroupConversationHeader(this.conversation, {this.group, this.onDelete});

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
          TextSpan(text: memberStatus.toUpperCase(), style: Styles().textStyles.getTextStyleEx('widget.title.medium.fat', color: memberColor)),
      ]),
    );
  }

  Widget get _avtarWidget => DirectoryProfilePhoto(
    photoUrl: Content().getUserPhotoUrl(type: UserProfileImageType.medium,),
    photoSize: _photoSize,
    photoUrlHeaders: DirectoryProfilePhotoUtils.authHeaders,
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

class _GroupConversationMessageCard extends StatelessWidget {
  final Message message;
  final Conversation? conversation;
  final Group? group;
  final Member? adminSender;
  final AnalyticsFeature? analyticsFeature;

  _GroupConversationMessageCard(this.message, { this.conversation, this.group, this.adminSender, this.analyticsFeature });

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _cardDecoration, child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _GroupConversationMessageHeader(message, conversation: conversation, group: group, adminSender: adminSender, onCommands: null,),
        Padding(padding: EdgeInsets.symmetric(horizontal: _horzPadding), child:
          SelectionArea(child:
            LinkTextEx(
              message.message ?? '',
              textStyle: Styles().textStyles.getTextStyle('widget.detail.regular'),
              linkStyle: Styles().textStyles.getTextStyleEx('widget.detail.regular.underline', decorationColor: Styles().colors.fillColorPrimary),
              onLinkTap: _onTapLink,
            ),
          ),
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: _horzPadding, vertical: _horzPadding), child:
          GroupReactionsLayout(group: group, entityId: message.id, reactionSource: SocialEntityType.post, analyticsFeature: analyticsFeature,)
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

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent),
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  static const double _horzPadding = 8;
  static const double _vertPadding = 8;
}

class _GroupConversationMessageHeader extends StatelessWidget {
  final Message message;
  final Conversation? conversation;
  final Group? group;
  final Member? adminSender;
  final void Function()? onCommands;

  _GroupConversationMessageHeader(this.message, { this.conversation, this.group, this.adminSender, this.onCommands });

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
    String? memberStatus = groupMemberStatusToDisplayString(adminSender?.status);
    Color? memberColor = groupMemberStatusToColor(adminSender?.status);
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

  static const double _horzPadding = _GroupConversationMessageCard._horzPadding;
  static const double _vertPadding = _GroupConversationMessageCard._vertPadding;
  static const double _photoSize = 36;
}

class _GroupConversationMessageEditBar extends StatefulWidget {
  final String? title;
  
  final String? text;
  final String? hint;
  final TextStyle? textStyle;
  final TextStyle? linkTextStyle;

  final int minLines;
  final int maxLines;
  final bool autofocus;

  final EdgeInsetsGeometry padding;

  _GroupConversationMessageEditBar({this.title,
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

class _GroupConversationMessageEditBarState extends State<_GroupConversationMessageEditBar> {

  late quill.QuillController _quillController;
  late Delta _initialQuillDelta;
  late FocusNode _focusNode;
  late TextStyle _textStyle;
  late TextStyle _linkTextStyle;
  Set<_EditBarCommand> _selectedCommands = <_EditBarCommand>{};

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
          Event2ImageCommandButton(
            Styles().images.getImage('paper-plane',
              color: _canSubmit ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
              size: _buttonIconSize,
              excludeFromSemantics: true
            ),
            label: Localization().getStringEx('', 'Send'),
            hint: Localization().getStringEx('', 'Tap to send message'),
            contentPadding: _buttonPadding,
            onTap: _canSubmit ? _onSubmit : null,
          ),
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

  bool get _canSubmit => _selectedCommands.contains(_EditBarCommand.submit);

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

  void _onSubmit() {
    Analytics().logSelect(target: 'Submit');
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