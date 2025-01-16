import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/notifications/NotificationsFilterPanel.dart';
import 'package:illinois/ui/notifications/NotificationsHomePanel.dart';
import 'package:illinois/ui/widgets/UnderlinedButton.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:illinois/ext/InboxMessage.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class NotificationsInboxPage extends StatefulWidget {
  final bool? unread;
  final void Function()? onTapBanner;
  NotificationsInboxPage({Key? key, this.unread, this.onTapBanner}) : super(key: key);

  _NotificationsInboxPageState createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends State<NotificationsInboxPage> implements NotificationsListener {

  final List<_FilterEntry> _mutedValues = [
    _FilterEntry(name: Localization().getStringEx("panel.inbox.label.muted.show", "Show Muted"), value: null),  // Show both muted and not muted messages
    _FilterEntry(name: Localization().getStringEx("panel.inbox.label.muted.hide", "Hide Muted"), value: false), // Show only not muted messages
  ];

  final List<_FilterEntry> _times = [
    _FilterEntry(name: Localization().getStringEx("panel.inbox.label.time.any", "Any Time"), value: null),
    _FilterEntry(name: Localization().getStringEx("panel.inbox.label.time.today", "Today"), value: _TimeFilter.Today),
    _FilterEntry(name: Localization().getStringEx("panel.inbox.label.time.yesterday", "Yesterday"), value: _TimeFilter.Yesterday),
    _FilterEntry(name: Localization().getStringEx("panel.inbox.label.time.this_week", "This week"), value: _TimeFilter.ThisWeek),
    _FilterEntry(name: Localization().getStringEx("panel.inbox.label.time.last_week", "Last week"), value: _TimeFilter.LastWeek),
    _FilterEntry(name: Localization().getStringEx("panel.inbox.label.time.this_month", "This month"), value: _TimeFilter.ThisMonth),
    _FilterEntry(name: Localization().getStringEx("panel.inbox.label.time.last_month", "Last Month"), value: _TimeFilter.LastMonth),
  ];

  final int _messagesPageSize = 8;
  static final double _defaultPaddingValue = 16;

  String? _selectedCategory;
  _TimeFilter? _selectedTime;
  bool? _selectedMutedValue;
  _FilterType? _selectedFilter;
  bool? _hasMoreMessages;
  
  bool? _loading, _loadingMore;
  List<InboxMessage> _messages = <InboxMessage>[];
  List<dynamic>? _contentList;
  ScrollController _scrollController = ScrollController();

  bool _isEditMode = false;
  Set<String> _selectedMessageIds = Set<String>();

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
                      strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary)))),
          Visibility(visible: (_selectedFilter != null), child: Stack(children: <Widget>[_buildFilterValues()]))
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
          selected: (_isEditMode == true) ? _selectedMessageIds.contains(entry.messageId) : null,
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
    if (_isEditMode == true) {
      _handleSelectionTap(message);
    } else {
      _handleRedirectTap(message);
    }
  }

  void _handleSelectionTap(InboxMessage message) {
    Analytics().logSelect(target: message.subject);
    setState(() {
      if (message.messageId != null) {
        if (_selectedMessageIds.contains(message.messageId)) {
          _selectedMessageIds.remove(message.messageId);
          AppSemantics.announceMessage(context, "Deselected");
        } else {
          _selectedMessageIds.add(message.messageId!);
          AppSemantics.announceMessage(context, "Selected");
        }
      }
    });
  }

  void _handleRedirectTap(InboxMessage message) {
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

  // Filters Dropdowns

  Widget _buildFilterValues() {

    List<_FilterEntry> filterValues;
    dynamic selectedFilterValue;
    List<String>? subLabels;
    switch(_selectedFilter) {
      case _FilterType.Muted: filterValues = _mutedValues; selectedFilterValue = _selectedMutedValue; subLabels = null; break;
      case _FilterType.Time: filterValues = _times; selectedFilterValue = _selectedTime; subLabels = _buildTimeDates(); break;
      default: filterValues = []; break;
    }

    return Padding(padding: EdgeInsets.only(top: 6, left: 16, right: 16, bottom: 32), child:
      Container(decoration: BoxDecoration(color: Styles().colors.fillColorSecondary, borderRadius: BorderRadius.circular(5.0)), child: 
        Padding(padding: EdgeInsets.only(top: 2), child:
          Container(color: Colors.white, child:
            ListView.separated(
              shrinkWrap: true,
              separatorBuilder: (context, index) => Divider(height: 1, color: Styles().colors.fillColorPrimaryTransparent03,),
              itemCount: filterValues.length,
              itemBuilder: (context, index) {
                return  FilterListItem(
                  title: filterValues[index].name,
                  description: (subLabels != null) ? subLabels[index] : null,
                  selected: selectedFilterValue == filterValues[index].value,
                  onTap: () { _onFilterValue(_selectedFilter, filterValues[index]); },
                );
              }
            ),
          ),
        )
      )
    );
  }

  List<String> _buildTimeDates() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    Map<_TimeFilter, _DateInterval> intervals = _getTimeFilterIntervals();

    List<String> timeDates = <String>[];
    for (_FilterEntry timeEntry in _times) {
      String? timeDate;
      _DateInterval? interval = intervals[timeEntry.value];
      if (interval != null) {
        DateTime startDate = interval.startDate!;
        String? startStr = AppDateTime().formatDateTime(interval.startDate, format: 'MM/dd', ignoreTimeZone: true);

        DateTime endDate = interval.endDate ?? today;
        if (1 < endDate.difference(startDate).inDays) {
          String? endStr = AppDateTime().formatDateTime(endDate, format: 'MM/dd', ignoreTimeZone: true);  
          timeDate = "$startStr - $endStr";
        }
        else {
          timeDate = startStr;
        }
      }
      timeDates.add(timeDate ?? '');
    }

    return timeDates;
  }

  static Map<_TimeFilter, _DateInterval> _getTimeFilterIntervals() {
    DateTime now = DateTime.now();
    return {
      _TimeFilter.Today:     _DateInterval(startDate: DateTime(now.year, now.month, now.day)),
      _TimeFilter.Yesterday: _DateInterval(startDate: DateTime(now.year, now.month, now.day - 1), endDate: DateTime(now.year, now.month, now.day)),
      _TimeFilter.ThisWeek:  _DateInterval(startDate: DateTime(now.year, now.month, now.day - now.weekday + 1)),
      _TimeFilter.LastWeek:  _DateInterval(startDate: DateTime(now.year, now.month, now.day - now.weekday + 1 - 7), endDate: DateTime(now.year, now.month, now.day - now.weekday + 1)),
      _TimeFilter.ThisMonth: _DateInterval(startDate: DateTime(now.year, now.month, 1)),
      _TimeFilter.LastMonth: _DateInterval(startDate: DateTime(now.year, now.month - 1, 1), endDate: DateTime(now.year, now.month, 0)),
    };
  }

  void _onFilterValue(_FilterType? filterType, _FilterEntry filterEntry) {
    Analytics().logSelect(target: "FilterItem: ${filterEntry.name}");
    setState(() {
      switch(filterType) {
        case _FilterType.Muted: _selectedMutedValue = filterEntry.value; break;
        case _FilterType.Time: _selectedTime = filterEntry.value; break;
        default: break;
      }
      _selectedFilter = null;
    });

    _loadInitialContent();
  }

  Future<void> _refreshMessages() async{
    int limit = max(_messages.length, _messagesPageSize);
    _DateInterval? selectedTimeInterval = (_selectedTime != null) ? _getTimeFilterIntervals()[_selectedTime] : null;
    List<InboxMessage>? messages = await Inbox().loadMessages(unread: widget.unread, muted: _selectedMutedValue, offset: 0, limit: limit, category: _selectedCategory, startDate: selectedTimeInterval?.startDate, endDate: selectedTimeInterval?.endDate);
    if (mounted) {
      setState(() {
        if (messages != null) {
          _messages = messages;
          _hasMoreMessages = (_messagesPageSize <= messages.length);
        }
        else {
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
    NotificationsFilterPanel.present(context);
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

    _DateInterval? selectedTimeInterval = (_selectedTime != null) ? _getTimeFilterIntervals()[_selectedTime] : null;
    Inbox().loadMessages(unread: widget.unread, muted: _selectedMutedValue, offset: 0, limit: _messagesPageSize, category: _selectedCategory, startDate: selectedTimeInterval?.startDate, endDate: selectedTimeInterval?.endDate).then((List<InboxMessage>? messages) {
      if (mounted) {
        setState(() {
          if (messages != null) {
            _messages = messages;
            _hasMoreMessages = (_messagesPageSize <= messages.length);
          }
          else {
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

    _DateInterval? selectedTimeInterval = (_selectedTime != null) ? _getTimeFilterIntervals()[_selectedTime] : null;
    Inbox().loadMessages(unread: widget.unread, muted: _selectedMutedValue, offset: _messages.length, limit: _messagesPageSize, category: _selectedCategory, startDate: selectedTimeInterval?.startDate, endDate: selectedTimeInterval?.endDate).then((List<InboxMessage>? messages) {
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
    _DateInterval? selectedTimeInterval = (_selectedTime != null) ? _getTimeFilterIntervals()[_selectedTime] : null;
    Inbox().loadMessages(unread: widget.unread, muted: _selectedMutedValue, offset: 0, limit: limit, category: _selectedCategory, startDate: selectedTimeInterval?.startDate, endDate: selectedTimeInterval?.endDate).then((List<InboxMessage>? messages) {
      setStateIfMounted(() {
        if (messages != null) {
            _messages = messages;
            _hasMoreMessages = (_messagesPageSize <= messages.length);
          }
          else {
            _messages.clear();
            _hasMoreMessages = null;
          }
          _contentList = _buildContentList();
          _loading = false;
      });
    });
  }

  List<dynamic> _buildContentList() {
    Map<_TimeFilter, _DateInterval> intervals = _getTimeFilterIntervals();
    Map<_TimeFilter, List<InboxMessage>> timesMap = Map<_TimeFilter, List<InboxMessage>>();
    List<InboxMessage>? otherList;
    for (InboxMessage? message in _messages) {
      _TimeFilter? timeFilter = _filterTypeFromDate(message!.dateCreatedUtc?.toLocal(), intervals: intervals);
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
    for (_FilterEntry timeEntry in _times) {
      _TimeFilter? timeFilter = timeEntry.value;
      List<InboxMessage>? timeList = (timeFilter != null) ? timesMap[timeFilter] : null;
      if (timeList != null) {
        contentList.add(timeEntry.name!.toUpperCase());
        contentList.addAll(timeList);
      }
    }
    
    if (otherList != null) {
      contentList.add(_FilterEntry.entryInList(_times, null)?.name?.toUpperCase() ?? '');
      contentList.addAll(otherList);
    }
    
    return contentList;
  }

  _TimeFilter? _filterTypeFromDate(DateTime? dateTime, { Map<_TimeFilter, _DateInterval>? intervals }) {
    for (_FilterEntry timeEntry in _times) {
      _TimeFilter? timeFilter = timeEntry.value;
      _DateInterval? timeInterval = ((intervals != null) && (timeFilter != null)) ? intervals[timeFilter] : null;
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

  bool get _showBanner{
    return FirebaseMessaging().notificationsPaused ?? false;
  }

  void _onTapBanner() {
    if (widget.onTapBanner != null) {
      widget.onTapBanner!();
    }
    else {
      // SettingsNotificationsContentPanel.present(context, content: SettingsNotificationsContent.preferences);
    }
  }
}

class _FilterEntry {
  final String? _name;
  final dynamic _value;
  
  String? get name => _name;
  dynamic get value => _value;
  
  _FilterEntry({String? name, dynamic value}) :
    _name = name ?? value?.toString(),
    _value = value;

  static _FilterEntry? entryInList(List<_FilterEntry>? entries, dynamic value) {
    if (entries != null) {
      for (_FilterEntry entry in entries) {
        if (entry.value == value) {
          return entry;
        }
      }
    }
    return null;
  }
}

class _DateInterval {
  final DateTime? startDate;
  final DateTime? endDate;
  
  _DateInterval({this.startDate, this.endDate});

  bool contains(DateTime? dateTime) {
    if (dateTime == null) {
      return false;
    }
    else if ((startDate != null) && startDate!.isAfter(dateTime)) {
      return false;
    }
    else if ((endDate != null) && endDate!.isBefore(dateTime)) {
      return false;
    }
    else {
      return true;
    }
  }
}

enum _TimeFilter {
  Today, Yesterday, ThisWeek, LastWeek, ThisMonth, LastMonth
}

enum _FilterType {
  Muted, Time
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
