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
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/mainImpl.dart';
import 'package:illinois/model/DailyIllini.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DailyIllini.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
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

  static _HomeDailyIlliniWidgetState? of(BuildContext context) =>
      context.findAncestorStateOfType<_HomeDailyIlliniWidgetState>();
}


class _HomeDailyIlliniWidgetState extends State<HomeDailyIlliniWidget> implements NotificationsListener {
  List<DailyIlliniItem>? _illiniItems;
  bool _loadingItems = false;
  DateTime? _pausedDateTime;
  PageController? _pageController;
  GlobalKey _viewPagerKey = GlobalKey();
  final double _pageSpacing = 16;
  String _string = "Not set yet";

  set string(String value) => setState(() => _string = value);

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
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeDailyIlliniWidget.title,
      titleIconKey: 'news',
      child: _buildContent(),
    );
  }
  Widget _buildContent() {
    List<Widget> widgetsList = <Widget>[];
    if (CollectionUtils.isNotEmpty(_illiniItems)) {
      int itemsCount = _illiniItems!.length;
      for (int i = 0; i < 3; i++) {
        bool isFirst = (i == 0);
        bool isLast = ((i + 1) == itemsCount);
        DailyIlliniItem item = _illiniItems![i];
        // var summary = item.summary;
        // debugPrint('cock:  $summary');
        if (i == 0) {
          widgetsList.add(_MainStoryWidget(illiniItem: item,));
        }
        else {
          widgetsList.add(_MinorStory(illiniItem: item,));
        }
        /*widgetsList.add(_DailyIlliniItemWidget(
            illiniItem: item,
            margin: EdgeInsets.only(right: _pageSpacing, bottom: 10),
            onTapPrevious: isFirst ? null : _onTapPrevious,
            onTapNext: isLast ? null : _onTapNext));*/
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

        contentWidget = Column(
          children: <Widget>[
            widgetsList[0],
            widgetsList[1],
            widgetsList[2],
            SizedBox(height: 12),
          ]
        );
      } else {

        contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: widgetsList.first);
      }

      //This column moves view all button to the top right
      return Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: LinkButton(
                textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, decoration: TextDecoration.underline),
                title: Localization().getStringEx('widget.home.daily_illini.button.all.title', 'View All'),
                hint: Localization().getStringEx('widget.home.daily_illini.button.all.hint', 'Tap to view the daily illini feed'),
                onTap: _onViewAll),
          ),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Styles().colors!.white,
                boxShadow: [
                BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))
                ],
                borderRadius: BorderRadius.all(Radius.circular(4))),
              child: contentWidget,
            ),
        ),
        //DailyIlliniPopupMenu(dotColor: Colors.blue, backgroundColor: Colors.white, padding: EdgeInsets.symmetric(), fontSize: 16),
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

  _onViewAll() async {
    final Uri url = Uri.parse('https://dailyillini.com');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
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
    MenuItems? selectedMenu;
    return Scaffold(
        appBar: HeaderBar(
          title: HomeDailyIlliniWidget.title,
          actions: [DailyIlliniPopupMenu(dotColor: Styles().colors!.textColorPrimary, backgroundColor: Color(0xFF576379), padding: EdgeInsets.all(15), fontSize: 14)]
        ),
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
class _MainStoryWidget extends StatelessWidget {
  final DailyIlliniItem? illiniItem;

  _MainStoryWidget({this.illiniItem});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
    padding: EdgeInsets.zero,
    child: Align(
      alignment: FractionalOffset.bottomCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              child: _buildImage()
          ),
          Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8, left: 20, right: 20),
              child: Text(StringUtils.ensureNotEmpty(illiniItem?.title), textAlign: TextAlign.left,
                  style: Styles().textStyles?.getTextStyle('widget.title.extra_large.extra_fat'))),
          Padding(
              padding: EdgeInsets.only(bottom: 6, left: 20),
              child: Text(StringUtils.ensureNotEmpty(illiniItem?.displayPubDate),
                style: Styles().textStyles?.getTextStyle("widget.info.small.medium_fat"),))
        ]
      ),
    ));
  }
  Widget _buildImage() {
    return StringUtils.isNotEmpty(illiniItem?.thumbImageUrl)
        ? ModalImageHolder(child: Image.network(illiniItem!.thumbImageUrl!, excludeFromSemantics: true, loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) {
        return child;
      }
      return Padding(padding: EdgeInsets.symmetric(vertical: 30), child: CircularProgressIndicator());
    }, errorBuilder: (context, error, stackTrace) {
      return _defaultPlaceholderImage();
    }))
        : _defaultPlaceholderImage();
  }
  Widget _defaultPlaceholderImage() {
    return Row(children: [Expanded(child: Styles().images?.getImage('news-placeholder', fit: BoxFit.fill) ?? Container())]);
  }
}
class _MinorStory extends StatelessWidget {
  final DailyIlliniItem? illiniItem;

  _MinorStory({this.illiniItem});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
        padding: EdgeInsets.zero,
        child: Align(
          alignment: FractionalOffset.bottomCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(color: Styles().colors!.blackTransparent06),
              Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8, left: 20, right: 20),
                  child: Text(StringUtils.ensureNotEmpty(illiniItem?.title), textAlign: TextAlign.left,
                      style: Styles().textStyles?.getTextStyle('widget.title.medium.extra_fat'))),
              Padding(
                  padding: EdgeInsets.only(bottom: 6, left: 20),
                  child: Text(StringUtils.ensureNotEmpty(illiniItem?.displayPubDate),
                    style: Styles().textStyles?.getTextStyle("widget.info.small.medium_fat"),))
            ]
          ),
        ));
  }
}

