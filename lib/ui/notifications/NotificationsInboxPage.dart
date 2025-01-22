import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/notifications/NotificationsFilterPanel.dart';
import 'package:illinois/ui/notifications/NotificationsHomePanel.dart';
import 'package:illinois/ui/widgets/UnderlinedButton.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:illinois/ext/InboxMessage.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class NotificationsInboxPage extends StatefulWidget {
  final bool? unread;
  final void Function()? onTapBanner;
  NotificationsInboxPage({this.unread, this.onTapBanner});

  _NotificationsInboxPageState createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends State<NotificationsInboxPage> implements NotificationsListener {

  final int _messagesPageSize = 8;
  static final double _defaultPaddingValue = 16;

  DateInterval? _selectedDateInterval;
  bool? _selectedMutedValue;
  bool? _selectedUnreadValue;
  bool? _hasMoreMessages;
  
  bool? _loading, _loadingMore;
  List<InboxMessage> _messages = <InboxMessage>[];
  List<dynamic>? _contentList;
  ScrollController _scrollController = ScrollController();

  bool _loadingMarkAllAsRead = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Inbox.notifyInboxUserInfoChanged,
      Inbox.notifyInboxMessageRead,
      Inbox.notifyInboxMessagesDeleted
    ]);

    _scrollController.addListener(_scrollListener);
    _selectedMutedValue = false;
    _selectedUnreadValue = widget.unread;
    _loadInitialContent();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if(name == Inbox.notifyInboxUserInfoChanged){
      if(mounted){
        setState(() {
          //refresh
        });
      }
    } else if (name == Inbox.notifyInboxMessageRead) {
      _refreshContent();
    } else if (name == Inbox.notifyInboxMessagesDeleted) {
      _refreshContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _onPullToRefresh,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[_buildBanner(), _buildHeaderSection(), Expanded(child: _buildContent())]));
  }

  // Messages

  Widget _buildContent() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: _defaultPaddingValue),
        child: Stack(children: [
          Visibility(visible: (_loading != true), child: Padding(padding: EdgeInsets.only(top: 12), child: _buildMessagesContent())),
          Visibility(
              visible: (_loading == true),
              child: Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary))))
        ]));
  }

  Widget _buildMessagesContent() {
    if ((_contentList != null) && (0 < _contentList!.length)) {
      int count = _contentList!.length + ((_loadingMore == true) ? 1 : 0);
      return ListView.separated(
        separatorBuilder: (context, index) => Container(),
        itemCount: count,
        itemBuilder: _buildListEntry,
        controller: _scrollController);
    }
    else {
      return Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text(Localization().getStringEx('panel.inbox.label.content.empty', 'No messages'), textAlign: TextAlign.center,),
        Expanded(child: Container(), flex: 3),
      ]);
    }
  }

  Widget _buildListEntry(BuildContext context, int index) {
    dynamic entry = ((_contentList != null) && (0 <= index) && (index < _contentList!.length)) ? _contentList![index] : null;
    if (entry is InboxMessage) {
      return Padding(padding: EdgeInsets.only(bottom: 20), child: InboxMessageCard(
          message: entry,
          onTap: () => _onTapMessage(entry)));
    }
    else if (entry is String) {
      return _buildListHeading(text: entry);
    }
    else {
      return _buildListLoadingIndicator();
    }
  }

  Widget _buildListHeading({String? text}) {
    return Semantics(
        header: true,
        child: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(text ?? '', style: Styles().textStyles.getTextStyle('widget.title.regular.fat'))));
  }

  Widget _buildListLoadingIndicator() {
    return Container(padding: EdgeInsets.only(left: 6, top: 6, right: 6, bottom: 20), child:
      Align(alignment: Alignment.center, child:
        SizedBox(width: 24, height: 24, child:
          CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),),),),);
  }

  void _onTapMessage(InboxMessage message) {
    Analytics().logSelect(target: message.subject);
    NotificationsHomePanel.launchMessageDetail(message);
  }

  Widget _buildHeaderSection() {
    return Container(
        decoration: BoxDecoration(color: Styles().colors.white),
        padding: EdgeInsets.symmetric(horizontal: _defaultPaddingValue, vertical: 10),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildFilterButton(), _buildReadAllButton()]));
  }

  Widget _buildFilterButton() {
    String title = Localization().getStringEx('panel.inbox.button.filter.title', 'Filter');
    return Semantics(
        label: title,
        button: true,
        child: InkWell(
            onTap: _onTapFilter,
            child: Container(
                decoration: BoxDecoration(
                    color: Styles().colors.white,
                    border: Border.all(color: Styles().colors.disabledTextColor, width: 1),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                    child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Padding(padding: EdgeInsets.only(right: 6), child: Styles().images.getImage('filters')),
                      Text(title, style: Styles().textStyles.getTextStyle('widget.button.title.regular'), semanticsLabel: ''),
                      Padding(padding: EdgeInsets.only(left: 3), child: Styles().images.getImage('chevron-right'))
                    ])))));
  }

  // Banner
  Widget _buildBanner(){ //TBD localize
    return
    Visibility(
      visible: _showBanner,
      child:GestureDetector(
        onTap: _onTapBanner,
        child:Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: Styles().colors.saferLocationWaitTimeColorYellow,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child:
                Text(
                  "Notifications Paused",
                  textAlign: TextAlign.center,
                  style: Styles().textStyles.getTextStyle("widget.detail.regular")
                ),
              ),
              Text(">",
                style: Styles().textStyles.getTextStyle("widget.detail.regular")
              ),

          ],)
        )
      ));
  }

  // Buttons
  Widget _buildReadAllButton() {
    return Semantics(
        container: true,
        child: Container(
            child: UnderlinedButton(
                title: Localization().getStringEx('panel.inbox.mark_all_read.label', 'Mark all as read'),
                padding: EdgeInsets.symmetric(vertical: 8),
                progress: _loadingMarkAllAsRead,
                onTap: _onTapMarkAllAsRead)));
  }

  Future<void> _refreshMessages() async {
    int limit = max(_messages.length, _messagesPageSize);
    List<InboxMessage>? messages = await Inbox().loadMessages(
        unread: _selectedUnreadValue,
        muted: _selectedMutedValue,
        offset: 0,
        limit: limit,
        startDate: _selectedDateInterval?.startDate,
        endDate: _selectedDateInterval?.endDate);
    if (mounted) {
      setState(() {
        if (messages != null) {
          _messages = messages;
          _hasMoreMessages = (_messagesPageSize <= messages.length);
        } else {
          _messages.clear();
          _hasMoreMessages = null;
        }
        _contentList = _buildContentList();
      });
    }
  }

  Future<void> _onPullToRefresh() async {
    _refreshMessages();
  }

  void _onTapFilter() {
    Analytics().logSelect(target: 'Filter');
    NotificationsFilterPanel.present(context, muted: _selectedMutedValue, unread: _selectedUnreadValue, interval: _selectedDateInterval).then((result) {
      if (result is FilterResult) {
        _selectedMutedValue = result.muted;
        _selectedUnreadValue = result.unread;
        _selectedDateInterval = result.dateInterval;
        _refreshContent();
      }
    });
  }

  void _onTapMarkAllAsRead() {
    Analytics().logSelect(target: 'Mark All As Read');
    _setMarkAllAsReadLoading(true);
    Inbox().markAllMessagesAsRead().then((succeeded) {
      if (succeeded) {
        _loadInitialContent();
      } else {
        AppAlert.showTextMessage(
            context, Localization().getStringEx('panel.inbox.mark_as_read.failed.msg', 'Failed to mark all messages as read'));
      }
      _setMarkAllAsReadLoading(false);
    });
  }

  void _setMarkAllAsReadLoading(bool loading) {
    setStateIfMounted(() {
      _loadingMarkAllAsRead = loading;
    });
  }

  // Content

  void _loadInitialContent() {
    setState(() {
      _loading = true;
    });

    Inbox()
        .loadMessages(
            unread: _selectedUnreadValue,
            muted: _selectedMutedValue,
            offset: 0,
            limit: _messagesPageSize,
            startDate: _selectedDateInterval?.startDate,
            endDate: _selectedDateInterval?.endDate)
        .then((List<InboxMessage>? messages) {
      if (mounted) {
        setState(() {
          if (messages != null) {
            _messages = messages;
            _hasMoreMessages = (_messagesPageSize <= messages.length);
          } else {
            _messages.clear();
            _hasMoreMessages = null;
          }
          _contentList = _buildContentList();
          _loading = false;
        });
      }
    });
  }

  void _loadMoreContent() {
    setState(() {
      _loadingMore = true;
    });

    Inbox()
        .loadMessages(
            unread: _selectedUnreadValue,
            muted: _selectedMutedValue,
            offset: _messages.length,
            limit: _messagesPageSize,
            startDate: _selectedDateInterval?.startDate,
            endDate: _selectedDateInterval?.endDate)
        .then((List<InboxMessage>? messages) {
      if (mounted) {
        setState(() {
          if (messages != null) {
            _messages.addAll(messages);
            _hasMoreMessages = (_messagesPageSize <= messages.length);
            _contentList = _buildContentList();
          }
          _loadingMore = false;
        });
      }
    });
  }

  void _refreshContent({int? messagesCount}) {
    setStateIfMounted(() {
      _loading = true;
    });

    int limit = max(messagesCount ?? _messages.length, _messagesPageSize);
    Inbox()
        .loadMessages(
            unread: _selectedUnreadValue,
            muted: _selectedMutedValue,
            offset: 0,
            limit: limit,
            startDate: _selectedDateInterval?.startDate,
            endDate: _selectedDateInterval?.endDate)
        .then((List<InboxMessage>? messages) {
      setStateIfMounted(() {
        if (messages != null) {
          _messages = messages;
          _hasMoreMessages = (_messagesPageSize <= messages.length);
        } else {
          _messages.clear();
          _hasMoreMessages = null;
        }
        _contentList = _buildContentList();
        _loading = false;
      });
    });
  }

  List<dynamic> _buildContentList() {
    Map<TimeFilter, DateInterval> intervals = NotificationsFilterPanel.getTimeFilterIntervals();
    Map<TimeFilter, List<InboxMessage>> timesMap = Map<TimeFilter, List<InboxMessage>>();
    List<InboxMessage>? otherList;
    for (InboxMessage? message in _messages) {
      TimeFilter? timeFilter = _timeFilterFromDate(message!.dateCreatedUtc?.toLocal(), intervals: intervals);
      if (timeFilter != null) {
        List<InboxMessage>? timeList = timesMap[timeFilter];
        if (timeList == null) {
          timesMap[timeFilter] = timeList = <InboxMessage>[];
        }
        timeList.add(message);
      }
      else {
        if (otherList == null) {
          otherList = <InboxMessage>[];
        }
        otherList.add(message);
      }
    }

    List<dynamic> contentList = <dynamic>[];
    List<FilterEntry> dateFilterEntries = NotificationsFilterPanel.dateFilterEntries;
    for (FilterEntry timeEntry in dateFilterEntries) {
      TimeFilter? timeFilter = timeEntry.value;
      List<InboxMessage>? timeList = (timeFilter != null) ? timesMap[timeFilter] : null;
      if (timeList != null) {
        contentList.add(timeEntry.name!.toUpperCase());
        contentList.addAll(timeList);
      }
    }

    if (otherList != null) {
      contentList.add(FilterEntry.entryInList(dateFilterEntries, null)?.name?.toUpperCase() ?? '');
      contentList.addAll(otherList);
    }

    return contentList;
  }

  TimeFilter? _timeFilterFromDate(DateTime? dateTime, { Map<TimeFilter, DateInterval>? intervals }) {
    for (FilterEntry timeEntry in NotificationsFilterPanel.dateFilterEntries) {
      TimeFilter? timeFilter = timeEntry.value;
      DateInterval? timeInterval = ((intervals != null) && (timeFilter != null)) ? intervals[timeFilter] : null;
      if ((timeInterval != null) && (timeInterval.contains(dateTime))) {
        return timeFilter;
      }
    }
    return null;
  }

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && (_hasMoreMessages != false) && (_loadingMore != true) && (_loading != true)) {
      _loadMoreContent();
    }
  }

  bool get _showBanner => FirebaseMessaging().notificationsPaused ?? false;

  void _onTapBanner() {
    if (widget.onTapBanner != null) {
      widget.onTapBanner!();
    }
    else {
      // SettingsNotificationsContentPanel.present(context, content: SettingsNotificationsContent.preferences);
    }
  }
}

