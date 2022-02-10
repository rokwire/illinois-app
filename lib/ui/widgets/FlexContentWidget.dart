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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:url_launcher/url_launcher.dart';

/*
  "emergency": {
    "title": "Emergency",
    "text": "Something urgent happened.",
    "can_close": true,
    "buttons":[
      {"title":"Yes", "link": {"url": "https://illinois.edu", "options": { "target": "internal", "title": "Yes Web Panel" } } },
      {"title":"No", "link": {"url": "https://illinois.edu", "options": { "target": "external" } } },
      {"title":"Maybe", "link": {"url": "https://illinois.edu", "options": { "target": { "ios": "internal", "android": "external" } } } }
    ]
  }
*/

class FlexContentWidget extends StatefulWidget {
  final dynamic assetsKey;
  final Map<String, dynamic>? jsonContent;
  final void Function(BuildContext context)? onClose;

  FlexContentWidget({this.assetsKey, this.jsonContent, this.onClose});

  static FlexContentWidget? fromAssets(dynamic assetsKey, { void Function(BuildContext context)? onClose }) {
    Map<String, dynamic>? jsonContent;
    dynamic assetsContent = Assets()[assetsKey];
    try { jsonContent = (assetsContent is Map) ? assetsContent.cast<String, dynamic>() : null; }
    catch (e) { print(e.toString()); }
    return (jsonContent != null) ? FlexContentWidget(assetsKey: assetsKey, jsonContent: jsonContent, onClose: onClose) : null;
  }

  @override
  _FlexContentWidgetState createState() => _FlexContentWidgetState();
}

class _FlexContentWidgetState extends State<FlexContentWidget> implements NotificationsListener {
  bool _visible = true;
  Map<String, dynamic>? _jsonContent;

  @override
  void initState() {
    super.initState();
    
    if (widget.jsonContent != null) {
      _jsonContent = widget.jsonContent;  
    }
    if (widget.assetsKey != null) {
      NotificationService().subscribe(this, Assets.notifyChanged);
      if (_jsonContent == null) {
        dynamic content = Assets()[widget.assetsKey];
        try { _jsonContent = (content is Map) ? content.cast<String, dynamic>() : null; }
        catch (e) { print(e.toString()); }
      }
    }
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  void onNotification(String name, dynamic param){
    if (name == Assets.notifyChanged) {
      if (widget.assetsKey != null) {
        Map<String, dynamic>? jsonContent;
        dynamic content = Assets()[widget.assetsKey];
        try { jsonContent = (content is Map) ? content.cast<String, dynamic>() : null; }
        catch (e) { print(e.toString()); }
        
        if (jsonContent != null) {
          setState(() { _jsonContent = jsonContent; });
        }
        else if (widget.onClose != null) {
          widget.onClose!(context);
        }
        else {
          setState(() { _visible = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool closeVisible = _jsonContent != null ? (_jsonContent!['can_close'] ?? false) : false;
    return Visibility(visible: _visible, child:
      Semantics(container: true, child:
        Container(color: Styles().colors!.lightGray, child:
          Row(children: <Widget>[
            Expanded(child:
              Stack(children: <Widget>[
                Container(height: 1, color: Styles().colors!.fillColorPrimaryVariant,),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30), child:
                  _buildContent()),
                Visibility(visible: closeVisible, child:
                  Container(alignment: Alignment.topRight, child:
                    Semantics(label: Localization().getStringEx("widget.flex_content_widget.button.close.hint", "Close"), button: true, excludeSemantics: true, child:
                      InkWell(onTap: _onClose, child:
                        Container(width: 48, height: 48, alignment: Alignment.center, child:
                          Image.asset('images/close-orange.png', excludeFromSemantics: true))))),),
    ],),)],),),),);
  }

  Widget _buildContent() {
    bool hasJsonContent = (_jsonContent != null);
    String? title = hasJsonContent ? _jsonContent!['title'] : null;
    String? text = hasJsonContent ? _jsonContent!['text'] : null;
    List<dynamic>? buttonsJsonContent = hasJsonContent ? _jsonContent!['buttons'] : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Visibility(visible: StringUtils.isNotEmpty(title), child:
        Padding(padding: EdgeInsets.only(top: 0), child:
          Text(title ?? '', style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, ),
        ),),),
        Visibility(visible: StringUtils.isNotEmpty(text), child:
          Padding(padding: EdgeInsets.only(top: 10), child:
            Text(StringUtils.ensureNotEmpty(text), style: TextStyle(color: Color(0xff494949), fontFamily: Styles().fontFamilies!.medium, fontSize: 16, ), ),
        ),),
        _buildButtons(buttonsJsonContent)
      ],
    );
  }

  Widget _buildButtons(List<dynamic>? buttonsJsonContent) {
    if (CollectionUtils.isEmpty(buttonsJsonContent)) {
      return Container();
    }
    List<Widget> buttons = [];
    for (Map<String, dynamic> buttonContent in buttonsJsonContent!) {
      String? title = buttonContent['title'];
      buttons.add(Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        RoundedButton(
          label: StringUtils.ensureNotEmpty(title),
          textColor: Styles().colors!.fillColorPrimary,
          borderColor: Styles().colors!.fillColorSecondary,
          backgroundColor: Styles().colors!.white,
          contentWeight: 0.0,
          onTap: () => _onTapButton(buttonContent),
        ),],
      ));
    }
    return Padding(padding: EdgeInsets.only(top: 20), child: Wrap(runSpacing: 8, spacing: 16, children: buttons));
  }

  void _onClose() {
    Analytics().logSelect(target: "Flex Content: Close");
    if (widget.onClose != null) {
      widget.onClose!(context);
    }
    else {
      setState(() {
        _visible = false;
      });
    }
  }

  void _onTapButton(Map<String, dynamic> button) {
    String? title = button['title'];
    Analytics().logSelect(target: "Flex Content: $title");
    
    Map<String, dynamic>? linkJsonContent = button['link'];
    if (linkJsonContent == null) {
      return;
    }
    String? url = linkJsonContent['url'];
    if (StringUtils.isEmpty(url)) {
      return;
    }
    Map<String, dynamic>? options = linkJsonContent['options'];
    dynamic target = (options != null) ? options['target'] : 'internal';
    if (target is Map) {
      target = target[Platform.operatingSystem.toLowerCase()];
    }

    if ((target is String) && (target == 'external')) {
      launch(url!);
    }
    else {
      String? panelTitle = ((options != null) ? JsonUtils.stringValue(options['title']) : null) ?? title;
      Navigator.of(context).push(CupertinoPageRoute(builder: (context) => WebPanel(url: url, title: panelTitle, hideToolBar: !Storage().onBoardingPassed!, )));
    }
  }
}