class _DailyIlliniItemWidget extends StatelessWidget {
  final DailyIlliniItem? illiniItem;
  final EdgeInsetsGeometry? margin;
  final void Function()? onTapNext;
  final void Function()? onTapPrevious;

  _DailyIlliniItemWidget({this.illiniItem, this.margin, this.onTapNext, this.onTapPrevious});

  //This is the build function that builds the main body of our DailyIllini Home widget
  //The padding is the rectangle that bounds the column so that it doesn't go to the edge of the screen
  //the column on line 328 is the column that holds our image, next/prev buttons, and our title
  //within the column on line 328 we see a _buildImage() that builds our image, a row that holds our next/prev buttons and a padding that holds our title for the article
  //under this column we see a padding property that hold the date and time that the article was published
  //TODO: we need to change the items in the column so we only load one image for one main story and get rid of the next/prev buttons, we also need to load 2 stories without an image underneath the first one
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
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                clipBehavior: Clip.hardEdge,
                child: Column(children: <Widget>[
                  Column(children: [
                    _buildImage(),
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
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child: Text(StringUtils.ensureNotEmpty(illiniItem?.title), textAlign: TextAlign.center,
                            style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat')))
                  ]),
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Text(StringUtils.ensureNotEmpty(illiniItem?.displayPubDate),
                          style: Styles().textStyles?.getTextStyle("widget.info.small.medium_fa")))
                ]))));
  }

  Widget _buildImage() {
    return StringUtils.isNotEmpty(illiniItem?.thumbImageUrl)
        ? ModalImageHolder(child: Image.network(illiniItem!.thumbImageUrl!, excludeFromSemantics: true, loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Padding(padding: EdgeInsets.symmetric(vertical: 30), child: CircularProgressIndicator());
          }, errorBuilder: (context, error, stackTrace) {
            return _defaultPlaceholderImage();
          }))
        : _defaultPlaceholderImage();
  }

  Widget _defaultPlaceholderImage() {
    return Row(children: [Expanded(child: Styles().images?.getImage('news-placeholder', fit: BoxFit.fill) ?? Container())]);
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
                        style: Styles().textStyles?.getTextStyle("widget.button.title.extra_large")
                    )))));
  }

  void _onTap() {
    String? url = illiniItem!.link;
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        LaunchMode launchMode = Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault;
        launchUrl(uri, mode: launchMode);
      }
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


//Popup menu code starts from here
enum MenuItems {Featured, News, Opinion, Buzz, Sports}

class DailyIlliniPopupMenu extends StatefulWidget {
  final Color? dotColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  DailyIlliniPopupMenu({required this.dotColor, required this.backgroundColor, required this.padding, required this.fontSize});

  get selectedMenu => null;

  @override
  State<DailyIlliniPopupMenu> createState() => _DailyIlliniPopupMenu(dotColor: this.dotColor, backgroundColor: this.backgroundColor, padding: this.padding, fontSize: fontSize);
}

class _DailyIlliniPopupMenu extends State<DailyIlliniPopupMenu> {
  final Color? dotColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  MenuItems? selectedMenu = MenuItems.Featured;
  String text = "Featured";

  _DailyIlliniPopupMenu({required this.dotColor, required this.backgroundColor, required this.padding, required this.fontSize});

  //This is the code that changes the popup menu names and effects, right now it doesn't effect the feed
  //TODO: reload feed with updated filter input
  @override
  Widget build(BuildContext context) {
    return Padding (
      padding: padding,
      child: PopupMenuButton<MenuItems>(
        initialValue: selectedMenu,
        child: ElevatedButton(
          style: TextButton.styleFrom(
            foregroundColor: backgroundColor,
            textStyle: TextStyle(
              fontSize: fontSize,
              color: dotColor
            ),
          ),
          onPressed: null,
          child: Text(
              text,
              style: TextStyle(
                  fontFamily: Styles().fontFamilies!.semiBold,
                  color: dotColor)
          )
        ),
        // Callback that sets the selected popup menu item.

          //featured can be first items on webpage
        onSelected: (MenuItems item) {
          setState(() {
            switch (item) {
              case MenuItems.Featured:
                text = "Featured";
                break;
              case MenuItems.News:
                text = "News";
                break;
              case MenuItems.Opinion:
                text = "Opinion";
                break;
              case MenuItems.Buzz:
                text = "Buzz";
                break;
              case MenuItems.Sports:
                text = "Sports";
                break;
            }
          });
          HomeDailyIlliniWidget.of(context)?.string = selectedMenu.toString();
          selectedMenu = item;
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuItems>>[
              const PopupMenuItem<MenuItems>(
                value: MenuItems.Featured,
                child: Text('Featured'),
              ),
              const PopupMenuItem<MenuItems>(
                value: MenuItems.News,
                child: Text('News')
              ),
              const PopupMenuItem<MenuItems>(
                value: MenuItems.Opinion,
                child: Text('Opinion'),
              ),
              const PopupMenuItem<MenuItems>(
                  value: MenuItems.Buzz,
                  child: Text('Buzz')
              ),
              const PopupMenuItem<MenuItems> (
                value: MenuItems.Sports,
                child: Text("Sports")
              )
        ]
      )
    );
  }

}
