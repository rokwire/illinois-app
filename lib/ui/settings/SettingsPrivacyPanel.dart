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

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Onboarding.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/model/PrivacyData.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

enum SettingsPrivacyPanelMode { regular, onboarding, update }

class SettingsPrivacyPanel extends StatefulWidget with OnboardingPanel {
  final SettingsPrivacyPanelMode mode;
  final Map<String, dynamic> onboardingContext;

  SettingsPrivacyPanel({Key key, this.mode = SettingsPrivacyPanelMode.regular, this.onboardingContext}) : super(key: key);

  @override
  _SettingsPrivacyPanelState createState() => _SettingsPrivacyPanelState();
}

class _SettingsPrivacyPanelState extends State<SettingsPrivacyPanel> implements NotificationsListener {
  PrivacyData _data;
  double _sliderValue;
  String _selectedPrivacyState = "feature";

  ScrollController _controller;
  bool _disabled = false;
  bool _updating = false; 

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this,[
      Assets.notifyChanged,
      Localization.notifyLocaleChanged,
      Assets.notifyChanged
    ]);

    _controller = ScrollController();
    _controller.addListener(_scrollListener);
    _disabled = (widget.mode != SettingsPrivacyPanelMode.regular);

    _loadPrivacyData();
    _loadPrivacyLevel();

  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Assets.notifyChanged) {
      setState(() {
        _loadPrivacyData();
      });
    } else if (name == Localization.notifyLocaleChanged) {
      //We need to refresh because the text fields are preloaded with the locale
      _data?.reload();
      setState(() {});
    }
    else if (name == Assets.notifyChanged) {
      setState(() {
        _loadPrivacyData();
      });

    }
  }

  void _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent && !_controller.position.outOfRange) {
      //enable when the user scroll to bottom.
      setState(() {
        _disabled = false;
      });
    }
  }

  void _loadPrivacyLevel() async {
    setState(() {
      _sliderValue = this._privacyLevel;
    });
  }

  void _loadPrivacyData() async {
      dynamic _jsonData = Assets()['privacy'];
      _data = PrivacyData.fromJson(_jsonData);
  }

  double get _privacyLevel {
    int privacyLevel = User().privacyLevel;
    return (privacyLevel != null) ? privacyLevel.toDouble() : 5.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widget.mode == SettingsPrivacyPanelMode.regular)
          ? SimpleHeaderBarWithBack(
              context: context,
              titleWidget: Text(
                Localization().getStringEx('panel.settings.privacy.label.title', 'My Privacy'),
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            )
          : null,
      body: _buildContentWidget(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: (widget.mode == SettingsPrivacyPanelMode.regular) ? TabBarWidget() : null,
    );
  }

  Widget _buildContentWidget() {
    return Column(
      children: <Widget>[
        Expanded(
            child: SafeArea(child: CustomScrollView(
            controller: _controller,
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildContentHeadingWidget(),
                  _descriptionLayout(),
                ]),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedSliverHeading(child: _buildTabsWidget())
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  _PrivacyEntriesListWidget(
                    data: _data,
                    selectedPrivacyLevel: _sliderValue,
                    selectedPrivacyState: _selectedPrivacyState,
                  ),
                  _bottomDescriptionLayout(),
                ]),
              )
            ],
        ))),
        Container(
          color: Styles().colors.fillColorPrimary,
          child: SafeArea(
            top: false,
            child: SizedBox(
//              height: 180.0,
              child: Container(
                child: Column(
                  children: <Widget>[
                    Container(
//                        height: 100,
                        color: Styles().colors.fillColorPrimary,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          child: _PrivacyLevelSlider(
                            initialValue: _sliderValue,
                            onValueChanged: (double value) {
                              if (value != _sliderValue) {
                                setState(() {
                                  _sliderValue = value;
                                });
                              }
                            },
                          ),
                        )),
                    _buildSaveCancelButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveCancelButtons() {
    return Container(
        color: Styles().colors.fillColorPrimaryVariant,
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: Stack(children: <Widget>[
                    RoundedButton(
                        label: _disabled
                            ? Localization().getStringEx('panel.settings.privacy.button.set_privacy.disabled.title', 'Scroll to Review')
                            : Localization().getStringEx('panel.settings.privacy.button.set_privacy.title', 'Set my Privacy'),
                        hint: _disabled
                            ? Localization().getStringEx('panel.settings.privacy.button.set_privacy.disabled.hint', '')
                            : Localization().getStringEx('panel.settings.privacy.button.set_privacy.hint', ''),
                        height: 48,
                        borderColor: _disabled ? Styles().colors.disabledTextColorTwo : Styles().colors.fillColorSecondary,
                        backgroundColor: Styles().colors.fillColorPrimaryVariant,
                        textColor: _disabled ? Styles().colors.disabledTextColorTwo : Styles().colors.white,
                        onTap: () => _onSaveClicked()),
                    Visibility(
                      visible: _updating,
                      child: Container(
                        height: 48, 
                        child: Align(
                          alignment:Alignment.center,
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.white),),),),),),
                    ]))
              ],
            )));
  }

  Widget _buildUpdatePrivacyDialog(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                color: Styles().colors.fillColorPrimary,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Center(
                          child: Text(
                            Localization().getStringEx("panel.settings.privacy.dialog.update_privacy.title", "New Privacy Settings"),
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            border: Border.all(color: Styles().colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '\u00D7',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Container(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            Localization().getStringEx("panel.settings.privacy.dialog.update_privacy.label1", "Your new privacy setting"),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Colors.black),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              color: Styles().colors.fillColorPrimary,
              height: 30,
              width: 30,
              child: Center(
                child: Text(
                  _sliderValue?.round()?.toString() ?? "",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            Localization().getStringEx("panel.settings.privacy.dialog.update_privacy.label2", "requires us to make the following chages:"),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Colors.black),
          ),
        ),
        _buildPrivacyFeature2DialogEntries(),
        Container(
          height: 10,
        ),
        Text(
          Localization().getStringEx("panel.settings.privacy.dialog.update_privacy.confirm", "Are you sure?"),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Colors.black),
        ),
        Container(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RoundedButton(
                  onTap: () {
                    Navigator.pop(context);
                    Analytics.instance.logAlert(text: "Update privacy", selection: "Yes");
                    _save();
                  },
                  backgroundColor: Colors.transparent,
                  borderColor: Styles().colors.fillColorSecondary,
                  textColor: Styles().colors.fillColorPrimary,
                  label: Localization().getStringEx("panel.settings.privacy.dialog.update_privacy.yes", "Yes")),
              Container(
                height: 10,
              ),
              RoundedButton(
                  onTap: () {
                    Analytics.instance.logAlert(text: "Update privacy", selection: "No");
                    Navigator.pop(context);
                  },
                  backgroundColor: Colors.transparent,
                  borderColor: Styles().colors.fillColorSecondary,
                  textColor: Styles().colors.fillColorPrimary,
                  label: Localization().getStringEx("panel.settings.privacy.dialog.update_privacy.no", "No"))
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyFeature2DialogEntries() {
    List<Widget> list = List<Widget>();
    if (_data?.features2 != null) {
      for (PrivacyFeature2 feature2 in _data.features2) {
        if (feature2.maxLevel.round() >= _sliderValue.round()) {
          list.add(Text(
            Localization().getStringEx(feature2.key, feature2.text),
            style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Colors.black),
          ));
        }
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  void _onSaveClicked() {
    if (!_disabled) {
      Analytics.instance.logSelect(target: 'Set Privacy');
      if ((widget.mode == SettingsPrivacyPanelMode.regular) && (_sliderValue.toInt() < this._privacyLevel)) {
        AppAlert.showCustomDialog(context: context, contentPadding: EdgeInsets.all(0), contentWidget: _buildUpdatePrivacyDialog(context));
      }
      else {
        _save();
      }
    }
  }

  void _save() {
    User().privacyLevel = _sliderValue.toInt();
    Storage().privacyUpdateVersion = Config().appVersion;
    
    if (widget.mode == SettingsPrivacyPanelMode.regular) {
      Navigator.pop(context);
    } else if (widget.mode == SettingsPrivacyPanelMode.onboarding) {
      if (!_updating) {
        setState(() { _updating = true; });
        FlexUI().update().then((_){
          if (mounted) {
            setState(() { _updating = false; });
            Onboarding().next(context, widget);
          }
        });
      }
    } else if (widget.mode == SettingsPrivacyPanelMode.update) {
      
    }
  }

  Widget _buildContentHeadingWidget() {
    return (widget.mode == SettingsPrivacyPanelMode.onboarding)
        ? Semantics(explicitChildNodes: true, child:
            Container(color: Styles().colors.surface, child:
                Stack(children: <Widget>[
                  _titleLayout(),
                  OnboardingBackButton(
                      padding: const EdgeInsets.only(left: 10, top: 10, right: 20, bottom: 5),
                      onTap: () {
                        Analytics.instance.logSelect(target: "Back");
                        Navigator.pop(context);
                      }),
                ])))
        : _titleLayout();
  }

  Widget _titleLayout() {
    String title = (widget.mode != SettingsPrivacyPanelMode.update)
      ? Localization().getStringEx('panel.settings.privacy.label.set_your_privacy_level', 'Set your privacy level')
      : Localization().getStringEx('panel.settings.privacy.label.update_your_privacy_level', 'Update your privacy level');
    String hint = (widget.mode != SettingsPrivacyPanelMode.update)
      ? Localization().getStringEx('panel.settings.privacy.label.set_your_privacy_level.hint', 'Header 1')
      : Localization().getStringEx('panel.settings.privacy.label.update_your_privacy_level.hint', 'Header 1');
    Widget titleWidget = Semantics(
      label: title,
      hint: hint,
      excludeSemantics: true,
      header: true,
      child: Container(
          color: Styles().colors.surface,
          child: Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 10),
            child: Center(
              child: Text(
                title,
                style: new TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 24.0, color: Styles().colors.fillColorPrimary),
            )),
          )));
    
    Widget subTitleWidget;
    if (widget.mode == SettingsPrivacyPanelMode.update) {
      String subTitle = Localization().getStringEx('panel.settings.privacy.label.some_details_have_changed', 'Some details have changed');
      String subTitleHint = Localization().getStringEx('panel.settings.privacy.label.some_details_have_changed.hint', 'Header 2');
      subTitleWidget = Semantics(
        label: subTitle,
        hint: subTitleHint,
        excludeSemantics: true,
        header: true,
        child: Container(
            color: Styles().colors.surface,
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: 10, top: 5),
              child: Center(
                child: Text(
                  subTitle,
                  style: new TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 18.0, color: Styles().colors.fillColorPrimary),
              )),
            )));
    }
    else {
      subTitleWidget = Container();
    }

    return Column(children: <Widget>[
      titleWidget,
      subTitleWidget,
    ],);
  }

  Widget _descriptionLayout() {
    return Container(
        color: Styles().colors.surface,
        child: Padding(
            padding: EdgeInsets.only(top: 14, left: 24, right: 24, bottom: 24),
            child: Text(
                Localization().getStringEx('panel.settings.privacy.label.description',
                  'Choose your privacy level with the slider below. You can review what information you share and change your setting at any time.'),
                style: new TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16.0, color: Styles().colors.textBackground),
                textAlign: TextAlign.center)));
  }

  Widget _bottomDescriptionLayout() {
    return Container(
        child: Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              Localization().getStringEx('panel.settings.privacy.label.bottom_description',
                  'Regardless of the privacy level anonymous data will be collected and used to optimize performance'),
              style: TextStyle(fontFamily: Styles().fontFamilies.regular, color: Styles().colors.textBackground, fontSize: 14),
            )));
  }

  Widget _buildTabsWidget() {
    return Container(
        color: Styles().colors.background,
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), child: Row(children: _buildTypeTabs())));
  }

  List<Widget> _buildTypeTabs() {
    List<Widget> tabs = new List();
    if (_data != null && AppCollection.isCollectionNotEmpty(_data.types)) {
      _data.types.forEach((PrivacyType type) {
        tabs.add(Expanded(
            child: _PreferenceTab(
                text: type.title,
                left: _data.types.first == type,
                selected: _selectedPrivacyState == type.value,
                onTap: () {
                  setState(() {
                    _selectedPrivacyState = type.value;
                  });
                })));
      });
    }
    return tabs;
  }
}