class InboxMessageCard extends StatefulWidget {
  final InboxMessage? message;
  final bool? selected;
  final void Function()? onTap;
  
  InboxMessageCard({this.message, this.selected, this.onTap });

  @override
  _InboxMessageCardState createState() {
    return _InboxMessageCardState();
  }
}

class _InboxMessageCardState extends State<InboxMessageCard> implements NotificationsListener {

  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double leftPadding = (widget.selected != null) ? 12 : 16;
    String mutedStatus = Localization().getStringEx('widget.inbox_message_card.status.muted', 'Muted');
    return Container(
        decoration: BoxDecoration(
          color: Styles().colors.white,
          borderRadius: BorderRadius.all(Radius.circular(4)),
          boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]
        ),
        clipBehavior: Clip.none,
        child: Stack(children: [
          InkWell(onTap: widget.onTap, child:
            Padding(padding: EdgeInsets.only(left: leftPadding, right: 16, top: 16, bottom: 16), child:
              Row(children: <Widget>[
                Visibility(visible: (widget.selected != null), child:
                  Padding(padding: EdgeInsets.only(right: leftPadding), child:
                    Semantics(label:(widget.selected == true) ? Localization().getStringEx('widget.inbox_message_card.selected.hint', 'Selected') : Localization().getStringEx('widget.inbox_message_card.unselected.hint', 'Not Selected'), child:
                      Styles().images.getImage((widget.selected == true) ? 'check-circle-filled' : 'check-circle-outline-gray', excludeFromSemantics: true,),
                    )
                  ),
                ),
                
                Expanded(child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[

                    StringUtils.isNotEmpty(widget.message?.subject) ?
                      Padding(padding: EdgeInsets.only(bottom: 4), child:
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child:
                            Text(widget.message?.subject ?? '', semanticsLabel: sprintf(Localization().getStringEx('widget.inbox_message_card.subject.hint', 'Subject: %s'), [widget.message?.subject ?? '']), style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'))
                          ),
                          (widget.message?.mute == true) ? Semantics(label: sprintf(Localization().getStringEx('widget.inbox_message_card.status.hint', 'status: %s ,for: '), [mutedStatus.toLowerCase()]), excludeSemantics: true, child:
                            Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Styles().colors.fillColorSecondary, borderRadius: BorderRadius.all(Radius.circular(2))), child:
                              Text(mutedStatus.toUpperCase(), style: Styles().textStyles.getTextStyle("widget.heading.extra_small"))
                          )) : Container()
                        ])
                      ) : Container(),

                    StringUtils.isNotEmpty(widget.message?.body) ?
                      Padding(padding: EdgeInsets.only(bottom: 6), child:
                        Row(children: [
                          Expanded(child:
                            Text(widget.message?.displayBody ?? '', semanticsLabel: sprintf(Localization().getStringEx('widget.inbox_message_card.body.hint', 'Body: %s'), [widget.message?.displayBody ?? '']), style: Styles().textStyles.getTextStyle('widget.card.detail.small'))
                      )])) : Container(),

                    Row(children: [
                      Expanded(child:
                        Text(widget.message?.displayInfo ?? '', style: Styles().textStyles.getTextStyle('widget.info.tiny'))
                      ),
                    ]),
                  ])
                ),
              ],)
            ),
          ),
          Container(color: Styles().colors.fillColorSecondary, height: 4),
          Positioned(bottom: 0, right: 0, child:
            Stack(alignment: Alignment.center, children: [
              InkWell(onTap: _onTapDelete, splashColor: Colors.transparent, child: Container(padding: EdgeInsets.all(16), child: Styles().images.getImage('trash-blue'))),
              Visibility(visible: _deleting, child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 1, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary))))
            ])
          )
        ])
    );
  }

  void _onTapDelete() {
    Analytics().logSelect(target: 'Delete Inbox Message');
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(Localization()
            .getStringEx('widget.inbox_message_card.delete.confirm.msg', 'Are you sure that you want to delete this message?')),
        actions: <Widget>[
          TextButton(
              child: Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMessage();
              }),
          TextButton(child: Text(Localization().getStringEx('dialog.no.title', 'No')), onPressed: () => Navigator.of(context).pop())
        ]);
  }

  void _deleteMessage() {
    setStateIfMounted(() {
      _deleting = true;
    });
    Inbox().deleteMessage(widget.message!.messageId!).then((bool succeeded) {
      setStateIfMounted(() {
        _deleting = false;
      });
      if (!succeeded) {
        AppAlert.showDialogResult(
            context,
            Localization()
                .getStringEx('widget.inbox_message_card.delete.failed.msg', 'Failed to delete message. Please, try again later.'));
      }
    });
  }
}
