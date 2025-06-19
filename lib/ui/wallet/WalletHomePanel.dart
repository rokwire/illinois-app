// Copyright 2024 Board of Trustees of the University of Illinois.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/wallet/WalletAddIlliniCashPage.dart';
import 'package:illinois/ui/wallet/WalletICardPage.dart';
import 'package:illinois/ui/wallet/WalletIlliniCashPage.dart';
import 'package:illinois/ui/wallet/WalletLibraryCardPage.dart';
import 'package:illinois/ui/wallet/WalletBusPassPage.dart';
import 'package:illinois/ui/wallet/WalletMealPlanPage.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum WalletContentType { illiniId, busPass, libraryCard, mealPlan, illiniCash, addIlliniCash }

class WalletHomePanel extends StatefulWidget with AnalyticsInfo {

  static const String _stateAccess  = "edu.illinois.rokwire.wallet.state.access";

  static Set<WalletContentType> requireOidcContentTypes = <WalletContentType>{
    WalletContentType.illiniId,
    WalletContentType.busPass,
    WalletContentType.libraryCard,
    WalletContentType.mealPlan,
    WalletContentType.illiniCash,
  };

  static WalletContentType _defaultContentType = WalletContentType.illiniId;

  final WalletContentType? contentType;
  final List<WalletContentType>? contentTypes;

  WalletHomePanel._({this.contentType, this.contentTypes});

  @override
  _WalletHomePanelState createState() => _WalletHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => _state?._selectedContentType?.analyticsFeature ??
    _targetContentType(contentType: contentType, contentTypes: contentTypes)?.analyticsFeature;

  static void present(BuildContext context, { WalletContentType? contentType }) {
    List<WalletContentType> contentTypes = _buildContentTypes();
    if ((contentType != null) && !contentTypes.contains(contentType)) {
      AppAlert.showTextMessage(context, Localization().getStringEx('panel.wallet.not_available.content_type.label', '{{content_type}} is not available.').
        replaceAll('{{content_type}}', contentType.displayTitle));
    }
    else if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.wallet.offline.label', 'The Wallet is not available while offline.'));
    }
    else if (!Auth2().isOidcLoggedIn && requireOidcContentTypes.contains(_targetContentType(contentType: contentType, contentTypes: contentTypes))) {
      AppAlert.showTextMessage(context, Localization().getStringEx('panel.wallet.logged_out.label', 'To access the Wallet, you need to sign in with your NetID and set your privacy level to 4 or 5 under Profile.'));
    }
    else {
      MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
      double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: true,
          useRootNavigator: true,
          routeSettings: RouteSettings(),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Styles().colors.background,
          constraints: BoxConstraints(maxHeight: height, minHeight: height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (context) {
            return WalletHomePanel._(contentType: contentType, contentTypes: contentTypes);
          });
    }
  }

  static List<WalletContentType> _buildContentTypes() {
    List<WalletContentType> contentTypes = <WalletContentType>[];
    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['wallet']);
    if (contentCodes != null) {
      for (String code in contentCodes) {
        WalletContentType? value = WalletContentTypeImpl.fromJsonString(code);
        if (value != null) {
          contentTypes.add(value);
        }
      }
    }
    contentTypes.sortAlphabetical();
    return contentTypes;
  }

  static WalletContentType? _targetContentType({ WalletContentType? contentType, List<WalletContentType>? contentTypes}) {

    WalletContentType? lastContentType;
    if ((contentType != null) && (contentTypes?.contains(contentType) != false)) {
      return contentType;
    }
    else if (((lastContentType = Storage()._waletContentType) != null) && (contentTypes?.contains(lastContentType) != false)) {
      return lastContentType;
    }
    else if ((contentTypes?.contains(_defaultContentType) != false)) {
      return _defaultContentType;
    }
    else if ((contentTypes?.isNotEmpty == true)) {
      return contentTypes?.first;
    }
    else {
      return null;
    }
  }

  static _WalletHomePanelState? get _state {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(_stateAccess);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if ((subscriber is _WalletHomePanelState) && subscriber.mounted) {
          return subscriber;
        }
      }
    }
    return null;
  }
}

