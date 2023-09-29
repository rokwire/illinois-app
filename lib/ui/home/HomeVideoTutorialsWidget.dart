/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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
import 'package:illinois/model/Video.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsVideoTutorialListPanel.dart';
import 'package:illinois/ui/settings/SettingsVideoTutorialPanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/ui/widgets/VideoPlayButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeVideoTutorialsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeVideoTutorialsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.video_tutorials.button.title', 'Video Tutorials');

  State<HomeVideoTutorialsWidget> createState() => _HomeVideoTutorialsWidgetState();
}

class _HomeVideoTutorialsWidgetState extends State<HomeVideoTutorialsWidget> implements NotificationsListener {
  List<Video>? _videos;
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  final double _pageSpacing = 16;

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Content.notifyVideoTutorialsChanged,
      AppLivecycle.notifyStateChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refresh();
        }
      });
    }
    _load();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Content.notifyVideoTutorialsChanged) {
      _refresh();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refresh();
        }
      }
    }
  }

  void _load() {
    Map<String, dynamic>? videoTutorials = Content().videoTutorials;
    if (videoTutorials != null) {
      List<dynamic>? videoJsonList = JsonUtils.listValue(videoTutorials['videos']);
      if (CollectionUtils.isNotEmpty(videoJsonList)) {
        Map<String, dynamic>? strings = JsonUtils.mapValue(videoTutorials['strings']);
        _videos = Video.listFromJson(jsonList: videoJsonList, contentStrings: strings);
      }
    }
  }

  void _refresh() {
    _load();
    setStateIfMounted(() {
      _pageViewKey = UniqueKey();
      _contentKeys.clear();
      // _pageController = null;
      _pageController?.jumpToPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeVideoTutorialsWidget.title,
      titleIconKey: 'play-circle',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (CollectionUtils.isEmpty(_videos)) {
      return HomeMessageCard(
        message: Localization().getStringEx("widget.home.video_tutorials.text.empty.description", "There are no video tutorials, yet."));
    }
    else {
      return _buildVideosContent();
    }
  }

  Widget _buildVideosContent() {
    Widget contentWidget;
    List<Widget> pages = <Widget>[];

    if (_videosCount > 1) {
      for (int index = 0; index < _videosCount; index++) {
        Video video = _videos![index];
        pages.add(Padding(
            key: _contentKeys[StringUtils.ensureNotEmpty(video.id)] ??= GlobalKey(),
            padding: EdgeInsets.only(right: _pageSpacing + 2, bottom: 8),
            child: _buildVideoEntry(video)));
      }

      if (_pageController == null) {
        double screenWidth = MediaQuery.of(context).size.width;
        double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
        _pageController = PageController(viewportFraction: pageViewport);
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
        ExpandablePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: _pageHeight,
          allowImplicitScrolling: true,
          children: pages,
        ),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.only(left: 16, right: 16), child:
        _buildVideoEntry(_videos!.first)
      );
    }

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => pages.length, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.video_tutorials.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.video_tutorials.button.all.hint', 'Tap to view all video tutorials'),
          onTap: _onTapViewAll,
        ),
      ),
    ]);
  }

  Widget _buildVideoEntry(Video video) {
    String? videoTitle = video.title;
    String? imageUrl = video.thumbUrl;
    bool hasImage = StringUtils.isNotEmpty(imageUrl);
    final Widget emptyImagePlaceholder = Container(height: 102);
    return Container(
        decoration: BoxDecoration(
            color: Styles().colors?.white,
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4))),
        child: Stack(children: [
          GestureDetector(
              onTap: () => _onTapVideo(video),
              child: Semantics(
                  button: true,
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(StringUtils.ensureNotEmpty(videoTitle),
                                style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'))),
                        Stack(alignment: Alignment.center, children: [
                          hasImage
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(imageUrl!,
                                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        return (loadingProgress == null) ? child : emptyImagePlaceholder;
                                      }))
                                  : emptyImagePlaceholder,
                          VideoPlayButton(hasBackground: !hasImage)
                        ])
                      ])))),
          Container(color: Styles().colors?.accentColor3, height: 4)
        ]));
  }

  double get _pageHeight {
    double? minContentHeight;
    for (GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }
    return minContentHeight ?? 0;
  }

  void _onTapVideo(Video video) {
    Analytics().logSelect(target: 'Video Tutorial', source: widget.runtimeType.toString(), attributes: video.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsVideoTutorialPanel(videoTutorial: video)));
  }

  void _onTapViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    if (_canViewVideos) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => SettingsVideoTutorialListPanel(videoTutorials: _videos)));
    }
  }

  bool get _canViewVideos {
    return _videosCount > 0;
  }

  int get _videosCount {
    return _videos?.length ?? 0;
  }
}