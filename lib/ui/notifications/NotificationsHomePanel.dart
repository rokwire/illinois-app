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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:illinois/ui/widgets/UnderlinedButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:illinois/ext/InboxMessage.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class NotificationsHomePanel extends StatefulWidget {
  static final String routeName = 'settings_notifications_content_panel';

  NotificationsHomePanel._();

  static void present(BuildContext context) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(
          context, Localization().getStringEx('panel.browse.label.offline.inbox', 'Notifications are not available while offline.'));
    } else if (!Auth2().isOidcLoggedIn) {
      AppAlert.showLoggedOutFeatureNAMessage(context, Localization().getStringEx('generic.app.feature.notifications', 'Notifications'));
    } else if (ModalRoute.of(context)?.settings.name != routeName) {
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
          builder: (context) {
            return NotificationsHomePanel._();
          });
    }
  }

  static void launchMessageDetail(InboxMessage message, { AnalyticsFeature? analyticsFeature } ) {
    Analytics().logNotification(message, feature: analyticsFeature);
    if (message.isRead == false) {
      Inbox().readMessage(message.messageId);
    }
    FirebaseMessaging().processDataMessageEx(message.data, allowedPayloadTypes: {
      FirebaseMessaging.payloadTypeHome,
      FirebaseMessaging.payloadTypeBrowse,
      FirebaseMessaging.payloadTypeMap,
      FirebaseMessaging.payloadTypeMapEvents,
      FirebaseMessaging.payloadTypeMapDining,
      FirebaseMessaging.payloadTypeMapBuildings,
      FirebaseMessaging.payloadTypeMapStudentCourses,
      FirebaseMessaging.payloadTypeMapAppointments,
      FirebaseMessaging.payloadTypeMapMtdStops,
      FirebaseMessaging.payloadTypeMapMyLocations,
      FirebaseMessaging.payloadTypeMapMentalHealth,
      FirebaseMessaging.payloadTypeMapLaundry,
      FirebaseMessaging.payloadTypeAcademics,
      FirebaseMessaging.payloadTypeAcademicsAppointments,
      FirebaseMessaging.payloadTypeAcademicsGiesCanvasCourses,
      FirebaseMessaging.payloadTypeAcademicsDueDateCatalog,
      FirebaseMessaging.payloadTypeAcademicsEvents,
      FirebaseMessaging.payloadTypeAcademicsGiesCheckilst,
      FirebaseMessaging.payloadTypeAcademicsMedicineCourses,
      FirebaseMessaging.payloadTypeAcademicsMyIllini,
      FirebaseMessaging.payloadTypeAcademicsSkillsSelfEvaluation,
      FirebaseMessaging.payloadTypeAcademicsStudentCourses,
      FirebaseMessaging.payloadTypeAcademicsToDoList,
      FirebaseMessaging.payloadTypeAcademicsUiucCheckilst,
      FirebaseMessaging.payloadTypeWellness,
      FirebaseMessaging.payloadTypeWellnessAppointments,
      FirebaseMessaging.payloadTypeWellnessDailyTips,
      FirebaseMessaging.payloadTypeWellnessHealthScreener,
      FirebaseMessaging.payloadTypeWellnessMentalHealth,
      FirebaseMessaging.payloadTypeWellnessResources,
      FirebaseMessaging.payloadTypeWellnessRings,
      FirebaseMessaging.payloadTypeWellnessTodoList,
      FirebaseMessaging.payloadTypeWellnessToDoItem,
      FirebaseMessaging.payloadTypeLaundry,
      FirebaseMessaging.payloadTypeEventDetail,
      FirebaseMessaging.payloadTypeEvent,
      FirebaseMessaging.payloadTypeGameDetail,
      FirebaseMessaging.payloadTypeAthleticsGameStarted,
      FirebaseMessaging.payloadTypeAthleticsNewDetail,
      FirebaseMessaging.payloadTypeGroup,
      FirebaseMessaging.payloadTypePostReaction,
      FirebaseMessaging.payloadTypeAppointment,
      FirebaseMessaging.payloadTypePoll,
      FirebaseMessaging.payloadTypeProfileMy,
      FirebaseMessaging.payloadTypeProfileWhoAreYou,
      FirebaseMessaging.payloadTypeProfileLogin,
      FirebaseMessaging.payloadTypeSettingsSections, //TBD deprecate. Use payloadTypeProfileLogin instead
      FirebaseMessaging.payloadTypeSettingsFoodFilters,
      FirebaseMessaging.payloadTypeSettingsSports,
      FirebaseMessaging.payloadTypeSettingsFavorites,
      FirebaseMessaging.payloadTypeSettingsAssessments,
      FirebaseMessaging.payloadTypeSettingsCalendar,
      FirebaseMessaging.payloadTypeSettingsAppointments,
      FirebaseMessaging.payloadTypeSocialMessage,
    });
  }

  @override
  _NotificationsHomePanelState createState() => _NotificationsHomePanelState();
}

