import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsAddIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsMealPlanPanel.dart';
import 'package:illinois/ui/wallet/IDCardPanel.dart';
import 'package:illinois/ui/wallet/MTDBusPassPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section.dart';
import 'package:sprintf/sprintf.dart';

class HomeWalletWidget extends StatefulWidget {
  
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeWalletWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: Localization().getStringEx('widget.home.wallet.label.title', 'Wallet'),
    );

  @override
  State<HomeWalletWidget> createState() => _HomeWalletWidgetState();
}

class _HomeWalletWidgetState extends State<HomeWalletWidget> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
    ]);

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: Localization().getStringEx('widget.home.wallet.label.title', 'Wallet'),
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      child: Column(children: _buildCommandsList(),
    ),
    );
  }

  List<Widget> _buildCommandsList() {
    List<Widget> contentList = <Widget>[];
    List<dynamic>? contentListCodes = FlexUI()['home.wallet'];
    if (contentListCodes != null) {
      for (dynamic contentListCode in contentListCodes) {
        Widget? contentEntry;
        if (contentListCode == 'illini_cash_card') {
          contentEntry = HomeIlliniCashWalletWidget(updateController: widget.updateController,);
        }
        else if (contentListCode == 'meal_plan_card') {
          contentEntry = HomeMealPlanWalletWidget(updateController: widget.updateController,);
        }
        else if (contentListCode == 'bus_pass_card') {
          contentEntry = HomeBusPassWalletWidget(updateController: widget.updateController,);
        }
        else if (contentListCode == 'illini_id_card') {
          contentEntry = HomeIlliniIdWalletWidget(updateController: widget.updateController,);
        }
        else if (contentListCode == 'library_card') {
          contentEntry = HomeLibraryCardWalletWidget(updateController: widget.updateController,);
        }

        if (contentEntry != null) {
          if (contentList.isNotEmpty) {
            contentList.add(Container(height: 8,));
          }
          contentList.add(contentEntry);
        }
      }

    }
   return contentList;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
  }

}

// HomeIlliniCashWalletWidget

class HomeIlliniCashWalletWidget extends StatefulWidget {
  final StreamController<String>? updateController;

  HomeIlliniCashWalletWidget({Key? key, this.updateController}) : super(key: key);

  @override
  State<HomeIlliniCashWalletWidget> createState() => _HomeIlliniCashWalletWidgetState();
}

class _HomeIlliniCashWalletWidgetState extends State<HomeIlliniCashWalletWidget> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
      IlliniCash.notifyBallanceUpdated
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _onTap, child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(Localization().getStringEx('widget.home.wallet.illini_cash.title', 'Illini Cash'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))),
                      Row(children: <Widget>[
                      ])
                    ])
                  ),
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        VerticalTitleValueSection(
                          title: Localization().getStringEx('widget.home.wallet.illini_cash.label.current_balance', 'Current Illini Cash Balance'),
                          value: IlliniCash().ballance?.balanceDisplayText ?? '\$0.00',
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        )
                      ),
                      Semantics(button: true, excludeSemantics: true, label: Localization().getStringEx('widget.home.wallet.illini_cash.button.add_illini_cash.title', 'Add Illini Cash'), hint: Localization().getStringEx('widget.home.wallet.illini_cash.button.add_illini_cash.hint', ''), child:
                        IconButton(color: Styles().colors!.fillColorPrimary, icon: Image.asset('images/button-plus-orange.png', excludeFromSemantics: true), onPressed: _onTapPlus)
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _onTap() {
    Analytics().logSelect(target: 'Illini Cash');
    Navigator.push(context, CupertinoPageRoute( settings: RouteSettings(name: SettingsIlliniCashPanel.routeName), builder: (context) => SettingsIlliniCashPanel()));
  }

  void _onTapPlus() {
    Analytics().logSelect(target: "Add Illini Cash");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsAddIlliniCashPanel()));
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if (name == IlliniCash.notifyBallanceUpdated) {
      if (mounted) {
        setState(() {});
      }
    }
  }
}

// HomeMealPlanWalletWidget

class HomeMealPlanWalletWidget extends StatefulWidget {
  final StreamController<String>? updateController;

  HomeMealPlanWalletWidget({Key? key, this.updateController}) : super(key: key);

  @override
  State<HomeMealPlanWalletWidget> createState() => _HomeMealPlanWalletWidgetState();
}

