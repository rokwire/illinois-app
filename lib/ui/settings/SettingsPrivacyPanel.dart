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

import "package:flutter/material.dart";
import "package:illinois/model/PrivacyData.dart";
import "package:illinois/service/Analytics.dart";
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import "package:illinois/service/Config.dart";
import "package:illinois/service/FlexUI.dart";
import 'package:rokwire_plugin/service/content.dart';
import "package:rokwire_plugin/service/localization.dart";
import "package:rokwire_plugin/service/notification_service.dart";
import "package:rokwire_plugin/service/onboarding.dart";
import "package:illinois/service/Storage.dart";
import "package:illinois/ui/onboarding/OnboardingBackButton.dart";
import "package:illinois/ui/widgets/HeaderBar.dart";
import 'package:illinois/ui/widgets/PrivacySlider.dart';
import "package:rokwire_plugin/ui/widgets/rounded_button.dart";
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import "package:rokwire_plugin/utils/utils.dart";
import "package:rokwire_plugin/service/styles.dart";

enum SettingsPrivacyPanelMode { regular, onboarding, update }

class SettingsPrivacyPanel extends StatefulWidget with OnboardingPanel {
  final SettingsPrivacyPanelMode? mode;
  final Map<String, dynamic>? onboardingContext;

  SettingsPrivacyPanel({Key? key, this.onboardingContext, this.mode}) : super(key: key);

  @override
  State createState() => _SettingsPrivacyPanelState();
}

class _SettingsPrivacyPanelState extends State<SettingsPrivacyPanel> implements NotificationsListener {
  PrivacyData? _data;
  double? _sliderValue;

