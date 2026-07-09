
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/ui/groups/GroupConversationWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
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

  double _screenInsetsBottom = 0;
  Timer? _screenInsetsBottomChangedTimer;

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
      if (screenInsetsBottom != _screenInsetsBottom) {
        _screenInsetsBottom = screenInsetsBottom;
        _screenInsetsBottomChangedTimer?.cancel();
        _screenInsetsBottomChangedTimer = Timer(Duration(milliseconds: 100), (){
          if (mounted) {
            _screenInsetsBottomChangedTimer = null;
            _onKeyboardVisibilityChanged();
          }
        });
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

  Widget get _messagesContent => Column(children: [
    GroupConversationHeader(widget.conversation, group: widget.group, groupAdmins: widget.groupAdmins, onDelete: _onDeleteConversation, onTap: _isKeyboardVisible ? _onHideKeyboard : null,),
    Expanded(child:
      RefreshIndicator(onRefresh: _onRefresh, child:
        SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), scrollDirection: Axis.vertical, child:
          Stack(children: [
            _listContent,
            Positioned.fill(child:
              InkWell(onTap: _isKeyboardVisible ?  _onHideKeyboard : null, child: Container()),
            )
          ],)
        )
      )
    ),
    GroupConversationMessageEditBar(
      onSendMessage: (widget.conversation.id?.isNotEmpty == true) ? _onSendMessage : null ,
      title: Localization().getStringEx('', 'REPLY'),
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

  void _onKeyboardVisibilityChanged() {
    if (_isKeyboardVisible && mounted) {
      _scrollToLast();
    }
    setStateIfMounted();
  }

  bool get _isKeyboardVisible => (_screenInsetsBottom > 0);

  void _onHideKeyboard() {
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
      if (newMessage != null) {
        int? index = _contentList?.indexOf(tempMessage);
        if ((index != null) && (index >= 0)) {
          setState(() {
            _contentList![index] = newMessage;
          });
        }
        return true;
      } else {
        AppAlert.showDialogResult(context, Localization().getStringEx('', 'Failed to send message.'));
        return false;
      }
    } else {
      return false;
    }
  }

  Future<void> _onRefresh() async {
    Analytics().logSelect(target: 'Refresh');
    return _refreshContent();
  }

  void _onDeleteConversation() {
    Analytics().logSelect(target: 'Delete Conversation');

  }
}

enum _ContentActivity { reload, refresh, update, extend }