class _PrivacyEntriesListWidget extends StatefulWidget {
  final PrivacyData data;
  final double selectedPrivacyLevel;
  final String selectedPrivacyState;

  const _PrivacyEntriesListWidget({Key key, this.data, this.selectedPrivacyLevel, this.selectedPrivacyState}) : super(key: key);

  PrivacyEntriesListState createState() => PrivacyEntriesListState();
}

class PrivacyEntriesListState extends State<_PrivacyEntriesListWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(top: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildCategories()));
  }

  List<Widget> _buildCategories() {
    List<Widget> widgets = new List();
    PrivacyData data = widget.data;
    if (data != null && AppCollection.isCollectionNotEmpty(data.categories)) {
      data.categories.forEach((PrivacyCategory category) {
        _fillListContent(widgets, category);
      });
    }

    return widgets;
  }

  void _fillListContent(List<Widget> widgets, PrivacyCategory category) {
    widgets.add(_buildCategoryHeaderWidget(category));
    widgets.add(_buildCategoryContent(category));
  }

  Widget _buildCategoryContent(PrivacyCategory category) {
    BorderSide borderSide = BorderSide(color: Styles().colors.surfaceAccent, style: BorderStyle.solid);
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Semantics(container: true,child: Container(
            decoration: BoxDecoration(border: Border(left: borderSide, right: borderSide)),
            child: Column(children: _buildCategoryEntries(category)))));
  }

  List<Widget> _buildCategoryEntries(PrivacyCategory category) {
    List<Widget> widgets = new List();
    List<PrivacyEntry> entries = category?.entries;
    widgets.add(_buildCategoryDescriptionWidget(category));
    if (AppCollection.isCollectionNotEmpty(entries)) {
      entries.forEach((PrivacyEntry entry) {
        widgets.add(_buildEntryWidget(entry));
      });
    }
    return widgets;
  }

  Widget _buildCategoryHeaderWidget(PrivacyCategory category) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Semantics(
            label: category.title,
            hint: Localization().getStringEx("app.common.heading.two.hint", "Header 2"),
            header: true,
            excludeSemantics: true,
            child: Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  border: Border.all(color: Styles().colors.surfaceAccent),
                  color: Styles().colors.lightGray,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(0), topRight: Radius.circular(0)),
                ),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(category.title, style: TextStyle(fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary, fontSize: 16))))));
  }

  Widget _buildCategoryDescriptionWidget(PrivacyCategory category) {
    String categoryStateDescription = PrivacyData().getLocalizedString(category?.description != null ? category?.description[widget.selectedPrivacyState] : null);
    bool hasDescription = AppString.isStringNotEmpty(categoryStateDescription);
    return !hasDescription
        ? Container()
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: 0),
            child: Container(
                color: Styles().colors.white,
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Text(categoryStateDescription, style: TextStyle(fontFamily: Styles().fontFamilies.regular, color: Styles().colors.textBackground, fontSize: 16)))));
  }

  Widget _buildEntryWidget(PrivacyEntry entry, {bool isLast = false}) {
    bool active = _isActive(entry);
    if (entry.type == widget.selectedPrivacyState)
      return Padding(
          padding: EdgeInsets.symmetric(horizontal: 0),
          child: Semantics(
              label: entry.text,
              checked: active,
              enabled: active,
              excludeSemantics: true,
              child: Container(
                  color: Styles().colors.white,
                  child: Padding(
                      padding: EdgeInsets.only(right: 24, top: 8, bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          flex: 1,
                          child: Padding(padding: EdgeInsets.only(left: 12), child: Image.asset(active ? 'images/selected.png' : "images/disabled.png")),
                        ),
                        Expanded(
                            flex: 9,
                            child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text(
                                  entry.text,
                                  style: TextStyle(fontFamily: Styles().fontFamilies.regular, color: active ? Styles().colors.textBackground : Styles().colors.disabledTextColor, fontSize: 14),
                                )))
                      ])))));
    else
      return Container();
  }

  bool _isActive(PrivacyEntry entry) {
    return entry.minLevel <= widget.selectedPrivacyLevel;
  }
}