class _WalletHomePanelState extends State<WalletHomePanel> with NotificationsListener {
  late List<WalletContentType> _contentTypes;
  WalletContentType? _selectedContentType;
  bool _contentValuesVisible = false;
  Map<WalletContentType, GlobalKey> _pageKeys = <WalletContentType, GlobalKey>{};

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      WalletHomePanel._stateAccess,
      FlexUI.notifyChanged,
      WalletIlliniCashPage.notifyAddIlliniCash,
    ]);

    _contentTypes = widget.contentTypes ?? WalletHomePanel._buildContentTypes();
    _selectedContentType = WalletHomePanel._targetContentType(contentType: widget.contentType, contentTypes: _contentTypes);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == FlexUI.notifyChanged) {
      _updateContentTypes();
    }
    else if (name == WalletIlliniCashPage.notifyAddIlliniCash) {
      if (FlexUI().isAddIlliniCashAvailable) {
        _onTapDropdownItem(WalletContentType.addIlliniCash);
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
    Scaffold(backgroundColor: Styles().colors.white, body:
      Column(children: [
        Row(children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16), child:
              _headerTitle
            )
          ),
          _headerCloseButton,
        ]),
        Container(color: Styles().colors.surfaceAccent, height: 1),
        Expanded(child: _panelContent)
      ]),
    );

  Widget get _headerTitle =>
    Text(Localization().getStringEx('panel.wallet.header.title', 'Wallet'), style: Styles().textStyles.getTextStyle("widget.label.medium.fat"));

  Widget get _headerCloseButton => Semantics(
    label: Localization().getStringEx('dialog.close.title', 'Close'),
    hint: Localization().getStringEx('dialog.close.hint', ''),
    inMutuallyExclusiveGroup: true,
    button: true, child:
      InkWell(onTap: _onTapClose, child:
        Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
          Styles().images.getImage('close-circle', excludeFromSemantics: true)
        )
      )
    );


  Widget get _panelContent {

    Widget? pageWidget = _contentPage;
    Color backColor = (pageWidget is WalletHomePage) ? (pageWidget as WalletHomePage).backgroundColor  : Styles().colors.white;

    return Column(children: <Widget>[
      Expanded(child:
        Container(color: backColor, child:
          SingleChildScrollView(physics: _contentValuesVisible ? NeverScrollableScrollPhysics() : null, child:
            Stack(children: [
              SafeArea(child: pageWidget ?? Container()),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
                  RibbonButton(
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
                    backgroundColor: Styles().colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                    rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
                    label: _selectedContentType?.displayTitle  ?? '',
                    onTap: _onTapContentSwitch
                  )
                ),
                _dropdownContainer,
              ]),
            ]),
          ),
        ),
      )
    ]);
  }

  Widget? get _contentPage {
    switch(_selectedContentType) {
      case WalletContentType.illiniId:      return WalletICardPage(key: _contentPageKey, topOffset: 80,);
      case WalletContentType.busPass:       return WalletBusPassPage(key: _contentPageKey, topOffset: 80);
      case WalletContentType.libraryCard:   return WalletLibraryCardPage(key: _contentPageKey, topOffset: 80,);
      case WalletContentType.mealPlan:      return WalletMealPlanPage(key: _contentPageKey, headerHeight: 82,);
      case WalletContentType.illiniCash:    return WalletIlliniCashPage(key: _contentPageKey, headerHeight: 88);
      case WalletContentType.addIlliniCash: return WalletAddIlliniCashPage(key: _contentPageKey, topOffset: 82, hasCancel: false,);
      default: return null;
    }
  }

  GlobalKey? get _contentPageKey => (_selectedContentType != null) ?
    (_pageKeys[_selectedContentType!] ??= GlobalKey()) : null;

  Widget get _dropdownContainer => Visibility(visible: _contentValuesVisible, child:
    Container(child:
      Stack(children: <Widget>[
        _dropdownDismissLayer,
        _dropdownList,
      ])
    )
  );

  Widget get _dropdownDismissLayer => Container(child:
    BlockSemantics(child:
      GestureDetector(onTap: _onTapDismissLayer, child:
        Container(color: Styles().colors.blackTransparent06, height: MediaQuery.of(context).size.height)
      )
    )
  );

  Widget get _dropdownList {
    List<Widget> contentList = <Widget>[];
    contentList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (WalletContentType contentType in _contentTypes) {
      contentList.add(RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        textStyle: Styles().textStyles.getTextStyle((_selectedContentType == contentType) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
        rightIconKey: (_selectedContentType == contentType) ? 'check-accent' : null,
        label: contentType.displayTitle,
        onTap: () => _onTapDropdownItem(contentType)
      ));
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: contentList)
      )
    );
  }

  void _updateContentTypes() {
    List<WalletContentType> contentTypes = WalletHomePanel._buildContentTypes();
    if (!DeepCollectionEquality().equals(_contentTypes, contentTypes) && mounted) {
      setState(() {
        _contentTypes = contentTypes;
        _contentValuesVisible = false;
        if (!_contentTypes.contains(_selectedContentType)) {
          _selectedContentType = _contentTypes.isNotEmpty ? _contentTypes.first : null;
        }
      });
    }
  }

  void _onTapDropdownItem(WalletContentType contentType) {
    Analytics().logSelect(target: contentType.displayTitleEn, source: widget.runtimeType.toString());

    if (contentType != _selectedContentType) {
      if (!Auth2().isOidcLoggedIn && WalletHomePanel.requireOidcContentTypes.contains(contentType)) {
        AppAlert.showTextMessage(context, Localization().getStringEx('panel.wallet.logged_out.content_type.label', 'To access {{content_type}}, you need to sign in with your NetID and set your privacy level to 4 or 5 under Profile.').
          replaceAll('{{content_type}}', contentType.displayTitle));
      }
      else if (_contentTypes.contains(contentType)) {
        setState(() {
          Storage()._waletContentType = _selectedContentType = contentType;
          _contentValuesVisible = false;
        });
        Analytics().logPageWidget(_contentPage);
      }
    }
    else {
      setState(() {
        _contentValuesVisible = false;
      });
    }
  }

  void _onTapContentSwitch() {
    setState(() {
      _contentValuesVisible = !_contentValuesVisible;
    });
  }

  void _onTapDismissLayer() {
    setState(() {
      _contentValuesVisible = false;
    });
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }
}