class _NotificationsHomePanelState extends State<NotificationsHomePanel> with NotificationsListener {
  static final int _messagesPageSize = 8;
  static final double _defaultPaddingValue = 16;

  bool _isFilterVisible = false;

  bool? _unreadSelectedValue;
  bool? _mutedSelectedValue;
  _DateInterval? _dateIntervalSelectedValue;

  bool? _unreadPreviewValue;
  bool? _mutedPreviewValue;
  _TimeFilter? _timeFilterPreviewValue;

  bool? _hasMoreMessages, _loadingMessages, _loadingMoreMessages;
  bool _loadingMarkAllAsRead = false;

  List<InboxMessage> _messages = <InboxMessage>[];
  List<dynamic>? _contentList;
  ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Inbox.notifyInboxUserInfoChanged,
      Inbox.notifyInboxMessageRead,
      Inbox.notifyInboxMessagesDeleted
    ]);

    _scrollController.addListener(_scrollListener);

    // Show unread notifications only if NotificationsContent.unread content is selected.
    _unreadSelectedValue = _unreadPreviewValue = Storage().notificationsFilterUnread;
    _mutedSelectedValue = _mutedPreviewValue = (Storage().notificationsFilterMuted ?? false);
    _dateIntervalSelectedValue = _getDateIntervalBy(filter: (_timeFilterPreviewValue = _TimeFilterImpl.fromJson(Storage().notificationsFilterTimeInterval)));

    _loadMessages();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if(name == Inbox.notifyInboxUserInfoChanged){
      if(mounted){
        setState(() {
          //refresh
        });
      }
    } else if (name == Inbox.notifyInboxMessageRead) {
      _refreshMessages();
    } else if (name == Inbox.notifyInboxMessagesDeleted) {
      _refreshMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
          color: Styles().colors.white,
          child: Row(children: [
            Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Semantics(
                        container: true,
                        header: true,
                        child: Text(Localization().getStringEx('panel.settings.notifications.header.inbox.label', 'Notifications'),
                            style: Styles().textStyles.getTextStyle("widget.sheet.title.regular"))))),
            Semantics(
                label: Localization().getStringEx('dialog.close.title', 'Close'),
                hint: Localization().getStringEx('dialog.close.hint', ''),
                container: true,
                button: true,
                child: InkWell(
                    onTap: _onTapClose,
                    child: Container(
                        padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                        child: Styles().images.getImage('close-circle', excludeFromSemantics: true))))
          ])),
      Container(color: Styles().colors.surfaceAccent, height: 1),
      Expanded(child: Semantics(container: true, child: Container(color: Styles().colors.background, child: _contentWidget)))
    ]);
  }

  // Common Widgets

  Widget get _contentWidget => _isFilterVisible ? _buildFilterContent() : _buildInboxContent();

  // Inbox Widgets

  Widget _buildInboxContent() {
    return RefreshIndicator(
        onRefresh: _onPullToRefresh,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          _buildBanner(),
          _buildMessagesHeaderSection(),
          Expanded(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: _defaultPaddingValue),
                  child: Stack(children: [
                    Visibility(
                        visible: (_loadingMessages != true),
                        child: Padding(padding: EdgeInsets.only(top: 12), child: _buildMessagesContent())),
                    Visibility(
                        visible: (_loadingMessages == true),
                        child: Align(
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                                strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary))))
                  ])))
        ]));
  }

  Widget _buildMessagesContent() {
    if ((_contentList != null) && (0 < _contentList!.length)) {
      int count = _contentList!.length + ((_loadingMoreMessages == true) ? 1 : 0);
      return ListView.separated(
          separatorBuilder: (context, index) => Container(), itemCount: count, itemBuilder: _buildMessagesListEntry, controller: _scrollController);
    } else {
      return Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text(
          Localization().getStringEx('panel.inbox.label.content.empty', 'No messages'),
          textAlign: TextAlign.center,
        ),
        Expanded(child: Container(), flex: 3),
      ]);
    }
  }

  Widget _buildMessagesListEntry(BuildContext context, int index) {
    dynamic entry = ((_contentList != null) && (0 <= index) && (index < _contentList!.length)) ? _contentList![index] : null;
    if (entry is InboxMessage) {
      return Padding(padding: EdgeInsets.only(bottom: 20), child: InboxMessageCard(message: entry, onTap: () => _onTapMessage(entry)));
    } else if (entry is String) {
      return _buildMessagesListHeading(text: entry);
    } else {
      return _buildMessagesListLoadingIndicator();
    }
  }

  Widget _buildMessagesListHeading({String? text}) {
    return Semantics(
        header: true,
        child: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(text ?? '', style: Styles().textStyles.getTextStyle('widget.title.regular.fat'))));
  }

  Widget _buildMessagesListLoadingIndicator() {
    return Container(
        padding: EdgeInsets.only(left: 6, top: 6, right: 6, bottom: 20),
        child: Align(
            alignment: Alignment.center,
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary)))));
  }

  Widget _buildMessagesHeaderSection() {
    return Container(
        decoration: BoxDecoration(color: Styles().colors.white),
        child: Column(children: [
          Padding(padding: EdgeInsets.symmetric(horizontal: _defaultPaddingValue, vertical: 10), child:
            Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _buildFilterButton(),
              _buildReadAllButton()
            ]),
          ),
          if (_hasFilters)
            Column(children: [
              Container(color: Styles().colors.surfaceAccent, height: 1),
              Padding(padding: EdgeInsets.symmetric(horizontal: _defaultPaddingValue, vertical: 10), child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children:[
                  Expanded(child:
                    _buildFilterDescription(),
                  ),
                ]),
              ),
            ]),
          Container(color: Styles().colors.surfaceAccent, height: 1,),
        ],)
    );
  }

  Widget _buildFilterDescription() {
    TextStyle? boldStyle = Styles().textStyles.getTextStyle("widget.card.title.tiny.fat");
    TextStyle? regularStyle = Styles().textStyles.getTextStyle("widget.card.detail.small.regular");
    List<InlineSpan> descriptionList = <InlineSpan>[];

    if (_hasUnreadFilter) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.inbox.filter.unread.description', 'Unread'), style: regularStyle,),);
    }

    if (_hasMutedFilter) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.inbox.filter.muted.description', 'Muted'), style: regularStyle,),);
    }

    _TimeFilter? timeFilter = _getTimeFilterBy(interval: _dateIntervalSelectedValue);
    if (timeFilter != null) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: timeFilter.toDisplayString(), style: regularStyle,),);
    }

    if (descriptionList.isNotEmpty) {
      descriptionList.insert(0, TextSpan(text: Localization().getStringEx('panel.inbox.filter.label.title', 'Filter: ') , style: boldStyle,));
      descriptionList.add(TextSpan(text: '.', style: regularStyle,),);
    }

    return RichText(text: TextSpan(style: regularStyle, children: descriptionList));
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

  Widget _buildBanner() {
    //TBD localize
    return Visibility(
        visible: _showBanner,
        child: GestureDetector(
            onTap: _onTapBanner,
            child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                color: Styles().colors.saferLocationWaitTimeColorYellow,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Expanded(
                      child: Text('Notifications Paused',
                          textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.detail.regular"))),
                  Text(">", style: Styles().textStyles.getTextStyle("widget.detail.regular"))
                ]))));
  }

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

  // Filter Widgets

  Widget _buildFilterContent() {
    return Semantics(
        container: true,
        child: SingleChildScrollView(
            child: Container(
                color: Styles().colors.background,
                padding: EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildViewFilters(), _buildDateFilters(), _buildApplyButton()]))));
  }

  Widget _buildViewFilters() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Localization().getStringEx('panel.inbox.filter.view.label', 'VIEW'),
          style: Styles().textStyles.getTextStyle('widget.title.regular.fat')),
      Padding(
          padding: EdgeInsets.only(top: 10),
          child: _buildToggleWidget(
              label: Localization().getStringEx('panel.inbox.filter.notifications.toggle.unread.label', 'Unread Notifications'),
              value: (_unreadPreviewValue == true),
              onTapValue: _onTapUnreadFilter)),
      Padding(
          padding: EdgeInsets.only(top: 10),
          child: _buildToggleWidget(
              label: Localization().getStringEx('panel.inbox.filter.notifications.toggle.muted.label', 'Muted Notifications'),
              value: (_mutedPreviewValue != false),
              onTapValue: _onTapMutedFilter)),
      Padding(
          padding: EdgeInsets.only(left: 12, top: 6),
          child: Text(
              Localization()
                  .getStringEx('panel.inbox.filter.notifications.toggle.muted.description', 'View notifications you have turned off.'),
              style: Styles().textStyles.getTextStyle('panel.inbox.notifications.filter.muted.description')))
    ]);
  }

  Widget _buildToggleWidget({required String label, bool? value, required void Function()? onTapValue}) {
    bool toggled = (value == true);
    String semanticsValue = AppSemantics.toggleValue(toggled);
    String semanticsHint = AppSemantics.toggleHint(toggled,
      subject: label,
    );

    return Semantics(label: label, hint: semanticsHint, value: semanticsValue, button: true, child:
      Container(
        decoration: BoxDecoration(
            color: Styles().colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 4.0, offset: Offset(2, 2))]),
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Padding(padding: EdgeInsets.only(left: 10), child: Text(label, style: Styles().textStyles.getTextStyle('widget.title.small'))),
          InkWell(
              onTap: onTapValue,
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Styles().images.getImage((value == true) ? 'toggle-on' : 'toggle-off') ?? Container()))
        ])));
  }

  Widget _buildDateFilters() {
    return Padding(
        padding: EdgeInsets.only(top: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Localization().getStringEx('panel.inbox.filter.date.label', 'DATE RANGE'),
              style: Styles().textStyles.getTextStyle('widget.title.regular.fat')),
          Padding(padding: EdgeInsets.only(top: 8), child: _buildDateRangeFilterValues())
        ]));
  }

  Widget _buildDateRangeFilterValues() {
    final Radius borderRadiusValue = Radius.circular(10);
    List<_FilterEntry> dateFilterEntries = _dateFilterEntries;
    List<String> subLabels = _buildDateLabels();
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 4.0, offset: Offset(2, 2))]),
        child: ListView.separated(
            shrinkWrap: true,
            separatorBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Divider(height: 1, color: Styles().colors.fillColorPrimaryTransparent03)),
            itemCount: dateFilterEntries.length,
            itemBuilder: (context, index) {
              _FilterEntry filterEntry = dateFilterEntries[index];
              _TimeFilter? timeFilter = (filterEntry.value is _TimeFilter) ? (filterEntry.value as _TimeFilter) : null;
              BorderRadius? borderRadius;
              if (index == 0) {
                borderRadius = BorderRadius.only(topLeft: borderRadiusValue, topRight: borderRadiusValue);
              } else if (index == (dateFilterEntries.length - 1)) {
                borderRadius = BorderRadius.only(bottomLeft: borderRadiusValue, bottomRight: borderRadiusValue);
              }
              return _buildDateEntryWidget(
                  title: _dateFilterLabel(timeFilter),
                  description: subLabels[index],
                  borderRadius: borderRadius,
                  onTap: () => _onTapTimeFilter(filterEntry.value),
                  selected: (_timeFilterPreviewValue == filterEntry.value));
            }));
  }

  List<String> _buildDateLabels() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    Map<_TimeFilter, _DateInterval> intervals = _getTimeFilterIntervals();

    List<String> timeDates = <String>[];
    for (_FilterEntry timeEntry in _dateFilterEntries) {
      String? timeDate;
      _DateInterval? interval = intervals[timeEntry.value];
      if (interval != null) {
        DateTime startDate = interval.startDate!;
        String? startStr = AppDateTime().formatDateTime(interval.startDate, format: 'MM/dd', ignoreTimeZone: true);

        DateTime endDate = interval.endDate ?? today;
        if (1 < endDate.difference(startDate).inDays) {
          String? endStr = AppDateTime().formatDateTime(endDate, format: 'MM/dd', ignoreTimeZone: true);
          timeDate = "$startStr - $endStr";
        } else {
          timeDate = startStr;
        }
      }
      timeDates.add(timeDate ?? '');
    }

    return timeDates;
  }

  Widget _buildDateEntryWidget(
      {String? title, String? description, required bool selected, void Function()? onTap, BorderRadius? borderRadius}) {
    TextStyle? titleTextStyle =
    selected ? Styles().textStyles.getTextStyle('widget.title.small.fat') : Styles().textStyles.getTextStyle('widget.title.small');

    List<Widget> contentList = <Widget>[Expanded(child: Text(StringUtils.ensureNotEmpty(title), style: titleTextStyle))];
    if (StringUtils.isNotEmpty(description)) {
      contentList.add(Text(StringUtils.ensureNotEmpty(description),
          maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles.getTextStyle('widget.title.regular')));
    }
    contentList.add(Padding(
        padding: EdgeInsets.only(left: 10),
        child: (selected ? Styles().images.getImage('radio-button-on') : Styles().images.getImage('radio-button-off'))));

    return Semantics(
        label: title,
        button: true,
        selected: selected,
        excludeSemantics: true,
        child: InkWell(
            onTap: onTap,
            child: Container(
                decoration: BoxDecoration(color: Styles().colors.white, borderRadius: borderRadius),
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Row(mainAxisSize: MainAxisSize.max, children: contentList)))));
  }

  Widget _buildApplyButton() {
    return Padding(
        padding: EdgeInsets.only(top: 30),
        child: RoundedButton(
            label: Localization().getStringEx('panel.inbox.filter.apply.button', 'Apply'),
            padding: EdgeInsets.symmetric(vertical: 4),
            contentWeight: 0.35,
            fontSize: 16,
            onTap: _onTapApplyFilter));
  }

  // Handlers

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  void _onTapBanner() {
    Analytics().logSelect(target: 'Notifications Paused', source: widget.runtimeType.toString());
    if (mounted) {
      SettingsHomePanel.present(context, content: SettingsContentType.notifications);
    }
  }

  Future<void> _onPullToRefresh() async {
    int limit = max(_messages.length, _messagesPageSize);
    List<InboxMessage>? messages = await Inbox().loadMessages(
        unread: _unreadSelectedValue,
        muted: _mutedSelectedValue,
        offset: 0,
        limit: limit,
        startDate: _dateIntervalSelectedValue?.startDate,
        endDate: _dateIntervalSelectedValue?.endDate);
    if (mounted) {
      setState(() {
        if (messages != null) {
          _messages = messages;
          _hasMoreMessages = (_messagesPageSize <= messages.length);
        } else {
          _messages.clear();
          _hasMoreMessages = null;
        }
        _contentList = _buildMessagesContentList();
      });
    }
  }

  void _onTapMarkAllAsRead() {
    Analytics().logSelect(target: 'Mark All As Read');
    _setMarkAllAsReadLoading(true);
    Inbox().markAllMessagesAsRead().then((succeeded) {
      if (succeeded) {
        _loadMessages();
      } else {
        AppAlert.showTextMessage(
            context, Localization().getStringEx('panel.inbox.mark_as_read.failed.msg', 'Failed to mark all messages as read'));
      }
      _setMarkAllAsReadLoading(false);
    });
  }

  void _onTapFilter() {
    Analytics().logSelect(target: 'Filter');
    setStateIfMounted(() {
      _unreadPreviewValue = _unreadSelectedValue;
      _mutedPreviewValue = _mutedSelectedValue;
      _timeFilterPreviewValue = _getTimeFilterBy(interval: _dateIntervalSelectedValue);
      _isFilterVisible = true;
    });
  }

  void _onTapMessage(InboxMessage message) {
    Analytics().logSelect(target: message.subject);
    NotificationsHomePanel.launchMessageDetail(message, analyticsFeature: AnalyticsFeature.Notifications);
  }

  void _setMarkAllAsReadLoading(bool loading) {
    setStateIfMounted(() {
      _loadingMarkAllAsRead = loading;
    });
  }

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && (_hasMoreMessages != false) && (_loadingMoreMessages != true) && (_loadingMessages != true)) {
      _loadMoreMessages();
    }
  }

  void _onTapApplyFilter() {
    Analytics().logSelect(target: 'Apply');

    _unreadSelectedValue = _unreadPreviewValue;
    _mutedSelectedValue = _mutedPreviewValue;
    _dateIntervalSelectedValue = _getDateIntervalBy(filter: _timeFilterPreviewValue);

    Storage().notificationsFilterUnread = _unreadPreviewValue;
    Storage().notificationsFilterMuted = (_mutedPreviewValue != false) ? true : false;
    Storage().notificationsFilterTimeInterval = _timeFilterPreviewValue?.toJson();

    _isFilterVisible = false;
    _refreshMessages();
  }

  ///
  /// Muted requires special treatment. Values meanings:
  ///  - null - show muted and not-muted notifications
  ///  - false - do not show muted notifications
  ///  - true - show only muted notifications
  ///
  void _onTapMutedFilter() {
    setStateIfMounted(() {
      if (_mutedPreviewValue != false) {
        _mutedPreviewValue = false;
      } else {
        _mutedPreviewValue = null;
      }
    });
  }

  ///
  /// Unread requires special treatment. Values meanings:
  ///  - null - show read and unread notifications
  ///  - false - show only read notifications
  ///  - true - show only unread notifications
  ///
  void _onTapUnreadFilter() {
    setStateIfMounted(() {
      if (_unreadPreviewValue != true) {
        _unreadPreviewValue = true;
      } else {
        _unreadPreviewValue = null;
      }
    });
  }

  void _onTapTimeFilter(dynamic timeFilterValue) {
    setStateIfMounted(() {
      if (timeFilterValue is _TimeFilter) {
        _timeFilterPreviewValue = timeFilterValue;
      } else {
        _timeFilterPreviewValue = null;
      }
    });
  }

  void _loadMessages() {
    setState(() {
      _loadingMessages = true;
    });

    Inbox()
        .loadMessages(
        unread: _unreadSelectedValue,
        muted: _mutedSelectedValue,
        offset: 0,
        limit: _messagesPageSize,
        startDate: _dateIntervalSelectedValue?.startDate,
        endDate: _dateIntervalSelectedValue?.endDate)
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
          _contentList = _buildMessagesContentList();
          _loadingMessages = false;
        });
      }
    });
  }

  void _loadMoreMessages() {
    setState(() {
      _loadingMoreMessages = true;
    });

    Inbox()
        .loadMessages(
        unread: _unreadSelectedValue,
        muted: _mutedSelectedValue,
        offset: _messages.length,
        limit: _messagesPageSize,
        startDate: _dateIntervalSelectedValue?.startDate,
        endDate: _dateIntervalSelectedValue?.endDate)
        .then((List<InboxMessage>? messages) {
      if (mounted) {
        setState(() {
          if (messages != null) {
            _messages.addAll(messages);
            _hasMoreMessages = (_messagesPageSize <= messages.length);
            _contentList = _buildMessagesContentList();
          }
          _loadingMoreMessages = false;
        });
      }
    });
  }

  void _refreshMessages({int? messagesCount}) {
    setStateIfMounted(() {
      _loadingMessages = true;
    });

    int limit = max(messagesCount ?? _messages.length, _messagesPageSize);
    Inbox()
        .loadMessages(
        unread: _unreadSelectedValue,
        muted: _mutedSelectedValue,
        offset: 0,
        limit: limit,
        startDate: _dateIntervalSelectedValue?.startDate,
        endDate: _dateIntervalSelectedValue?.endDate)
        .then((List<InboxMessage>? messages) {
      setStateIfMounted(() {
        if (messages != null) {
          _messages = messages;
          _hasMoreMessages = (_messagesPageSize <= messages.length);
        } else {
          _messages.clear();
          _hasMoreMessages = null;
        }
        _contentList = _buildMessagesContentList();
        _loadingMessages = false;
      });
    });
  }

  List<dynamic> _buildMessagesContentList() {
    Map<_TimeFilter, _DateInterval> intervals = _getTimeFilterIntervals();
    Map<_TimeFilter, List<InboxMessage>> timesMap = Map<_TimeFilter, List<InboxMessage>>();
    List<InboxMessage>? otherList;
    for (InboxMessage? message in _messages) {
      _TimeFilter? timeFilter = _timeFilterFromDate(message!.dateCreatedUtc?.toLocal(), intervals: intervals);
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
    List<_FilterEntry> dateFilterEntries = _dateFilterEntries;
    for (_FilterEntry timeEntry in dateFilterEntries) {
      _TimeFilter? timeFilter = timeEntry.value;
      List<InboxMessage>? timeList = (timeFilter != null) ? timesMap[timeFilter] : null;
      if (timeList != null) {
        contentList.add(timeEntry.name!.toUpperCase());
        contentList.addAll(timeList);
      }
    }

    if (otherList != null) {
      contentList.add(_FilterEntry.entryInList(dateFilterEntries, null)?.name?.toUpperCase() ?? '');
      contentList.addAll(otherList);
    }

    return contentList;
  }

  Map<_TimeFilter, _DateInterval> _getTimeFilterIntervals() {
    DateTime now = DateTime.now();
    return {
      _TimeFilter.Today: _DateInterval(startDate: DateTime(now.year, now.month, now.day)),
      _TimeFilter.Yesterday:
      _DateInterval(startDate: DateTime(now.year, now.month, now.day - 1), endDate: DateTime(now.year, now.month, now.day)),
      _TimeFilter.ThisWeek: _DateInterval(startDate: DateTime(now.year, now.month, now.day - now.weekday + 1)),
      _TimeFilter.LastWeek: _DateInterval(
          startDate: DateTime(now.year, now.month, now.day - now.weekday + 1 - 7),
          endDate: DateTime(now.year, now.month, now.day - now.weekday + 1)),
      _TimeFilter.ThisMonth: _DateInterval(startDate: DateTime(now.year, now.month, 1)),
      _TimeFilter.LastMonth: _DateInterval(startDate: DateTime(now.year, now.month - 1, 1), endDate: DateTime(now.year, now.month, 0)),
    };
  }

  _TimeFilter? _timeFilterFromDate(DateTime? dateTime, { Map<_TimeFilter, _DateInterval>? intervals }) {
    for (_FilterEntry timeEntry in _dateFilterEntries) {
      _TimeFilter? timeFilter = timeEntry.value;
      _DateInterval? timeInterval = ((intervals != null) && (timeFilter != null)) ? intervals[timeFilter] : null;
      if ((timeInterval != null) && (timeInterval.contains(dateTime))) {
        return timeFilter;
      }
    }
    return null;
  }

  _DateInterval? _getDateIntervalBy({_TimeFilter? filter}) {
    if (filter == null) {
      return null;
    }
    return _getTimeFilterIntervals()[filter];
  }

  _TimeFilter? _getTimeFilterBy({_DateInterval? interval}) {
    if (interval != null) {
      Map<_TimeFilter, _DateInterval> filterIntervals = _getTimeFilterIntervals();
      for (_TimeFilter filter in filterIntervals.keys) {
        _DateInterval? current = filterIntervals[filter];
        if (current == interval) {
          return filter;
        }
      }
    }
    return null;
  }

  String _dateFilterLabel(_TimeFilter? timeFilter) {
    if (timeFilter == null) {
      return Localization().getStringEx('panel.inbox.filter.time.all.label', 'All Notifications');
    }
    late String prefix = timeFilter.toDisplayString();;
    return "$prefix's ${Localization().getStringEx('panel.inbox.filter.time.notifications.label', 'Notifications')}";
  }

  bool get _showBanner => FirebaseMessaging().notificationsPaused ?? false;

  bool get _hasFilters => _hasUnreadFilter || _hasMutedFilter || _hasDateIntervalFilter;
  bool get _hasUnreadFilter => (_unreadSelectedValue == true);
  bool get _hasMutedFilter => (_mutedSelectedValue != false);
  bool get _hasDateIntervalFilter => (_dateIntervalSelectedValue != null);

  static final List<_FilterEntry> _dateFilterEntries = [
    _FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.all.label', 'All Notifications'), value: null),
    _FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.today.label', 'Today'), value: _TimeFilter.Today),
    _FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.yesterday.label', 'Yesterday'), value: _TimeFilter.Yesterday),
    _FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.this_week.label', 'This Week'), value: _TimeFilter.ThisWeek),
    _FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.last_week.label', 'Last Week'), value: _TimeFilter.LastWeek),
    _FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.this_month.label', 'This Month'), value: _TimeFilter.ThisMonth),
    _FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.last_month.label', 'Last Month'), value: _TimeFilter.LastMonth),
  ];
}

