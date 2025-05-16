/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/messages/MessagesDirectoryPanel.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/messages/MessagesWidgets.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class MessagesHomePanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'messages_home_content_panel';

  static int get conversationsPageSize => _MessagesHomePanelState._conversationsPageSize;

  // 1) Add a field to hold the search text
  final String? search;
  final List<Conversation>? conversations;
  static bool enableMute = false;

  // Make the constructor private, but accept the new param
  MessagesHomePanel._({Key? key, this.search, this.conversations}) : super(key: key);

  // 2) Add an optional `search` param to present()
  static void present(BuildContext context, { String? search, List<Conversation>? conversations }) {
    if (!Auth2().isLoggedIn) {
      AppAlert.showLoggedOutFeatureNAMessage(context, Localization().getStringEx('generic.app.feature.conversations', 'Conversations'));
    }
    else if (ModalRoute.of(context)?.settings.name != routeName) {
      MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
      double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        useRootNavigator: true,
        routeSettings: RouteSettings(name: routeName),
        clipBehavior: Clip.antiAlias,
        backgroundColor: Styles().colors.background,
        constraints: BoxConstraints(maxHeight: height, minHeight: height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        // Pass the `search` parameter into our constructor:
        builder: (context) => MessagesHomePanel._(search: search, conversations: conversations),
      );
    }
  }

  @override
  _MessagesHomePanelState createState() => _MessagesHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Messages;
}

class _MessagesHomePanelState extends State<MessagesHomePanel> with NotificationsListener, TickerProviderStateMixin {
  final List<_FilterEntry> _mutedValues = MessagesHomePanel.enableMute ? [
    _FilterEntry(name: Localization().getStringEx("panel.messages.label.muted.show", "Show Muted"), value: null),
    _FilterEntry(name: Localization().getStringEx("panel.messages.label.muted.hide", "Hide Muted"), value: false),
  ] : [];

  final List<_FilterEntry> _times = [
    _FilterEntry(name: Localization().getStringEx("panel.messages.label.time.any", "Any Time"), value: null),
    _FilterEntry(name: Localization().getStringEx("panel.messages.label.time.today", "Today"), value: _TimeFilter.Today),
    _FilterEntry(name: Localization().getStringEx("panel.messages.label.time.yesterday", "Yesterday"), value: _TimeFilter.Yesterday),
    _FilterEntry(name: Localization().getStringEx("panel.messages.label.time.this_week", "This week"), value: _TimeFilter.ThisWeek),
    _FilterEntry(name: Localization().getStringEx("panel.messages.label.time.last_week", "Last week"), value: _TimeFilter.LastWeek),
    _FilterEntry(name: Localization().getStringEx("panel.messages.label.time.this_month", "This month"), value: _TimeFilter.ThisMonth),
    _FilterEntry(name: Localization().getStringEx("panel.messages.label.time.last_month", "Last Month"), value: _TimeFilter.LastMonth),
  ];

  static const int _conversationsPageSize = 20;

  _TimeFilter? _selectedTime;
  bool? _selectedMutedValue;
  _FilterType? _selectedFilter;
  bool? _hasMoreConversations;

  bool? _loading, _loadingMore, _processingOption;
  List<Conversation> _conversations = <Conversation>[];
  ScrollController _scrollController = ScrollController();

  bool _isEditMode = false;
  Set<String> _selectedConversationIds = Set<String>();

  String _searchText = '';

