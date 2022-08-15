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

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/main.dart';
import 'package:illinois/model/DailyIllini.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DailyIllini.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeDailyIlliniWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeDailyIlliniWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
      HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position, title: title);

  static String get title => Localization().getStringEx('widget.home.daily_illini.header.label', 'Daily Illini');

  @override
  _HomeDailyIlliniWidgetState createState() => _HomeDailyIlliniWidgetState();
}

class _HomeDailyIlliniWidgetState extends State<HomeDailyIlliniWidget> implements NotificationsListener {
  List<DailyIlliniItem>? _illiniItems;
  bool _loadingItems = false;
  DateTime? _pausedDateTime;
  PageController? _pageController;
  GlobalKey _viewPagerKey = GlobalKey();
  final double _pageSpacing = 16;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [AppLivecycle.notifyStateChanged]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _loadFeedItems();
        }
      });
    }

    double screenWidth = MediaQuery.of(App.instance?.currentContext ?? context).size.width;
    double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
    _pageController = PageController(viewportFraction: pageViewport);

    _loadFeedItems();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController?.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _loadFeedItems();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
            container: true,
            child: Column(children: <Widget>[
              _buildHeader(),
              Stack(children: <Widget>[_buildSlant(), _buildContent()])
            ]));
  }

  Widget _buildHeader() {
    return Semantics(
        child: Padding(
            padding: EdgeInsets.zero,
            child: Container(
                color: Styles().colors!.fillColorPrimary,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  HomeTitleIcon(image: Image.asset('images/campus-tools.png')),
                  Expanded(
                      child: Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Semantics(
                              label: HomeDailyIlliniWidget.title,
                              header: true,
                              excludeSemantics: true,
                              child: Text(HomeDailyIlliniWidget.title,
                                  style: TextStyle(
                                      color: Styles().colors?.textColorPrimary,
                                      fontFamily: Styles().fontFamilies?.extraBold,
                                      fontSize: 20))))),
                  HomeFavoriteButton(favorite: HomeFavorite(widget.favoriteId), style: FavoriteIconStyle.SlantHeader, prompt: true)
                ]))));
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color: Styles().colors!.fillColorPrimary, height: 45),
      Container(
          color: Styles().colors!.fillColorPrimary,
          child: CustomPaint(
              painter: TrianglePainter(painterColor: Styles().colors!.background, horzDir: TriangleHorzDirection.rightToLeft),
              child: Container(height: 65)))
    ]);
  }

  Widget _buildContent() {
    List<Widget> widgetsList = <Widget>[];
    if (CollectionUtils.isNotEmpty(_illiniItems)) {
      int itemsCount = _illiniItems!.length;
      for (int i = 0; i < itemsCount; i++) {
        bool isFirst = (i == 0);
        bool isLast = ((i + 1) == itemsCount);
        DailyIlliniItem item = _illiniItems![i];
        widgetsList.add(_DailyIlliniItemWidget(
            illiniItem: item,
            margin: EdgeInsets.only(right: _pageSpacing, bottom: 10),
            onTapPrevious: isFirst ? null : _onTapPrevious,
            onTapNext: isLast ? null : _onTapNext));
      }
    }

    if (_loadingItems == true) {
      widgetsList.add(
          _DailyIlliniLoadingWidget(progressColor: Styles().colors!.white!, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24)));
    }

    if (widgetsList.isEmpty) {
      return HomeMessageCard(
          message: Localization().getStringEx('widget.home.daily_illini.text.empty.description', 'Failed to load daily illini feed.'));
    } else {
      Widget contentWidget;
      if (1 < widgetsList.length) {
        double pageHeight = MediaQuery.of(context).size.width;

        contentWidget = Container(
            constraints: BoxConstraints(minHeight: pageHeight),
            child: ExpandablePageView(
                key: _viewPagerKey,
                controller: _pageController,
                children: widgetsList,
                estimatedPageSize: pageHeight));
      } else {
        contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: widgetsList.first);
      }

      return Column(children: [
        Padding(padding: EdgeInsets.only(top: 8), child: contentWidget),
        LinkButton(
            title: Localization().getStringEx('widget.home.daily_illini.button.all.title', 'View All'),
            hint: Localization().getStringEx('widget.home.daily_illini.button.all.hint', 'Tap to view the daily illini feed'),
            onTap: _onViewAll)
      ]);
    }
  }

  void _loadFeedItems() {
    _setLoading(true);
    DailyIllini().loadFeed().then((items) {
      _illiniItems = items;
      _setLoading(false);
    });
  }

  void _onTapPrevious() {
    _pageController?.previousPage(duration: Duration(milliseconds: 500), curve: Curves.easeIn);
  }

  void _onTapNext() {
    _pageController?.nextPage(duration: Duration(milliseconds: 500), curve: Curves.easeIn);
  }

  void _onViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DailyIlliniListPanel()));
  }

  void _setLoading(bool loading) {
    _loadingItems = loading;
    if (mounted) {
      setState(() {});
    }
  }
}

class DailyIlliniListPanel extends StatefulWidget {

