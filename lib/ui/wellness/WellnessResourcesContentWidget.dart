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

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessResourcesContentWidget extends StatefulWidget {
  static const String wellnessCategoryKey = 'resources';
  final String wellnessCategory = wellnessCategoryKey;

  WellnessResourcesContentWidget();

  @override
  State<WellnessResourcesContentWidget> createState() => _WellnessResourcesContentWidgetState();

  static void ensureDefaultFavorites(List<dynamic>? commands) {
    String favoriteKey = WellnessFavorite.favoriteKeyName(category: wellnessCategoryKey);
    if ((Auth2().prefs?.getFavorites(favoriteKey) == null) && (commands != null)) {

      List<dynamic> sortedCommands = List.from(commands);
      
      sortedCommands.sort((dynamic entry1, dynamic entry2) {
        
        Map<String, dynamic>? command1 = JsonUtils.mapValue(entry1);
        int? favorite1 = (command1 != null) ? JsonUtils.intValue(command1['favorite']) : null;
        
        Map<String, dynamic>? command2 = JsonUtils.mapValue(entry2);
        int? favorite2 = (command2 != null) ? JsonUtils.intValue(command2['favorite']) : null;

        if (favorite1 != null) {
          return (favorite2 != null) ? favorite1.compareTo(favorite2) : 1;
        }
        else {
          return (favorite2 != null) ? -1 : 0; 
        }
      });
      
      LinkedHashSet<String> favoriteIds = LinkedHashSet<String>();
      for (dynamic entry in sortedCommands.reversed) {
        Map<String, dynamic>? command = JsonUtils.mapValue(entry);
        if (command != null) {
          String? id = JsonUtils.stringValue(command['id']);
          int? favorite = JsonUtils.intValue(command['favorite']);
          if ((id != null) && (favorite != null)) {
            favoriteIds.add(id);
          }
        }
      }
      Auth2().prefs?.setFavorites(favoriteKey, favoriteIds);
    }
  }
}

class _WellnessResourcesContentWidgetState extends State<WellnessResourcesContentWidget> implements NotificationsListener {

  List<dynamic>? _commands;
  Map<String, dynamic>? _strings;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Wellness.notifyResourcesContentChanged,
    ]);
    _initContent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }
  
  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Wellness.notifyResourcesContentChanged) {
      if (mounted) {
        setState(() {
          _initContent();
        });
      }
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      _buildLargeButtonsContainer(),
      _buildRegularButtonsContainer(),
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
            String? id = JsonUtils.stringValue(command['id']);
            Favorite favorite = WellnessFavorite(id, category: widget.wellnessCategory);
            if (widgetList.isNotEmpty) {
              widgetList.add(Container(height: 8));
            }
            widgetList.add(WellnessLargeResourceButton(
              label: _getString(id),
              favorite: favorite,
              hasExternalLink: UrlUtils.isWebScheme(JsonUtils.stringValue(command['url'])),
              onTap: () => _onCommand(command),
            ));
          }
        }
      }
    }

    widgetList.add(Container(height: 16,));
    
    return Column(children: widgetList);
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
            String? id = JsonUtils.stringValue(command['id']);
            Favorite favorite = WellnessFavorite(id, category: widget.wellnessCategory);
            widgetList.add(WellnessRegularResourceButton(
              label: _getString(id),
              favorite: favorite,
              hasExternalLink: UrlUtils.isWebScheme(JsonUtils.stringValue(command['url'])),
              onTap: () => _onCommand(command),
            ));
          }
        }
      }
    }

    return Container(decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.circular(5)), child:
      Column(children: widgetList)
    );

  }

  void _initContent() {
    Map<String, dynamic>? content = Wellness().resources;
    _commands = (content != null) ? JsonUtils.listValue(content['commands']) : null;
    _strings = (content != null) ? JsonUtils.mapValue(content['strings']) : null;
    WellnessResourcesContentWidget.ensureDefaultFavorites(_commands);
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
    Analytics().logSelect(
      target: _getString(JsonUtils.stringValue(command['id']), languageCode: Localization().defaultLocale?.languageCode),
      source: widget.runtimeType.toString()
    );

    String? url = JsonUtils.stringValue(command['url']);
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }
}

class WellnessLargeResourceButton extends StatelessWidget {
  final String? label;
  final Favorite? favorite;
  final bool hasExternalLink;
  final void Function()? onTap;

  WellnessLargeResourceButton({Key? key, this.label, this.favorite, this.hasExternalLink = false, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.circular(5)), child:
      InkWell(onTap: onTap, child:
        Padding(padding: EdgeInsets.only(left: 16), child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child:
              Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
                Text(label ?? '', style: Styles().textStyles?.getTextStyle("panel.wellness.resource.button.title.large")),
              ),
            ),
            hasExternalLink ? Padding(padding: EdgeInsets.only(left: 6, top: 18, bottom: 18), child:
              Styles().images?.getImage('external-link', excludeFromSemantics: true)
            ) : Container(),
            FavoriteButton(favorite: favorite, style: FavoriteIconStyle.Button, padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),)
          ]),
        ),
      ),
    );
  }
}

class WellnessRegularResourceButton extends StatelessWidget {
  final String? label;
  final Favorite? favorite;
  final bool hasExternalLink;
  final bool hasBorder;
  final void Function()? onTap;

  WellnessRegularResourceButton({Key? key, this.label, this.favorite, this.hasExternalLink = false, this.hasBorder = false, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return hasBorder ? Container(decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.circular(5)), child:
      _buildInterior()
    ) : _buildInterior();
  }

  Widget _buildInterior() {
    return InkWell(onTap: onTap, child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FavoriteButton(favorite: favorite, style: FavoriteIconStyle.Button, padding: EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16)),
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(vertical: 17), child:
            Text(label ?? '', style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'))
          ),
        ),
        hasExternalLink ? Padding(padding: EdgeInsets.only(left: 8, top: 18, bottom: 18), child:
          Styles().images?.getImage('external-link', excludeFromSemantics: true)
        ) : Container(),
        Padding(padding: EdgeInsets.only(left: 8, right: 16, top: 18, bottom: 18), child:
          Styles().images?.getImage('chevron-right-bold', excludeFromSemantics: true)
        ),
      ]),
    );
  }
}