enum _TimeFilter { Today, Yesterday, ThisWeek, LastWeek, ThisMonth, LastMonth }

extension _TimeFilterImpl on _TimeFilter {

  static _TimeFilter? fromJson(String? value) {
    switch (value) {
      case 'today': return _TimeFilter.Today;
      case 'yesterday': return _TimeFilter.Yesterday;
      case 'thisWeek': return _TimeFilter.ThisWeek;
      case 'lastWeek': return _TimeFilter.LastWeek;
      case 'thisMonth': return _TimeFilter.ThisMonth;
      case 'lastMonth': return _TimeFilter.LastMonth;
      default: return null;
    }
  }

  String toJson() {
    switch (this) {
      case _TimeFilter.Today: return 'today';
      case _TimeFilter.Yesterday: return 'yesterday';
      case _TimeFilter.ThisWeek: return 'thisWeek';
      case _TimeFilter.LastWeek: return 'lastWeek';
      case _TimeFilter.ThisMonth: return 'thisMonth';
      case _TimeFilter.LastMonth: return 'lastMonth';
    }
  }

  String toDisplayString() {
    switch (this) {
      case _TimeFilter.Today: return Localization().getStringEx('panel.inbox.filter.time.today.label', 'Today');
      case _TimeFilter.Yesterday: return Localization().getStringEx('panel.inbox.filter.time.yesterday.label', 'Yesterday');
      case _TimeFilter.ThisWeek: return Localization().getStringEx('panel.inbox.filter.time.this_week.label', 'This Week');
      case _TimeFilter.LastWeek: return Localization().getStringEx('panel.inbox.filter.time.last_week.label', 'Last Week');
      case _TimeFilter.ThisMonth: return Localization().getStringEx('panel.inbox.filter.time.this_month.label', 'This Month');
      case _TimeFilter.LastMonth: return Localization().getStringEx('panel.inbox.filter.time.last_month.label', 'Last Month');
    }
  }

}

