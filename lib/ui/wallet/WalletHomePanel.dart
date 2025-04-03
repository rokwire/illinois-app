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
import 'package:illinois/ui/wallet/WalletAddIlliniCashPanel.dart';
import 'package:illinois/ui/wallet/WalletICardContentWidget.dart';
import 'package:illinois/ui/wallet/WalletIlliniCashPanel.dart';
import 'package:illinois/ui/wallet/WalletLibraryCardWidget.dart';
import 'package:illinois/ui/wallet/WalletMTDBusPassPanel.dart';
import 'package:illinois/ui/wallet/WalletMealPlanPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum WalletContentType { illiniId, busPass, libraryCard, mealPlan, illiniCash, addIlliniCash }

class WalletHomePanel extends StatefulWidget with AnalyticsInfo {
  final WalletContentType? contentType;
  final List<WalletContentType>? contentTypes;

  static Set<WalletContentType> requireOidcContentTypes = {
    WalletContentType.illiniId,
    WalletContentType.busPass,
    WalletContentType.libraryCard,
    WalletContentType.mealPlan,
    WalletContentType.illiniCash,
  };

  static Map<WalletContentType, AnalyticsFeature> contentAnalyticsFeatures = {
    WalletContentType.illiniId:    AnalyticsFeature.WalletIlliniID,
    WalletContentType.busPass:     AnalyticsFeature.WalletBusPass,
    WalletContentType.libraryCard: AnalyticsFeature.WalletLibraryCard,
    WalletContentType.mealPlan:    AnalyticsFeature.WalletMealPlan,
    WalletContentType.illiniCash:  AnalyticsFeature.WalletIlliniCash,
    // Everything not mentioned here would go as AnalyticsFeature.Wallet
  };

  WalletHomePanel._({this.contentType, this.contentTypes});

  @override
  _WalletHomePanelState createState() => _WalletHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => contentAnalyticsFeatures[getTargetContentType(contentType: contentType, contentTypes: contentTypes)];

  static void present(BuildContext context, { WalletContentType? contentType }) {
    List<WalletContentType> contentTypes = buildContentTypes();
    if ((contentType != null) && !contentTypes.contains(contentType)) {
      AppAlert.showTextMessage(context, Localization().getStringEx('panel.wallet.not_available.content_type.label', '{{content_type}} is not available.').
        replaceAll('{{content_type}}', _walletContentTypeToDisplayString(contentType) ?? Localization().getStringEx('panel.wallet.header.title', 'Wallet')));
    }
    else if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.wallet.offline.label', 'The Wallet is not available while offline.'));
    }
    else if (!Auth2().isOidcLoggedIn && requireOidcContentTypes.contains(getTargetContentType(contentType: contentType, contentTypes: contentTypes))) {
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

  static List<WalletContentType> buildContentTypes() {
    List<WalletContentType> contentTypes = <WalletContentType>[];
    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['wallet']);
    if (contentCodes != null) {
      for (String code in contentCodes) {
        WalletContentType? value = _walletContentTypeFromString(code);
        if (value != null) {
          contentTypes.add(value);
        }
      }
    }
    return contentTypes;
  }

