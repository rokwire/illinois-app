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

import 'dart:math';

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:illinois/model/PrivacyData.dart";
import "package:illinois/service/Analytics.dart";
import "package:illinois/service/Assets.dart";
import 'package:illinois/service/Auth2.dart';
import "package:illinois/service/Config.dart";
import "package:illinois/service/FlexUI.dart";
import "package:illinois/service/Localization.dart";
import "package:illinois/service/NotificationService.dart";
import "package:illinois/service/Onboarding.dart";
import "package:illinois/service/Storage.dart";
import "package:illinois/ui/onboarding/OnboardingBackButton.dart";
import "package:illinois/ui/widgets/HeaderBar.dart";
import 'package:illinois/ui/widgets/PrivacySlider.dart';
import "package:illinois/ui/widgets/RoundedButton.dart";
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import "package:illinois/ui/widgets/TabBarWidget.dart";
import "package:illinois/utils/Utils.dart";
import "package:illinois/service/Styles.dart";

enum SettingsPrivacyPanelMode { regular, onboarding, update }

class SettingsNewPrivacyPanel extends StatefulWidget with OnboardingPanel {
  final SettingsPrivacyPanelMode? mode;
  final Map<String, dynamic>? onboardingContext;

  SettingsNewPrivacyPanel({Key? key, this.onboardingContext, this.mode}) : super(key: key);

  @override
  State createState() => SettingsNewPrivacyPanelState();
}

class SettingsNewPrivacyPanelState extends State<SettingsNewPrivacyPanel> implements NotificationsListener {
  PrivacyData? _data;
  double? _sliderValue;

  ScrollController? _controller;
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
    _controller!.addListener(_scrollListener);
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
    if (_controller!.offset >= _controller!.position.maxScrollExtent && !_controller!.position.outOfRange) {
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
    dynamic _jsonData = Assets()["privacy_new"];
    _data = PrivacyData.fromJson(_jsonData);
  }

