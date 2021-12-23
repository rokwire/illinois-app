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
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/NativeCommunicator.dart';
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

  bool _isOnline;
  bool _isTrackingEnabled;
  bool _isPageLoading = true;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, AppLivecycle.notifyStateChanged);
    _getOnline().then((bool isOnline) {
      setState(() {
        _isOnline = isOnline;
      });
      if (isOnline) {
        _getTrackingEnabled().then((bool trackingEnabled) {
          setState(() {
            _isTrackingEnabled = trackingEnabled;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;
    if (_isOnline == false) {
      contentWidget = _buildStatus(
        title: "Web Content Not Available",
        message: Localization().getStringEx("panel.web.offline.message", "You need to be online in order to perform this operation. Please check your Internet connection."),
      );
    }
    else if (_isTrackingEnabled == false) {
      contentWidget = _buildStatus(
        title: "Web Content Blocked",
        message: "You have opted to deny cookie usage for web content in this app, therefore we have blocked access to web sites. If you change your mind, change your preference <a href='${NativeCommunicator.APP_SETTINGS_URI}'>here</a>.",
      );
    }
    else if ((_isOnline == true) && (_isTrackingEnabled == true)) {
      contentWidget = _buildWebView();
    }
    else {
      contentWidget = _buildInitializing();
    }

    return Scaffold(
      appBar: _getHeaderBar(),
      backgroundColor: Styles().colors.background,
      body: Column(children: <Widget>[
        Expanded(child: contentWidget),
        widget.hideToolBar ? Container() : TabBarWidget()
      ],),);
  }

  Widget _buildWebView() {
    return Stack(children: [
      Visibility(visible: _isForeground,
        child: WebView(
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        navigationDelegate: _processNavigation,
        onPageFinished: (url) {
          setState(() {
            _isPageLoading = false;
          });
        },),),
      Visibility(visible: _isPageLoading,
        child: Center(
          child: CircularProgressIndicator(),
      )),
    ],);
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

  Widget _buildStatus({String title, String message}) {
    List<Widget> contentList = <Widget>[];
    contentList.add(Expanded(flex: 1, child: Container()));
    
    if (title != null) {
      contentList.add(Html(data: title,
          onLinkTap: (url, context, attributes, element) => _onTapStatusLink(url),
          style: { "body": Style(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold, fontSize: FontSize(32), textAlign: TextAlign.center, padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
      );
    }

    if ((title != null) && (message != null)) {
      contentList.add(Container(height: 48));
    }

    if ((message != null)) {
      contentList.add(Html(data: message,
        onLinkTap: (url, context, attributes, element) => _onTapStatusLink(url),
        style: { "body": Style(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), textAlign: TextAlign.left, padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
      );
    }

    contentList.add(Expanded(flex: 3, child: Container()));

    return Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
      Column(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, children: contentList,)
    );
  }

  Widget _buildInitializing(){
    return Center(child:
      CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary),),
    );
  }

  static Future<bool> _getOnline() async {
    List<InternetAddress> result;
    try {
      result = await InternetAddress.lookup('www.example.com');
    } on SocketException catch (_) {
    }
    return ((result != null) && result.isNotEmpty && (result.first.rawAddress != null) && result.first.rawAddress.isNotEmpty);
  }

  static Future<bool> _getTrackingEnabled() async {
    AuthorizationStatus status = await NativeCommunicator().queryTrackingAuthorization('query');
    if (status == AuthorizationStatus.NotDetermined) {
      status = await NativeCommunicator().queryTrackingAuthorization('request');
    }
    return (status == AuthorizationStatus.Allowed);
  }

  Widget _getHeaderBar() {
    return SimpleHeaderBarWithBack(context: context,
      titleWidget: Text(widget.title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),),);
  }

  void _onTapStatusLink(String url) {
    if (AppString.isStringNotEmpty(url)) {
      launch(url);
    }
  }

  void onNotification(String name, dynamic param){
    if (name == AppLivecycle.notifyStateChanged) {
      setState(() {
        _isForeground = (param == AppLifecycleState.resumed);
      });
    }
  }

}

