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
import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessPanel extends StatefulWidget {
  final Map<String, dynamic> content;

  WellnessPanel({this.content});

  @override
  _WellnessPanelState createState() => _WellnessPanelState();
}

class _WellnessPanelState extends State<WellnessPanel> implements NotificationsListener {
  Map<String, dynamic> _jsonContent;
  Map<String, dynamic> _stringsContent;

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
    String headerTitleKey = AppMapPathKey.entry(_jsonContent, 'header.title');
    String headerTitle = Localization().getStringFromKeyMapping(headerTitleKey, _stringsContent);
    String introTextKey = AppMapPathKey.entry(_jsonContent, 'description.intro_text');
    String introText = Localization().getStringFromKeyMapping(introTextKey, _stringsContent);
    String mainTextKey = AppMapPathKey.entry(_jsonContent, 'description.main_text');
    String mainText = Localization().getStringFromKeyMapping(mainTextKey, _stringsContent);
    String bulletKey = AppMapPathKey.entry(_jsonContent, 'description.bullet');
    String bullet = Localization().getStringFromKeyMapping(bulletKey, _stringsContent);
    String secondaryTextKey = AppMapPathKey.entry(_jsonContent, 'description.secondary_text');
    String secondaryText = Localization().getStringFromKeyMapping(secondaryTextKey, _stringsContent);
    return Scaffold(
      backgroundColor: Styles().colors.background,
      appBar: PreferredSize(
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
          flexibleSpace: SingleChildScrollView(child:Column(
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
          )),
          centerTitle: true,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Visibility(
              visible: AppString.isStringNotEmpty(introText),
              child: Padding(
                padding: EdgeInsets.only(left: 24, top: 24, right: 24),
                child: Text(
                  AppString.getDefaultEmptyString(value: introText),
                  style: TextStyle(fontSize: 20, color: Styles().colors.textBackground),
                ),
              ),
            ),
            Visibility(
              visible: AppString.isStringNotEmpty(mainText),
              child: Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                child: Text(
                  AppString.getDefaultEmptyString(value: mainText),
                  style: TextStyle(fontSize: 16, color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular),
                ),
              ),
            ),
            _buildDescriptionButtons(),
            Visibility(
              visible: AppString.isStringNotEmpty(bullet),
              child: Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                child: Text(
                  AppString.getDefaultEmptyString(value: bullet),
                  style: TextStyle(fontSize: 20, color: Styles().colors.textBackground),
                ),
              ),
            ),
            Visibility(
              visible: AppString.isStringNotEmpty(secondaryText),
              child: Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 6),
                child: Text(
                  AppString.getDefaultEmptyString(value: secondaryText),
                  style: TextStyle(fontSize: 16, color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular),
                ),
              ),
            ),
            _buildActivities(),
            _buildResources()
          ],
        ),
      ),
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildDescriptionButtons() {
    List<dynamic> ribbonButtonsContent = AppMapPathKey.entry(_jsonContent, 'description.ribbon_buttons');
    List<Widget> ribbonButtons = _buildRibbonButtons(ribbonButtonsContent);
    return Visibility(
        visible: AppCollection.isCollectionNotEmpty(ribbonButtons),
        child: Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child: Column(children: ribbonButtons)));
  }

  Widget _buildActivities() {
    List<Widget> widgetList = [];
    List<dynamic> activities = AppMapPathKey.entry(_jsonContent, 'activities');
    if (AppCollection.isCollectionNotEmpty(activities)) {
      activities.forEach((dynamic activitiesContent) {
        String sectionHeaderTextKey = AppMapPathKey.entry(activitiesContent, 'header.title');
        String sectionHeaderText = Localization().getStringFromKeyMapping(sectionHeaderTextKey, _stringsContent);
        List<dynamic> items = AppMapPathKey.entry(activitiesContent, 'items');
        Stack activitiesWidget = Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                  color: Styles().colors.fillColorPrimary,
                  height: 40,
                ),
                Container(
                  height: 112,
                  width: double.infinity,
                  child: Image.asset('images/slant-down-right-blue.png', color: Styles().colors.fillColorPrimary, fit: BoxFit.fill),
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
                              AppString.getDefaultEmptyString(value: sectionHeaderText),
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

  List<Widget> _buildActivitiesColumns(List<dynamic> itemsJson) {
    List<Widget> columnOneChildren = [];
    List<Widget> columnTwoChildren = [];
    if (AppCollection.isCollectionNotEmpty(itemsJson)) {
      for (int i = 0; i < itemsJson.length; i++) {
        Map<String, dynamic> item = itemsJson[i];
        String titleKey = AppMapPathKey.entry(item, 'title');
        String title = Localization().getStringFromKeyMapping(titleKey, _stringsContent);
        String imageName = AppMapPathKey.entry(item, 'image');
        dynamic fontSizeJson = AppMapPathKey.entry(item, 'font_size');
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
    String titleKey = AppMapPathKey.entry(activity, 'title');
    String title = Localization().getString(titleKey, language:'en') ?? titleKey;
    if (title != null) {
      Analytics().logSelect(target:title);
    }

    Map<String, dynamic> action = AppMapPathKey.entry(activity, 'action');
    String actionName = AppMapPathKey.entry(action, 'name');
    if ('panel' == actionName) {
      String panelSource = AppMapPathKey.entry(action, 'source');
      Map<String, dynamic> panelContent = AppMapPathKey.entry(Assets()['wellness.panels'], panelSource);
      if (panelContent != null) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessPanel(content: panelContent,)));
      }
    } else if ('web' == actionName) {
      String url = AppMapPathKey.entry(action, 'source');
      if (AppString.isStringNotEmpty(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      }
    }
  }

  Widget _buildImage(Map<String, dynamic> json, String key) {
    String imageName = AppMapPathKey.entry(json, key);
    if (AppString.isStringEmpty(imageName)) {
      return Container();
    }
    return Image.asset('images/$imageName', excludeFromSemantics: true,);
  }

  Widget _buildResources() {
    List<Widget> resourceSections = [];
    List<dynamic> resources = AppMapPathKey.entry(_jsonContent, 'resources');
    if (AppCollection.isCollectionNotEmpty(resources)) {
      for (Map<String, dynamic> resourceItem in resources) {
        String resourceHeaderTitleKey = AppMapPathKey.entry(resourceItem, 'title');
        String resourceHeaderTitle = Localization().getStringFromKeyMapping(resourceHeaderTitleKey, _stringsContent);
        bool isTitleVisible = AppString.isStringNotEmpty(resourceHeaderTitle);
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
                      color: Styles().colors.backgroundVariant,
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
                          AppString.getDefaultEmptyString(value: resourceHeaderTitle),
                          style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 20),
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
        Widget socialMedia = _buildSocialMediaWidget(resourceItem);
        if (socialMedia != null) {
          resourceSections.add(socialMedia);
        }
      }
    }

    return (0 < resourceSections.length) ? Column(children: resourceSections,) : Container();
  }

  List<Widget> _buildResourceRibbonButtons(Map<String, dynamic> resourceItem) {
    List<dynamic> ribbonButtonsContent = AppMapPathKey.entry(resourceItem, 'ribbon_buttons');
    List<Widget> ribbonButtons = _buildRibbonButtons(ribbonButtonsContent);
    return ribbonButtons;
  }

  void _onTapRibbonButton(Map<String, dynamic> ribbonButton) {
    String titleKey = AppMapPathKey.entry(ribbonButton, 'title');
    String title = Localization().getString(titleKey, language:'en') ?? titleKey;
    if (title != null) {
      Analytics().logSelect(target:title);
    }

    String url = AppMapPathKey.entry(ribbonButton, 'url');
    String guideId = AppMapPathKey.entry(ribbonButton, 'guide_id');
    Map<String, dynamic> guideEntry = (guideId != null) ? Guide().entryById(guideId) : null;
    if (guideEntry != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntryId: guideId,)));
    }
    else if (AppString.isStringNotEmpty(url)) {
      if(AppUrl.launchInternal(url)){
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      }
      else{
        launch(url);
      }
    }
  }

  Widget _buildSocialMediaWidget(Map<String, dynamic> resourceItem) {
    List<dynamic> socialMediaContent = AppMapPathKey.entry(resourceItem, 'social_media');
    String resourceItemTitleKey = AppMapPathKey.entry(resourceItem, 'title');
    String resourceItemTitle = Localization().getStringFromKeyMapping(resourceItemTitleKey, _stringsContent);
    String followLabel = Localization().getStringFromKeyMapping('panel.wellness.common.resources.follow.label', _stringsContent, defaults: 'Follow');
    String socialMediaTitle = AppString.isStringNotEmpty(resourceItemTitle) ? '$followLabel $resourceItemTitle' : '';
    return AppCollection.isCollectionNotEmpty(socialMediaContent) ? Padding(
      padding: EdgeInsets.only(top: 16, bottom: 32),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              socialMediaTitle,
              style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
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

  List<Widget> _buildSocialMediaButtons(List<dynamic> socialItems) {
    List<Widget> socialWidgets = [];
    if (AppCollection.isCollectionNotEmpty(socialItems)) {
      for (Map<String, dynamic> socialItem in socialItems) {
        String type = AppMapPathKey.entry(socialItem, 'type');
        String imagePath = _getImagePathBySocialMediaType(type);
        if (!AppString.isStringEmpty(imagePath)) {
          socialWidgets.add(Semantics(label: type ?? "", button: true,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () => _onTapSocialMedia(socialItem),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Styles().colors.fillColorPrimary, borderRadius: BorderRadius.all(Radius.circular(4))),
                    child: Center(
                      child: Image.asset(imagePath, excludeFromSemantics: true,),
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

  List<Widget> _buildRibbonButtons(List<dynamic> buttonsContent) {
    List<Widget> buttonWidgets = [];
    if (AppCollection.isCollectionNotEmpty(buttonsContent)) {
      for (Map<String, dynamic> ribbonButtonSource in buttonsContent) {
        String titleKey = AppMapPathKey.entry(ribbonButtonSource, 'title');
        String title = Localization().getStringFromKeyMapping(titleKey, _stringsContent);
        String icon = AppMapPathKey.entry(ribbonButtonSource, 'icon');
        String iconValue = AppString.getDefaultEmptyString(value: icon, defaultValue: 'chevron-right.png');
        String hint = AppMapPathKey.entry(ribbonButtonSource, 'hint');
        String hintKey =
            hint != null ? AppString.getDefaultEmptyString(value: hint, defaultValue: "panel.wellness.common.resources.poor_accessibility.hint") : null;
        String hintValue = AppString.isStringNotEmpty(hintKey) ? Localization().getStringFromKeyMapping(hintKey, _stringsContent) : "";
        RibbonButton button = RibbonButton(
          height: null,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
          borderRadius: BorderRadius.all(Radius.circular(5)),
          label: title,
          hint: hintValue,
          icon: 'images/$iconValue',
          onTap: () => _onTapRibbonButton(ribbonButtonSource),
        );
        buttonWidgets.add(button);
      }
    }
    return buttonWidgets;
  }

  void _onTapSocialMedia(Map<String, dynamic> socialMedia) {
    String type = AppMapPathKey.entry(socialMedia, 'type');
    if (type != null) {
      Analytics().logSelect(target:type);
    }
    
    String url = AppMapPathKey.entry(socialMedia, 'url');
    if (url != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url,)));
    }
  }

  void _onTapBack() {
    Analytics.instance.logSelect(target: "Back");
    Navigator.pop(context);
  }

  String _getImagePathBySocialMediaType(String socialMediaType) {
    if (AppString.isStringEmpty(socialMediaType)) {
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
  final String imageName;
  final String label;
  final String hint;
  final double fontSize;
  final double orderIndex;
  final GestureTapCallback onTap;

  _WellnessActivityButton({@required this.imageName, @required this.label, this.hint = '', this.fontSize = 20.0, this.onTap, this.orderIndex});

  @override
  Widget build(BuildContext context) {
    return (AppString.isStringNotEmpty(label) || AppString.isStringNotEmpty(imageName)) ? Semantics(
        label: label,
        button: true,
        excludeSemantics: true,
        sortKey: OrdinalSortKey(orderIndex),
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
                    AppString.isStringNotEmpty(imageName) ? Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Image.asset('images/$imageName'),
                    ) : Container(),
                    AppString.isStringNotEmpty(label) ? Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: fontSize, color: Styles().colors.fillColorPrimary),
                    ) : Container()
                  ],
                ),
              ),
            ),
          ),
        )) : Container();
  }
}
