
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/groups/GroupConversationWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
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
    GroupConversationHeader(widget.conversation, group: widget.group, onDelete: _onDeleteConversation,),
    Expanded(child:
      RefreshIndicator(onRefresh: _onRefresh, child:
        SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
          _listContent,
        )
      )
    ),
    GroupConversationMessageEditBar(
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
        GroupConversationMessageCard(message,
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