  double get _privacyLevel {
    return Auth2().prefs?.privacyLevel?.toDouble() ?? 5.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widget.mode == SettingsPrivacyPanelMode.regular)
          ? SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          Localization().getStringEx("panel.settings.new_privacy.privacy.label.title", "Choose Your Privacy Level")!,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
      )
          : null,
      body: _buildContentWidget(),
      backgroundColor: Styles().colors!.background,
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
                    _buildSliderInstructions()
                  ]),
                ),
                SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedSliverHeading(child: _buildPrivacySlider())
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    _PrivacyEntriesListWidget(
                      data: _data,
                      selectedPrivacyLevel: _sliderValue,
                    ),
                  ]),
                ),
              ],
            ))),
        _buildSaveButton()
      ],
    );
  }

  Widget _buildPrivacySlider(){
    return
      Container(
        padding: EdgeInsets.symmetric(vertical:18),
        color: Styles().colors!.white,
        child: SafeArea(
          top: false,
          child: Column(children: <Widget>[
            Container(height: 6,),
            PrivacyLevelSlider(
              initialValue: _sliderValue,
              onValueChanged: (double value) {
                if (value != _sliderValue) {
                  setState(() {
                    _sliderValue = value;
                  });
                }
              },
            ),
          ],)
          ));
  }

  Widget _buildSaveButton() {
    return Container(
        color: Styles().colors!.fillColorPrimaryVariant,
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                    child: Stack(children: <Widget>[
                      ScalableRoundedButton(
                          label: _disabled
                              ? Localization().getStringEx("panel.settings.new_privacy.privacy.button.set_privacy.disabled.title", "Scroll to Review")
                              : Localization().getStringEx("panel.settings.new_privacy.privacy.button.set_privacy.title", "Set my Privacy"),
                          hint: _disabled
                              ? Localization().getStringEx("panel.settings.new_privacy.privacy.button.set_privacy.disabled.hint", "")
                              : Localization().getStringEx("panel.settings.new_privacy.privacy.button.set_privacy.hint", ""),
                          borderColor: _disabled ? Styles().colors!.disabledTextColorTwo : Styles().colors!.fillColorSecondary,
                          backgroundColor: Styles().colors!.fillColorPrimaryVariant,
                          textColor: _disabled ? Styles().colors!.disabledTextColorTwo : Styles().colors!.white,
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
                                valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.white),),),),),),
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
                color: Styles().colors!.fillColorPrimary,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: <Widget>[
                       Expanded(
                          child: Center( child:
                            Container(
                              padding: EdgeInsets.only(top: 42, bottom: 10, left: 40, right: 40),
                              child:
                              Semantics(button:false,  hint: "${_sliderValue?.round().toString() ?? ""}",
                                child: Text(
                                  Localization().getStringEx("panel.settings.new_privacy.privacy.dialog.update_privacy.title", "Your new \nprivacy level")!,
                                  style: TextStyle(fontSize: 24, color: Colors.white, fontFamily: Styles().fontFamilies!.bold),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            )
                          ),
                      ),
                      Semantics(
                        explicitChildNodes: true,
                        child:
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(15)),
                                border: Border.all(color: Styles().colors!.white!, width: 2),
                              ),
                              child: Semantics( button: true, label: Localization().getStringEx("panel.settings.new_privacy.privacy.dialog.update_privacy.button.back.title", "Back"),child:
                                Center(child:
                                ExcludeSemantics( child:
                                  Text(
                                    "\u00D7",
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                    ),
                                  )
                                ),
                              ),
                            ),
                          ),
                        )
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(child: SingleChildScrollView(
          child: Column(children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  child: Column(children: <Widget>[
                    Container(
                      height: 48,
                      color: Styles().colors!.fillColorPrimary,
                    ),
                    Container(
                      height: 48,
                      color: Styles().colors!.white,
                    ),

                  ],),
                ),
                Center(
                  child: Container(
                      height: 86,
                      width: 86,
                      child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Container(
                            padding: EdgeInsets.all(1),
                            decoration: BoxDecoration(
                                color: Styles().colors!.white,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(width:2, color: Styles().colors!.fillColorPrimary!,)
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Styles().colors!.white,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(width:2, color: Styles().colors!.fillColorSecondary!,)
                              ),
                              child: Center(
                                child: Semantics(
                                  label: Localization().getStringEx("panel.settings.new_privacy.privacy.dialog.label.new_privacy", "Privacy Level: "),
                                  child: Text(
                                    _sliderValue?.round().toString() ?? "",
                                    style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 24, fontFamily: Styles().fontFamilies!.extraBold),
                                  ),
                                )
                              ),
                            ),))
                  ),
                )
              ],),
            Container(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text(
                Localization().getStringEx("panel.settings.new_privacy.privacy.dialog.update_privacy.label2", "This change requires us to make the following changes:")!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimaryVariant),
              ),
            ),
            _buildPrivacyFeature2DialogEntries(),
            Container(
              height: 10,
            ),
            Text(
              Localization().getStringEx("panel.settings.new_privacy.privacy.dialog.update_privacy.confirm", "Are you sure?")!,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimaryVariant),
            ),
            Container(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: RoundedButton(
                      onTap: () {
                        Navigator.pop(context);
                        Analytics.instance.logAlert(text: "Update privacy", selection: "Yes");
                        _save();
                      },
                      backgroundColor: Colors.transparent,
                      borderColor: Styles().colors!.fillColorSecondary,
                      textColor: Styles().colors!.fillColorPrimary,
                      label: Localization().getStringEx("panel.settings.new_privacy.privacy.dialog.update_privacy.yes", "Yes")),
                  ),
                  Container(
                    width: 10,
                  ),
                  Expanded(
                    child:RoundedButton(
                      onTap: () {
                        Analytics.instance.logAlert(text: "Update privacy", selection: "No");
                        Navigator.pop(context);
                      },
                      backgroundColor: Colors.transparent,
                      borderColor: Styles().colors!.fillColorSecondary,
                      textColor: Styles().colors!.fillColorPrimary,
                      label: Localization().getStringEx("panel.settings.new_privacy.privacy.dialog.update_privacy.no", "No"))
                  )
                ],
              ),
            ),
            Container(height:20)
          ],),)),
      ],
    );
  }

  Widget _buildPrivacyFeature2DialogEntries() {
    List<Widget> list = [];
    if (_data?.features2 != null) {
      for (PrivacyFeature2? feature2 in _data!.features2!) {
        if (feature2!.maxLevel!.round() >= _sliderValue!.round()) {
          list.add(
              Row(children: <Widget>[
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: Styles().colors!.fillColorSecondary,),
                ),
                Container(width: 8,),
                Expanded( child:
                Text(
                  Localization().getStringEx(feature2.key, feature2.text)!,
                  style: TextStyle( fontSize: 16, color: Styles().colors!.fillColorPrimaryVariant,),
                )
                )
              ],)
              );
        }
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  void _onSaveClicked() {
    if (!_disabled) {
      Analytics.instance.logSelect(target: "Set Privacy");
      if ((widget.mode == SettingsPrivacyPanelMode.regular) && (_sliderValue!.toInt() < this._privacyLevel)) {
        AppAlert.showCustomDialog(context: context, contentPadding: EdgeInsets.all(0), contentWidget: _buildUpdatePrivacyDialog(context));
      }
      else {
        _save();
      }
    }
  }

  void _save() {
    Auth2().prefs?.privacyLevel = _sliderValue!.toInt();
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
    Container(color: Styles().colors!.surface, child:
    Stack(children: <Widget>[
      _titleLayout(),
      OnboardingBackButton(
          padding: const EdgeInsets.only(left: 10, top: 10, right: 20, bottom: 5),
          onTap: () {
            Analytics.instance.logSelect(target: "Back");
            Navigator.pop(context);
          }),
    ])))
        : Container();
  }

  Widget _titleLayout() {
    String title = (widget.mode != SettingsPrivacyPanelMode.update)
        ? Localization().getStringEx("panel.settings.new_privacy.privacy.label.set_your_privacy_level", "Set your privacy level")!
        : Localization().getStringEx("panel.settings.new_privacy.privacy.label.update_your_privacy_level", "Update your privacy level")!;
    String? hint = (widget.mode != SettingsPrivacyPanelMode.update)
        ? Localization().getStringEx("panel.settings.new_privacy.privacy.label.set_your_privacy_level.hint", "Header 1")
        : Localization().getStringEx("panel.settings.new_privacy.privacy.label.update_your_privacy_level.hint", "Header 1");
    Widget titleWidget = Semantics(
        label: title,
        hint: hint,
        excludeSemantics: true,
        header: true,
        child: Container(
            color: Styles().colors!.surface,
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: 10, top: 10),
              child: Center(
                  child: Text(
                    title,
                    style: new TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 24.0, color: Styles().colors!.fillColorPrimary),
                  )),
            )));

    Widget subTitleWidget;
    if (widget.mode == SettingsPrivacyPanelMode.update) {
      String subTitle = Localization().getStringEx("panel.settings.new_privacy.privacy.label.some_details_have_changed", "Some details have changed")!;
      String? subTitleHint = Localization().getStringEx("panel.settings.new_privacy.privacy.label.some_details_have_changed.hint", "Header 2");
      subTitleWidget = Semantics(
          label: subTitle,
          hint: subTitleHint,
          excludeSemantics: true,
          header: true,
          child: Container(
              color: Styles().colors!.surface,
              child: Padding(
                padding: EdgeInsets.only(left: 10, right: 10, top: 5),
                child: Center(
                    child: Text(
                      subTitle,
                      style: new TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 18.0, color: Styles().colors!.fillColorPrimary),
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
  Widget _buildSliderInstructions(){
    return Container(
      padding: EdgeInsets.only(left: 22, right: 22,),
      color: Styles().colors!.white,
      child: Row(children: <Widget>[
        Expanded(child:
        Text(
          Localization().getStringEx("panel.settings.new_privacy.privacy.label.slider_help", "Adjust slider to change your privacy level")!,
          style: TextStyle(color: Styles().colors!.textSurface, fontSize: 18, fontFamily:Styles().fontFamilies!.bold),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        )
      ],)
    );
  }

  Widget _descriptionLayout() {
    int level = _sliderValue?.round() ?? _privacyLevel.truncate();
    PrivacyDescription? description = _data?.privacyDescription?.firstWhere((element) => element!.level == level);
    if(description == null){
      return Container(); //empty
    }
    return Container(
        height: 160,
        color: Styles().colors!.white,
        child: Padding(
            padding: EdgeInsets.only(top: 24, left: 22, right: 22,),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
              Container(
                height: 60,
                width: 60,
                alignment: Alignment.center,
                decoration:  BoxDecoration(
                  border: Border.all(color: Styles().colors!.fillColorPrimary!,width: 2),
                  color: Styles().colors!.white,
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                ),
                child: Container(
                  height: 52,
                  width: 52,
                  alignment: Alignment.center,
                  decoration:  BoxDecoration(
                    border: Border.all(color: Styles().colors!.fillColorSecondary!, width: 2),
                    color: Styles().colors!.white,
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                  ),
                  child: Semantics( label:Localization().getStringEx("panel.settings.new_privacy.label.privacy_level.title", "Privacy Level: "),
                    child: Text(level.toString(),
                      style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 24, color: Styles().colors!.fillColorPrimary)),
                  ),
                )),
                Container(width: 20,),
                Expanded(child:
                  Text( Localization().getStringEx(description.key, description.text)!,
                    style: new TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16.0, color: Styles().colors!.textSurface),
                    textAlign: TextAlign.left))
              ])));

  }
}

class _PrivacyEntriesListWidget extends StatefulWidget {
  final PrivacyData? data;
  final double? selectedPrivacyLevel;

  const _PrivacyEntriesListWidget({Key? key, this.data, this.selectedPrivacyLevel,}) : super(key: key);

  PrivacyEntriesListState createState() => PrivacyEntriesListState();
}

class PrivacyEntriesListState extends State<_PrivacyEntriesListWidget>  with TickerProviderStateMixin{
  List<AnimationController> _animationControllers = [];
  Map<String?, bool> expansionState = Map();
  Key expansionTileKey = new Key(new Random().nextInt(10000).toString());

  @override
  void initState() {
    if(widget.data?.categories?.isNotEmpty ?? false){
      widget.data!.categories!.forEach((PrivacyCategory category) {
        //prepare for expand/colapse
        expansionState[category.title] = false;
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    if(_animationControllers.isNotEmpty) {
      _animationControllers.forEach((controller) {
        controller.dispose();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(top: 10,),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Text(Localization().getStringEx("panel.settings.new_privacy.label.description.title", "Features and Data Collection")!,
                  style: TextStyle(fontFamily: Styles().fontFamilies!.bold, color: Styles().colors!.fillColorPrimary, fontSize: 20)),
              ),
              Container(height: 7,),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Text(Localization().getStringEx("panel.settings.new_privacy.label.description.info", "Learn more about specific features, and use dropdown for more information about how data is being used.")!,
                  style: TextStyle(fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface, fontSize: 16)),
              ),
              Container(height: 12,),
              Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 18),
                child:
                Semantics(
                  button: true,
                  child: Container(
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Styles().colors!.fillColorSecondary!))),
                    child: GestureDetector(
                      onTap: _onTapExpandAll,
                      child: Text(
                        _canClose? Localization().getStringEx("panel.settings.new_privacy.button.close_all.title","Close All")! : Localization().getStringEx("panel.settings.new_privacy.button.expand_all.title","Expand All")!,
                        style: TextStyle(fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface, fontSize: 16)
                      ),
                    )
                  )
                )
              ),
              Container(height: 12),
              Column(children: _buildCategories(),)
            ]));
  }

  List<Widget> _buildCategories() {
    List<Widget> widgets =  [];
    PrivacyData? data = widget.data;
    if (data != null && AppCollection.isCollectionNotEmpty(data.categories)) {
      data.categories!.forEach((PrivacyCategory category) {
        widgets.add(_buildCategory(category));
        widgets.add(Container(height: 12,));
      });
    }

    return widgets;
  }

  Widget _buildCategory(PrivacyCategory category){
    final Animatable<double> _halfTween = Tween<double>(begin: 0.0, end: 0.5);
    final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
    AnimationController _controller = AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    _animationControllers.add(_controller);
    bool expanded = expansionState[category.title]!;
    Animation<double> _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));
    //Fix for the wrong arrow position when expand all
    if(expanded){
      _controller.forward();
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.circular(4), border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)),
        padding: EdgeInsets.symmetric(horizontal: 0),
        child: Theme(data: ThemeData(accentColor: Styles().colors!.white,
            dividerColor: Colors.white,
            backgroundColor: Styles().colors!.white,
            ),
            child: ExpansionTile(
              key: expansionTileKey,
              initiallyExpanded: expanded,
              title:
              Semantics(label: Localization().getStringEx(category.titleKey??"",category.title),
                  hint: Localization().getStringEx("panel.settings.new_privacy.label.hint","Double tap to ")! +(expanded?"Hide" : "Show ")+" information",
                  excludeSemantics:true,child:
                  Container(child: Text(Localization().getStringEx(category.titleKey??"",category.title)!, style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 16),))),
              backgroundColor: Styles().colors!.fillColorPrimary,
              children: _buildCategoryEntries(category),
              trailing: RotationTransition(
                  turns: _iconTurns,
                  child: Icon(Icons.arrow_drop_down, color: Styles().colors!.white,)),
              onExpansionChanged: (bool expand) {
                if (expand) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
                expansionState[category.title] = expand;
                setState(() {});
              },
            ))));
  }

  List<Widget> _buildCategoryEntries(PrivacyCategory category){
    List<Widget> entries = [];
    if(category.entries2?.isNotEmpty??false){
      category.entries2!.forEach((entry) {
        entries.add(_PrivacyEntry(data: entry, currentPrivacyLevel: widget.selectedPrivacyLevel?.round()??0,));
      });
    }
    return entries;
  }

  void _onTapExpandAll(){
    if(_canClose){
      expansionState.forEach((key, value) {
        expansionState[key] = false;
      });
    } else {
      expansionState.forEach((key, value) {
        expansionState[key] = true;
      });
    }
    //Workaround to recreate the widget so it can redraw with new initialExpanded property (which works only when creating the widget for the first time)
    expansionTileKey = new Key(new Random().nextInt(10000).toString());
    setState(() {});
  }

  bool get _canClose{
    return expansionState.containsValue(true);
  }
}

