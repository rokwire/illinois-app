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
import 'package:neom/model/Analytics.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/messages/MessagesInboxPage.dart';
import 'package:neom/ui/widgets/TextTabBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class MessagesHomePanel extends StatefulWidget with AnalyticsInfo {

  static final String routeName = 'messages_home_content_panel';

  MessagesHomePanel._();

  @override
  _MessagesHomePanelState createState() => _MessagesHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Messages;

  static void present(BuildContext context) {
    if (ModalRoute.of(context)?.settings.name != routeName) {
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
          return MessagesHomePanel._();
        }
      );
      /*Navigator.push(context, PageRouteBuilder(
        settings: RouteMessages(name: routeName),
        pageBuilder: (context, animation1, animation2) => MessagesHomeContentPanel._(content: content),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero
      ));*/
    }
  }
}

class _MessagesHomePanelState extends State<MessagesHomePanel> with TickerProviderStateMixin /*implements NotificationsListener*/ {

  late TabController _tabController;
  int _selectedTab = 0;

  final List<String> _tabNames = [
    Localization().getStringEx('panel.messages.content_type.all', 'All Messages'),
    Localization().getStringEx('panel.messages.content_type.unread', 'Unread Messages'),
  ];

  @override
  void initState() {
    _tabController = TabController(length: 2, initialIndex: _selectedTab, vsync: this);
    _tabController.addListener(_onTabChanged);

    super.initState();
    // NotificationService().subscribe(this, [
    //   MobileAccess.notifyMobileStudentIdChanged,
    //   Localization.notifyLocaleChanged,
    // ]);
    // _buildContentValues();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();

    // NotificationService().unsubscribe(this);
    super.dispose();
  }

  // void _buildContentValues() {
  //   List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['messages']);
  //   List<MessagesContent>? contentValues;
  //   if (contentCodes != null) {
  //     contentValues = [];
  //     for (String code in contentCodes) {
  //       MessagesContent? value = _getMessagesValueFromCode(code);
  //       if (value != null) {
  //         contentValues.add(value);
  //       }
  //     }
  //   }
  //
  //   _contentValues = contentValues;
  //   if (mounted) {
  //     setState(() {});
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    //return _buildScaffold(context);
    return _buildSheet(context);
  }

  Widget _buildSheet(BuildContext context) {
    // MediaQuery(data: MediaQueryData.fromWindow(WidgetsBinding.instance.window), child: SafeArea(bottom: false, child: ))
    return Column(children: [
        Container(color: Styles().colors.backgroundAccent, child:
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 16), child:
                Text(Localization().getStringEx('panel.messages.home.header.messages.label', 'MESSAGES'), style: Styles().textStyles.getTextStyle("widget.title.light.large.fat"))
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
        Expanded(child:
          _buildPage(context),
        )
      ],);
  }

  Widget _buildPage(BuildContext context) {
    List<Widget> tabs = _tabNames.map((e) => TextTabButton(title: e)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextTabBar(tabs: tabs, controller: _tabController, isScrollable: false, onTap: (index){_onTabChanged();}),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MessagesInboxPage(),
            MessagesInboxPage(unread: true),
          ],
        ),
      ),
    ],);
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  void _onTabChanged({bool manual = true}) {
    if (!_tabController.indexIsChanging && _selectedTab != _tabController.index) {
      setState(() {
        _selectedTab = _tabController.index;
      });
    }
  }
}
