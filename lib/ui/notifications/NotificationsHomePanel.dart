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

import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/FirebaseMessaging.dart';
import 'package:neom/ui/notifications/NotificationsInboxPage.dart';
import 'package:neom/ui/settings/SettingsHomeContentPanel.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:neom/ext/InboxMessage.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum NotificationsContent { all, unread }

class NotificationsHomePanel extends StatefulWidget {
  static final String routeName = 'settings_notifications_content_panel';

  final NotificationsContent? content;

  NotificationsHomePanel._({this.content});

  static void present(BuildContext context, {NotificationsContent? content}) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.inbox', 'Notifications are not available while offline.'));
    }
    else if (!Auth2().isLoggedIn) {
      AppAlert.showLoggedOutFeatureNAMessage(context, Localization().getStringEx('generic.app.feature.notifications', 'Notifications'));
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
        builder: (context) {
          return NotificationsHomePanel._(content: content);
        }
      );

      /*Navigator.push(context, PageRouteBuilder(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation1, animation2) => SettingsNotificationsContentPanel._(content: content),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero
      ));*/
    }
  }

  static void launchMessageDetail(InboxMessage message) {
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
      FirebaseMessaging.payloadTypeMapMtdDestinations,
      FirebaseMessaging.payloadTypeMapMentalHealth,
      FirebaseMessaging.payloadTypeMapStateFarmWayfinding,
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
      FirebaseMessaging.payloadTypeWellnessPodcast,
      FirebaseMessaging.payloadTypeWellnessResources,
      FirebaseMessaging.payloadTypeWellnessRings,
      FirebaseMessaging.payloadTypeWellnessStruggling,
      FirebaseMessaging.payloadTypeWellnessTodoList,
      FirebaseMessaging.payloadTypeWellnessToDoItem,
      FirebaseMessaging.payloadTypeEventDetail,
      FirebaseMessaging.payloadTypeEvent,
      FirebaseMessaging.payloadTypeGameDetail,
      FirebaseMessaging.payloadTypeAthleticsGameStarted,
      FirebaseMessaging.payloadTypeAthleticsNewDetail,
      FirebaseMessaging.payloadTypeGroup,
      FirebaseMessaging.payloadTypeAppointment,
      FirebaseMessaging.payloadTypePoll,
      FirebaseMessaging.payloadTypeProfileMy,
      FirebaseMessaging.payloadTypeProfileWhoAreYou,
      FirebaseMessaging.payloadTypeProfileLogin,
      FirebaseMessaging.payloadTypeSettingsSections,  //TBD deprecate. Use payloadTypeProfileLogin instead
      FirebaseMessaging.payloadTypeSettingsFoodFilters,
      FirebaseMessaging.payloadTypeSettingsSports,
      FirebaseMessaging.payloadTypeSettingsFavorites,
      FirebaseMessaging.payloadTypeSettingsAssessments,
      FirebaseMessaging.payloadTypeSettingsCalendar,
      FirebaseMessaging.payloadTypeSettingsAppointments
    });
  }

  @override
  _NotificationsHomePanelState createState() => _NotificationsHomePanelState();
}

class _NotificationsHomePanelState extends State<NotificationsHomePanel> implements NotificationsListener {
  late NotificationsContent? _selectedContent;
  static NotificationsContent? _lastSelectedContent;
  bool _contentValuesVisible = false;

  final GlobalKey _allContentKey = GlobalKey();
  final GlobalKey _unreadContentKey = GlobalKey();
  final GlobalKey _sheetHeaderKey = GlobalKey();
  final GlobalKey _contentDropDownKey = GlobalKey();
  double _contentWidgetHeight = 300; // default value

  static final double _defaultPadding = 16;