class _PrivacyLevelSlider extends StatefulWidget {
  final double initialValue;
  final Function onValueChanged;

  const _PrivacyLevelSlider({Key key, this.onValueChanged, this.initialValue}) : super(key: key);

  @override
  _PrivacyLevelSliderState createState() => _PrivacyLevelSliderState();
}

class _PrivacyLevelSliderState extends State<_PrivacyLevelSlider> {
  double _discreteValue;
  Color _mainColor = Styles().colors.white;
  Color _trackColor = Styles().colors.fillColorSecondary;

  @override
  void initState() {
    super.initState();
    _discreteValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    int _roundedValue = _discreteValue?.round();
    final ThemeData theme = Theme.of(context);
    return Container(
        color: Styles().colors.fillColorPrimary,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 6, right: 6, bottom: 8, top: 8),
              child:
              Semantics(excludeSemantics: true, child:
                Row(
                  children: <Widget>[
                    Expanded(
                        child: Row(children: <Widget>[
                      Image.asset("images/chevron-left.png"),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(Localization().getStringEx('widget.privacy_level_slider.label.left.title', "More Privacy"),
                              style: TextStyle(fontFamily: Styles().fontFamilies.regular, color: Styles().colors.white, fontSize: 14))),
                    ])),
                    Expanded(
                        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(Localization().getStringEx('widget.privacy_level_slider.label.right.title', "More Features"),
                              style: TextStyle(fontFamily: Styles().fontFamilies.regular, color: Styles().colors.white, fontSize: 14))),
                      Image.asset("images/chevron-right.png"),
                    ])),
                  ],
                ),
              )
            ),
            Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Container(
                            height: 25,
                            decoration: BoxDecoration(
                              color: Styles().colors.fillColorPrimaryVariant,
                              border: Border.all(color: Styles().colors.fillColorPrimaryVariant, width: 1),
                              borderRadius: BorderRadius.circular(24.0),
                            )),
                      )),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  SliderTheme(
                      data: theme.sliderTheme.copyWith(
                          activeTrackColor: _trackColor,
                          inactiveTrackColor: _trackColor,
                          activeTickMarkColor: _mainColor,
                          thumbColor: _mainColor,
                          thumbShape: _CustomThumbShape(),
                          tickMarkShape: _CustomTickMarkShape(),
                          showValueIndicator: ShowValueIndicator.never,
                          valueIndicatorTextStyle: TextStyle(fontSize: 20, fontFamily: Styles().fontFamilies.extraBold, color: Styles().colors.fillColorPrimary)),
                      child: MergeSemantics(
                          child: Semantics(
                              label: Localization().getStringEx('panel.settings.privacy.button.set_privacy.slider.hint', "Privacy Level"),
                              enabled: true,
                              increasedValue: Localization().getStringEx('panel.settings.privacy.button.set_privacy.slider.increase', "increased to") +
                                  (_roundedValue + 1).toString(),
                              decreasedValue: Localization().getStringEx('panel.settings.privacy.button.set_privacy.slider.decrease', "decreased to") +
                                  (_roundedValue - 1).toString(),
                              child: Slider(
                                value: _discreteValue,
                                min: 1.0,
                                max: 5.0,
                                divisions: 4,
                                semanticFormatterCallback: (double value) => value.round().toString(),
                                label: '$_roundedValue',
                                onChanged: (double value) {
                                  setState(() {
                                    _discreteValue = value;
                                    widget.onValueChanged(value);
                                  });
                                },
                              )))),
                ])
              ],
            )
          ],
        ));
  }
}

