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
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:neom/service/Storage.dart';
import 'package:neom/ui/wallet/WalletAddIlliniCashPanel.dart';
import 'package:neom/ui/wallet/WalletICardContentWidget.dart';
import 'package:neom/ui/wallet/WalletICardFaqsContentWidget.dart';
import 'package:neom/ui/wallet/WalletIlliniCashPanel.dart';
import 'package:neom/ui/wallet/WalletMTDBusPassPanel.dart';
import 'package:neom/ui/wallet/WalletMealPlanPanel.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum WalletContentType { illiniId, illiniIdFaqs, busPass, mealPlan, illiniCash, addIlliniCash }

class WalletHomePanel extends StatefulWidget {
  final WalletContentType? contentType;

  WalletHomePanel._({this.contentType});

  @override
  _WalletHomePanelState createState() => _WalletHomePanelState();

  static void present(BuildContext context, { WalletContentType? contentType }) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.wallet.offline.label', 'The Wallet is not available while offline.'));
    }
    else if (!Auth2().isOidcLoggedIn) {
      AppAlert.showMessage(context, Localization().getStringEx('panel.wallet.logged_out.label', 'To access the Wallet, you need to sign in with your NetID and set your privacy level to 4 or 5 under Profile.'));
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
            return WalletHomePanel._(contentType: contentType,);
          });
    }
  }
}

class _WalletHomePanelState extends State<WalletHomePanel> implements NotificationsListener {
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

    _contentTypes = _buildContentTypes();

    WalletContentType? selectedContentType = widget.contentType;
    if ((selectedContentType != null) && _contentTypes.contains(selectedContentType)) {
      Storage()._contentType = _selectedContentType = selectedContentType;
    }
    else {
      selectedContentType = Storage()._contentType;
      if ((selectedContentType == null) || !_contentTypes.contains(selectedContentType)) {
        selectedContentType = _contentTypes.isNotEmpty ? _contentTypes.first : null;
      }
      if (selectedContentType != null) {
        _selectedContentType = selectedContentType;
      }
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
    switch(_selectedContentType!) {
      case WalletContentType.illiniId:      return WalletICardContentWidget(key: _contentPageKey);
      case WalletContentType.illiniIdFaqs:  return WalletICardFaqsContentWidget(key: _contentPageKey);
      case WalletContentType.busPass:       return WalletMTDBusPassContentWidget(key: _contentPageKey, expandHeight: false, canClose: false,);
      case WalletContentType.mealPlan:      return WalletMealPlanContentWidget(key: _contentPageKey, headerHeight: 82,);
      case WalletContentType.illiniCash:    return WalletIlliniCashContentWidget(key: _contentPageKey, headerHeight: 88);
      case WalletContentType.addIlliniCash: return WalletAddIlliniCashContentWidget(key: _contentPageKey, topOffset: 82, hasCancel: false,);
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

  List<WalletContentType> _buildContentTypes() {
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

  void _updateContentTypes() {
    List<WalletContentType> contentTypes = _buildContentTypes();
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
    setState(() {
      Storage()._contentType = _selectedContentType = contentType;
      _contentValuesVisible = !_contentValuesVisible;
    });
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
    case 'illini_id_faq': return WalletContentType.illiniIdFaqs;
    case 'bus_pass': return WalletContentType.busPass;
    case 'meal_plan': return WalletContentType.mealPlan;
    case 'illini_cash': return WalletContentType.illiniCash;
    case 'add_illini_cash': return WalletContentType.addIlliniCash;
    default: return null;
  }
}

String? _walletContentTypeToString(WalletContentType? value) {
  switch(value) {
    case WalletContentType.illiniId: return 'illini_id';
    case WalletContentType.illiniIdFaqs: return 'illini_id_faq';
    case WalletContentType.busPass: return 'bus_pass';
    case WalletContentType.mealPlan: return 'meal_plan';
    case WalletContentType.illiniCash: return 'illini_cash';
    case WalletContentType.addIlliniCash: return 'add_illini_cash';
    default: return null;
  }
}

String? _walletContentTypeToDisplayString(WalletContentType? contentType) {
  switch (contentType) {
    case WalletContentType.illiniId: return Localization().getStringEx('panel.wallet.content_type.illini_id.label', 'Illini ID');
    case WalletContentType.illiniIdFaqs: return Localization().getStringEx('panel.wallet.content_type.illini_id_faqs.label', 'Illini ID FAQs');
    case WalletContentType.busPass: return Localization().getStringEx('panel.wallet.content_type.bus_pass.label', 'Bus Pass');
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