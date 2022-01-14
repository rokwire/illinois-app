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
import 'package:flutter_html/flutter_html.dart' as FlutterHtml;
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:flutter/material.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart' as FlutterWebView;

class WebPanel extends StatefulWidget implements AnalyticsPageName, AnalyticsPageAttributes{
  final String? url;
  final String? analyticsName;
  final String? title;
  final bool hideToolBar;

  WebPanel({required this.url, this.analyticsName, this.title = "", this.hideToolBar = false});

  @override
  _WebPanelState createState() => _WebPanelState();

  @override
  String? get analyticsPageName {
    return analyticsName;
  }

  @override
  Map<String, dynamic> get analyticsPageAttributes {
    return { Analytics.LogAttributeUrl : url };
  }
}

class _WebPanelState extends State<WebPanel> implements NotificationsListener{

  bool? _isOnline;
  bool? _isTrackingEnabled;
  bool _isPageLoading = true;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, AppLivecycle.notifyStateChanged);
    if (Platform.isAndroid) {
      FlutterWebView.WebView.platform = FlutterWebView.SurfaceAndroidWebView();
    }
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
        title: Localization().getStringEx("panel.web.offline.title", "Web Content Not Available"),
        message: Localization().getStringEx("panel.web.offline.message", "You need to be online in order to access web content. Please check your Internet connection."),
      );
    }
    else if (_isTrackingEnabled == false) {
      contentWidget = _buildStatus(
        title: Localization().getStringEx("panel.web.tracking_disabled.title", "Web Content Blocked"),
        message: sprintf(Localization().getStringEx("panel.web.tracking_disabled.message", "You have opted to deny cookie usage for web content in this app, therefore we have blocked access to web sites. If you change your mind, change your preference <a href='%s'>here</a>. Your phone Settings may also need to have Privacy > Tracking enabled.")!, [NativeCommunicator.APP_SETTINGS_URI]),
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
      backgroundColor: Styles().colors!.background,
      body: Column(children: <Widget>[
        Expanded(child: contentWidget),
        widget.hideToolBar ? Container() : TabBarWidget()
      ],),);
  }

  Widget _buildWebView() {
    return Stack(children: [
      Visibility(visible: _isForeground,
        child: FlutterWebView.WebView(
        initialUrl: widget.url,
        javascriptMode: FlutterWebView.JavascriptMode.unrestricted,
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

  FutureOr<FlutterWebView.NavigationDecision> _processNavigation(FlutterWebView.NavigationRequest navigation) {
    String url = navigation.url;
    if (AppUrl.launchInternal(url)) {
      return FlutterWebView.NavigationDecision.navigate;
    }
    else {
      launch(url);
      return FlutterWebView.NavigationDecision.prevent;
    }
  }

  Widget _buildStatus({String? title, String? message}) {
    List<Widget> contentList = <Widget>[];
    contentList.add(Expanded(flex: 1, child: Container()));
    
    if (title != null) {
      contentList.add(FlutterHtml.Html(data: title,
          onLinkTap: (url, context, attributes, element) => _onTapStatusLink(url),
          style: { "body": FlutterHtml.Style(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: FlutterHtml.FontSize(32), textAlign: TextAlign.center, padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
      );
    }

    if ((title != null) && (message != null)) {
      contentList.add(Container(height: 48));
    }

    if ((message != null)) {
      contentList.add(FlutterHtml.Html(data: message,
        onLinkTap: (url, context, attributes, element) => _onTapStatusLink(url),
        style: { "body": FlutterHtml.Style(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular, fontSize: FlutterHtml.FontSize(20), textAlign: TextAlign.left, padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
      );
    }

    contentList.add(Expanded(flex: 3, child: Container()));

    return Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
      Column(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, children: contentList,)
    );
  }

  Widget _buildInitializing(){
    return Center(child:
      CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors!.fillColorPrimary!),),
    );
  }

  static Future<bool> _getOnline() async {
    List<InternetAddress>? result;
    try {
      result = await InternetAddress.lookup('www.example.com');
    } on SocketException catch (_) {
    }
    return ((result != null) && result.isNotEmpty && result.first.rawAddress.isNotEmpty);
  }

  static Future<bool> _getTrackingEnabled() async {
    AuthorizationStatus? status = await NativeCommunicator().queryTrackingAuthorization('query');
    if (status == AuthorizationStatus.NotDetermined) {
      status = await NativeCommunicator().queryTrackingAuthorization('request');
    }
    return (status == AuthorizationStatus.Allowed);
  }

  PreferredSizeWidget _getHeaderBar() {
    return SimpleHeaderBarWithBack(context: context,
      titleWidget: Text(widget.title!, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),),);
  }

  void _onTapStatusLink(String? url) {
    if (AppString.isStringNotEmpty(url)) {
      launch(url!);
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

