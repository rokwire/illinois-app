import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SettingsInboxHomeContentWidget extends StatefulWidget {
  SettingsInboxHomeContentWidget();

  _SettingsInboxHomeContentWidgetState createState() => _SettingsInboxHomeContentWidgetState();
}

class _SettingsInboxHomeContentWidgetState extends State<SettingsInboxHomeContentWidget> implements NotificationsListener {

  final List<_FilterEntry> _categories = [
    _FilterEntry(value: null, name: "Any Category"),
    _FilterEntry(value: "Admin"),
    _FilterEntry(value: "Academic"),
    _FilterEntry(value: "Athletics"),
    _FilterEntry(value: "Community"),
    _FilterEntry(value: "Entertainment"),
    _FilterEntry(value: "Recreation"),
    _FilterEntry(value: "Other"),
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

  String? _selectedCategory;
  _TimeFilter? _selectedTime;
  _FilterType? _selectedFilter;
  bool? _hasMoreMessages;
  
  bool? _loading, _loadingMore, _processingOption;
  List<InboxMessage> _messages = <InboxMessage>[];
  List<dynamic>? _contentList;
  ScrollController _scrollController = ScrollController();

  bool _isEditMode = false;
  Set<String> _selectedMessageIds = Set<String>();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Inbox.notifyInboxUserInfoChanged
    ]);

    _scrollController.addListener(_scrollListener);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _onPullToRefresh,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[_buildBanner(), _buildFilters(), Expanded(child: _buildContent())]));
  }

  // Messages

  Widget _buildContent() {
    return Stack(children: [
      Visibility(visible: (_loading != true), child:
        Padding(padding: EdgeInsets.only(top: 12), child: _buildMessagesContent())
      ),
      Visibility(visible: (_loading == true), child:
        Align(alignment: Alignment.center, child:
          CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
        )
      ),
      Visibility(visible: (_selectedFilter != null), child:
        Stack(children:<Widget>[
          _buildDisabledContentLayer(),
          _buildFilterValues(),
        ]),
      ),
    ]);
  }

  Widget _buildMessagesContent() {
    if ((_contentList != null) && (0 < _contentList!.length)) {
      int count = _contentList!.length + ((_loadingMore == true) ? 1 : 0);
      return ListView.separated(
        separatorBuilder: (context, index) => Container(height: 24),
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
      return _InboxMessageCard(
        message: entry,
        selected: (_isEditMode == true) ? _selectedMessageIds.contains(entry.messageId) : null,
        onTap: () => _onTapMessage(entry));
    }
    else if (entry is String) {
      return _buildListHeading(text: entry);
    }
    else {
      return _buildListLoadingIndicator();
    }
  }

  Widget _buildListHeading({String? text}) {
    return Container(color: Styles().colors!.fillColorPrimary, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
        Semantics(header: true, child:
          Text(text ?? '', style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 16, color: Styles().colors!.white),)
        )
    );
  }

  Widget _buildListLoadingIndicator() {
    return Container(padding: EdgeInsets.all(6), child:
      Align(alignment: Alignment.center, child:
        SizedBox(width: 24, height: 24, child:
          CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary),),),),);
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
    SettingsNotificationsContentPanel.launchMessageDetail(message);
  }
  
  // Banner
  Widget _buildBanner(){ //TBD localize
    return
    Visibility(
      visible: _showBanner,
      child:GestureDetector(
        onTap: (){
          SettingsNotificationsContentPanel.present(context, content: SettingsNotificationsContent.preferences);
        },
        child:Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: Styles().colors?.saferLocationWaitTimeColorYellow ?? Colors.amberAccent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child:
                Text(
                  "Notifications Paused",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Styles().colors?.fillColorPrimary,
                    fontFamily: Styles().fontFamilies?.regular,
                    fontSize: 16
                  ),
                ),
              ),
              Text(">",
                style: TextStyle(
                    color: Styles().colors?.fillColorPrimary,
                    fontSize: 16,
                ),
              ),

          ],)
        )
      ));
  }


  // Filters

  Widget _buildFilters() {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child:
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
          // Hide the "Categories" drop down in Inbox panel (#721)
          /*FilterSelector(
            title: _FilterEntry.entryInList(_categories, _selectedCategory)?.name ?? '',
            active: _selectedFilter == _FilterType.Category,
            onTap: () { _onFilter(_FilterType.Category); }
          ),*/
          FilterSelector(
            padding: EdgeInsets.symmetric(horizontal: 4),
            title: _FilterEntry.entryInList(_times, _selectedTime)?.name ?? '',
            active: _selectedFilter == _FilterType.Time,
            onTap: () { _onFilter(_FilterType.Time); }
          ),
          _buildEditBar()
        ],
    ));
  }

  void _onFilter(_FilterType? filterType) {
    setState(() {
      _selectedFilter = (filterType != _selectedFilter) ? filterType : null;
    });
  }

  // Filters Dropdowns

  Widget _buildDisabledContentLayer() {
    return Padding(padding: EdgeInsets.only(top: 12), child:
      BlockSemantics(child:
        GestureDetector(onTap: (){ _onFilter(null); }, child:
          Container(color: Color(0x99000000))
        ),
      ),
    );
  }

  Widget _buildFilterValues() {

    List<_FilterEntry> filterValues;
    dynamic selectedFilterValue;
    List<String>? subLabels;
    switch(_selectedFilter) {
      case _FilterType.Category: filterValues = _categories; selectedFilterValue = _selectedCategory; subLabels = null; break;
      case _FilterType.Time: filterValues = _times; selectedFilterValue = _selectedTime; subLabels = _buildTimeDates(); break;
      default: filterValues = []; break;
    }

    return Padding(padding: EdgeInsets.only(top: 6, left: 16, right: 16, bottom: 32), child:
      Container(decoration: BoxDecoration(color: Styles().colors!.fillColorSecondary, borderRadius: BorderRadius.circular(5.0)), child: 
        Padding(padding: EdgeInsets.only(top: 2), child:
          Container(color: Colors.white, child:
            ListView.separated(
              shrinkWrap: true,
              separatorBuilder: (context, index) => Divider(height: 1, color: Styles().colors!.fillColorPrimaryTransparent03,),
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
      _TimeFilter.ThisWeek:  _DateInterval(startDate: DateTime(now.year, now.month, now.day - now.weekday + 1) ),
      _TimeFilter.LastWeek:  _DateInterval(startDate: DateTime(now.year, now.month, now.day - now.weekday + 1 - 7), endDate: DateTime(now.year, now.month, now.day - now.weekday)),
      _TimeFilter.ThisMonth: _DateInterval(startDate: DateTime(now.year, now.month, 1)),
      _TimeFilter.LastMonth: _DateInterval(startDate: DateTime(now.year, now.month - 1, 1), endDate: DateTime(now.year, now.month, 0)),
    };
  }

  void _onFilterValue(_FilterType? filterType, _FilterEntry filterEntry) {
    Analytics().logSelect(target: "FilterItem: ${filterEntry.name}");
    setState(() {
      switch(filterType) {
        case _FilterType.Category: _selectedCategory = filterEntry.value; break;
        case _FilterType.Time: _selectedTime = filterEntry.value; break;
        default: break;
      }
      _selectedFilter = null;
    });

    _loadInitialContent();
  }

  // Header bar

  Widget _buildEditBar() {
    List<Widget> contentList = <Widget>[];
    if (_isEditMode == true) {
      contentList.addAll(<Widget>[
        _isAllMessagesSelected ? _buildDeselectAllButton() : _buildSelectAllButton(),
        _buildDoneButton()
      ]);
    }
    else {
      contentList.add(_buildEditButton());
    }
    
    if ((_isEditMode == true) && _isAnyMessageSelected) {
      contentList.insert(0, _buildOptionsButton());
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.end, children: contentList);
  }

  Widget _buildOptionsButton() {
    return Semantics(label: Localization().getStringEx('headerbar.options.title', 'Options'), hint: Localization().getStringEx('headerbar.options.hint', ''), button: true, excludeSemantics: true, child:
      Stack(children: [
        IconButton(icon: Image.asset('images/groups-more-inactive.png', color: Styles().colors!.fillColorPrimary), onPressed: _onOptions),
        Visibility(visible: (_processingOption == true), child:
          Container(padding: EdgeInsets.all(13), child:
            SizedBox(width: 22, height: 22, child:
              CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.white),),
            ),
          ),
        ),
      ],)
    );
  }

  Widget _buildEditButton() {
    return Semantics(label: Localization().getStringEx('headerbar.edit.title', 'Edit'), hint: Localization().getStringEx('headerbar.edit.hint', ''), button: true, excludeSemantics: true, child:
      TextButton(onPressed: _onEdit, child:
        Text(Localization().getStringEx('headerbar.edit.title', 'Edit'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.medium),)
      ));
  }

  Widget _buildDoneButton() {
    return Semantics(label: Localization().getStringEx('headerbar.done.title', 'Done'), hint: Localization().getStringEx('headerbar.done.hint', ''), button: true, excludeSemantics: true, child:
      TextButton(onPressed: _onDone, child:
        Text(Localization().getStringEx('headerbar.done.title', 'Done'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.medium),)
      ));
  }

  Widget _buildSelectAllButton() {
    return Semantics(label: Localization().getStringEx('headerbar.select.all.title', 'Select All'), hint: Localization().getStringEx('headerbar.select.all.hint', ''), button: true, excludeSemantics: true, child:
      TextButton(onPressed: _onSelectAll, child:
        Text(Localization().getStringEx('headerbar.select.all.title', 'Select All'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.medium),)
      ));
  }

  Widget _buildDeselectAllButton() {
    return Semantics(label: Localization().getStringEx('headerbar.deselect.all.title', 'Deselect All'), hint: Localization().getStringEx('headerbar.deselect.all.hint', ''), button: true, excludeSemantics: true, child:
      TextButton(onPressed: _onDeselectAll, child:
        Text(Localization().getStringEx('headerbar.deselect.all.title', 'Deselect All'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.medium),)
      ));
  }

  Widget _buildOptions(BuildContext context) {
    String headingText = (_selectedMessageIds.length == 1) ?
      '1 Message Selected' :
      '${_selectedMessageIds.length} Messages Selected';

    return Container(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16), child:
      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 16), child:
          Row(children:<Widget>[Expanded(child:
            Text(headingText, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold),)
          )]),
        ),

        Row(children:<Widget>[Expanded(child: Container(color: Styles().colors!.fillColorPrimaryTransparent015, height: 1))]),

        InkWell(onTap: () => _onDelete(context), child:
          Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
            Row(children:<Widget>[
              Padding(padding: EdgeInsets.only(right: 8), child:
                Image.asset('images/icon-delete-group.png')
              ),
              Expanded(child:
                Text("Delete", style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold),)
              ),
            ]),
          )
        ),

        Row(children:<Widget>[Expanded(child: Container(color: Styles().colors!.fillColorPrimaryTransparent015, height: 1))]),

        InkWell(onTap: () => _onCancelOptions(context), child:
          Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
            Row(children:<Widget>[
              Padding(padding: EdgeInsets.only(right: 8), child:
                Image.asset('images/close-orange.png', width: 18, height: 18)
              ),
              Expanded(child:
                Text("Cancel", style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold),)
              ),
            ]),
          )
        ),

        Row(children:<Widget>[Expanded(child: Container(color: Styles().colors!.fillColorPrimaryTransparent015, height: 1))]),
      ]),
    );
  }

  Widget _buildConfirmationDialog(BuildContext context, {String? title, String? message, String? positiveButtonTitle, String? negativeButtonTitle, void Function()? onPositive}) {
    return StatefulBuilder(builder: (context, setState) {
      return ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
        Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), ), child:
          Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Row(children: <Widget>[
              Expanded(child:
                Container(decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.vertical(top: Radius.circular(8)), ), child:
                  Padding(padding: EdgeInsets.all(16), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        Text(title!, style: TextStyle(fontSize: 20, color: Colors.white, fontFamily: Styles().fontFamilies!.bold),),
                      ),
                      Semantics(label: "Close", button: true,  child:
                        GestureDetector(onTap: () => Navigator.pop(context), child:
                          Container(height: 30, width: 30, decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(15)), border: Border.all(color: Styles().colors!.white!, width: 2), ), child:
                            Center(child:
                              Text('\u00D7', style: TextStyle(fontSize: 24, color: Colors.white, fontFamily: Styles().fontFamilies!.bold), semanticsLabel: "",),
                            ),
                          )
                        ),
                      ),
                    ],),
                  ),
                ),
              ),
            ],),

            Padding(padding: const EdgeInsets.all(16), child:
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Container(height: 16),
                Text(message!, textAlign: TextAlign.left, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 18, color: Styles().colors!.fillColorPrimary),),
                Container(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                  Expanded(child:
                    RoundedButton(label: negativeButtonTitle ?? '', onTap: () => _onCancelConfirmation(message: message, selection: negativeButtonTitle), backgroundColor: Colors.transparent, borderColor: Styles().colors!.fillColorPrimary, textColor: Styles().colors!.fillColorPrimary,),
                  ),
                  Container(width: 8, ),
                  Expanded(child:
                    RoundedButton(label: positiveButtonTitle ?? '', onTap: onPositive ?? (){}, backgroundColor: Styles().colors!.fillColorSecondaryVariant, borderColor: Styles().colors!.fillColorSecondaryVariant, textColor: Styles().colors!.surface, ),
                  ),
                ],)
              ],)
            ),
          ]),
        ),
      ); },
    );
  }

  void _onEdit() {
    Analytics().logSelect(target: "Edit");
    setState(() {
      _isEditMode = true;
      _selectedMessageIds.clear();
    });
  }

  void _onDone() {
    Analytics().logSelect(target: "Done");
    setState(() {
      _isEditMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _onSelectAll() {
    Analytics().logSelect(target: "Select All");
    setState(() {
      for (InboxMessage message in _messages) {
        if (message.messageId != null) {
          _selectedMessageIds.add(message.messageId!);
        }
      }
    });
  }

  void _onDeselectAll() {
    Analytics().logSelect(target: "Deselect All");
    setState(() {
      _selectedMessageIds.clear();
    });
  }

  void _onOptions() {
    Analytics().logSelect(target: "Options");
    showModalBottomSheet(context: context, backgroundColor: Colors.white, isScrollControlled: true, isDismissible: true, builder: _buildOptions);
  }

  void _onCancelOptions(BuildContext context) {
    Analytics().logSelect(target: "Cancel");
    Navigator.pop(context);
  }

  void _onDelete(BuildContext context) {
    Analytics().logSelect(target: "Delete");
    Navigator.pop(context);

    String message = (_selectedMessageIds.length == 1) ?
      'Delete 1 message?' :
      'Delete ${_selectedMessageIds.length} messages?';
    showDialog(context: context, builder: (context) => _buildConfirmationDialog(context,
      title: 'Delete',
      message: message,
      positiveButtonTitle: 'OK',
      negativeButtonTitle: 'Cancel',
      onPositive: () => _onDeleteConfirm(context)
    ));
  }

  void _onDeleteConfirm(BuildContext context) {
    Navigator.pop(context);
    setState(() {
      _processingOption = true;
    });
    Inbox().deleteMessages(_selectedMessageIds).then((bool result) {
      if (mounted) {
        setState(() {
          _processingOption = false;
          if (result == true) {
            _selectedMessageIds.clear();
            _isEditMode = false;
          }
        });
        if (result == true) {
          _refreshContent();
        }
        else {
          AppAlert.showDialogResult(this.context, "Failed to delete message(s).");
        }
      }
    });
  }

  void _onCancelConfirmation({String? message, String? selection}) {
    Analytics().logAlert(text: "Remove My Information", selection: "No");
    Navigator.pop(context);
  }

  Future<void> _onPullToRefresh() async {
    int limit = max(_messages.length, _messagesPageSize);
    _DateInterval? selectedTimeInterval = (_selectedTime != null) ? _getTimeFilterIntervals()[_selectedTime] : null;
    List<InboxMessage>? messages = await Inbox().loadMessages(offset: 0, limit: limit, category: _selectedCategory, startDate: selectedTimeInterval?.startDate, endDate: selectedTimeInterval?.endDate);
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

  bool get _isAllMessagesSelected {
    return _selectedMessageIds.length == _messages.length;
  }

  bool get _isAnyMessageSelected {
    return 0 < _selectedMessageIds.length;
  }

  // Content

  void _loadInitialContent() {
    setState(() {
      _loading = true;
    });

    _DateInterval? selectedTimeInterval = (_selectedTime != null) ? _getTimeFilterIntervals()[_selectedTime] : null;
    Inbox().loadMessages(offset: 0, limit: _messagesPageSize, category: _selectedCategory, startDate: selectedTimeInterval?.startDate, endDate: selectedTimeInterval?.endDate).then((List<InboxMessage>? messages) {
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
    Inbox().loadMessages(offset: _messages.length, limit: _messagesPageSize, category: _selectedCategory, startDate: selectedTimeInterval?.startDate, endDate: selectedTimeInterval?.endDate).then((List<InboxMessage>? messages) {
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
    setState(() {
      _loading = true;
    });

    int limit = max(messagesCount ?? _messages.length, _messagesPageSize);
    _DateInterval? selectedTimeInterval = (_selectedTime != null) ? _getTimeFilterIntervals()[_selectedTime] : null;
    Inbox().loadMessages(offset: 0, limit: limit, category: _selectedCategory, startDate: selectedTimeInterval?.startDate, endDate: selectedTimeInterval?.endDate).then((List<InboxMessage>? messages) {
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
  Category, Time
}

class _InboxMessageCard extends StatefulWidget {
  final InboxMessage? message;
  final bool? selected;
  final void Function()? onTap;
  
  _InboxMessageCard({this.message, this.selected, this.onTap });

  @override
  _InboxMessageCardState createState() {
    return _InboxMessageCardState();
  }
}

class _InboxMessageCardState extends State<_InboxMessageCard> implements NotificationsListener {

  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);
    _isFavorite = Auth2().isFavorite(widget.message);
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setState(() {
        _isFavorite = Auth2().isFavorite(widget.message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double leftPadding = (widget.selected != null) ? 12 : 16;
    return Container(
        decoration: BoxDecoration(
          color: Styles().colors!.white,
          borderRadius: BorderRadius.all(Radius.circular(4)),
          boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]
        ),
        clipBehavior: Clip.none,
        child: Stack(children: [
          InkWell(onTap: widget.onTap, child:
            Padding(padding: EdgeInsets.only(left: leftPadding, right: 16, top: 16, bottom: 16), child:
              Row(children: <Widget>[
                Visibility(visible: (widget.selected != null), child:
                  Padding(padding: EdgeInsets.only(right: leftPadding), child:
                    Semantics(label:(widget.selected == true) ? "Selected" : "Not Selected", child:
                      Image.asset((widget.selected == true) ? 'images/deselected-dark.png' : 'images/deselected.png', excludeFromSemantics: true,),
                    )
                  ),
                ),
                
                Expanded(child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    StringUtils.isNotEmpty(widget.message?.category) ?
                      Padding(padding: EdgeInsets.only(bottom: 3), child:
                        Row(children: [
                          Expanded(child:
                            Text(widget.message?.category ?? '', semanticsLabel: "Category: ${widget.message?.category ?? ''}, ",style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary))
                      )])) : Container(),
                    
                    StringUtils.isNotEmpty(widget.message?.subject) ?
                      Padding(padding: EdgeInsets.only(bottom: 4), child:
                        Row(children: [
                          Expanded(child:
                            Text(widget.message?.subject ?? '', semanticsLabel: "Subject: ${widget.message?.subject ?? ''}, ", style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary))
                      )])) : Container(),

                    StringUtils.isNotEmpty(widget.message?.body) ?
                      Padding(padding: EdgeInsets.only(bottom: 6), child:
                        Row(children: [
                          Expanded(child:
                            Text(widget.message?.body ?? '', semanticsLabel: "Body: ${widget.message?.body ?? ''}, ", style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground))
                      )])) : Container(),

                    Row(children: [
                      Expanded(child:
                        Text(widget.message?.displayInfo ?? '', style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 14, color: Styles().colors!.textSurface))
                    )]),
                  ])
                ),
              ],)
            ),
          ),
          Container(color: Styles().colors!.fillColorSecondary, height: 4),
          Visibility(visible: Auth2().canFavorite, child:
            Align(alignment: Alignment.topRight, child:
            Semantics(
              label: _isFavorite
                  ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                  : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
              hint: _isFavorite
                  ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                  : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
              button: true,
              child:
              GestureDetector(onTap: _onTapFavorite, child:
                Container(padding: EdgeInsets.all(9), child:
                  Image.asset(_isFavorite ? 'images/icon-star-blue.png' : 'images/icon-star-gray-frame-thin.png', excludeFromSemantics: true,)
            ),)),),),
        ],)
    );
  }

  void _onTapFavorite() {
    Analytics().logSelect(target: "Favorite: ${widget.message!.subject}");
    setState(() {
      Auth2().prefs?.toggleFavorite(widget.message);
    });
  }
}
