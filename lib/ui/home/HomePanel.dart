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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/home/HomeCanvasCoursesWidget.dart';
import 'package:illinois/ui/home/HomeGiesWidget.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/SearchPanel.dart';
import 'package:illinois/ui/home/HomeCampusRemindersWidget.dart';
import 'package:illinois/ui/home/HomeCampusToolsWidget.dart';
import 'package:illinois/ui/home/HomeCreatePollWidget.dart';
import 'package:illinois/ui/home/HomeGameDayWidget.dart';
import 'package:illinois/ui/home/HomeHighligtedFeaturesWidget.dart';
import 'package:illinois/ui/home/HomeLoginWidget.dart';
import 'package:illinois/ui/home/HomeMyGroupsWidget.dart';
import 'package:illinois/ui/home/HomePreferredSportsWidget.dart';
import 'package:illinois/ui/home/HomeRecentItemsWidget.dart';
import 'package:illinois/ui/home/HomeSaferWidget.dart';
import 'package:illinois/ui/home/HomeCampusGuideHighlightsWidget.dart';
import 'package:illinois/ui/home/HomeTwitterWidget.dart';
import 'package:illinois/ui/home/HomeVoterRegistrationWidget.dart';
import 'package:illinois/ui/home/HomeUpcomingEventsWidget.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:illinois/ui/widgets/FlexContent.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class HomePanel extends StatefulWidget {
  @override
  _HomePanelState createState() => _HomePanelState();
}

class _HomePanelState extends State<HomePanel> with AutomaticKeepAliveClientMixin<HomePanel> implements NotificationsListener {
  
  List<String>? _contentListCodes;
  StreamController<void> _refreshController = StreamController.broadcast();
  HomeSaferWidget? _saferWidget;
  GlobalKey _saferKey = GlobalKey();


  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Localization.notifyStringsUpdated,
      FlexUI.notifyChanged,
      Styles.notifyChanged,
      Assets.notifyChanged,
      HomeSaferWidget.notifyNeedsVisiblity,
    ]);
    _contentListCodes = JsonUtils.listStringsValue(FlexUI()['home'])  ?? [];
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _refreshController.close();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child: CustomScrollView(
        slivers: <Widget>[
          _SliverHomeHeaderBar(
            context: context,
            settingsVisible: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              Container(
                color: Styles().colors!.background,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _buildContentList(),
                ),
              ),
            ]),
          ),
        ],
      ),),
      backgroundColor: Styles().colors!.background,
    );
  }

  List<Widget> _buildContentList() {

    List<Widget> widgets = [];
    HomeSaferWidget? saferWidget;

    for (String code in _contentListCodes!) {
      Widget? widget;

      if (code == 'game_day') {
        widget = HomeGameDayWidget(refreshController: _refreshController);
      }
      else if (code == 'campus_tools') {
        widget = HomeCampusToolsWidget();
      }
      else if (code == 'pref_sports') {
        widget = HomePreferredSportsWidget(menSports: true, womenSports: true, refreshController: _refreshController);
      }
      else if (code == 'pref_msports') {
        widget = HomePreferredSportsWidget(menSports: true, refreshController: _refreshController);
      }
      else if (code == 'pref_wsports') {
        widget = HomePreferredSportsWidget(womenSports: true, refreshController: _refreshController);
      }
      else if (code == 'campus_reminders') {
        widget = HomeCampusRemindersWidget(refreshController: _refreshController);
      }
      else if (code == 'upcoming_events') {
        widget = HomeUpcomingEventsWidget(refreshController: _refreshController);
      }
      else if (code == 'recent_items') {
        widget = HomeRecentItemsWidget(refreshController: _refreshController);
      }
      else if (code == 'campus_guide_highlights') {
        widget = HomeCampusGuideHighlightsWidget(refreshController: _refreshController);
      }
      else if (code == 'twitter') {
        widget = HomeTwitterWidget(refreshController: _refreshController);
      }
      else if (code == 'gies') {
        widget = HomeGiesWidget(refreshController: _refreshController);
      }
      else if (code == 'canvas') {
        widget = HomeCanvasCoursesWidget(refreshController: _refreshController);
      }
      else if (code == 'voter_registration') {
        widget = HomeVoterRegistrationWidget();
      }
      else if (code == 'create_poll') {
        widget = HomeCreatePollWidget();
      }
      else if (code == 'connect') {
        widget = HomeLoginWidget();
      }
      else if (code == 'highlighted_features') {
        widget = HomeHighlightedFeatures();
      }
      else if (code == 'my_groups') {
        widget = HomeMyGroupsWidget(refreshController: _refreshController,);
      }
      else if (code == 'safer') {
        widget = saferWidget = _saferWidget ??= HomeSaferWidget(key: _saferKey);
      }
      else {
        widget = FlexContent.fromAssets(code);
      }

      if (widget != null) {
        widgets.add(widget);
      }
    }

    if ((saferWidget == null) && (_saferWidget != null)) {
      _saferWidget = null; // Clear the cached HomeSaferWidget if not Safer indget in Home content.
    }

    return widgets;
  }

  void _updateContentListCodes() {
    List<String>? contentListCodes = JsonUtils.listStringsValue(FlexUI()['home']);
    if ((contentListCodes != null) && !DeepCollectionEquality().equals(_contentListCodes, contentListCodes)) {
      setState(() {
        _contentListCodes = contentListCodes;
      });
    }
  }

  Future<void> _onPullToRefresh() async {
    LiveStats().refresh();
    _refreshController.add(null);
  }

  void _ensureSaferWidgetVisibiity() {
      BuildContext? saferContext = _saferKey.currentContext;
      if (saferContext != null) {
        Scrollable.ensureVisible(saferContext, duration: Duration(milliseconds: 300));
      }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        setState(() {});
      }
    }
    else if (name == Localization.notifyStringsUpdated) {
      setState(() { });
    }
    else if (name == FlexUI.notifyChanged) {
      _updateContentListCodes();
    }
    else if(name == Storage.offsetDateKey){
      setState(() {});
    }
    else if(name == Storage.useDeviceLocalTimeZoneKey){
      setState(() {});
    }
    else if (name == Styles.notifyChanged){
      setState(() {});
    }
    else if (name == Assets.notifyChanged) {
      setState(() {});
    }
    else if (name == HomeSaferWidget.notifyNeedsVisiblity) {
      _ensureSaferWidgetVisibiity();
    }
  }
}