////////////////////
// WalletContentType

extension WalletContentTypeImpl on WalletContentType {

  String get displayTitle => displayTitleLng();
  String get displayTitleEn => displayTitleLng('en');

  String displayTitleLng([String? language]) {
    switch (this) {
      case WalletContentType.illiniId: return Localization().getStringEx('panel.wallet.content_type.illini_id.label', 'Illini ID', language: language);
      case WalletContentType.busPass: return Localization().getStringEx('panel.wallet.content_type.bus_pass.label', 'Bus Pass', language: language);
      case WalletContentType.libraryCard: return Localization().getStringEx('panel.wallet.content_type.library_card.label', 'University Library Card', language: language);
      case WalletContentType.mealPlan: return Localization().getStringEx('panel.wallet.content_type.meal_plan.label', 'Meal Plan', language: language);
      case WalletContentType.illiniCash: return Localization().getStringEx('panel.wallet.content_type.illini_cash.label', 'Illini Cash', language: language);
      case WalletContentType.addIlliniCash: return Localization().getStringEx('panel.wallet.content_type.add_illini_cash.label', 'Add Illini Cash', language: language);
    }
  }

  String get jsonString {
    switch(this) {
      case WalletContentType.illiniId: return 'illini_id';
      case WalletContentType.busPass: return 'bus_pass';
      case WalletContentType.libraryCard: return 'library_card';
      case WalletContentType.mealPlan: return 'meal_plan';
      case WalletContentType.illiniCash: return 'illini_cash';
      case WalletContentType.addIlliniCash: return 'add_illini_cash';
    }
  }

  static WalletContentType? fromJsonString(String? value) {
    switch(value) {
      case 'illini_id': return WalletContentType.illiniId;
      case 'bus_pass': return WalletContentType.busPass;
      case 'library_card': return WalletContentType.libraryCard;
      case 'meal_plan': return WalletContentType.mealPlan;
      case 'illini_cash': return WalletContentType.illiniCash;
      case 'add_illini_cash': return WalletContentType.addIlliniCash;
      default: return null;
    }
  }

  AnalyticsFeature? get analyticsFeature {
    switch(this) {
      case WalletContentType.illiniId: return AnalyticsFeature.WalletIlliniID;
      case WalletContentType.busPass:     return AnalyticsFeature.WalletBusPass;
      case WalletContentType.libraryCard: return AnalyticsFeature.WalletLibraryCard;
      case WalletContentType.mealPlan:    return AnalyticsFeature.WalletMealPlan;
      case WalletContentType.illiniCash:  return AnalyticsFeature.WalletIlliniCash;
      default: return null;
    }
  }
}

extension _WalletContentTypeList on List<WalletContentType> {
  void sortAlphabetical() => sort((WalletContentType t1, WalletContentType t2) => t1.displayTitle.compareTo(t2.displayTitle));
}

extension _StorageWalletExt on Storage {
  WalletContentType? get _waletContentType => WalletContentTypeImpl.fromJsonString(walletContentType);
  set _waletContentType(WalletContentType? value) => walletContentType = value?.jsonString;
}

class WalletHomePage {
  Color get backgroundColor => Styles().colors.white;
}
