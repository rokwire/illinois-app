
import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/ext/Social.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/ui/groups/GroupConversationWidgets.dart';
import 'package:illinois/ui/groups/GroupPostReportAbuse.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GroupConversationMessagesPanel extends StatefulWidget {
  final Group? group;
  final List<Member>? groupAdmins;
  final Conversation conversation;
  final AnalyticsFeature? analyticsFeature;

  GroupConversationMessagesPanel(this.conversation, { super.key, this.group, this.groupAdmins, this.analyticsFeature });

  @override
  State<StatefulWidget> createState() => _GroupConversationMessagesPanelState();
}

class _GroupConversationMessagesPanelState extends State<GroupConversationMessagesPanel> with NotificationsListener, WidgetsBindingObserver {

  ScrollController _scrollController = ScrollController();

  List<Message>? _contentList;
  _ContentActivity? _contentActivity;
  bool? _lastPageLoadedAll;
  static const int _contentPageLength = 8;

  bool _keyboardVisible = false;
  double _screenInsetsBottom = 0;
  Timer? _screenInsetsBottomChangedTimer;

  FocusNode _editFocusNode = FocusNode();

  Message? _deletingMessage;
  String? get _deletingMessageId => _deletingMessage?.globalId;

  Message? _editingMessage;
  String? get _editingMessageText => _editingMessage?.message;
  String? get _editingMessageId => _editingMessage?.globalId;
  bool get _isEditingMessage => (_editingMessageId?.isNotEmpty == true);

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FirebaseMessaging.notifySocialMessageNotification
    ]);

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    });

    _scrollController.addListener(_scrollListener);
    _reloadContent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (mounted) {
      if (name == FirebaseMessaging.notifySocialMessageNotification) {
        _onFirebaseSocialMessageNotification(param);
      }
    }
  }

  @override
  void didChangeMetrics() {
    if (mounted) {
      double screenInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
      debugPrint('didChangeMetrics: $_screenInsetsBottom => $screenInsetsBottom');
      if (screenInsetsBottom != _screenInsetsBottom) {
        if (screenInsetsBottom < _screenInsetsBottom) {
          _onKeyboardWillHide();
        } else if (_screenInsetsBottom < screenInsetsBottom) {
          _onKeyboardWillShow();
        }
        _screenInsetsBottom = screenInsetsBottom;
        _screenInsetsBottomChangedTimer?.cancel();
        _screenInsetsBottomChangedTimer = Timer(_screenInsetsBottomChangedTimerDuration, _onScreenInsetsBottomChangedTimer);
      }
    }
  }

  @override
  Widget build(BuildContext context) =>  Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx('', 'Message')),
    body: _bodyWidget,
    backgroundColor: Styles().colors.background,
    resizeToAvoidBottomInset: true,
  );

  Widget get _bodyWidget {
    if (_contentActivity == _ContentActivity.reload) {
      return _loadingContent;
    }
    else if (_contentActivity == _ContentActivity.refresh) {
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

  Widget get _messagesContent =>
  Column(children: [
    Stack(children: <Widget>[
      GroupConversationHeader(widget.conversation, group: widget.group, groupAdmins: widget.groupAdmins),
      _hideKeyboardLayer,
    ],),
    Expanded(child:
      Stack(children: <Widget>[
        RefreshIndicator(onRefresh: _onRefresh, child:
          SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), scrollDirection: Axis.vertical, child:
            _listContent,
          )
        ),
        _hideKeyboardLayer,
      ],),
    ),
    GroupConversationMessageEditBar(
      autofocus: false,
      focusNode: _editFocusNode,
      title: _isEditingMessage ? Localization().getStringEx('', 'EDiT') : Localization().getStringEx('', 'REPLY'),
      text: _isEditingMessage ? _editingMessageText : null,
      showSubmitProgress: _isEditingMessage,
      onSubmitMessage: (widget.conversation.id?.isNotEmpty == true) ? _onSubmitMessage : null,
      onCancelEdit: _isEditingMessage ? _onCancelEdit : null,
    ),
  ],);

  Widget get _listContent {
    List<Widget> cardsList = <Widget>[];

    if (_contentActivity == _ContentActivity.extend) {
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
        GroupConversationMessageCard(message,
          conversation: widget.conversation,
          group: widget.group,
          //groupMember: MemberExt.getMember(widget.groupAdmins, userId: message.sender?.accountId),
          onCommand: () => _onMessageCommand(message),
          commandProgress: ((_deletingMessageId != null) && (_deletingMessageId == message.globalId)),
          commandIcon: ((_editingMessageId != null) && (_editingMessageId == message.globalId)) ? _editingMessageIcon : null,
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
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 2,)
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
  
  Widget? get _editingMessageIcon => Styles().images.getImage('edit', size: GroupConversationMessageHeader.buttonIconSize);

  Widget get _hideKeyboardLayer =>
    Visibility(visible: _keyboardVisible, child:
      Positioned.fill(child:
        GestureDetector(onTap: _onHideKeyboard, child:
          Container(color: Colors.transparent /* Color(0x40000000) */)
        )
      )
    );

  double get _screenHeight => MediaQuery.of(context).size.height;
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _cardOffset => (_screenWidth - 32) / 8;

  // Content Management

  bool? get _hasMoreContent => (_lastPageLoadedAll != false);
  int get _listSafeContentLength => _contentList?.length ?? 0;
  int get _refreshContentLength => max(_listSafeContentLength, _contentPageLength);

  Future<void> _reloadContent({ int limit = _contentPageLength }) async {
    if ((_contentActivity != _ContentActivity.reload) && mounted) {
      setState(() {
        _contentActivity = _ContentActivity.reload;
      });

      List<Message>? contentList = await Social().loadConversationMessages(
        conversationId: widget.conversation.id ?? '',
        offset: 0, limit: limit,
      );

      if (mounted && (_contentActivity == _ContentActivity.reload)) {
        setState(() {
          _contentList = (contentList != null) ? List<Message>.from(contentList) : null;
          _lastPageLoadedAll = (contentList != null) ? (contentList.length >= limit) : null;
          _contentActivity = null;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLast());
      }
    }
  }

  Future<void> _refreshContent({ _ContentActivity activity = _ContentActivity.refresh }) async {
    if (((_contentActivity != _ContentActivity.reload) && (_contentActivity != activity)) && mounted) {
      setState(() {
        _contentActivity = activity;
      });

      int contentLength = _refreshContentLength;
      List<Message>? contentList = await Social().loadConversationMessages(
        conversationId: widget.conversation.id ?? '',
        offset: 0, limit: contentLength,
      );

      if (mounted && (_contentActivity == activity)) {
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
        _contentActivity = _ContentActivity.extend;
      });

      int contentOffset = _contentList?.length ?? 0;
      int contentLength = _contentPageLength;
      List<Message>? contentList = await Social().loadConversationMessages(
        conversationId: widget.conversation.id ?? '',
        offset: contentOffset, limit: contentLength,
      );

      if (mounted && (_contentActivity == _ContentActivity.extend)) {
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

  static const Duration _screenInsetsBottomChangedTimerDuration = const Duration(milliseconds: 150);

  void _onScreenInsetsBottomChangedTimer() {
    if (mounted) {
      double screenInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
      if (_screenInsetsBottom != screenInsetsBottom) {
        _screenInsetsBottom = screenInsetsBottom;
        _screenInsetsBottomChangedTimer = Timer(_screenInsetsBottomChangedTimerDuration, _onScreenInsetsBottomChangedTimer);
      } else {
        _screenInsetsBottomChangedTimer = null;
        _onKeyboardFinishedAnimation();
      }
    }
  }

  void _onKeyboardWillShow() {
    if (_keyboardVisible != true) {
      setState((){
        _keyboardVisible = true;
      });
    }
  }

  void _onKeyboardWillHide() {
    if (_keyboardVisible != false) {
      setState((){
        _keyboardVisible = false;
      });
    }
  }

  void _onKeyboardFinishedAnimation() {
    if (mounted) {
      double screenInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
      bool keyboardVisible = (screenInsetsBottom > 0);
      debugPrint('onKeyboardFinishedAnimation: $keyboardVisible ($screenInsetsBottom)');
      if (_keyboardVisible != keyboardVisible) {
        setState((){
          _keyboardVisible = keyboardVisible;
        });
      }
      if (keyboardVisible) {
        _scrollToLast();
      }
    }
  }

  void _onHideKeyboard() {
    if (_isEditingMessage) {
      setState(() {
        _editingMessage = null;
      });
    }
    FocusScope.of(context).unfocus();
  }

  /*Widget get _lastContentAnchor =>
    Container(key: _lastContentAnchorKey, height: 0);

  Future<void> _scrollToLastAnimated() async {
    BuildContext? scrollToContext = _lastContentAnchorKey.currentContext;
    if ((scrollToContext != null) && scrollToContext.mounted) {
      await Scrollable.ensureVisible(scrollToContext, duration: _scrollDuration);
    }
  }*/

  void _onFirebaseSocialMessageNotification(dynamic param) {
    String? conversationId = (param is Map<String, dynamic>) ? JsonUtils.stringValue(param['entity_id']) : null;
    if (conversationId == widget.conversation.id) {
      _refreshContent(activity: _ContentActivity.update);
    }
  }

  Future<bool> _onSubmitMessage(String message) =>
    _isEditingMessage ? _onUpdateMessage(message) : _onSendMessage(message);

  Future<bool> _onSendMessage(String message) async {
    // Create a temporary message and add it immediately
    Message tempMessage = Message(
      sender: ConversationMember(accountId: Auth2().accountId, name: Auth2().fullName ?? ''),
      message: message,
      //fileAttachments: fileAttachments,
      dateSentUtc: DateTime.now().toUtc(),
    );

    setState(() {
      _contentList?.insert(0, tempMessage);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLast());

    List<Message>? newMessages = await Social().createConversationMessage(
      conversationId: widget.conversation.id ?? '',
      message: message,
      //fileAttachments: fileAttachments,
    );

    if (mounted) {
      Message? newMessage = newMessages?.firstOrNull;

      int? index = _contentList?.indexOf(tempMessage);
      if ((index != null) && (index >= 0)) {
        setState(() {
          if (newMessage != null) {
            _contentList?[index] = newMessage;
          } else {
            _contentList?.removeAt(index);
          }
        });
      }

      if (newMessage != null) {
        return true;
      } else {
        AppAlert.showDialogResult(context, Localization().getStringEx('', 'Failed to send message.'));
        return false;
      }
    } else {
      return false;
    }
  }

  Future<bool> _onUpdateMessage(String message) async {
    if (_isEditingMessage) {
      if (message == _editingMessage?.message) {
        setState(() {
          _editingMessage = null;
        });
        return true;
      }
      else {
        bool success = await Social().updateConversationMessage(
          conversationId: widget.conversation.id ?? '',
          globalMessageId: _editingMessage?.globalId ?? '',
          newText: message,
        );
        if (mounted) {
          if (success) {
            Message updatedMessage = Message.fromOther(_editingMessage,
              message: message,
              dateUpdatedUtc: DateTime.now().toUtc(), // Mark it as edited
            );
            int? index = _contentList?.indexWhere((msg) => msg.globalId == _editingMessage?.globalId);
            setState(() {
              if ((index != null) && (index >= 0)) {
                _contentList?[index] = updatedMessage;
              }
              _editingMessage = null;
            });
            return true;
          }
          else {
            AppAlert.showDialogResult(context, Localization().getStringEx('', 'Failed to update message'));
            return false;
          }
        }
        else {
          return false;
        }
      }
    }
    else {
      return false;
    }
  }

  void _onCancelEdit() {
    if (_isEditingMessage) {
      setState(() {
        _editingMessage = null;
      });
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _onRefresh() async {
    Analytics().logSelect(target: 'Refresh');
    return _refreshContent();
  }

  void _onMessageCommand(Message message) {
    Analytics().logSelect(target: 'Conversation Message Commands', attributes: widget.group?.analyticsAttributes);
    showModalBottomSheet(
      context: context,
      backgroundColor: Styles().colors.surface,
      isScrollControlled: true,
      isDismissible: true,
      barrierLabel: "Dismiss Menu",
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(padding: EdgeInsetsGeometry.all(16), child:
        Column(mainAxisSize: MainAxisSize.min, children: _buildMessageCommandEntries(message))
      )
    );
  }

  List<Widget> _buildMessageCommandEntries(Message message) => <Widget>[
    if (message.sender?.isCurrentUser != true) ...<Widget>[
      RibbonButton(title: Localization().getStringEx('panel.group.detail.post.button.report.students_dean.label', 'Report to Dean of Students'), leftIconKey: 'comment', onTap: () => _onReportMessageAbuse(message, options: GroupPostReportAbuseOptions(reportToDeanOfStudents: true))),
      RibbonButton(title: Localization().getStringEx('panel.group.detail.post.button.report.group_admins.label', 'Report to Group Administrator(s)'), leftIconKey: 'comment', onTap: () => _onReportMessageAbuse(message, options: GroupPostReportAbuseOptions(reportToGroupAdmins: true))),
    ] else ...<Widget>[
      RibbonButton(title: Localization().getStringEx('dialog.edit.title', 'Edit'), leftIconKey: 'edit', onTap: () => _onEditMessage(message)),
      RibbonButton(title: Localization().getStringEx('dialog.delete.title', 'Delete'), leftIconKey: 'trash', onTap: () => _onDeleteMessage(message)),
    ]

  ];

  void _onReportMessageAbuse(Message message, {required GroupPostReportAbuseOptions options}) {
    Analytics().logSelect(target: options.analyticsSelectTarget);
    Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => GroupPostReportAbusePanel(options: options, groupId: widget.group?.id ?? '', socialEntityId: message.globalId, socialEntityType: SocialEntityType.message,)));
  }

  void _onDeleteMessage(Message message) async {
    Analytics().logSelect(target: 'Delete Message');
    Navigator.pop(context);

    if (_deletingMessageId != message.globalId) {

      bool? deleteConfirmed = await GroupConversationConfirmDeleteDialog.show(context,
        Localization().getStringEx('', 'Deleting messages cannot be reversed.'),
        Localization().getStringEx('', 'How would you like to proceed?',));

      if ((deleteConfirmed == true) && mounted) {
        setState(() {
          _deletingMessage = message;
        });

        bool succeeded = await Social().deleteConversationMessage(conversationId: widget.conversation.id ?? '', globalMessageId: message.globalId ?? '');
        if (mounted) {
          setState(() {
            _deletingMessage = null;
          });
          if (succeeded) {
            setState(() {
              _contentList?.removeWhere((entry) => (entry.globalId == message.globalId));
            });
          } else {
            AppAlert.showDialogResult(context, Localization().getStringEx('', 'Failed to delete message'));
          }
        }
      }
    }
  }

  void _onEditMessage(Message message) {
    Analytics().logSelect(target: 'Edit Message');
    Navigator.pop(context);
    
    if (!_isEditingMessage && (_deletingMessageId != message.id)) {
      setState(() {
        _editingMessage = message;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editFocusNode.requestFocus();
      });
    }
  }

}

enum _ContentActivity { reload, refresh, update, extend }