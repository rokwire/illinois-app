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
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:flutter/material.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebPanel extends StatefulWidget implements AnalyticsPageName, AnalyticsPageAttributes{
  final String url;
  final String analyticsName;
  final String title;
  final bool hideToolBar;

  WebPanel({@required this.url, this.analyticsName, this.title = "", this.hideToolBar = false});

  @override
  _WebPanelState createState() => _WebPanelState();

  @override
  String get analyticsPageName {
    return analyticsName;
  }

  @override
  Map<String, dynamic> get analyticsPageAttributes {
    return { Analytics.LogAttributeUrl : url };
  }
}

class _WebPanelState extends State<WebPanel> implements NotificationsListener{

  _OnlineStatus _onlineStatus;
  bool _pageLoaded = false;

  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    _checkOnlineStatus();
    NotificationService().subscribe(this, AppLivecycle.notifyStateChanged);
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
          appBar: _getHeaderBar(),
          backgroundColor: Styles().colors.background,
          body: Column(
            children: <Widget>[
              Expanded(
                  child: (_onlineStatus == _OnlineStatus.offline)
                      ? _buildError()
                      : Stack(
                    children: _buildWebView(),
                  )
              ),
              widget.hideToolBar? Container() :TabBarWidget()
            ],
          ));
  }

  List<Widget> _buildWebView() {
    List<Widget> list = [];
    list.add(Visibility(
      visible: _isForeground,
      child: WebView(
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        navigationDelegate: _processNavigation,
        onPageFinished: (url) {
          setState(() {
            _pageLoaded = true;
          });
        },
        ),
    ));

    if (!_pageLoaded) {
      list.add(Center(child: CircularProgressIndicator()));
    }

    return list;
  }

  FutureOr<NavigationDecision> _processNavigation(NavigationRequest navigation) {
    String url = navigation.url;
    if (AppUrl.launchInternal(url)) {
      return NavigationDecision.navigate;
    }
    else {
      launch(url);
      return NavigationDecision.prevent;
    }
  }

  Widget _buildError(){
    return Center(
      child: Container(
          width: 280,
          child: Text(
            Localization().getStringEx(
                'panel.web.offline.message', 'You need to be online in order to perform this operation. Please check your Internet connection.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Styles().colors.fillColorPrimary,
            ),
          )),
    );
  }


  void _checkOnlineStatus() async {
    try {
      final result = await InternetAddress.lookup('www.example.com');
      setState(() {
        _onlineStatus = (result.isNotEmpty && result[0].rawAddress.isNotEmpty)
            ? _OnlineStatus.online
            : _OnlineStatus.offline;
      });
    } on SocketException catch (_) {
      setState(() {
        _onlineStatus = _OnlineStatus.offline;
      });
    }
  }

  Widget _getHeaderBar() {
    return SimpleHeaderBarWithBack(context: context,
      titleWidget: Text(widget.title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),),);
  }

  void onNotification(String name, dynamic param){
    if(name == AppLivecycle.notifyStateChanged) {
      setState(() {
        _isForeground = (param == AppLifecycleState.resumed);
      });
    }
  }

}

enum _OnlineStatus { online, offline }
