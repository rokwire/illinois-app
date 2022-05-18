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
import 'package:flutter/semantics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessPanel extends StatefulWidget {
  final Map<String, dynamic>? content;
  final bool rootTabDisplay;

  WellnessPanel({this.content, this.rootTabDisplay = false});

  @override
  _WellnessPanelState createState() => _WellnessPanelState();
}

class _WellnessPanelState extends State<WellnessPanel> implements NotificationsListener {
  Map<String, dynamic>? _jsonContent;
  Map<String, dynamic>? _stringsContent;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Assets.notifyChanged]);
    _loadAssetsStrings();
    _loadContent();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  void _loadAssetsStrings() {
    _stringsContent = Assets()['wellness.strings'];
  }

  void _loadContent() {
    if (widget.content != null) {
      _jsonContent = widget.content;
    } else {
      _jsonContent = Assets()['wellness.panels.home'];
    }
  }

  @override
  Widget build(BuildContext context) {
    String? introTextKey = MapPathKey.entry(_jsonContent, 'description.intro_text');
    String? introText = Localization().getStringFromKeyMapping(introTextKey, _stringsContent);
    String? mainTextKey = MapPathKey.entry(_jsonContent, 'description.main_text');
    String? mainText = Localization().getStringFromKeyMapping(mainTextKey, _stringsContent);
    String? bulletKey = MapPathKey.entry(_jsonContent, 'description.bullet');
    String? bullet = Localization().getStringFromKeyMapping(bulletKey, _stringsContent);
    String? secondaryTextKey = MapPathKey.entry(_jsonContent, 'description.secondary_text');
    String? secondaryText = Localization().getStringFromKeyMapping(secondaryTextKey, _stringsContent);
    
    return Scaffold(
      backgroundColor: Styles().colors!.background,
      appBar: widget.rootTabDisplay ? RootHeaderBar(title: Localization().getStringEx('panel.wellness.header.title', 'Wellness')) : _buildStandardHeaderBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Visibility(visible: widget.rootTabDisplay, child:
              Row(children: [
                Expanded(child:
                  Container(color: Styles().colors?.fillColorPrimaryVariant, padding: EdgeInsets.symmetric(vertical: 24), child:
                    Center(child: _buildImage(_jsonContent, 'header.image'))
                 )
                )
              ],)
            ),
            Visibility(
              visible: StringUtils.isNotEmpty(introText),
              child: Padding(
                padding: EdgeInsets.only(left: 24, top: 24, right: 24),
                child: Text(
                  StringUtils.ensureNotEmpty(introText),
                  style: TextStyle(fontSize: 20, color: Styles().colors!.textBackground),
                ),
              ),
            ),
            Visibility(
              visible: StringUtils.isNotEmpty(mainText),
              child: Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                child: Text(
                  StringUtils.ensureNotEmpty(mainText),
                  style: TextStyle(fontSize: 16, color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular),
                ),
              ),
            ),
            _buildDescriptionButtons(),
            Visibility(
              visible: StringUtils.isNotEmpty(bullet),
              child: Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                child: Text(
                  StringUtils.ensureNotEmpty(bullet),
                  style: TextStyle(fontSize: 20, color: Styles().colors!.textBackground),
                ),
              ),
            ),
            Visibility(
              visible: StringUtils.isNotEmpty(secondaryText),
              child: Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 6),
                child: Text(
                  StringUtils.ensureNotEmpty(secondaryText),
                  style: TextStyle(fontSize: 16, color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular),
                ),
              ),
            ),
            _buildActivities(),
            _buildResources()
          ],
        ),
      ),
      bottomNavigationBar: widget.rootTabDisplay ? null : uiuc.TabBar(),
    );
  }

  PreferredSizeWidget _buildStandardHeaderBar() {
    String? headerTitleKey = MapPathKey.entry(_jsonContent, 'header.title');
    String headerTitle = Localization().getStringFromKeyMapping(headerTitleKey, _stringsContent)!;
    return PreferredSize(
        preferredSize: Size.fromHeight(132),
        child: AppBar(
          leading: Semantics(
              label: Localization().getStringEx('headerbar.back.title', 'Back'),
              hint: Localization().getStringEx('headerbar.back.hint', ''),
              button: true,
              excludeSemantics: true,
              child: IconButton(
                  icon: Image.asset('images/chevron-left-white.png'),
                  onPressed: () => _onTapBack(),)),
          flexibleSpace: Align(alignment: Alignment.bottomCenter, child: SingleChildScrollView(child:Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              _buildImage(_jsonContent, 'header.image'),
              Padding(
                padding: EdgeInsets.only(top: 12, bottom: 24),
                child: Semantics(label: headerTitle, hint:  Localization().getStringEx("app.common.heading.one.hint","Header 1"), header: true, excludeSemantics: true, child: Text(
                  headerTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24),
                )),
              )
            ],
          ))),
          centerTitle: true,
        ),
      );
  }

  Widget _buildDescriptionButtons() {
    List<dynamic>? ribbonButtonsContent = MapPathKey.entry(_jsonContent, 'description.ribbon_buttons');
    List<Widget> ribbonButtons = _buildRibbonButtons(ribbonButtonsContent);
    return Visibility(
        visible: CollectionUtils.isNotEmpty(ribbonButtons),
        child: Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child: Column(children: ribbonButtons)));
  }

  Widget _buildActivities() {
    List<Widget> widgetList = [];
    List<dynamic>? activities = MapPathKey.entry(_jsonContent, 'activities');
    if (CollectionUtils.isNotEmpty(activities)) {
      activities!.forEach((dynamic activitiesContent) {
        String? sectionHeaderTextKey = MapPathKey.entry(activitiesContent, 'header.title');
        String? sectionHeaderText = Localization().getStringFromKeyMapping(sectionHeaderTextKey, _stringsContent);
        List<dynamic>? items = MapPathKey.entry(activitiesContent, 'items');
        Stack activitiesWidget = Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                  color: Styles().colors!.fillColorPrimary,
                  height: 40,
                ),
                Container(
                  height: 112,
                  width: double.infinity,
                  child: Image.asset('images/slant-down-right-blue.png', color: Styles().colors!.fillColorPrimary, fit: BoxFit.fill),
                )
              ],
            ),
            Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: _buildImage(activitiesContent, 'header.icon'),
                      ),
                      Expanded(child:
                        Semantics(label: sectionHeaderText,
                            hint: Localization().getStringEx("app.common.heading.two.hint", "Header 2"),
                            header: true,
                            excludeSemantics: true,
                            child:
                            Text(
                              StringUtils.ensureNotEmpty(sectionHeaderText),
                              style: TextStyle(color: Colors.white, fontSize: 20),
                            )
                        )
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildActivitiesColumns(items),
                  ),
                )
              ],
            )
          ],
        );

        widgetList.add(activitiesWidget);
      });
    }
    return (0 < widgetList.length) ? Padding(
      padding: EdgeInsets.only(top: 32),
      child: Column(
        children: widgetList,
      ),
    ) : Container();
  }

  List<Widget> _buildActivitiesColumns(List<dynamic>? itemsJson) {
    List<Widget> columnOneChildren = [];
    List<Widget> columnTwoChildren = [];
    if (CollectionUtils.isNotEmpty(itemsJson)) {
      for (int i = 0; i < itemsJson!.length; i++) {
        Map<String, dynamic> item = itemsJson[i];
        String? titleKey = MapPathKey.entry(item, 'title');
        String? title = Localization().getStringFromKeyMapping(titleKey, _stringsContent);
        String? imageName = MapPathKey.entry(item, 'image');
        dynamic fontSizeJson = MapPathKey.entry(item, 'font_size');
        double fontSizeDouble = 16.0; //by default
        if (fontSizeJson is int) {
          fontSizeDouble = fontSizeJson.toDouble();
        }
        _WellnessActivityButton button = _WellnessActivityButton(
          imageName: imageName,
          label: title,
          hint: '',
          fontSize: fontSizeDouble,
          orderIndex: i.toDouble(),
          onTap: () => _onTapActivity(item),
        );
        if ((i % 2) == 0) {
          columnOneChildren.add(button);
        } else {
          columnTwoChildren.add(button);
        }
      }
    }
    List<Column> columns = [];
    columns.add(Column(
      children: columnOneChildren,
    ));
    columns.add(Column(
      children: columnTwoChildren,
    ));
    return columns;
  }

  void _onTapActivity(Map<String, dynamic> activity) {
    String? titleKey = MapPathKey.entry(activity, 'title');
    String? title = Localization().getString(titleKey, language:'en') ?? titleKey;
    if (title != null) {
      Analytics().logSelect(target:title);
    }

    Map<String, dynamic>? action = MapPathKey.entry(activity, 'action');
    String? actionName = MapPathKey.entry(action, 'name');
    if ('panel' == actionName) {
      String? panelSource = MapPathKey.entry(action, 'source');
      Map<String, dynamic>? panelContent = MapPathKey.entry(Assets()['wellness.panels'], panelSource);
      if (panelContent != null) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessPanel(content: panelContent,)));
      }
    } else /*if ('web' == actionName)*/ {
      _launchUrl(MapPathKey.entry(action, 'source'));
    }
  }

  Widget _buildImage(Map<String, dynamic>? json, String key) {
    String? imageName = MapPathKey.entry(json, key);
    if (StringUtils.isEmpty(imageName)) {
      return Container();
    }
    return Image.asset('images/$imageName', excludeFromSemantics: true,);
  }

  Widget _buildResources() {
    List<Widget> resourceSections = [];
    List<dynamic>? resources = MapPathKey.entry(_jsonContent, 'resources');
    if (CollectionUtils.isNotEmpty(resources)) {
      for (Map<String, dynamic> resourceItem in resources!) {
        String? resourceHeaderTitleKey = MapPathKey.entry(resourceItem, 'title');
        String? resourceHeaderTitle = Localization().getStringFromKeyMapping(resourceHeaderTitleKey, _stringsContent);
        bool isTitleVisible = StringUtils.isNotEmpty(resourceHeaderTitle);
        Stack resourceWidget = Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Visibility(
              visible: isTitleVisible,
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  children: <Widget>[
                    Container(
                      color: Styles().colors!.backgroundVariant,
                      height: 40,
                    ),
                    Container(
                      height: 112,
                      decoration: BoxDecoration(image: DecorationImage(image: AssetImage('images/slant-down-right-grey.png'), fit: BoxFit.fill)),
                    )
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Visibility(
                  visible: isTitleVisible,
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Semantics(label: resourceHeaderTitle,
                        hint: Localization().getStringEx("app.common.heading.two.hint", "Header 2"),
                        header: true,
                        excludeSemantics: true,
                        child:
                        Text(
                          StringUtils.ensureNotEmpty(resourceHeaderTitle),
                          style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20),
                        ),
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Column(
                    children: _buildResourceRibbonButtons(resourceItem),
                  ),
                )
              ],
            )
          ],
        );
        resourceSections.add(resourceWidget);
        Widget? socialMedia = _buildSocialMediaWidget(resourceItem);
        if (socialMedia != null) {
          resourceSections.add(socialMedia);
        }
      }
    }

    return (0 < resourceSections.length) ? Column(children: resourceSections,) : Container();
  }

  List<Widget> _buildResourceRibbonButtons(Map<String, dynamic> resourceItem) {
    List<dynamic>? ribbonButtonsContent = MapPathKey.entry(resourceItem, 'ribbon_buttons');
    List<Widget> ribbonButtons = _buildRibbonButtons(ribbonButtonsContent);
    return ribbonButtons;
  }

  void _onTapRibbonButton(Map<String, dynamic> ribbonButton) {
    String? titleKey = MapPathKey.entry(ribbonButton, 'title');
    String? title = Localization().getString(titleKey, language:'en') ?? titleKey;
    if (title != null) {
      Analytics().logSelect(target:title);
    }

    _launchUrl(MapPathKey.entry(ribbonButton, 'url'));
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

  Widget? _buildSocialMediaWidget(Map<String, dynamic> resourceItem) {
    List<dynamic>? socialMediaContent = MapPathKey.entry(resourceItem, 'social_media');
    String? resourceItemTitleKey = MapPathKey.entry(resourceItem, 'title');
    String? resourceItemTitle = Localization().getStringFromKeyMapping(resourceItemTitleKey, _stringsContent);
    String? followLabel = Localization().getStringFromKeyMapping('panel.wellness.common.resources.follow.label', _stringsContent, defaults: 'Follow');
    String socialMediaTitle = StringUtils.isNotEmpty(resourceItemTitle) ? '$followLabel $resourceItemTitle' : '';
    return CollectionUtils.isNotEmpty(socialMediaContent) ? Padding(
      padding: EdgeInsets.only(top: 16, bottom: 32),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              socialMediaTitle,
              style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildSocialMediaButtons(socialMediaContent),
          )
        ],
      ),
    ) : null;
  }

  List<Widget> _buildSocialMediaButtons(List<dynamic>? socialItems) {
    List<Widget> socialWidgets = [];
    if (CollectionUtils.isNotEmpty(socialItems)) {
      for (Map<String, dynamic> socialItem in socialItems!) {
        String? type = MapPathKey.entry(socialItem, 'type');
        String? imagePath = _getImagePathBySocialMediaType(type);
        if (!StringUtils.isEmpty(imagePath)) {
          socialWidgets.add(Semantics(label: type ?? "", button: true,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () => _onTapSocialMedia(socialItem),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.all(Radius.circular(4))),
                    child: Center(
                      child: Image.asset(imagePath!, excludeFromSemantics: true,),
                    ),
                  ),
                ),
              ))
          );
        }
      }
    }
    return socialWidgets;
  }

  List<Widget> _buildRibbonButtons(List<dynamic>? buttonsContent) {
    List<Widget> buttonWidgets = [];
    if (CollectionUtils.isNotEmpty(buttonsContent)) {
      for (Map<String, dynamic> ribbonButtonSource in buttonsContent!) {
        String? titleKey = MapPathKey.entry(ribbonButtonSource, 'title');
        String? title = Localization().getStringFromKeyMapping(titleKey, _stringsContent);
        String? icon = MapPathKey.entry(ribbonButtonSource, 'icon');
        String? iconValue = StringUtils.ensureNotEmpty(icon, defaultValue: 'chevron-right.png');
        String? hint = MapPathKey.entry(ribbonButtonSource, 'hint');
        String? hintKey =
            hint != null ? StringUtils.ensureNotEmpty(hint, defaultValue: "panel.wellness.common.resources.poor_accessibility.hint") : null;
        String? hintValue = StringUtils.isNotEmpty(hintKey) ? Localization().getStringFromKeyMapping(hintKey, _stringsContent) : "";
        RibbonButton button = RibbonButton(
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
          borderRadius: BorderRadius.all(Radius.circular(5)),
          label: title,
          hint: hintValue,
          rightIconAsset: 'images/$iconValue',
          onTap: () => _onTapRibbonButton(ribbonButtonSource),
        );
        buttonWidgets.add(button);
      }
    }
    return buttonWidgets;
  }

  void _onTapSocialMedia(Map<String, dynamic> socialMedia) {
    String? type = MapPathKey.entry(socialMedia, 'type');
    if (type != null) {
      Analytics().logSelect(target:type);
    }
    
    _launchUrl(MapPathKey.entry(socialMedia, 'url'));
  }

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }

  String? _getImagePathBySocialMediaType(String? socialMediaType) {
    if (StringUtils.isEmpty(socialMediaType)) {
      return null;
    }
    switch (socialMediaType) {
      case 'facebook':
        return 'images/fb-10x20.png';
      case 'twitter':
        return 'images/twitter-20x18.png';
      case 'youtube':
        return 'images/you-tube-20x15.png';
      case 'instagram':
        return 'images/ig-20x20.png';
      default:
        return null;
    }
  }

  /// NotificationListener

  @override
  void onNotification(String name, param) {
    if (name == Assets.notifyChanged) {
      if (mounted) {
        setState(() {
          _loadAssetsStrings();
          _loadContent();
        });
      }
    }
  }
}

class _WellnessActivityButton extends StatelessWidget {
  final String? imageName;
  final String? label;
  final String hint;
  final double fontSize;
  final double? orderIndex;
  final GestureTapCallback? onTap;

  _WellnessActivityButton({required this.imageName, required this.label, this.hint = '', this.fontSize = 20.0, this.onTap, this.orderIndex});

  @override
  Widget build(BuildContext context) {
    return (StringUtils.isNotEmpty(label) || StringUtils.isNotEmpty(imageName)) ? Semantics(
        label: label,
        button: true,
        excludeSemantics: true,
        sortKey: OrdinalSortKey(orderIndex!),
        value: hint,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              width: 140,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    StringUtils.isNotEmpty(imageName) ? Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Image.asset('images/$imageName'),
                    ) : Container(),
                    StringUtils.isNotEmpty(label) ? Text(
                      label!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: fontSize, color: Styles().colors!.fillColorPrimary),
                    ) : Container()
                  ],
                ),
              ),
            ),
          ),
        )) : Container();
  }
}