class _PrivacyEntry extends StatefulWidget {
  final PrivacyEntry2? data;
  final int? currentPrivacyLevel;

  _PrivacyEntry({Key? key, this.data, this.currentPrivacyLevel}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PrivacyEntryState();
}

class _PrivacyEntryState extends State<_PrivacyEntry> with TickerProviderStateMixin{
  AnimationController? _infoController;
  AnimationController? _additionalInfoController;
  bool _dataUsageExpanded = false;
  bool _additionalDataUsageExpanded = false;

  @override
  void initState() {
    _infoController = AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    _additionalInfoController = AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _infoController!.dispose();
    _additionalInfoController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PrivacyEntry2 data = widget.data!;
    String title = Localization().getStringEx(data.titleKey, data.title)!;
    String? description = Localization().getStringEx(data.descriptionKey, data.description);
    String? dataUsageInfo = Localization().getStringEx(data.dataUsageKey, data.dataUsage);
    String iconRes = "images/" + data.iconRes!;
    String iconResOff = "images/" + data.offIconRes!;
    int minLevel = data.minLevel!;
    //The additional data is needed for the Wallet section (personalization)
    String? additionalDescription = Localization().getStringEx(data.additionalDescriptionKey, data.additionalDescription);
    String? additionalDataUsageInfo = Localization().getStringEx(data.additionalDataUsageKey, data.additionalDataUsage);
    int? additionalMinLevel = data.additionalDataMinLevel;

    bool isEnabled = widget.currentPrivacyLevel!>=minLevel;

    return
      Semantics( container: true,
        child: Container(
        padding: EdgeInsets.only(top: 14, bottom: 19, left: 14, right: 44),
        color: Styles().colors!.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: 4),
              child: PrivacyIcon(enabledIcon: iconRes, disabledIcon: iconResOff, minPrivacyLevel: minLevel, currentPrivacyLevel: widget.currentPrivacyLevel,)),
            Container(width: 10,),
            Expanded(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.start,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: <Widget>[
                 Text(title,
                  style:  TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.extraBold, color: isEnabled? Styles().colors!.fillColorPrimary: Styles().colors!.fillColorPrimaryTransparent015),
                 ),
                 Container(height: 2,),
                 Semantics( explicitChildNodes: false,
                  child: _buildInfo(description, dataUsageInfo, minLevel, false)),
                 Container(height: (additionalDescription?.isNotEmpty ?? false) ? 26: 0),
                 Semantics( explicitChildNodes: false,
                  child: _buildInfo(additionalDescription, additionalDataUsageInfo, additionalMinLevel, true))
               ],
             ),
           ),
          ],
        ),
      )
    );
  }

  _buildInfo(String? description, String? dataUsageInfo, int? minLevel, bool additionalInfo){
    final Animatable<double> _halfTween = Tween<double>(begin: 0.0, end: 0.5);
    final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
    Animation<double> _iconTurns = additionalInfo? _additionalInfoController!.drive(_halfTween.chain(_easeInTween)) : _infoController!.drive(_halfTween.chain(_easeInTween));
    bool infoExpanded = additionalInfo? _additionalDataUsageExpanded : _dataUsageExpanded;

    if(description?.isEmpty ?? true)
      return Container();

    bool isEnabled = widget.currentPrivacyLevel!>=minLevel!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(description!,
          style:  TextStyle(fontSize: 14, fontFamily: Styles().fontFamilies!.regular, color: isEnabled? Styles().colors!.textSurface: Styles().colors!.textSurfaceTransparent15),
        ),
        Semantics( explicitChildNodes: true,
          child: GestureDetector(
            onTap: (){
              setState(() {
                if(additionalInfo)
                  _additionalDataUsageExpanded = !_additionalDataUsageExpanded;
                else
                _dataUsageExpanded = !_dataUsageExpanded;
              });
              bool expanded = additionalInfo? _additionalDataUsageExpanded : _dataUsageExpanded;
              AnimationController? controller = additionalInfo? _additionalInfoController : _infoController;
              if (expanded) {
                controller!.forward();
              } else {
                controller!.reverse();
              }
            },
            child: Container(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(child:
                      Text(Localization().getStringEx("panel.settings.new_privacy.button.expand_data.title","See Data Usage")!,
                        style:  TextStyle(fontSize: 14, fontFamily: Styles().fontFamilies!.regular, color: isEnabled? Styles().colors!.fillColorPrimary: Styles().colors!.fillColorPrimaryTransparent015),
                      )
                    ),
                    Container(width: 9,),
                    RotationTransition(
                        turns: _iconTurns,
                        child: Image.asset(isEnabled? "images/down-arrow-orange.png": "images/down-arrow-orange-off.png", excludeFromSemantics: true,)),
                  ],
                )))),
        !infoExpanded? Container():
        Semantics( explicitChildNodes: true,
          child:
            Container(
              padding: EdgeInsets.only(top: 6, bottom: 8),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                    border: Border(left: BorderSide(width: 1, color: Styles().colors!.fillColorSecondary!))
                ),
                child: Text(dataUsageInfo!,
                    style:  TextStyle(fontSize: 14, fontFamily: Styles().fontFamilies!.regular, color: isEnabled? Styles().colors!.textSurface: Styles().colors!.textSurfaceTransparent15)),
              ),
            )
        )
      ],
    );
  }
}

class _PinnedSliverHeading extends SliverPersistentHeaderDelegate{
  final Widget child;
  double constExtent = 140;
  Size? childSize;

  _PinnedSliverHeading({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(child: child,);
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