  static WalletContentType? getTargetContentType({ WalletContentType? contentType, List<WalletContentType>? contentTypes}) {
    WalletContentType? resultContentType = null;

    if ((contentType != null) && ((contentTypes == null) || contentTypes.contains(contentType))) {
      resultContentType = contentType;
    }

    if (resultContentType == null) {
      WalletContentType? lastContentType = Storage()._contentType;
      if ((lastContentType != null) && ((contentTypes == null) || contentTypes.contains(lastContentType))) {
        resultContentType = lastContentType;
      }
    }

    if ((resultContentType == null) && (contentTypes != null) && contentTypes.isNotEmpty) {
      resultContentType = contentTypes.first;
    }

    return resultContentType;
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
      FlexUI.notifyChanged
    ]);

    _contentTypes = widget.contentTypes ?? WalletHomePanel.buildContentTypes();
    _selectedContentType = WalletHomePanel.getTargetContentType(contentType: widget.contentType, contentTypes: _contentTypes);
    if ((widget.contentType != null) && (widget.contentType == _selectedContentType)) {
      Storage()._contentType = _selectedContentType;
    }
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
    Color backColor = (pageWidget is WalletHomeContentWidget) ? (pageWidget as WalletHomeContentWidget).backgroundColor  : Styles().colors.white;

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
                    label: _walletContentTypeToDisplayString(_selectedContentType) ?? '',
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
      case WalletContentType.illiniId:      return WalletICardContentWidget(key: _contentPageKey);
      case WalletContentType.busPass:       return WalletMTDBusPassContentWidget(key: _contentPageKey, expandHeight: false, canClose: false,);
      case WalletContentType.libraryCard:   return WalletLibraryCardWidget(key: _contentPageKey, topOffset: 80,);
      case WalletContentType.mealPlan:      return WalletMealPlanContentWidget(key: _contentPageKey, headerHeight: 82,);
      case WalletContentType.illiniCash:    return WalletIlliniCashContentWidget(key: _contentPageKey, headerHeight: 88);
      case WalletContentType.addIlliniCash: return WalletAddIlliniCashContentWidget(key: _contentPageKey, topOffset: 82, hasCancel: false,);
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
      if (_selectedContentType != contentType) {
        contentList.add(RibbonButton(
          backgroundColor: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          rightIconKey: null,
          label: _walletContentTypeToDisplayString(contentType),
          onTap: () => _onTapDropdownItem(contentType)
        ));
      }
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: contentList)
      )
    );
  }

  void _updateContentTypes() {
    List<WalletContentType> contentTypes = WalletHomePanel.buildContentTypes();
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
    Analytics().logSelect(target: _walletContentTypeToDisplayString(contentType), source: widget.runtimeType.toString());

    if (!Auth2().isOidcLoggedIn && WalletHomePanel.requireOidcContentTypes.contains(contentType)) {
      AppAlert.showTextMessage(context, Localization().getStringEx('panel.wallet.logged_out.content_type.label', 'To access {{content_type}}, you need to sign in with your NetID and set your privacy level to 4 or 5 under Profile.').
        replaceAll('{{content_type}}', _walletContentTypeToDisplayString(contentType) ?? Localization().getStringEx('panel.wallet.header.title', 'Wallet')));
    }
    else {
      setState(() {
        Storage()._contentType = _selectedContentType = contentType;
        _contentValuesVisible = false;
      });
      Analytics().logPageWidget(_contentPage);
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

WalletContentType? _walletContentTypeFromString(String? value) {
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

String? _walletContentTypeToString(WalletContentType? value) {
  switch(value) {
    case WalletContentType.illiniId: return 'illini_id';
    case WalletContentType.busPass: return 'bus_pass';
    case WalletContentType.libraryCard: return 'library_card';
    case WalletContentType.mealPlan: return 'meal_plan';
    case WalletContentType.illiniCash: return 'illini_cash';
    case WalletContentType.addIlliniCash: return 'add_illini_cash';
    default: return null;
  }
}

String? _walletContentTypeToDisplayString(WalletContentType? contentType) {
  switch (contentType) {
    case WalletContentType.illiniId: return Localization().getStringEx('panel.wallet.content_type.illini_id.label', 'Illini ID');
    case WalletContentType.busPass: return Localization().getStringEx('panel.wallet.content_type.bus_pass.label', 'Bus Pass');
    case WalletContentType.libraryCard: return Localization().getStringEx('panel.wallet.content_type.library_card.label', 'Univerity Library Card');
    case WalletContentType.mealPlan: return Localization().getStringEx('panel.wallet.content_type.meal_plan.label', 'Meal Plan');
    case WalletContentType.illiniCash: return Localization().getStringEx('panel.wallet.content_type.illini_cash.label', 'Illini Cash');
    case WalletContentType.addIlliniCash: return Localization().getStringEx('panel.wallet.content_type.add_illini_cash.label', 'Add Illini Cash');
    default: return null;
  }
}

extension _StorageWalletExt on Storage {
  WalletContentType? get _contentType => _walletContentTypeFromString(walletContentType);
  set _contentType(WalletContentType? value) => walletContentType = _walletContentTypeToString(value);
}

class WalletHomeContentWidget {
  Color get backgroundColor => Styles().colors.white;
}