  @override
  _DailyIlliniListPanelState createState() => _DailyIlliniListPanelState();
}

class _DailyIlliniListPanelState extends State<DailyIlliniListPanel> {

  List<DailyIlliniItem>? _illiniItems;
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    _loadFeedItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: HomeDailyIlliniWidget.title),
        body: RefreshIndicator(
            onRefresh: _onPullToRefresh,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Expanded(child: _buildContent())])),
        backgroundColor: Styles().colors!.background);
  }

  Widget _buildContent() {
    if (_loadingItems) {
      return Center(
          child: SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(
                  strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary!))));
    } else {
      if (CollectionUtils.isNotEmpty(_illiniItems)) {
        int itemsCount = _illiniItems!.length;
        return ListView.separated(
            separatorBuilder: (context, index) => Container(height: 24),
            itemCount: itemsCount,
            itemBuilder: _buildListItemEntry);
      } else {
        return Column(children: <Widget>[
          Expanded(child: Container(), flex: 1),
          Text(Localization().getStringEx('widget.home.daily_illini.text.empty.description', 'Failed to load daily illini feed.'),
              textAlign: TextAlign.center),
          Expanded(child: Container(), flex: 3)
        ]);
      }
    }
  }
  
  Widget _buildListItemEntry(BuildContext context, int index) {
    DailyIlliniItem? item = (index < ((_illiniItems?.length) ?? 0)) ? _illiniItems![index] : null;
    if (item == null) {
      return Container();
    }
    return _DailyIlliniItemWidget(
        illiniItem: item, margin: (0 < index) ? EdgeInsets.symmetric(horizontal: 16) : EdgeInsets.only(left: 16, right: 16, top: 16));
  }

  void _loadFeedItems() {
    _setLoadingItems(true);
    DailyIllini().loadFeed().then((items) {
      _illiniItems = items;
      _setLoadingItems(false);
    });
  }

  Future<void> _onPullToRefresh() async {
    // Reload without progress indicator
    DailyIllini().loadFeed().then((items) {
      _illiniItems = items;
      _updateState();
    });
  }

  void _setLoadingItems(bool loading) {
    _loadingItems = loading;
    _updateState();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _DailyIlliniItemWidget extends StatelessWidget {
  final DailyIlliniItem? illiniItem;
  final EdgeInsetsGeometry? margin;
  final void Function()? onTapNext;
  final void Function()? onTapPrevious;

  _DailyIlliniItemWidget({this.illiniItem, this.margin, this.onTapNext, this.onTapPrevious});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: GestureDetector(
            onTap: _onTap,
            child: Container(
                decoration: BoxDecoration(
                    color: Styles().colors!.white,
                    boxShadow: [
                      BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))
                    ],
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(4))),
                clipBehavior: Clip.none,
                child: Column(children: <Widget>[
                  Column(children: [
                    StringUtils.isNotEmpty(illiniItem?.thumbImageUrl)
                        ? Image.network(illiniItem!.thumbImageUrl!, excludeFromSemantics: true,
                            loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Padding(padding: EdgeInsets.symmetric(vertical: 30), child: CircularProgressIndicator());
                          })
                        : Row(children: [Expanded(child: Image.asset('images/daily-illini-placeholder.jpg', fit: BoxFit.fill))]),
                    Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _buildNavigationButton(
                          navigationDirection: '<',
                          semanticsLabel: Localization().getStringEx('widget.home.daily_illini.item.page.previous.hint', 'Previous page'),
                          onTap: onTapPrevious),
                      _buildNavigationButton(
                          navigationDirection: '>',
                          semanticsLabel: Localization().getStringEx('widget.home.daily_illini.item.page.next.hint', 'Next page'),
                          onTap: onTapNext)
                      
                    ]),
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        child: Text(StringUtils.ensureNotEmpty(illiniItem?.title),
                            style: TextStyle(
                                color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.medium, fontSize: 16)))
                  ]),
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Text(StringUtils.ensureNotEmpty(illiniItem?.displayPubDate),
                          style: TextStyle(color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.medium, fontSize: 14)))
                ]))));
  }

  Widget _buildNavigationButton({required String navigationDirection, required String semanticsLabel, void Function()? onTap}) {
    return Visibility(
        visible: (onTap != null),
        child: Semantics(
            label: semanticsLabel,
            button: true,
            child: GestureDetector(
                onTap: onTap ?? () {},
                child: Container(
                    color: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Text(navigationDirection,
                        semanticsLabel: "",
                        style:
                            TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 26))))));
  }

  void _onTap() {
    String? url = illiniItem!.link;
    if (StringUtils.isNotEmpty(url)) {
      launch(url!);
    }
  }
}

class _DailyIlliniLoadingWidget extends StatelessWidget {
  final Color progressColor;
  final EdgeInsetsGeometry padding;
  _DailyIlliniLoadingWidget({required this.progressColor, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: padding,
        child: Container(
            color: Colors.transparent,
            clipBehavior: Clip.none,
            child: Center(
                child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(progressColor))))));
  }
}