class _CustomThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size.fromRadius(16);
  }

  @override
  void paint(
    PaintingContext context,
    Offset thumbCenter, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    final Canvas canvas = context.canvas;
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.activeTickMarkColor,
    );

    final ColorTween colorTween2 = ColorTween(
      begin: Styles().colors.white,
      end: Styles().colors.white,
    );

    final ColorTween colorTween3 = ColorTween(
      begin: Styles().colors.fillColorSecondary,
      end: Styles().colors.fillColorSecondary,
    );
    final ColorTween colorTween4 = ColorTween(
      begin: Styles().colors.fillColorPrimary,
      end: Styles().colors.fillColorPrimary,
    );

    canvas.drawCircle(thumbCenter, 25, Paint()..color = colorTween4.evaluate(enableAnimation));
    canvas.drawCircle(thumbCenter, 23, Paint()..color = colorTween2.evaluate(enableAnimation));
    canvas.drawCircle(thumbCenter, 21, Paint()..color = colorTween3.evaluate(enableAnimation));
    canvas.drawCircle(thumbCenter, 19, Paint()..color = colorTween.evaluate(enableAnimation));
    labelPainter.paint(canvas, thumbCenter + Offset(-labelPainter.width / 2.0, -labelPainter.height / 2.0));
  }
}