class _HomeMealPlanWalletWidgetState extends State<HomeMealPlanWalletWidget> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
      IlliniCash.notifyBallanceUpdated
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _onTap, child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child:
                        Text(Localization().getStringEx('widget.home.wallet.meal_plan.title', 'Meal Plan'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))
                      ),
                      Row(children: <Widget>[
                      ]),
                    ]),
                  ),
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        VerticalTitleValueSection(
                          title: Localization().getStringEx('widget.home.wallet.meal_plan.label.meals_remaining.text', 'Meals Remaining'),
                          value: IlliniCash().ballance?.mealBalanceDisplayText ?? "0",
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        )
                      ),
                      Expanded(child:
                        VerticalTitleValueSection(
                          title: Localization().getStringEx('widget.home.wallet.meal_plan.label.dining_dollars.text', 'Dining Dollars'),
                          value: IlliniCash().ballance?.cafeCreditBalanceDisplayText ?? "0",
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        )
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _onTap() {
    Analytics().logSelect(target: 'Meal Plan');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsMealPlanPanel()));
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if (name == IlliniCash.notifyBallanceUpdated) {
      if (mounted) {
        setState(() {});
      }
    }
  }
}

// HomeBusPassWalletWidget

class HomeBusPassWalletWidget extends StatefulWidget {
  final StreamController<String>? updateController;

  HomeBusPassWalletWidget({Key? key, this.updateController}) : super(key: key);

  @override
  State<HomeBusPassWalletWidget> createState() => _HomeBusPassWalletWidgetState();
}

class _HomeBusPassWalletWidgetState extends State<HomeBusPassWalletWidget> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyCardChanged
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _onTap, child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child:
                        Text(Localization().getStringEx('widget.home.wallet.bus_pass.title', 'MTD'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))
                      ),
                      Row(children: <Widget>[
                      ]),
                    ]),
                  ),
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        VerticalTitleValueSection(
                          title: Auth2().authCard?.role ?? '',
                          titleTextStyle: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 24, color: Styles().colors?.fillColorPrimary),
                          value: sprintf(Localization().getStringEx('widget.home.wallet.bus_pass.label.card_expires.text', 'Card Expires: %s'), [Auth2().authCard?.expirationDate ?? '']),
                          valueTextStyle: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 14, color: Styles().colors?.fillColorPrimary),
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        )
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _onTap() {
    Analytics().logSelect(target: 'Bus Pass');
    showModalBottomSheet(context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        builder: (context) => MTDBusPassPanel());
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyCardChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }
}

// HomeIlliniIdWalletWidget

class HomeIlliniIdWalletWidget extends StatefulWidget {
  final StreamController<String>? updateController;

  HomeIlliniIdWalletWidget({Key? key, this.updateController}) : super(key: key);

  @override
  State<HomeIlliniIdWalletWidget> createState() => _HomeIlliniIdWalletWidgetState();
}

class _HomeIlliniIdWalletWidgetState extends State<HomeIlliniIdWalletWidget> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyCardChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _onTap, child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child:
                        Text(Localization().getStringEx('widget.home.wallet.illini_id.title', 'Illini ID'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))
                      ),
                      Row(children: <Widget>[
            ]),
                    ]),
                  ),
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        VerticalTitleValueSection(
                          title: Auth2().authCard?.fullName ?? '',
                          value: Auth2().authCard?.uin ?? '',
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        )
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _onTap() {
    Analytics().logSelect(target: 'Illini ID');
    showModalBottomSheet(context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        builder: (context) => IDCardPanel());
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyCardChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }
}

// HomeLibraryCardWalletWidget

class HomeLibraryCardWalletWidget extends StatefulWidget {
  final StreamController<String>? updateController;

  HomeLibraryCardWalletWidget({Key? key, this.updateController}) : super(key: key);

  @override
  State<HomeLibraryCardWalletWidget> createState() => _HomeLibraryCardWalletWidgetState();
}

class _HomeLibraryCardWalletWidgetState extends State<HomeLibraryCardWalletWidget> implements NotificationsListener {
  String?        _libraryCode;
  MemoryImage?   _libraryBarcode;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyCardChanged,
    ]);
    _loadLibraryBarcode();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _onTap, child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child:
                        Text(Localization().getStringEx('widget.home.wallet.library_card.title', 'Library Card'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))
                      ),
                      Row(children: <Widget>[
                      ]),
                    ]),
                  ),
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 16, right: 16, bottom: 16, left: 16), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        Container(decoration: BoxDecoration(border: Border(left: BorderSide(color: Styles().colors?.fillColorSecondary ?? Colors.transparent, width: 3))), child:
                          Padding(padding: EdgeInsets.only(left: 10, top: 4, bottom: 4), child:
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                              Container(height: 50, decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                image: (_libraryBarcode != null) ? DecorationImage(fit: BoxFit.fill, image:_libraryBarcode! ,) : null,    
                              )),
                              Padding(padding: EdgeInsets.only(top: 4), child:
                                Row(children: [Expanded(child: Text(Auth2().authCard?.libraryNumber ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 14, color: Styles().colors?.fillColorPrimary)))]),
                              )
                            ],),
                          )
                        )
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _onTap() {
    Analytics().logSelect(target: 'Library Card');
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
        if (mounted) {
          setState(() {
            _libraryCode = libraryCode;
            _libraryBarcode = (imageData != null) ? MemoryImage(imageData) : null;
          });
        }
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

  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyCardChanged) {
      _updateLibraryBarcode();
    }
  }
}