  @override
  void initState() {
    NotificationService().subscribe(this, [Auth2.notifyLoginChanged]);
    
    if (_isContentItemEnabled(widget.content)) {
      _selectedContent = _lastSelectedContent = widget.content;
    }
    else if (_isContentItemEnabled(_lastSelectedContent)) {
      _selectedContent = _lastSelectedContent;
    }
    else  {
      _selectedContent = _initialSelectedContent;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalContentWidgetHeight();
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      _updateContentItemIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    //return _buildScaffold();
    return _buildSheet(context);
  }

  /*Widget _buildScaffold() {
    return Scaffold(
      appBar: RootHeaderBar(key: _headerBarKey, title: Localization().getStringEx('panel.settings.notifications.header.inbox.label', 'Notifications')),
      body: _buildPage(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(key: _tabBarKey)
    );
  }*/

  Widget _buildSheet(BuildContext context) {
    // MediaQuery(data: MediaQueryData.fromWindow(WidgetsBinding.instance.window), child: SafeArea(bottom: false, child: ))
    return Column(children: [
      Container(color: Styles().colors.gradientColorPrimary, child:
        Row(key: _sheetHeaderKey, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16), child:
              Semantics(container: true, header: true, child: Text(Localization().getStringEx('panel.settings.notifications.header.inbox.label', 'Notifications'), style:  Styles().textStyles.getTextStyle("widget.sheet.title.regular"),))
            )
          ),
          Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), container: true, button: true, child:
            InkWell(onTap : _onTapClose, child:
              Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
              Styles().images.getImage('close-circle', excludeFromSemantics: true),
              ),
            ),
          ),

        ],),
      ),
      Container(color: Styles().colors.surfaceAccent, height: 1,),
      Expanded(child:
        _buildPage(context),
      )
    ],);
  }

  Widget _buildPage(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(child:
        SingleChildScrollView(physics: (_contentValuesVisible ? NeverScrollableScrollPhysics() : null), child:
          _buildContent()
        )
      )
    ]);
  }

  Widget _buildContent() {
    return Semantics(container: true, child: Container(color: Styles().colors.background, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(key: _contentDropDownKey, padding: EdgeInsets.only(left: _defaultPadding, top: _defaultPadding, right: _defaultPadding), child:
          Semantics(hint: Localization().getStringEx("dropdown.hint", "DropDown"), focused: true, container: true, child:
          RibbonButton(
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
            backgroundColor: Styles().colors.gradientColorPrimary,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
            rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
            label: _getContentItemName(_selectedContent),
            onTap: _changeSettingsContentValuesVisibility
          )
        )),
        Container(height: _contentWidgetHeight, child:
          Stack(children: [
            Padding(padding: EdgeInsets.all(_defaultPadding), child: _contentWidget),
            _buildContentValuesContainer()
          ])
        )
      ])
    ));
  }

  Widget _buildContentValuesContainer() {
    return Visibility(visible: _contentValuesVisible, child:
      Positioned.fill(child:
        Stack(children: <Widget>[
          _buildContentDismissLayer(),
          _buildContentValuesWidget()
        ])
      )
    );
  }

  Widget _buildContentDismissLayer() {
    return Positioned.fill(
        child: BlockSemantics(
            child: Semantics(excludeSemantics: true, child:
              GestureDetector(
                onTap: () {
                  setState(() {
                    _contentValuesVisible = false;
                  });
                },
                child: Container(color: Styles().colors.blackTransparent06)))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> contentList = <Widget>[];
    contentList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (NotificationsContent contentItem in NotificationsContent.values) {
      if (_isContentItemEnabled(contentItem) && (_selectedContent != contentItem)) {
        contentList.add(_buildContentItem(contentItem));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: _defaultPadding), child: SingleChildScrollView(child: Column(children: contentList)));
  }

  Widget _buildContentItem(NotificationsContent contentItem) {
    return RibbonButton(
        textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
        backgroundColor: Styles().colors.gradientColorPrimary,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        rightIconKey: null,
        label: _getContentItemName(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _onTapContentItem(NotificationsContent contentItem) {
    Analytics().logSelect(target: contentItem.toString(), source: widget.runtimeType.toString());
    _selectedContent = _lastSelectedContent = contentItem;
    _changeSettingsContentValuesVisibility();
  }

  void _changeSettingsContentValuesVisibility() {
    _contentValuesVisible = !_contentValuesVisible;
    if (mounted) {
      setState(() {});
    }
  }

  void _evalContentWidgetHeight() {
    double takenHeight = 0;
    try {
      MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
      takenHeight += mediaQuery.viewPadding.top + mediaQuery.viewInsets.top + 16;

      final RenderObject? contentDropDownRenderBox = _contentDropDownKey.currentContext?.findRenderObject();
      if ((contentDropDownRenderBox is RenderBox) && contentDropDownRenderBox.hasSize) {
        takenHeight += contentDropDownRenderBox.size.height;
      }

      final RenderObject? sheetHeaderRenderBox = _sheetHeaderKey.currentContext?.findRenderObject();
      if ((sheetHeaderRenderBox is RenderBox) && sheetHeaderRenderBox.hasSize) {
        takenHeight += sheetHeaderRenderBox.size.height;
      }
    } on Exception catch (e) {
      print(e.toString());
    }

    if (mounted) {
      setState(() {
        _contentWidgetHeight = MediaQuery.of(context).size.height - takenHeight + _defaultPadding;
      });
    }
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  void _onTapPausedBanner() {
    Analytics().logSelect(target: 'Notifications Paused', source: widget.runtimeType.toString());
    if (mounted) {
      SettingsHomeContentPanel.present(context, content: SettingsContent.notifications);
    }
  }

  // Utilities

  Widget? get _contentWidget {
    switch (_selectedContent) {
      case NotificationsContent.all: return NotificationsInboxPage(key: _allContentKey, onTapBanner: _onTapPausedBanner,);
      case NotificationsContent.unread: return NotificationsInboxPage(unread: true, key: _unreadContentKey, onTapBanner: _onTapPausedBanner);
      default: return null;
    }
  }

  String? _getContentItemName(NotificationsContent? content) {
    switch (content) {
      case NotificationsContent.all: return Localization().getStringEx('panel.settings.notifications.content.notifications.all.label', 'All Notifications');
      case NotificationsContent.unread: return Localization().getStringEx('panel.settings.notifications.content.notifications.unread.label', 'Unread Notifications');
      default: return null;
    }
  }

  bool _isContentItemEnabled(NotificationsContent? contentItem) {
    switch (contentItem) {
      case NotificationsContent.all: return Auth2().isLoggedIn;
      case NotificationsContent.unread: return Auth2().isLoggedIn;
      default: return false;
    }
  }

  NotificationsContent? get _initialSelectedContent {
    for (NotificationsContent contentItem in NotificationsContent.values) {
      if (_isContentItemEnabled(contentItem)) {
        return contentItem;
      }
    }
    return null;
  }

  void _updateContentItemIfNeeded() {
    if ((_selectedContent == null) || !_isContentItemEnabled(_selectedContent)) {
      NotificationsContent? selectedContent = _isContentItemEnabled(_lastSelectedContent) ? _lastSelectedContent : _initialSelectedContent;
      if ((selectedContent != null) && (selectedContent != _selectedContent) && mounted) {
        setState(() {
          _selectedContent = selectedContent;
        });
      }
    }
  }
}