class _CustomTickMarkShape extends SliderTickMarkShape {
  @override
  Size getPreferredSize({SliderThemeData sliderTheme, bool isEnabled}) {
    return Size.fromRadius(3);
  }

  @override
  void paint(PaintingContext context, Offset center,
      {RenderBox parentBox, SliderThemeData sliderTheme, Animation<double> enableAnimation, Offset thumbCenter, bool isEnabled, TextDirection textDirection}) {
    final Canvas canvas = context.canvas;
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: Styles().colors.fillColorPrimary,
    );
    final ColorTween colorTween2 = ColorTween(begin: sliderTheme.disabledThumbColor, end: sliderTheme.thumbColor);
    canvas.drawCircle(center, 8, Paint()..color = colorTween.evaluate(enableAnimation));
    canvas.drawCircle(center, 6, Paint()..color = colorTween2.evaluate(enableAnimation));
  }
}

class _PreferenceTab extends StatelessWidget {
  final String text;
  final bool left;
  final bool selected;
  final GestureTapCallback onTap;

  _PreferenceTab({Key key, this.text, this.left, this.selected, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Semantics(
          label: text,
          button: true,
          excludeSemantics: true,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Color(0xffededed),
              border: Border.all(color: Color(0xffc1c1c1), width: 1, style: BorderStyle.solid),
              borderRadius: left ? BorderRadius.horizontal(left: Radius.circular(100.0)) : BorderRadius.horizontal(right: Radius.circular(100.0)),
            ),
            child: Center(
                child: Text(text,
                    style: TextStyle(fontFamily: selected ? Styles().fontFamilies.extraBold : Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.fillColorPrimary))),
          )),
    );
  }
}

class _PinnedSliverHeading extends SliverPersistentHeaderDelegate{

  final Widget child;
  final double constExtent = 80;

  _PinnedSliverHeading({@required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(height: constExtent, child: child,);
  }

  @override
  double get maxExtent => constExtent;

  @override
  double get minExtent => constExtent;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