  ScrollController? _controller;
  bool _disabled = false;
  bool _updating = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this,[
      Localization.notifyLocaleChanged,
    ]);

    _controller = ScrollController();
    _controller!.addListener(_scrollListener);
    _disabled = (widget.mode != SettingsPrivacyPanelMode.regular);
    _sliderValue = this._privacyLevel;

    _loading = true;
    Content().loadContentItem('privacy').then((dynamic value) {
      setStateIfMounted(() {
        _data = PrivacyData.fromJson(JsonUtils.mapValue(value));
        _loading = false;
      });
    });

  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Localization.notifyLocaleChanged) {
      //We need to refresh because the text fields are preloaded with the locale
      _data?.reload();
      setState(() {});
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

  double get _privacyLevel {
    return Auth2().prefs?.privacyLevel?.toDouble() ?? 5.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widget.mode == SettingsPrivacyPanelMode.regular)
        ? HeaderBar(title: Localization().getStringEx("panel.settings.privacy.privacy.label.title", "Choose Your Privacy Level"),)
        : null,
      body: _loading ? _buildLoadingWidget() : _buildContentWidget(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: (widget.mode == SettingsPrivacyPanelMode.regular) ? uiuc.TabBar() : null,
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
                Expanded(child: 
                  RoundedButton(
                      label: _disabled
                          ? Localization().getStringEx("panel.settings.privacy.privacy.button.set_privacy.disabled.title", "Scroll to Review")
                          : Localization().getStringEx("panel.settings.privacy.privacy.button.set_privacy.title", "Set My Privacy"),
                      hint: _disabled
                          ? Localization().getStringEx("panel.settings.privacy.privacy.button.set_privacy.disabled.hint", "")
                          : Localization().getStringEx("panel.settings.privacy.privacy.button.set_privacy.hint", ""),
                      textStyle: _disabled ? Styles().textStyles?.getTextStyle("widget.button.disabled.title.large.fat.variant_two") : Styles().textStyles?.getTextStyle("widget.colourful_button.title.large.accent"),
                      borderColor: _disabled ? Styles().colors!.disabledTextColorTwo : Styles().colors!.fillColorSecondary,
                      backgroundColor: Styles().colors!.fillColorPrimaryVariant,
                      progress: _updating,
                      onTap: () => _onSaveClicked()),
                )
              ],
            )));
  }

  Widget _buildUpdatePrivacyDialog(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Material(color: Styles().colors!.fillColorPrimary, child:
        Padding(padding: const EdgeInsets.all(16.0), child:
          Column(children: [
            Align(alignment: Alignment.centerRight, child:
              Semantics(label: Localization().getStringEx("panel.settings.privacy.privacy.dialog.update_privacy.button.back.title", "Back"), child:
                IconButton(icon: Styles().images?.getImage('close-circle-white') ?? Container(), onPressed: () => Navigator.pop(context))
              ),
            ),
            Padding(padding: EdgeInsets.all(8), child:
              Semantics(button:false, hint: "${_sliderIntValue?.toString() ?? ""}", child:
                Text(
                  Localization().getStringEx("panel.settings.privacy.privacy.dialog.update_privacy.title", "Your New\nPrivacy Level"),
                  textAlign: TextAlign.center,
                  style: Styles().textStyles?.getTextStyle("widget.dialog.message.large.fat"),
                ),
              ),
            ),
          ],),
        ),
      ),
      Column(children: <Widget>[
        Stack(alignment: Alignment.center, children: <Widget>[
          Column(children: <Widget>[
            Container(height: 48, color: Styles().colors!.fillColorPrimary,),
            Container(height: 48, color: Styles().colors!.white,),
          ],),
          Center(child:
            Container(height: 86, width: 86, child:
              Padding(padding: EdgeInsets.all(6), child:
                Container(padding: EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Styles().colors!.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(width:2, color: Styles().colors!.fillColorPrimary!,)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Styles().colors!.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(width:2, color: Styles().colors!.fillColorSecondary!,)
                    ),
                    child: Center(child:
                      Semantics(label: Localization().getStringEx("panel.settings.privacy.privacy.dialog.label.new_privacy", "Privacy Level: "), child:
                        Text(_sliderIntValue?.toString() ?? "", style: Styles().textStyles?.getTextStyle("widget.title.extra_large.extra_fat")),
                      )
                    ),
                  ),
                ),
              )
            ),
          )
        ],),
        SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 26), child:
          Text(
            Localization().getStringEx("panel.settings.privacy.privacy.dialog.update_privacy.label2", "This change requires us to make the following changes where applicable:"),
            textAlign: TextAlign.center,
            style: Styles().textStyles?.getTextStyle("panel.settings.privacy_panel.update.message.fat")
          ),
        ),
        _buildPrivacyFeature2DialogEntries(),
        SizedBox(height: 16),
        Text(
          Localization().getStringEx("panel.settings.privacy.privacy.dialog.update_privacy.confirm", "Are you sure?"),
          textAlign: TextAlign.center,
          style: Styles().textStyles?.getTextStyle("panel.settings.privacy_panel.update.message.fat")
        ),
        SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child:
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
            Expanded(child:
              RoundedButton(label: Localization().getStringEx("panel.settings.privacy.privacy.dialog.update_privacy.yes", "Yes"), onTap: () {
                Navigator.pop(context);
                Analytics().logAlert(text: "Update privacy", selection: "Yes");
                _save();
              },),
            ),
            SizedBox(width: 16),
            Expanded(child:
              RoundedButton(label: Localization().getStringEx("panel.settings.privacy.privacy.dialog.update_privacy.no", "No"), onTap: () {
                Analytics().logAlert(text: "Update privacy", selection: "No");
                Navigator.pop(context);
              },),
            )
          ],),
        ),
        SizedBox(height:20)
      ],),
    ],);
  }

  Widget _buildPrivacyFeature2DialogEntries() {
    List<Widget> list = [];
    if (_data?.features2 != null) {
      for (PrivacyFeature2? feature2 in _data!.features2!) {
        if (feature2!.maxLevel!.round() >= _sliderIntValue!) {
          list.add(
            Row(children: <Widget>[
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: Styles().colors!.fillColorSecondary,),
              ),
              SizedBox(width: 8),
              Expanded( child:
                Text(
                  Localization().getString(feature2.key, defaults:feature2.text) ?? '',
                  style: Styles().textStyles?.getTextStyle("panel.settings.privacy_panel.update.message"),
                )
              )
            ])
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
      Analytics().logSelect(target: "Set Privacy");
      if ((widget.mode == SettingsPrivacyPanelMode.regular) && (_sliderIntValue! < this._privacyLevel)) {
        showDialog(context: context, builder: (context) {
          return AlertDialog(content: _buildUpdatePrivacyDialog(context), scrollable: true, contentPadding: EdgeInsets.zero,);
        });
      }
      else {
        _save();
      }
    }
  }

  void _save() {
    Auth2().prefs?.privacyLevel = _sliderIntValue!;
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
    if (widget.mode == SettingsPrivacyPanelMode.onboarding) {
      return Semantics(explicitChildNodes: true, child:
        Container(color: Styles().colors!.surface, child:
          Stack(children: <Widget>[
            _titleLayout(),
            OnboardingBackButton(
                padding: const EdgeInsets.only(left: 10, top: 10, right: 20, bottom: 5),
                onTap: () {
                  Analytics().logSelect(target: "Back");
                  Navigator.pop(context);
                }),
        ])));
    }
    else if (widget.mode == SettingsPrivacyPanelMode.update) {
      return _titleLayout();
    }
    else {
      return Container(); // Do not show title layout as it matches pretty much the header bar title.
    }
  }

  Widget _titleLayout() {
    String title = (widget.mode != SettingsPrivacyPanelMode.update)
        ? Localization().getStringEx("panel.settings.privacy.privacy.label.set_your_privacy_level", "Set your privacy level")
        : Localization().getStringEx("panel.settings.privacy.privacy.label.update_your_privacy_level", "Update your privacy level");
    String? hint = (widget.mode != SettingsPrivacyPanelMode.update)
        ? Localization().getStringEx("panel.settings.privacy.privacy.label.set_your_privacy_level.hint", "Header 1")
        : Localization().getStringEx("panel.settings.privacy.privacy.label.update_your_privacy_level.hint", "Header 1");
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
                    style: Styles().textStyles?.getTextStyle("widget.title.extra_large.extra_fat")
                  )),
            )));

    Widget subTitleWidget;
    if (widget.mode == SettingsPrivacyPanelMode.update) {
      String subTitle = Localization().getStringEx("panel.settings.privacy.privacy.label.some_details_have_changed", "Some details have changed");
      String? subTitleHint = Localization().getStringEx("panel.settings.privacy.privacy.label.some_details_have_changed.hint", "Header 2");
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
                      style: Styles().textStyles?.getTextStyle("widget.title.medium.fat")
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
          Localization().getStringEx("panel.settings.privacy.privacy.label.slider_help", "Adjust slider to change your privacy level"),
          style:  Styles().textStyles?.getTextStyle("panel.settings.privacy_panel.privacy.label.medium"),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        )
      ],)
    );
  }

  Widget _descriptionLayout() {
    int level = _sliderIntValue ?? _privacyLevel.truncate();
    PrivacyDescription? description;
    if (CollectionUtils.isNotEmpty(_data?.privacyDescription)) {
      for (PrivacyDescription desc in _data!.privacyDescription!) {
        if (desc.level == level) {
          description = desc;
          break;
        }
      }
    }
    if(description == null){
      return Container(); //empty
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 180),
      child: Container(
        color: Styles().colors!.white,
        child: Padding(
            padding: EdgeInsets.only(top: 24, left: 22, right: 22, bottom: 8),
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
                  child: Semantics( label:Localization().getStringEx("panel.settings.privacy.label.privacy_level.title", "Privacy Level: "),
                    child: Text(level.toString(),
                      style: Styles().textStyles?.getTextStyle("widget.title.extra_large.extra_fat")),
                  ),
                )),
                Container(width: 20,),
                Expanded(child:
                  Text( Localization().getString(description.key, defaults: description.text) ?? '',
                    style: Styles().textStyles?.getTextStyle( "panel.settings.privacy_panel.privacy.label.regular"),
                    textAlign: TextAlign.left))
              ]))),
    );

  }

  Widget _buildLoadingWidget() => Center(child:
    SizedBox(width: 32, height: 32, child:
      CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
    )
  );

  int? get _sliderIntValue {
    return _sliderValue?.round();
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
  Map<String, bool> expansionState = Map();
  Key expansionTileKey = new Key(new Random().nextInt(10000).toString());

  @override
  void initState() {
    if(widget.data?.categories?.isNotEmpty ?? false){
      widget.data!.categories!.forEach((PrivacyCategory category) {
        //prepare for expand/colapse
        if (category.title != null) {
          expansionState[category.title!] = false;
        }
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
                child: Text(Localization().getStringEx("panel.settings.privacy.label.description.title", "Features and Data Collection"),
                  style:  Styles().textStyles?.getTextStyle("panel.settings.privacy_panel.privacy.description.large")),
              ),
              Container(height: 7,),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Text(Localization().getStringEx("panel.settings.privacy.label.description.info", "Learn more about specific features, and use dropdown for more information about how data is being used."),
                  style: Styles().textStyles?.getTextStyle("panel.settings.privacy_panel.privacy.label.regular")),
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
                        _canClose? Localization().getStringEx("panel.settings.privacy.button.close_all.title","Close All") : Localization().getStringEx("panel.settings.privacy.button.expand_all.title","Expand All"),
                        style: Styles().textStyles?.getTextStyle("panel.settings.privacy_panel.privacy.label.regular")
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
    if (data != null && CollectionUtils.isNotEmpty(data.categories)) {
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
        child: Theme(data: ThemeData(/*accentColor: Styles().colors!.white,*/
            /*backgroundColor: Styles().colors!.white,*/
            dividerColor: Colors.white,
            ),
            child: ExpansionTile(
              key: expansionTileKey,
              initiallyExpanded: expanded,
              title:
              Semantics(label: Localization().getString(category.titleKey, defaults: category.title),
                  hint: Localization().getStringEx("panel.settings.privacy.label.hint","Double tap to ") + (expanded ? "Hide" : "Show") + " information",
                  excludeSemantics:true,child:
                  Container(child: Text(Localization().getString(category.titleKey, defaults:category.title) ?? '', style: Styles().textStyles?.getTextStyle("widget.heading.regular.fat")))),
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
                if (category.title != null) {
                  expansionState[category.title!] = expand;
                }
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
    String title = Localization().getString(data.titleKey, defaults: data.title)!;
    String? description = Localization().getString(data.descriptionKey, defaults: data.description)?.replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
    String? dataUsageInfo = Localization().getString(data.dataUsageKey, defaults: data.dataUsage);
    String iconKey = data.iconRes!;
    String iconKeyOff = data.offIconRes!;
    int minLevel = data.minLevel!;
    //The additional data is needed for the Wallet section (personalization)
    String? additionalDescription = Localization().getString(data.additionalDescriptionKey, defaults: data.additionalDescription);
    String? additionalDataUsageInfo = Localization().getString(data.additionalDataUsageKey, defaults: data.additionalDataUsage);
    int? additionalMinLevel = data.additionalDataMinLevel;

    bool isEnabled = widget.currentPrivacyLevel!>=minLevel;

    return
      Semantics( container: true,
        child: Container(
        padding: EdgeInsets.only(top: 14, bottom: 19, left: 14, right: 24),
        color: Styles().colors!.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: 4),
              child: PrivacyIcon(enabledIconKey: iconKey, disabledIconKey: iconKeyOff, minPrivacyLevel: minLevel, currentPrivacyLevel: widget.currentPrivacyLevel,)),
            Container(width: 10,),
            Expanded(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.start,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: <Widget>[
                 Padding(padding: EdgeInsets.only(right: 20), child: Text(title,
                  style:  isEnabled?  Styles().textStyles?.getTextStyle("panel.settings.privacy_panel.privacy.entry.title.enabled") : Styles().textStyles?.getTextStyle("panel.settings.privacy_panel.privacy.entry.title.disabled"),
                 )),
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
        Padding(padding: EdgeInsets.only(right: 20), child: Text(description!,
          style: isEnabled? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.variant.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.variant.disabled")
        )),
        Semantics( explicitChildNodes: true,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _onTapInfo(additionalInfo),
            child: Container(
                padding: EdgeInsets.only(top: 8, bottom: 6),
                child: Row(
                  children: <Widget>[
                    Expanded(child:
                      Text(Localization().getStringEx("panel.settings.privacy.button.expand_data.title","See Data Usage"),
                        style: isEnabled? Styles().textStyles?.getTextStyle("panel.settings.privacy_panel.privacy.entry.info.enabled") : Styles().textStyles?.getTextStyle("panel.settings.privacy_panel.privacy.entry.info.disabled")
                      )
                    ),
                    Container(width: 9,),
                    Container(padding: EdgeInsets.only(right: 20), child: RotationTransition(
                        turns: _iconTurns,
                        child: Styles().images?.getImage(isEnabled? "chevron-down": "chevron-down-gray", excludeFromSemantics: true))),
                  ],
                )))),
        !infoExpanded? Container():
        Semantics( explicitChildNodes: true,
          child:
            Container(
              padding: EdgeInsets.only(bottom: 8, right: 20),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                    border: Border(left: BorderSide(width: 1, color: Styles().colors!.fillColorSecondary!))
                ),
                child: Text(dataUsageInfo!,
                    style: isEnabled? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.variant.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.variant.disabled")),
              ),
            )
        )
      ],
    );
  }

  void _onTapInfo(bool additionalInfo) {
    setState(() {
      if (additionalInfo)
        _additionalDataUsageExpanded = !_additionalDataUsageExpanded;
      else
        _dataUsageExpanded = !_dataUsageExpanded;
    });
    bool expanded = additionalInfo ? _additionalDataUsageExpanded : _dataUsageExpanded;
    AnimationController? controller = additionalInfo ? _additionalInfoController : _infoController;
    if (expanded) {
      controller!.forward();
    } else {
      controller!.reverse();
    }
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