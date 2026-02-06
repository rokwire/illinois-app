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

import 'package:flutter/material.dart';
import 'package:illinois/mainImpl.dart';
import 'package:illinois/model/DailyIllini.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DailyIllini.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeDailyIlliniWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeDailyIlliniWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
      HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position, title: title);

  static String get title => Localization().getStringEx('widget.home.daily_illini.header.label', 'The Daily Illini');

  @override
  _HomeDailyIlliniWidgetState createState() => _HomeDailyIlliniWidgetState();

  static _HomeDailyIlliniWidgetState? of(BuildContext context) =>
      context.findAncestorStateOfType<_HomeDailyIlliniWidgetState>();
}


class _HomeDailyIlliniWidgetState extends State<HomeDailyIlliniWidget> with NotificationsListener {
  List<DailyIlliniItem>? _illiniItems;
  bool _loadingItems = false;
  DateTime? _pausedDateTime;
  PageController? _pageController;

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
    double pageViewport = (screenWidth - 2 * HomeCard.pageSpacing) / screenWidth;
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
    return HomeFavoriteWidget(favoriteId: widget.favoriteId,
      title: HomeDailyIlliniWidget.title,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    List<Widget> widgetsList = <Widget>[];
    if (CollectionUtils.isNotEmpty(_illiniItems)) {
      for (int i = 0; i < 3; i++) {
        DailyIlliniItem item = _illiniItems![i];
        if (i == 0) {
          widgetsList.add(_MainStoryWidget(illiniItem: item,));
        }
        else {
          widgetsList.add(_MinorStoryWidget(illiniItem: item,));
        }
      }
    }

    if (widgetsList.isEmpty && !_loadingItems) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.daily_illini.text.empty.description', 'Failed to load daily illini feed.'));
    } else {
      Widget contentWidget;
      if (widgetsList.length >= 3) {
        contentWidget = Padding(
          padding: HomeCard.defaultSingleCardMargin,
          child: Container(decoration: HomeCard.boxDecoration, child:
            Column(children: <Widget>[
              widgetsList[0],
              widgetsList[1],
              widgetsList[2],
              SizedBox(height: 12),
            ]),
          ),
        );
      } else {
        contentWidget = Padding(
          padding: HomeCard.defaultSingleCardMargin,
          child: _DailyIlliniLoadingWidget(
            progressColor: Styles().colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          ),
        );
      }

      return Column(
        children: [
          contentWidget,
          HomeBrowseLinkButton(
              title: Localization().getStringEx('widget.home.daily_illini.button.all.title', 'More Stories'),
              hint: Localization().getStringEx('widget.home.daily_illini.button.all.hint', 'Tap to go to the Daily Illini home page'),
              onTap: _onViewAll
          ),
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

  void _onViewAll() {
    Analytics().logSelect(target: 'View All');
    AppLaunchUrl.launchExternal(url: Config().dailyIlliniHomepageUrl);
  }

  void _setLoading(bool loading) {
    _loadingItems = loading;
    if (mounted) {
      setState(() {});
    }
  }
}

abstract class _StoryWidget extends StatelessWidget {
  final DailyIlliniItem? illiniItem;

  _StoryWidget({this.illiniItem});

  void _onTap() {
    String? url = illiniItem?.link;
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        Map<String, String>? urlParams = Config().dailyIlliniUrlParams;
        if ((urlParams != null) && urlParams.isNotEmpty) {
          uri = UriExt.addQueryParameters(uri, urlParams);
        }

        AppLaunchUrl.launchExternal(uri: uri);
      }
    }
  }
}

class _MainStoryWidget extends _StoryWidget {
  _MainStoryWidget({super.illiniItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
    padding: EdgeInsets.zero,
    child: Align(
      alignment: FractionalOffset.bottomCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
                borderRadius: BorderRadius.vertical(top: HomeCard.radius),
                child: _buildImage()
          ),
          InkWell(
            onTap: _onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 8, left: 20, right: 20),
                  child: Text(StringUtils.ensureNotEmpty(illiniItem?.title), textAlign: TextAlign.left,
                      style: Styles().textStyles.getTextStyle('widget.title.medium.extra_fat')),
                ),
                Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 20),
                    child: Text(StringUtils.ensureNotEmpty(illiniItem?.displayPubDate),
                        style: Styles().textStyles.getTextStyle("widget.info.small.semi_fat"))
                ),
              ],
            ),
          ),
        ],
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
    return Row(children: [Expanded(child: Styles().images.getImage('news-placeholder', fit: BoxFit.fill) ?? Container())]);
  }
}

class _MinorStoryWidget extends _StoryWidget {
  _MinorStoryWidget({super.illiniItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.zero,
        child: Align(
          alignment: FractionalOffset.bottomCenter,
          child: InkWell(
            onTap: _onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Styles().colors.blackTransparent06),
                Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8, left: 20, right: 20),
                  child: Text(StringUtils.ensureNotEmpty(illiniItem?.title), textAlign: TextAlign.left,
                      style: Styles().textStyles.getTextStyle('widget.title.medium.extra_fat')),
                ),
                Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 20),
                    child: Text(StringUtils.ensureNotEmpty(illiniItem?.displayPubDate),
                        style: Styles().textStyles.getTextStyle("widget.info.small.semi_fat"))
                ),
              ],
            ),
          ),
        ));
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