class _DateInterval {
  final DateTime? startDate;
  final DateTime? endDate;

  _DateInterval({this.startDate, this.endDate});

  bool contains(DateTime? dateTime) {
    if (dateTime == null) {
      return false;
    } else if ((startDate != null) && startDate!.isAfter(dateTime)) {
      return false;
    } else if ((endDate != null) && endDate!.isBefore(dateTime)) {
      return false;
    } else {
      return true;
    }
  }

  @override
  bool operator ==(other) => (other is _DateInterval) && (other.startDate == startDate) && (other.endDate == endDate);

  @override
  int get hashCode => (startDate?.hashCode ?? 0) ^ (endDate?.hashCode ?? 0);
}

class _FilterEntry {
  final String? _name;
  final dynamic _value;

  String? get name => _name;

  dynamic get value => _value;

  _FilterEntry({String? name, dynamic value})
      : _name = name ?? value?.toString(),
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

class InboxMessageCard extends StatefulWidget {
  final InboxMessage? message;
  final bool? selected;
  final void Function()? onTap;

  InboxMessageCard({this.message, this.selected, this.onTap});

  @override
  _InboxMessageCardState createState() {
    return _InboxMessageCardState();
  }
}

class _InboxMessageCardState extends State<InboxMessageCard> with NotificationsListener {
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
      setStateIfMounted(() {});
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
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]),
        clipBehavior: Clip.none,
        child: Stack(children: [
          InkWell(
            onTap: widget.onTap,
            child: Padding(
                padding: EdgeInsets.only(left: leftPadding, right: 16, top: 16, bottom: 16),
                child: Row(
                  children: <Widget>[
                    Visibility(
                      visible: (widget.selected != null),
                      child: Padding(
                          padding: EdgeInsets.only(right: leftPadding),
                          child: Semantics(
                            label: (widget.selected == true)
                                ? Localization().getStringEx('widget.inbox_message_card.selected.hint', 'Selected')
                                : Localization().getStringEx('widget.inbox_message_card.unselected.hint', 'Not Selected'),
                            child: Styles().images.getImage(
                                  (widget.selected == true) ? 'check-circle-filled' : 'check-circle-outline-gray',
                                  excludeFromSemantics: true,
                                ),
                          )),
                    ),
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      StringUtils.isNotEmpty(widget.message?.subject)
                          ? Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(
                                    child: Text(widget.message?.subject ?? '',
                                        semanticsLabel: sprintf(
                                            Localization().getStringEx('widget.inbox_message_card.subject.hint', 'Subject: %s'),
                                            [widget.message?.subject ?? '']),
                                        style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'))),
                                (widget.message?.mute == true)
                                    ? Semantics(
                                        label: sprintf(
                                            Localization().getStringEx('widget.inbox_message_card.status.hint', 'status: %s ,for: '),
                                            [mutedStatus.toLowerCase()]),
                                        excludeSemantics: true,
                                        child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: Styles().colors.fillColorSecondary,
                                                borderRadius: BorderRadius.all(Radius.circular(2))),
                                            child: Text(mutedStatus.toUpperCase(),
                                                style: Styles().textStyles.getTextStyle("widget.heading.extra_small"))))
                                    : Container()
                              ]))
                          : Container(),
                      StringUtils.isNotEmpty(widget.message?.body)
                          ? Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Row(children: [
                                Expanded(
                                    child: Text(widget.message?.displayBody ?? '',
                                        semanticsLabel: sprintf(
                                            Localization().getStringEx('widget.inbox_message_card.body.hint', 'Body: %s'),
                                            [widget.message?.displayBody ?? '']),
                                        style: Styles().textStyles.getTextStyle('widget.card.detail.small')))
                              ]))
                          : Container(),
                      Row(children: [
                        Expanded(
                            child: Text(widget.message?.displayInfo ?? '', style: Styles().textStyles.getTextStyle('widget.info.tiny'))),
                      ]),
                    ])),
                  ],
                )),
          ),
          Container(color: Styles().colors.fillColorSecondary, height: 4),
          Positioned(
              bottom: 0,
              right: 0,
              child: Stack(alignment: Alignment.center, children: [
                InkWell(
                    onTap: _onTapDelete,
                    splashColor: Colors.transparent,
                    child: Container(padding: EdgeInsets.all(16), child: Styles().images.getImage('trash-blue'))),
                Visibility(
                    visible: _deleting,
                    child: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 1, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary))))
              ]))
        ]));
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
