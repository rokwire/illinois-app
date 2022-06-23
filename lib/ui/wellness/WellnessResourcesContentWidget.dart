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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessResourcesContentWidget extends StatefulWidget {
  WellnessResourcesContentWidget();

  @override
  State<WellnessResourcesContentWidget> createState() => _WellnessResourcesContentWidgetState();
}

class _WellnessResourcesContentWidgetState extends State<WellnessResourcesContentWidget> {

  List<dynamic>? _commands;
  Map<String, dynamic>? _strings;

  @override
  void initState() {
    Map<String, dynamic>? content = JsonUtils.mapValue(Assets()['wellness.resources']) ;
    _commands = (content != null) ? JsonUtils.listValue(content['commands']) : null;
    _strings = (content != null) ? JsonUtils.mapValue(content['strings']) : null;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      _buildHeader(),
      _buildLargeButtonsContainer(),
      _buildRegularButtonsContainer(),
    ]));
  }

  Widget _buildHeader() {
    return Padding(
        padding: EdgeInsets.only(left: 5, bottom: 10, right: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(Localization().getStringEx('panel.wellness.resources.header.label', 'Wellness Resources'),
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 22, fontFamily: Styles().fontFamilies!.extraBold)),
          HomeFavoriteStar(selected: false, style: HomeFavoriteStyle.Button, padding: EdgeInsets.symmetric(horizontal: 16))
        ]));
  }

  Widget _buildLargeButtonsContainer() {
    List<Widget> widgetList = <Widget>[];
    if (_commands != null) {
      for (dynamic entry in _commands!) {
        Map<String, dynamic>? command = JsonUtils.mapValue(entry);
        if (command != null) {
          String? type = JsonUtils.stringValue(command['type']);
          if (type == 'large') {
            widgetList.add(_buildLargeButton(
              label: _getString(JsonUtils.stringValue(command['id'])),
              hasExternalLink: UrlUtils.isWebScheme(JsonUtils.stringValue(command['url'])),
              onTap: () => _onCommand(command),
            ));
          }
        }
      }
    }
    
    return Column(children: widgetList);
  }

  Widget _buildLargeButton({String? label, bool hasExternalLink = false, void Function()? onTap}) {
    return Padding(padding: EdgeInsets.only(bottom: 10), child:
      Container(decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.circular(5)), child:
        InkWell(onTap: onTap, child:
          Padding(padding: EdgeInsets.only(left: 16), child:
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child:
                Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
                  Text(label ?? '', style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 18)),
                ),
              ),
              hasExternalLink ? Padding(padding: EdgeInsets.only(left: 6, top: 18, bottom: 18), child:
                Image.asset('images/external-link.png', color: Styles().colors!.mediumGray)
              ) : Container(),
              HomeFavoriteButton(style: HomeFavoriteStyle.Button, padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),)
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildRegularButtonsContainer() {
    List<Widget> widgetList = <Widget>[];
    if (_commands != null) {
      for (dynamic entry in _commands!) {
        Map<String, dynamic>? command = JsonUtils.mapValue(entry);
        if (command != null) {
          String? type = JsonUtils.stringValue(command['type']);
          if (type == 'regular') {
            if (widgetList.isNotEmpty) {
              widgetList.add(Divider(color: Styles().colors!.surfaceAccent, height: 1,));
            }
            widgetList.add(_buildRegularButton(
              label: _getString(JsonUtils.stringValue(command['id'])),
              hasExternalLink: UrlUtils.isWebScheme(JsonUtils.stringValue(command['url'])),
              onTap: () => _onCommand(command),
            ));
          }
        }
      }
    }

    return Container(decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.circular(5)), child:
    Column(children: widgetList));

  }

  Widget _buildRegularButton({String? label, bool hasExternalLink = true, void Function()? onTap}) {
    return InkWell(onTap: onTap, child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HomeFavoriteButton(style: HomeFavoriteStyle.Button, padding: EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16)),
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(vertical: 17), child:
            Text(label ?? '', style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 16))
          ),
        ),
        hasExternalLink ? Padding(padding: EdgeInsets.only(left: 8, top: 18, bottom: 18), child:
          Image.asset('images/external-link.png', color: Styles().colors!.mediumGray)
        ) : Container(),
        Padding(padding: EdgeInsets.only(left: 8, right: 16, top: 18, bottom: 18), child:
          Image.asset('images/chevron-right.png')
        ),
      ]),
    );
  }

  String? _getString(String? key, {String? languageCode}) {
    if ((_strings != null) && (key != null)) {
      Map<String, dynamic>? mapping =
        JsonUtils.mapValue(_strings![languageCode]) ??
        JsonUtils.mapValue(_strings![Localization().currentLocale?.languageCode]) ??
        JsonUtils.mapValue(_strings![Localization().defaultLocale?.languageCode]);
      if (mapping != null) {
        return JsonUtils.stringValue(mapping[key]);
      }
    }
    return null;
  }

  void _onCommand(Map<String, dynamic> command) {
    Analytics().logSelect(target: _getString(JsonUtils.stringValue(command['id']), languageCode: Localization().defaultLocale?.languageCode),);
    _launchUrl(JsonUtils.stringValue(command['url']));
  }

  void _launchUrl(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else if (UrlUtils.launchInternal(url)){
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      }
      else{
        launch(url!);
      }
    }
  }
}
