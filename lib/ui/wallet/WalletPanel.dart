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

import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/settings/SettingsLoginPhoneOrEmailPanel.dart';
import 'package:rokwire_plugin/service/app_navigation.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:rokwire_plugin/service/auth2.dart' as plugin_auth;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/wallet/IDCardPanel.dart';
import 'package:illinois/ui/wallet/MTDBusPassPanel.dart';
import 'package:illinois/ui/settings/SettingsAddIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsMealPlanPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/section.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WalletPanel extends StatefulWidget{

  final ScrollController? scrollController;
  final String? ensureVisibleCard;

  WalletPanel({this.scrollController, this.ensureVisibleCard});

  _WalletPanelState createState() => _WalletPanelState();
}

class _WalletPanelState extends State<WalletPanel> implements NotificationsListener{

  bool _authLoading = false;
  String?        _libraryCode;
  MemoryImage?   _libraryBarcode;
  GlobalKey     _mtdCardKey = GlobalKey();
  GlobalKey     _illiniIdCardKey = GlobalKey();
  GlobalKey     _libraryCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Auth2.notifyCardChanged,
      FlexUI.notifyChanged,
      IlliniCash.notifyBallanceUpdated,
    ]);
    _loadLibraryBarcode();

    if (widget.ensureVisibleCard != null) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        _ensureVisibleCard(widget.ensureVisibleCard);
      });
    }

  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Styles().colors!.background,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverHeaderBar(
            leadingAsset: null,
            backgroundColor: Styles().colors?.surface,
            title: Localization().getStringEx( "panel.wallet.label.title", "Wallet"),
            textColor: Styles().colors!.fillColorPrimary,
            fontSize: 20,
            actions: <Widget>[
              Visibility(
                visible: widget.scrollController != null,
                child: Semantics(button: true,excludeSemantics: true,label: Localization().getStringEx("panel.wallet.button.close.title", "close"), child:
                  IconButton(
                    icon: Image.asset('images/close-orange.png',excludeFromSemantics: true,),
                    onPressed: () {
                      Analytics().logSelect(target: 'Close');
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                )
              )
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _authLoading
                  ? Padding(
                    padding: EdgeInsets.only(left: 32, right: 32, top: MediaQuery.of(context).size.height / 3),
                    child: Center(
                      child: CircularProgressIndicator(),
                    )
                  )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16,),
                      child: Column(
                        children: _buildContentList(),
                    ),
                  )
            ]),
          )
        ],
      ),
    );
  }

  List<Widget> _buildContentList() {
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['wallet'] ?? [];
    for (String code in codes) {
      dynamic widget;
      if (code == 'connect') {
        widget = _buildConnect();
      }
      else if (code == 'vcards') {
        widget = _buildVerticalCardsList();
      }
      else if (code == 'hcards') {
        widget = _buildHorizontalCardsList();
      }

      if (widget != null) {
        if (0 < contentList.length) {
          contentList.add(Container(height: 20,));
        }
        if (widget is Widget) {
          contentList.add(widget);
        }
        else if (widget is List) {
          contentList.addAll(widget.cast<Widget>());
        }
      }
    }
    return contentList;
  }

  Widget _buildConnect() {
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['wallet.connect'] ?? [];
    for (String code in codes) {
      Widget? widget;
      if (code == 'netid') {
        widget = _buildLoginNetIdButton();
      }
      else if (code == 'phone_or_email') {
        widget = _buildLoginPhoneOrEmailButton();
      }
      if (widget != null) {
        if (0 < contentList.length) {
          contentList.add(Container(height: 20,));
        }
        contentList.add(widget);
      }
    }
    return Padding(padding: EdgeInsets.only(left: 32, right: 32, top: MediaQuery.of(context).size.height / 3),
      child: Column(children: contentList,),
    );
  }

  Widget _buildLoginNetIdButton() {
    return RoundedButton(
      label: Localization().getStringEx('panel.wallet.button.connect.netid.title', 'Connect NetID'),
      hint: Localization().getStringEx('panel.wallet.button.connect.netid.hint', ''),
      backgroundColor: Styles().colors!.surface,
      fontSize: 16.0,
      textColor: Styles().colors!.fillColorPrimary,
      textAlign: TextAlign.center,
      borderColor: Styles().colors!.fillColorSecondary,
      onTap: () {
        Analytics().logSelect(target: "Log in");
        if (_authLoading != true) {
          setState(() { _authLoading = true; });
          Auth2().authenticateWithOidc().then((plugin_auth.Auth2OidcAuthenticateResult? result) {
            if (mounted) {
              setState(() { _authLoading = false; });
              if (result != plugin_auth.Auth2OidcAuthenticateResult.succeeded) {
                AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
              }
            }
          });
        }
      },
    );
  }

  Widget _buildLoginPhoneOrEmailButton() {
    return RoundedButton(
        label: Localization().getStringEx('panel.wallet.button.connect.phone_or_email.title', 'Sign In by Email or Phone'),
        hint: Localization().getStringEx('panel.wallet.button.connect.phone_or_email.hint', ''),
        backgroundColor: Styles().colors!.surface,
        fontSize: 16.0,
        textColor: Styles().colors!.fillColorPrimary,
        textAlign: TextAlign.center,
        borderColor: Styles().colors!.fillColorSecondary,
        onTap: () {
          Analytics().logSelect(target: "Log in");
          Navigator.push(context, CupertinoPageRoute(
            settings: RouteSettings(),
            builder: (context) => SettingsLoginPhoneOrEmailPanel(
              onFinish: () {
                _didLogin(context);
              }
            ),
          ),);
        },
      );
  }

  void _didLogin(_) {
    Navigator.of(context).popUntil((Route route){
      Widget? _widget = AppNavigation.routeRootWidget(route, context: context);
      return _widget == null || _widget.runtimeType == widget.runtimeType;
    });
  }

  List<Widget> _buildVerticalCardsList() {

    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['wallet.vcards'] ?? [];
    for (String code in codes) {
      Widget? widget;
      if (code == 'illini_cash_card') {
        widget = _buildIlliniCashCard();
      }
      else if (code == 'meal_plan_card') {
        widget = _buildMealPlanCard();
      }
      if (widget != null) {
        if (0 < contentList.length) {
          contentList.add(Container(height: 20,));
        }
        contentList.add(widget);
      }
    }
    return contentList;
  }

  Widget _buildIlliniCashCard() {
    return _RoundedWidget(
      onView: (){
        Analytics().logSelect(target: "Illini Cash");
        Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
            settings: RouteSettings(name: SettingsIlliniCashPanel.routeName),
            builder: (context){
              return SettingsIlliniCashPanel();
            }
        ));
      },
      title: Localization().getStringEx( "panel.wallet.label.illini_cash.title","ILLINI CASH"),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: VerticalTitleValueSection(
                title: Localization().getStringEx('panel.settings.illini_cash.label.current_balance','Current Illini Cash Balance'),
                value: IlliniCash().ballance?.balanceDisplayText ?? "\$0.00",
              ),
            ),
            Semantics(button: true, excludeSemantics: true,
              label: Localization().getStringEx("panel.wallet.button.add_illini_cash.title","Add Illini Cash"),
              hint: Localization().getStringEx("panel.wallet.button.add_illini_cash.hint",""),
              child: IconButton(
              color: Styles().colors!.fillColorPrimary,
              icon: Image.asset('images/button-plus-orange.png', excludeFromSemantics: true,),
                onPressed: (){
                  Analytics().logSelect(target: "Add Illini Cash");
                  Navigator.push(context, CupertinoPageRoute(
                    builder: (context) => SettingsAddIlliniCashPanel()
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealPlanCard() {
    return _RoundedWidget(
      onView: (){
        Analytics().logSelect(target: "Meal plan");
        Navigator.of(context, rootNavigator: false).push(CupertinoPageRoute(
            builder: (context){
              return SettingsMealPlanPanel();
            }
        ));
      },
      title: Localization().getStringEx( "panel.wallet.label.meal_plan.title", "MEAL PLAN"),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: VerticalTitleValueSection(
                title: Localization().getStringEx(
                    "panel.settings.meal_plan.label.meals_remaining.text", "Meals Remaining"),
                value: IlliniCash().ballance?.mealBalanceDisplayText ?? "0",
              ),
            ),
            Expanded(
              child: VerticalTitleValueSection(
                title: Localization().getStringEx(
                    "panel.settings.meal_plan.label.dining_dollars.text", "Dining Dollars"),
                value: IlliniCash().ballance?.cafeCreditBalanceDisplayText ?? "0",
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCardsList() {
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['wallet.hcards'] ?? [];
    contentList.add(Container(width: 8,));
    for (String code in codes) {
      Widget? widget;
      if (code == 'bus_pass_card') {
        widget = _buildMTDBusCard();
      }
      else if (code == 'illini_id_card') {
        widget = _buildIlliniIdCard();
      }
      else if (code == 'library_card') {
        widget = _buildLibraryCard();
      }

      if (widget != null) {
        contentList.add(widget);
      }
    }

    contentList.add(Container(width: 8,));

    return Container(
//      height: 180,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: contentList,),
      ),
    );
  }

  void _ensureVisibleCard(String? code) {
    GlobalKey? cardKey;
    if (code == 'mtd') {
      cardKey = _mtdCardKey;
    }
    else if (code == 'id') {
      cardKey = _illiniIdCardKey;
    }
    else if (code == 'library') {
      cardKey = _libraryCardKey;
    }

    BuildContext? buildContext = cardKey?.currentContext;
    if (buildContext != null) {
      Scrollable.ensureVisible(buildContext, duration: Duration(milliseconds: 10));
    }
  }

  Widget _buildMTDBusCard(){
    String expires = Auth2().authCard?.expirationDate ?? "";
    return _Card(
      key: _mtdCardKey,
      title: Localization().getStringEx("panel.wallet.label.mtd.title", "MTD",),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              Auth2().authCard?.role ?? "",
              style: TextStyle(
                color: Styles().colors!.fillColorPrimary,
                fontFamily: Styles().fontFamilies!.extraBold,
                fontSize: 24,
              ),
            ),
            Text(
              Localization().getStringEx("panel.wallet.label.expires.title", "Card expires") + " $expires",
              style: TextStyle(
                color: Styles().colors!.fillColorPrimary,
                fontFamily: Styles().fontFamilies!.medium,
                fontSize: 12,
              ),
            ),
            Container(height: 5,),
            Semantics(explicitChildNodes: true,child:
              RoundedButton(
                label: Localization().getStringEx("panel.wallet.button.use_bus_pass.title", "Use Bus Pass"),
                hint: Localization().getStringEx("panel.wallet.button.use_bus_pass.hint", ""),
                textColor: Styles().colors!.fillColorPrimary,
                backgroundColor: Styles().colors!.white,
                borderColor: Styles().colors!.fillColorSecondary,
                onTap: (){
                  Analytics().logSelect(target: "MTD Bus Pass");
                  Navigator.push(context, CupertinoPageRoute(
                      builder: (context) => MTDBusPassPanel()
                  ));
                },
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIlliniIdCard(){
    return _Card(
      key: _illiniIdCardKey,
      title: Localization().getStringEx("panel.wallet.label.illini_id.title", "Illini ID",),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              Localization().getStringEx("panel.wallet.label.uin.title", "UIN",),
              style: TextStyle(
                color: Styles().colors!.fillColorPrimary,
                fontFamily: Styles().fontFamilies!.medium,
                fontSize: 14,
              ),
            ),
            Text(
              Auth2().authCard?.uin ?? "",
              style: TextStyle(
                color: Styles().colors!.fillColorPrimary,
                fontFamily: Styles().fontFamilies!.extraBold,
                fontSize: 24,
              ),
            ),
            Container(height: 5,),
            Semantics(explicitChildNodes: true,child:
              RoundedButton(
                label: Localization().getStringEx("panel.wallet.button.use_id.title", "Use ID"),
                hint: Localization().getStringEx("panel.wallet.button.use_id.hint", ""),
                textColor: Styles().colors!.fillColorPrimary,
                backgroundColor: Styles().colors!.white,
                borderColor: Styles().colors!.fillColorSecondary,
                onTap: (){
                  Analytics().logSelect(target: "Use ID");
                  Navigator.push(context, CupertinoPageRoute(
                      builder: (context) => IDCardPanel()
                  ));
                },
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryCard(){
    return _Card(
      key: _libraryCardKey,
      title: Localization().getStringEx("panel.wallet.label.library.title", "Library Card",),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(height: 10,),
            Container(
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                image: (_libraryBarcode != null) ? DecorationImage(fit: BoxFit.fill, image:_libraryBarcode! ,) : null,    
              )),
            
            Container(height: 5,),
            Text(
              Auth2().authCard?.libraryNumber ?? "",
              style: TextStyle(
                  fontFamily: Styles().fontFamilies!.light,
                  fontSize: 12,
                  color: Styles().colors!.fillColorPrimaryVariant,
                  letterSpacing: 1
              ),
            ),
            Container(height: 18,),
          ],
        ),
      ),
    );
  }

  void _loadLibraryBarcode() {
    String? libraryCode = Auth2().authCard?.libraryNumber;
    if (0 < (libraryCode?.length ?? 0)) {
      NativeCommunicator().getBarcodeImageData({
        'content': Auth2().authCard?.libraryNumber,
        'format': 'codabar',
        'width': 161 * 3,
        'height': 50
      }).then((Uint8List? imageData) {
        setState(() {
          _libraryCode = libraryCode;
          _libraryBarcode = (imageData != null) ? MemoryImage(imageData) : null;
        });
      });
    }
    else {
      _libraryCode = null;
      _libraryBarcode = null;
    }
  }

  void _updateLibraryBarcode() {
    String? libraryCode = Auth2().authCard?.libraryNumber;
    if (((_libraryCode == null) && (libraryCode != null)) ||
        ((_libraryCode != null) && (_libraryCode != libraryCode)))
    {
      _loadLibraryBarcode();
    }
  }

  // NotificationsListener

  void onNotification(String name, dynamic param){
    if (name == Auth2.notifyCardChanged) {
      _updateLibraryBarcode();
    }
    else if(name == FlexUI.notifyChanged){
      setState(() {});
    }
    else if(name == IlliniCash.notifyBallanceUpdated){
      setState(() {});
    }
  }
}

class _RoundedWidget extends StatelessWidget{

  final String? title;
  final Widget child;
  final void Function() onView;

  _RoundedWidget({Key? key, this.title, required this.onView, required this.child}):super(key:key);

  @override
  Widget build(BuildContext context) {
    return Semantics(container: true,child:Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 1.0, color: Styles().colors!.surfaceAccent!),
          borderRadius: BorderRadius.all(Radius.circular(8))
        ),
        child: Column(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                  color: Styles().colors!.lightGray,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyle(
                          color: Styles().colors!.fillColorPrimary,
                          fontFamily: Styles().fontFamilies!.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Semantics(explicitChildNodes: true, child:
                      _ViewButton(
                        label: Localization().getStringEx( "panel.wallet.button.view.title", "View"),
                        hint: title,
                        onTap: onView,
                      )
                    ),
                    Container(height: 1, color: Styles().colors!.surfaceAccent,)
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Styles().colors!.white,
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
              ),
              child: child
            ),
          ],
        ),
      ),
    ));
  }
}

class _ViewButton extends StatelessWidget{

  final String? label;
  final String? hint;
  final void Function() onTap;

  _ViewButton({required this.label, required this.onTap, this.hint});

  @override
  Widget build(BuildContext context) {
    return
      Semantics(
        label: label,
        hint: hint ?? "",
        child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
              Text(label!,
                semanticsLabel: "",
                style: TextStyle(
                  color: Styles().colors!.fillColorPrimary,
                  fontFamily: Styles().fontFamilies!.bold,
                  fontSize: 16,
                ),
              ),
              Container(width: 10,),
              Image.asset('images/chevron-right.png', excludeFromSemantics: true),
            ],
          ),
        ),
      )
    );
  }
}

class _Card extends StatelessWidget{

  static double width = 240;
  final String? title;
  final Color? titleTextColor;
  final Color? titleBackColor;
  final Color? titleIconColor;
  final Widget child;

  final Color? _defaultTitleTextColor = Styles().colors!.white;
  final Color? _defaultTitleBackColor = Styles().colors!.fillColorPrimary;

  _Card({Key? key, required this.title, this.titleBackColor, this.titleTextColor, this.titleIconColor,  required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(container: true,child:Container(
      width: width,
      margin: new EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Styles().colors!.lightGray!,
            blurRadius: 2.0,
            spreadRadius: 2.0,
            offset: Offset(0.0, 0.0,),
          )
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: titleBackColor ?? _defaultTitleBackColor,
                      //borderRadius: BorderRadius.all(Radius.circular(8),),
                    ),
                    width: width,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                      child: Text(
                        title!,
                        style: TextStyle(
                          color: titleTextColor ?? _defaultTitleTextColor,
                          fontFamily: Styles().fontFamilies!.extraBold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    color: Styles().colors!.white,
                    child: child,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}