class _SliverHomeHeaderBar extends SliverAppBar {
  final BuildContext context;
  final bool searchVisible;
  final bool savedVisible;
  final bool settingsVisible;

  _SliverHomeHeaderBar(
      {required this.context,  this.searchVisible = false, this.savedVisible = false, this.settingsVisible = false})
      : super(
      pinned: true,
      floating: true,
      primary:true,
      backgroundColor: Styles().colors!.fillColorPrimaryVariant,
      title: ExcludeSemantics(
          child: IconButton(
              icon: Image.asset('images/block-i-orange.png'),
              onPressed: () {
                Analytics().logSelect(target: "Home");
                Navigator.of(context).popUntil((route) => route.isFirst);
//                NativeCommunicator().launchTest();
              }
          )
      ),
      actions: <Widget>[
        Visibility(
            visible: searchVisible,
            child: Semantics(
                label: Localization().getStringEx(
                    'headerbar.search.title', 'Search'),
                hint: Localization().getStringEx('headerbar.search.hint', ''),
                button: true,
                child: IconButton(
                    icon: Image.asset('images/icon-search.png'),
                    onPressed: () {
                      Analytics().logSelect(target: "Search");
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) =>
                                  SearchPanel()));
                    }))),
        Visibility(
            visible: savedVisible,
            child: Semantics(
            label: Localization().getStringEx('headerbar.saved.title', 'Saved'),
            hint: Localization().getStringEx('headerbar.saved.hint', ''),
            button: true,
              excludeSemantics: true,
              child: InkWell(
              onTap: () {
                Analytics().logSelect(target: "Saved");
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) =>
                            SavedPanel()));
                
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(Localization().getStringEx(
                    'headerbar.saved.title', 'Saved'),
                    style: TextStyle(color: Colors.white,
                        fontSize: 16,
                        fontFamily: Styles().fontFamilies!.semiBold,
                        decoration: TextDecoration.underline,
                        decorationColor: Styles().colors!.fillColorSecondary,
                        decorationThickness: 1,
                        decorationStyle: TextDecorationStyle.solid)),),))),


            Visibility(
            visible: settingsVisible,
            child: Semantics(
              label: Localization().getStringEx('headerbar.settings.title', 'Settings'),
              hint: Localization().getStringEx('headerbar.settings.hint', ''),
              button: true,
              excludeSemantics: true,
              child: IconButton(
                  icon: Image.asset('images/settings-white.png'),
                  onPressed: () {
                    Analytics().logSelect(target: "Settings");
                    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsHomePanel()));
                  })))

      ],
      centerTitle: true);
}