  // bool _loadingMarkAllAsRead = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Social.notifyConversationsUpdated,
      Social.notifyMessageSent,
      Social.notifyMessageEdited,
      Social.notifyMessageDeleted,
    ]);

    _scrollController.addListener(_scrollListener);
    _searchText = widget.search ?? '';

    if (widget.conversations?.isNotEmpty == true) {
      _conversations = widget.conversations!;
    }
    else {
      _loadContent();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == Social.notifyConversationsUpdated ||
        name == Social.notifyMessageSent ||
        name == Social.notifyMessageEdited ||
        name == Social.notifyMessageDeleted) {
      if (mounted) {
        _loadContent();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(color: Styles().colors.backgroundAccent, child:
        Row(children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16), child:
              Text(Localization().getStringEx('panel.messages.header.messages.label', 'CONVERSATIONS'), style: Styles().textStyles.getTextStyle("widget.title.light.large.fat"),)
            ),
          ),
          Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
            InkWell(onTap : _onTapClose, child:
              Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
                Styles().images.getImage('close-circle-white', excludeFromSemantics: true),
              ),
            ),
          ),
        ],),
      ),
      // _buildBanner(),
      _buildAdditionalButtons(),
      _buildFilters(),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DirectoryFilterBar(
          key: ValueKey(_searchText),
          searchText: _searchText,
          onSearchText: _onSearchText,
        ),
      ),
      Expanded(child:
        _buildPage(context),
      )
    ],);
  }

  Widget _buildPage(BuildContext context) {
    return Container(
      color: Styles().colors.background,
      child: Stack(children: [
        Visibility(visible: (_loading != true), child:
          Padding(padding: EdgeInsets.symmetric(vertical: 12), child: _buildConversationsContent())
        ),
        Visibility(visible: (_loading == true), child:
          Align(alignment: Alignment.center, child:
            CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary), )
          )
        ),
        Visibility(visible: (_selectedFilter != null), child:
          Stack(children:<Widget>[
            _buildDisabledContentLayer(),
            _buildFilterValues(),
          ]),
        ),
      ]),
    );
  }

  Widget _buildConversationsContent() {
    if (_conversations.isNotEmpty) {
      int count = _conversations.length + ((_loadingMore == true) ? 1 : 0);
      return RefreshIndicator(
        onRefresh: _onPullToRefresh,
        child: ListView.separated(
            separatorBuilder: (context, index) => Container(height: 16),
            itemCount: count,
            itemBuilder: _buildListEntry,
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
        ),
      );
    }
    else {
      return Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text(Localization().getStringEx('panel.messages.label.content.empty', 'No conversations'), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.title.regular.thin')),
        Expanded(child: Container(), flex: 2),
      ]);
    }
  }

  Widget _buildListEntry(BuildContext context, int index) {
    if ((0 <= index) && (index < _conversations.length)) {
      Conversation entry = _conversations[index];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ConversationCard(
          conversation: entry,
          selected: (_isEditMode == true) ? _selectedConversationIds.contains(entry.id) : null,
          onTap: (_isEditMode == true) ? _handleSelectionTap : null,
        ),
      );
    }
    else if (index == _conversations.length) {
      // loading more conversations
      return _buildListLoadingIndicator();
    }
    return Container();
  }

  Widget _buildListLoadingIndicator() {
    return Container(padding: EdgeInsets.all(6), child:
      Align(alignment: Alignment.center, child:
        SizedBox(width: 24, height: 24, child:
          CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),
        ),
      ),
    ),);
  }

  void _handleSelectionTap(Conversation conversation) {
    Analytics().logSelect(target: conversation.id);
    setState(() {
      if (conversation.id != null) {
        if (_selectedConversationIds.contains(conversation.id)) {
          _selectedConversationIds.remove(conversation.id);
          AppSemantics.announceMessage(context, "Deselected");
        } else {
          _selectedConversationIds.add(conversation.id!);
          AppSemantics.announceMessage(context, "Selected");
        }
      }
    });
  }

  // Banner
  /*
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
                          "Messages Paused",
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
  */

  //Buttons
  Widget _buildAdditionalButtons() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child:
      Align(alignment: Alignment.centerRight, child:
        _buildNewMessageButton(),
      )
      //Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // _buildReadAllButton(), //TODO: uncomment once implemented on Social BB
        //Spacer(),
        //Flexible(flex: 1, child: _buildNewMessageButton()),
      //],),
    );
  }

  // Widget _buildReadAllButton() {
  //   return Semantics(container: true, child: Container(
  //       child: UnderlinedButton(
  //           title: Localization().getStringEx("panel.messages.mark_all_read.label", "Mark all as read"),
  //           // titleStyle: Styles().textStyles.getTextStyle("widget.button.light.title.medium"),
  //           padding: EdgeInsets.symmetric(vertical: 8),
  //           progress: _loadingMarkAllAsRead,
  //           onTap: _onTapMarkAllAsRead)));
  // }

  Widget _buildNewMessageButton() {
    String title = Localization().getStringEx('panel.messages.button.new.title', 'New Conversation');
    String hint = Localization().getStringEx('panel.messages.button.new.hint', '');
    Widget? iconW = Styles().images.getImage('plus-circle-white', color: Styles().colors.textColorPrimary);
    Widget? textW = Text(title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.variant2"), maxLines: 1, overflow: TextOverflow.ellipsis);
    return Semantics(label: title, hint: hint, button: true, excludeSemantics: true, child:
      GestureDetector(onTap: _onTapNewMessage, child:
        Container(decoration: BoxDecoration(color: Styles().colors.fillColorSecondary, borderRadius: BorderRadius.all(Radius.circular(8))), child:
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            (iconW != null) ? Row(mainAxisSize: MainAxisSize.min, children: [
              Padding(padding: const EdgeInsets.only(right: 8), child: iconW),
              textW,
            ],) : textW,
          )
        ),
      )
    );
  }

  // Filters
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child:
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        if (MessagesHomePanel.enableMute)
          FilterSelector(
            padding: EdgeInsets.symmetric(horizontal: 4),
            title: _FilterEntry.entryInList(_mutedValues, _selectedMutedValue)?.name ?? '',
            titleTextStyle: Styles().textStyles.getTextStyle('widget.button.title.medium.fat'),
            activeTitleTextStyle: Styles().textStyles.getTextStyle('widget.button.title.medium.fat.secondary'),
            active: _selectedFilter == _FilterType.Muted,
            onTap: () { _onFilter(_FilterType.Muted); }
        ),
        FilterSelector(
            padding: EdgeInsets.symmetric(horizontal: 4),
            title: _FilterEntry.entryInList(_times, _selectedTime)?.name ?? '',
            titleTextStyle: Styles().textStyles.getTextStyle('widget.button.title.medium.fat'),
            activeTitleTextStyle: Styles().textStyles.getTextStyle('widget.button.title.medium.fat.secondary'),
            active: _selectedFilter == _FilterType.Time,
            onTap: () { _onFilter(_FilterType.Time); }
        ),
        Visibility(
          visible: MessagesHomePanel.enableMute == true,
          child: _buildEditBar()
        ),
      ],
      )),
    );
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
      case _FilterType.Muted: filterValues = _mutedValues; selectedFilterValue = _selectedMutedValue; subLabels = null; break;
      case _FilterType.Time: filterValues = _times; selectedFilterValue = _selectedTime; subLabels = _buildTimeDates(); break;
      default: filterValues = []; break;
    }

    return Padding(padding: EdgeInsets.only(top: 6, left: 16, right: 16, bottom: 32), child:
      Container(decoration: BoxDecoration(color: Styles().colors.fillColorSecondary, borderRadius: BorderRadius.circular(5.0)), child:
        Padding(padding: EdgeInsets.only(top: 2), child:
          Container(color: Styles().colors.surface, child:
            ListView.separated(
                shrinkWrap: true,
                separatorBuilder: (context, index) => Divider(height: 1, color: Styles().colors.fillColorPrimary.withAlpha(77),),
                itemCount: filterValues.length,
                itemBuilder: (context, index) {
                  return FilterListItem(
                    title: filterValues[index].name,
                    description: (subLabels != null) ? subLabels[index] : null,
                    iconKey: (selectedFilterValue == filterValues[index].value) ? 'check-circle-filled' : 'check-circle-outline-gray',
                    onTap: () {
                      _onFilterValue(_selectedFilter, filterValues[index]);
                    },
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
    Map<_TimeFilter, _DateTimeInterval> intervals = _getTimeFilterIntervals();

    List<String> timeDates = <String>[];
    for (_FilterEntry timeEntry in _times) {
      String? timeDate;
      _DateTimeInterval? interval = intervals[timeEntry.value];
      if (interval != null) {
        DateTime startDate = interval.fromTime!;
        String? startStr = AppDateTime().formatDateTime(interval.fromTime, format: 'MM/dd', ignoreTimeZone: true);

        DateTime endDate = interval.toTime ?? today;
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

  static Map<_TimeFilter, _DateTimeInterval> _getTimeFilterIntervals() {
    DateTime now = DateTime.now();
    return {
      _TimeFilter.Today:     _DateTimeInterval(fromTime: DateTime(now.year, now.month, now.day)),
      _TimeFilter.Yesterday: _DateTimeInterval(fromTime: DateTime(now.year, now.month, now.day - 1), toTime: DateTime(now.year, now.month, now.day)),
      _TimeFilter.ThisWeek:  _DateTimeInterval(fromTime: DateTime(now.year, now.month, now.day - now.weekday + 1)),
      _TimeFilter.LastWeek:  _DateTimeInterval(fromTime: DateTime(now.year, now.month, now.day - now.weekday + 1 - 7), toTime: DateTime(now.year, now.month, now.day - now.weekday + 1)),
      _TimeFilter.ThisMonth: _DateTimeInterval(fromTime: DateTime(now.year, now.month, 1)),
      _TimeFilter.LastMonth: _DateTimeInterval(fromTime: DateTime(now.year, now.month - 1, 1), toTime: DateTime(now.year, now.month, 0)),
    };
  }

  void _onFilterValue(_FilterType? filterType, _FilterEntry filterEntry) {
    Analytics().logSelect(target: "FilterItem: ${filterEntry.name}");
    bool shouldLoadContent = false;
    setState(() {
      switch(filterType) {
        case _FilterType.Muted:
          if (_selectedMutedValue != filterEntry.value) {
            _selectedMutedValue = filterEntry.value;
            shouldLoadContent = true;
          }
          break;
        case _FilterType.Time:
          if (_selectedTime != filterEntry.value) {
            _selectedTime = filterEntry.value;
            shouldLoadContent = true;
          }
          break;
        default: break;
      }
      _selectedFilter = null;
    });

    if (shouldLoadContent) {
      _loadContent();
    }
  }

  // Header bar

  Widget _buildEditBar() {
    List<Widget> contentList = <Widget>[];
    if (_isEditMode == true) {
      contentList.addAll(<Widget>[
        _isAllConversationsSelected ? _buildDeselectAllButton() : _buildSelectAllButton(),
        _buildDoneButton()
      ]);
    }
    else {
      contentList.add(_buildEditButton());
    }

    if ((_isEditMode == true) && _isAnyConversationSelected) {
      contentList.insert(0, _buildOptionsButton());
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.end, children: contentList);
  }

  Widget _buildOptionsButton() {
    return Semantics(label: Localization().getStringEx('headerbar.options.title', 'Options'), hint: Localization().getStringEx('headerbar.options.hint', ''), button: true, excludeSemantics: true, child:
      Stack(children: [
        IconButton(icon: Styles().images.getImage('more') ?? Container(), onPressed: _onOptions),
        Visibility(visible: (_processingOption == true), child:
          Container(padding: EdgeInsets.all(13), child:
            SizedBox(width: 22, height: 22, child:
              CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.surface),),
            ),
          ),
        ),
      ],)
    );
  }

  Widget _buildEditButton() {
    return Semantics(label: Localization().getStringEx('headerbar.edit.title', 'Edit'), hint: Localization().getStringEx('headerbar.edit.hint', ''), button: true, excludeSemantics: true, child:
      TextButton(onPressed: _onEdit, child:
        Text(Localization().getStringEx('headerbar.edit.title', 'Edit'), style:  Styles().textStyles.getTextStyle("widget.button.light.title.medium"),)
      )
    );
  }

  Widget _buildDoneButton() {
    return Semantics(label: Localization().getStringEx('headerbar.done.title', 'Done'), hint: Localization().getStringEx('headerbar.done.hint', ''), button: true, excludeSemantics: true, child:
    TextButton(onPressed: _onDone, child:
    Text(Localization().getStringEx('headerbar.done.title', 'Done'), style:  Styles().textStyles.getTextStyle("widget.button.light.title.medium"),)
    ));
  }

  Widget _buildSelectAllButton() {
    return Semantics(label: Localization().getStringEx('headerbar.select.all.title', 'Select All'), hint: Localization().getStringEx('headerbar.select.all.hint', ''), button: true, excludeSemantics: true, child:
    TextButton(onPressed: _onSelectAll, child:
    Text(Localization().getStringEx('headerbar.select.all.title', 'Select All'), style:  Styles().textStyles.getTextStyle("widget.button.light.title.medium"),)
    ));
  }

  Widget _buildDeselectAllButton() {
    return Semantics(label: Localization().getStringEx('headerbar.deselect.all.title', 'Deselect All'), hint: Localization().getStringEx('headerbar.deselect.all.hint', ''), button: true, excludeSemantics: true, child:
    TextButton(onPressed: _onDeselectAll, child:
    Text(Localization().getStringEx('headerbar.deselect.all.title', 'Deselect All'), style:  Styles().textStyles.getTextStyle("widget.button.light.title.medium"),)
    ));
  }

  Widget _buildOptions(BuildContext context) {
    String headingText = (_selectedConversationIds.length == 1) ?
    '1 Conversation Selected' :
    '${_selectedConversationIds.length} Conversations Selected';

    return Container(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16), child:
    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Padding(padding: EdgeInsets.only(bottom: 16), child:
        Row(children:<Widget>[Expanded(child:
          Text(headingText, style: Styles().textStyles.getTextStyle("widget.title.dark.regular.fat"),)
        )]),
      ),

      Row(children:<Widget>[Expanded(child: Container(color: Styles().colors.fillColorPrimary.withAlpha(38), height: 1))]),

    if (MessagesHomePanel.enableMute) ...[
    InkWell(onTap: () => _onToggleMute(mute: true), child:
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
          Row(children:<Widget>[
            Padding(padding: EdgeInsets.only(right: 8), child:
              Styles().images.getImage('notification-off')
            ),
            Expanded(child:
              Text("Mute", style: Styles().textStyles.getTextStyle("widget.button.title.regular"),)
            ),
          ]),
        )
      ),
    ],

      Row(children:<Widget>[Expanded(child: Container(color: Styles().colors.fillColorPrimary.withAlpha(38), height: 1))]),

      InkWell(onTap: () => _onToggleMute(mute: false), child:
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
          Row(children:<Widget>[
            Padding(padding: EdgeInsets.only(right: 8), child:
              Styles().images.getImage('notification-orange')
            ),
            Expanded(child:
              Text("Unmute", style: Styles().textStyles.getTextStyle("widget.button.title.regular"),)
            ),
          ]),
        )
      ),

      // Row(children:<Widget>[Expanded(child: Container(color: Styles().colors.fillColorPrimary.withAlpha(38), height: 1))]),

      //TODO: what does deleting a conversation mean?
      // InkWell(onTap: () => _onDelete(context), child:
      //   Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
      //     Row(children:<Widget>[
      //       Padding(padding: EdgeInsets.only(right: 8), child:
      //         Styles().images.getImage('trash')
      //       ),
      //       Expanded(child:
      //         Text("Delete", style: Styles().textStyles.getTextStyle("widget.button.title.regular"),)
      //       ),
      //     ]),
      //   )
      // ),

      Row(children:<Widget>[Expanded(child: Container(color: Styles().colors.fillColorPrimary.withAlpha(38), height: 1))]),

      InkWell(onTap: () => _onCancelOptions(context), child:
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
          Row(children:<Widget>[
            Padding(padding: EdgeInsets.only(right: 8), child:
              Styles().images.getImage('close-circle', excludeFromSemantics: true)
            ),
            Expanded(child:
              Text("Cancel", style: Styles().textStyles.getTextStyle("widget.button.title.regular"),)
            ),
          ]),
        )
      ),

      Row(children:<Widget>[Expanded(child: Container(color: Styles().colors.fillColorPrimary.withAlpha(38), height: 1))]),
    ]),
    );
  }

  /*
  Widget _buildConfirmationDialog(BuildContext context, {String? title, String? message, String? positiveButtonTitle, String? negativeButtonTitle, void Function()? onPositive}) {
    return StatefulBuilder(builder: (context, setState) {
      return ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
      Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), ), child:
      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Row(children: <Widget>[
          Expanded(child:
            Container(decoration: BoxDecoration(color: Styles().colors.fillColorPrimary, borderRadius: BorderRadius.vertical(top: Radius.circular(8)), ), child:
              Padding(padding: EdgeInsets.all(16), child:
                Row(children: <Widget>[
                  Expanded(child:
                    Text(title!, style: Styles().textStyles.getTextStyle("widget.dialog.message.regular.fat"),),
                  ),
                  Semantics(label: "Close", button: true,  child:
                    GestureDetector(onTap: () => Navigator.pop(context), child:
                      Container(height: 30, width: 30, decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(15)), border: Border.all(color: Styles().colors.surface, width: 2), ), child:
                        Center(child:
                          Text('\u00D7', style: Styles().textStyles.getTextStyle("widget.dialog.message.large.fat"), semanticsLabel: "",),
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
            Text(message!, textAlign: TextAlign.left, style: Styles().textStyles.getTextStyle("widget.message.medium"),),
            Container(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Expanded(child:
                RoundedButton(label: negativeButtonTitle ?? '', onTap: () => _onCancelConfirmation(message: message, selection: negativeButtonTitle), textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"), backgroundColor: Colors.transparent, borderColor: Styles().colors.fillColorPrimary,),
              ),
              Container(width: 8, ),
              Expanded(child:
                RoundedButton(label: positiveButtonTitle ?? '', onTap: onPositive ?? (){}, textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat.variant2"), backgroundColor: Styles().colors.fillColorSecondaryVariant, borderColor: Styles().colors.fillColorSecondaryVariant),
              ),
            ],)
          ],)
        ),
      ]),
      ),
      ); },
    );
  }
  */

  void _onEdit() {
    Analytics().logSelect(target: "Edit");
    setState(() {
      _isEditMode = true;
      _selectedConversationIds.clear();
    });
  }

  void _onDone() {
    Analytics().logSelect(target: "Done");
    setState(() {
      _isEditMode = false;
      _selectedConversationIds.clear();
    });
  }

  void _onSelectAll() {
    Analytics().logSelect(target: "Select All");
    setState(() {
      for (Conversation conversation in _conversations) {
        if (conversation.id != null) {
          _selectedConversationIds.add(conversation.id!);
        }
      }
    });
  }

  void _onDeselectAll() {
    Analytics().logSelect(target: "Deselect All");
    setState(() {
      _selectedConversationIds.clear();
    });
  }

  void _onOptions() {
    Analytics().logSelect(target: "Options");
    showModalBottomSheet(context: context, backgroundColor: Styles().colors.surface, isScrollControlled: true, isDismissible: true, builder: _buildOptions);
  }

  void _onCancelOptions(BuildContext context) {
    Analytics().logSelect(target: "Cancel");
    Navigator.pop(context);
  }

  void _onToggleMute({required bool mute}) {
    Analytics().logSelect(target: mute ? "Mute" : "Unmute");

    //TODO: bulk update conversation API on Social BB?
    for (String conversationId in _selectedConversationIds) {
      Social().updateConverstion(conversationId: conversationId, mute: mute);
    }

    setState(() {
      _selectedConversationIds.clear();
    });
    Navigator.pop(context);
  }

  /*
  void _onDelete(BuildContext context) {
    Analytics().logSelect(target: "Delete");
    Navigator.pop(context);

    String message = (_selectedConversationIds.length == 1) ?
    'Delete 1 conversation?' :
    'Delete ${_selectedConversationIds.length} conversations?';
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
    Inbox().deleteMessages(_selectedConversationIds).then((bool result) {
      if (mounted) {
        setState(() {
          _processingOption = false;
          if (result == true) {
            _selectedConversationIds.clear();
            _isEditMode = false;
          }
        });
        if (result == true) {
          // _refreshContent();
        }
        else {
          AppAlert.showDialogResult(this.context, "Failed to delete conversation(s).");
        }
      }
    });
  }

  void _onCancelConfirmation({String? message, String? selection}) {
    Analytics().logAlert(text: "Remove My Information", selection: "No");
    Navigator.pop(context);
  }
  */

  void _onTapNewMessage() {
    Analytics().logSelect(target: "Messages Directory");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MessagesDirectoryPanel(recentConversations: _conversations, conversationPageSize: _conversationsPageSize,)));
  }

  void _onSearchText(String searchText) {
    if (mounted) {
      setState(() {
        _searchText = searchText;
      });
      _loadContent();
    }
  }

  Future<void> _onPullToRefresh() async {
    _loadContent();
  }

  //TODO: implement once set up on Social BB
  // void _onTapMarkAllAsRead() {
  //   return;
  //   Analytics().logSelect(target: "Mark All As Read");
  //   _setMarkAllAsReadLoading(true);
  //   Inbox().markAllMessagesAsRead().then((succeeded) {
  //     if (succeeded) {
  //       _loadInitialContent();
  //     } else {
  //       AppAlert.showMessage(
  //           context, Localization().getStringEx('panel.messages.mark_as_read.failed.msg', 'Failed to mark all conversations as read'));
  //     }
  //     _setMarkAllAsReadLoading(false);
  //   });
  // }

  // void _setMarkAllAsReadLoading(bool loading) {
  //   setStateIfMounted(() {
  //     _loadingMarkAllAsRead = loading;
  //   });
  // }

  bool get _isAllConversationsSelected {
    return _selectedConversationIds.length == _conversations.length;
  }

  bool get _isAnyConversationSelected {
    return 0 < _selectedConversationIds.length;
  }

  // Content

  Future<void> _loadContent() async {
    setStateIfMounted(() {
      _loading = true;
    });

    _DateTimeInterval? selectedTimeInterval = (_selectedTime != null) ? _getTimeFilterIntervals()[_selectedTime] : null;
    // Load all conversations
    List<Conversation>? conversations = await Social().loadConversations(
      mute: _selectedMutedValue,
      offset: 0,
      limit: _conversationsPageSize,
      name: _searchText,
      fromTime: selectedTimeInterval?.fromTime,
      toTime: selectedTimeInterval?.toTime
    );

    if (mounted) {
      setState(() {
        _loading = false;
        if (conversations != null) {
          _conversations = conversations;
          Conversation.sortListByLastActivityTime(_conversations);
          _hasMoreConversations = (_conversationsPageSize <= conversations.length);
        } else {
          _conversations.clear();
          _hasMoreConversations = null;
        }
      });
    }
  }


  Future<void> _loadMoreContent() async {
    setState(() {
      _loadingMore = true;
    });

    _DateTimeInterval? selectedTimeInterval = (_selectedTime != null) ? _getTimeFilterIntervals()[_selectedTime] : null;
    List<Conversation>? conversations = await Social().loadConversations(
      mute: _selectedMutedValue,
      offset: _conversations.length,
      limit: _conversationsPageSize,
      name: _searchText,
      fromTime: selectedTimeInterval?.fromTime,
      toTime: selectedTimeInterval?.toTime
    );
    setStateIfMounted(() {
      if (conversations != null) {
        _conversations.addAll(conversations);
        _hasMoreConversations = (_conversationsPageSize <= conversations.length);
        // _contentList = _buildContentList();
      }
      _loadingMore = false;
    });
  }

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && (_hasMoreConversations != false) && (_loadingMore != true) && (_loading != true)) {
      _loadMoreContent();
    }
  }

  /*
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
  */

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
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

class _DateTimeInterval {
  final DateTime? fromTime;
  final DateTime? toTime;

  _DateTimeInterval({this.fromTime, this.toTime});

  bool contains(DateTime? dateTime) {
    if (dateTime == null) {
      return false;
    }
    else if ((fromTime != null) && fromTime!.isAfter(dateTime)) {
      return false;
    }
    else if ((toTime != null) && toTime!.isBefore(dateTime)) {
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