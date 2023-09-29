import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsAddIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsMealPlanPanel.dart';
import 'package:illinois/ui/wallet/ICardHomeContentPanel.dart';
import 'package:illinois/ui/wallet/MTDBusPassPanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class HomeWalletWidget extends StatefulWidget {
  
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeWalletWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.wallet.label.title', 'Wallet');

  @override
  State<HomeWalletWidget> createState() => _HomeWalletWidgetState();
}

class _HomeWalletWidgetState extends HomeCompoundWidgetState<HomeWalletWidget> {

  _HomeWalletWidgetState() : super(direction: Axis.horizontal);

  @override String? get favoriteId => widget.favoriteId;
  @override String? get title => HomeWalletWidget.title;
  @override String? get titleIconKey => 'wallet';
  @override String? get emptyMessage => Localization().getStringEx("widget.home.wallet.text.empty.description", "Tap the \u2606 on items in Wallet so you can quickly find them here.");

  @override
  Widget? widgetFromCode(String code) {
    if (code == 'illini_cash_card') {
      return HomeIlliniCashWalletWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
    }
    else if (code == 'meal_plan_card') {
      return HomeMealPlanWalletWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
    }
    else if (code == 'bus_pass_card') {
      return HomeBusPassWalletWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
    }
    else if (code == 'illini_id_card') {
      return HomeIlliniIdWalletWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
    }
    else if (code == 'library_card') {
      return HomeLibraryCardWalletWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
    }
    else {
      return null;
    }
  }
}

// HomeIlliniCashWalletWidget

class HomeIlliniCashWalletWidget extends StatefulWidget {
  final HomeFavorite? favorite;
  final StreamController<String>? updateController;

  HomeIlliniCashWalletWidget({Key? key, this.favorite, this.updateController}) : super(key: key);

  @override
  State<HomeIlliniCashWalletWidget> createState() => _HomeIlliniCashWalletWidgetState();
}

class _HomeIlliniCashWalletWidgetState extends State<HomeIlliniCashWalletWidget> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      IlliniCash.notifyBallanceUpdated,
      IlliniCash.notifyEligibilityUpdated,
      Connectivity.notifyStatusChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if ((name == Auth2.notifyLoginChanged) ||
        (name == IlliniCash.notifyBallanceUpdated) ||
        (name == IlliniCash.notifyEligibilityUpdated) ||
        (name == Connectivity.notifyStatusChanged)) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;
    String? ballance = IlliniCash().ballance?.balanceDisplayText;
    if (StringUtils.isNotEmpty(ballance)) {
      contentWidget = VerticalTitleValueSection(
        title: Localization().getStringEx('widget.home.wallet.illini_cash.label.current_balance', 'Current Illini Cash Balance'),
        value: ballance,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
    }
    else if (IlliniCash().eligibility?.eligible == false) {
      String title = Localization().getStringEx('widget.home.wallet.illini_cash.label.ineligible', 'Ineligible');
      String? status = StringUtils.isNotEmpty(IlliniCash().eligibility?.accountStatus) ? IlliniCash().eligibility?.accountStatus :
        Localization().getStringEx('widget.home.wallet.illini_cash.label.ineligible_status', 'You are not eligibile for Illini Cash');
      
      contentWidget = VerticalTitleValueSection(
        title: title,
        titleTextStyle: Styles().textStyles?.getTextStyle("widget.title.large.extra_fat"),
        value: status,
        valueTextStyle: Styles().textStyles?.getTextStyle("widget.detail.medium"),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
    }
    else if (!Auth2().isOidcLoggedIn) {
      contentWidget = VerticalTitleValueSection(
       title: Localization().getStringEx('panel.browse.label.logged_out.illini_cash.short', 'You need to be logged in with your NetID to access Illini Cash.'),
        titleTextStyle: Styles().textStyles?.getTextStyle("widget.message.regular.semi_fat"),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
    }    
    else {
      contentWidget = Container();
    }

    return GestureDetector(onTap: _onTap, child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wallet.illini_cash.title', 'Illini Cash'), style: Styles().textStyles?.getTextStyle("widget.title.large.fat"))),
                      ),
                    HomeFavoriteButton(favorite: widget.favorite, style: FavoriteIconStyle.Button, padding: EdgeInsets.all(12), prompt: true)
                  ])
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        contentWidget
                      ),
                      Visibility(visible: SettingsAddIlliniCashPanel.canPresent, child:
                        Semantics(button: true, excludeSemantics: true, label: Localization().getStringEx('widget.home.wallet.illini_cash.button.add_illini_cash.title', 'Add Illini Cash'), hint: Localization().getStringEx('widget.home.wallet.illini_cash.button.add_illini_cash.hint', ''), child:
                          IconButton(color: Styles().colors!.fillColorPrimary, icon: Styles().images?.getImage('plus-circle-large', excludeFromSemantics: true) ?? Container(), onPressed: _onTapPlus)
                        ),
                      )
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
    Analytics().logSelect(target: 'Illini Cash', source: widget.runtimeType.toString());
    SettingsIlliniCashPanel.present(context);
  }

  void _onTapPlus() {
    Analytics().logSelect(target: "Add Illini Cash", source: widget.runtimeType.toString());
    SettingsAddIlliniCashPanel.present(context);
  }
}

// HomeMealPlanWalletWidget

class HomeMealPlanWalletWidget extends StatefulWidget {
  final HomeFavorite? favorite;
  final StreamController<String>? updateController;

  HomeMealPlanWalletWidget({Key? key, this.favorite, this.updateController}) : super(key: key);

  @override
  State<HomeMealPlanWalletWidget> createState() => _HomeMealPlanWalletWidgetState();
}

class _HomeMealPlanWalletWidgetState extends State<HomeMealPlanWalletWidget> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      IlliniCash.notifyBallanceUpdated,
      IlliniCash.notifyEligibilityUpdated,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if ((name == Auth2.notifyLoginChanged) ||
        (name == IlliniCash.notifyBallanceUpdated) ||
        (name == IlliniCash.notifyEligibilityUpdated)) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;
    String? mealBalance = IlliniCash().ballance?.mealBalanceDisplayText;
    String? cafeCreditBalance = IlliniCash().ballance?.cafeCreditBalanceDisplayText;

    if (StringUtils.isNotEmpty(mealBalance) || StringUtils.isNotEmpty(cafeCreditBalance)) {
      contentWidget = Row(children: <Widget>[
        Expanded(child:
          Opacity(opacity: StringUtils.isNotEmpty(mealBalance) ? 1 : 0, child:
            VerticalTitleValueSection(
              title: Localization().getStringEx('widget.home.wallet.meal_plan.label.meals_remaining.text', 'Meals Remaining'),
              value: mealBalance,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            )
          ),
        ),
        Expanded(child:
          Opacity(opacity: StringUtils.isNotEmpty(cafeCreditBalance) ? 1 : 0, child:
            VerticalTitleValueSection(
              title: Localization().getStringEx('widget.home.wallet.meal_plan.label.dining_dollars.text', 'Dining Dollars'),
              value: cafeCreditBalance,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ]);
    }
    else if (IlliniCash().eligibility?.eligible == false) {
      String title = Localization().getStringEx('widget.home.wallet.meal_plan.label.ineligible', 'Ineligible');
      String? status = StringUtils.isNotEmpty(IlliniCash().eligibility?.accountStatus) ? IlliniCash().eligibility?.accountStatus :
        Localization().getStringEx('widget.home.wallet.meal_plan.label.ineligible_status', 'You are not eligibile for Meal Plan');
      
      contentWidget = Row(children: <Widget>[
        Expanded(child:
          VerticalTitleValueSection(
            title: title,
            titleTextStyle: Styles().textStyles?.getTextStyle("widget.title.large.extra_fat"),
            value: status,
            valueTextStyle: Styles().textStyles?.getTextStyle("widget.detail.medium"),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ]);
    }
    else if (!Auth2().isOidcLoggedIn) {
      contentWidget = Row(children: <Widget>[
        Expanded(child:
          VerticalTitleValueSection(
          title: Localization().getStringEx('panel.browse.label.logged_out.meal_plan.short', 'You need to be logged in with your NetID to access University Housing Meal Plan.'),
            titleTextStyle: Styles().textStyles?.getTextStyle("widget.message.regular.semi_fat"),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ]);
    }    
    else {
      contentWidget = Row(children: <Widget>[
        Expanded(child:
        Container()
      )
    ]);
    }

    return GestureDetector(onTap: _onTap, child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wallet.meal_plan.title', 'Meal Plan'), style: Styles().textStyles?.getTextStyle("widget.title.large.fat"))
                      ),
                    ),
                    HomeFavoriteButton(favorite: widget.favorite, style: FavoriteIconStyle.Button, padding: EdgeInsets.all(12), prompt: true)
                  ]),
              ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    contentWidget,
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
    Analytics().logSelect(target: 'Meal Plan', source: widget.runtimeType.toString());
    SettingsMealPlanPanel.present(context);
  }
}

// HomeBusPassWalletWidget

class HomeBusPassWalletWidget extends StatefulWidget {
  final HomeFavorite? favorite;
  final StreamController<String>? updateController;

  HomeBusPassWalletWidget({Key? key, this.favorite, this.updateController}) : super(key: key);

  @override
  State<HomeBusPassWalletWidget> createState() => _HomeBusPassWalletWidgetState();
}

class _HomeBusPassWalletWidgetState extends State<HomeBusPassWalletWidget> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      Auth2.notifyCardChanged
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if ((name == Auth2.notifyLoginChanged) || (name == Auth2.notifyCardChanged)) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? message;
    if (!Auth2().isOidcLoggedIn) {
      message = Localization().getStringEx('panel.browse.label.logged_out.bus_pass.short', 'You need to be logged in with your NetID to access MTD Bus Pass.');
    }
    else if (StringUtils.isEmpty(Auth2().authCard?.cardNumber) || (Auth2().authCard?.expirationDateTimeUtc == null)) {
      message = Localization().getStringEx('panel.browse.label.no_card.bus_pass', 'You need a valid Illini Identity card to access MTD Bus Pass.');
    }
    return GestureDetector(onTap: _onTap, child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wallet.bus_pass.title', 'MTD Bus Pass'), style: Styles().textStyles?.getTextStyle("widget.title.large.fat"))
                      ),
                    ),
                    HomeFavoriteButton(favorite: widget.favorite, style: FavoriteIconStyle.Button, padding: EdgeInsets.all(12), prompt: true)
                  ]),
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        VerticalTitleValueSection(
                          title: (message != null) ? message : Auth2().authCard?.role ?? '',
                          titleTextStyle: (message != null) ? Styles().textStyles?.getTextStyle("widget.message.regular.semi_fat") : Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'),
                          value: (message != null) ? null : StringUtils.isNotEmpty(Auth2().authCard?.expirationDate) ? sprintf(Localization().getStringEx('widget.home.wallet.bus_pass.label.card_expires.text', 'Expires: %s'), [Auth2().authCard?.expirationDate ?? '']) : '',
                          valueTextStyle: (message != null) ? null : Styles().textStyles?.getTextStyle("widget.detail.small"),
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
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
    Analytics().logSelect(target: 'Bus Pass', source: widget.runtimeType.toString());
    MTDBusPassPanel.present(context);
  }
}

// HomeIlliniIdWalletWidget

class HomeIlliniIdWalletWidget extends StatefulWidget {
  final HomeFavorite? favorite;
  final StreamController<String>? updateController;

  HomeIlliniIdWalletWidget({Key? key, this.favorite, this.updateController}) : super(key: key);

  @override
  State<HomeIlliniIdWalletWidget> createState() => _HomeIlliniIdWalletWidgetState();
}

class _HomeIlliniIdWalletWidgetState extends State<HomeIlliniIdWalletWidget> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      Auth2.notifyCardChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if ((name == Auth2.notifyLoginChanged) || (name == Auth2.notifyCardChanged)) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? message, warning;
    if (!Auth2().isOidcLoggedIn) {
      message = Localization().getStringEx('panel.browse.label.logged_out.illini_id.short', 'You need to be logged in with your NetID to access Illini ID.');
    }
    else if (StringUtils.isEmpty(Auth2().authCard?.cardNumber)) {
      message = Localization().getStringEx('panel.browse.label.no_card.illini_id', 'No Illini ID information. You do not have an active Illini ID. Please visit the ID Center.');
    }
    else {
      int? expirationDays = Auth2().authCard?.expirationIntervalInDays;
      if (expirationDays != null) {
        if (expirationDays <= 0) {
          message = sprintf(Localization().getStringEx('panel.browse.label.expired_card.illini_id', 'No Illini ID information. Your Illini ID expired on %s. Please visit the ID Center.'), [Auth2().authCard?.expirationDate ?? '']);
        }
        else if ((0 < expirationDays) && (expirationDays < 30)) {
          warning = sprintf(Localization().getStringEx('panel.browse.label.expiring_card.illini_id','Your ID will expire on %s. Please visit the ID Center.'), [Auth2().authCard?.expirationDate ?? '']);
        }
      }
    }

    return GestureDetector(onTap: _onTap, child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wallet.illini_id.title', 'Illini ID'), style: Styles().textStyles?.getTextStyle("widget.title.large.fat"))
                      ),
                    ),
                    HomeFavoriteButton(favorite: widget.favorite, style: FavoriteIconStyle.Button, padding: EdgeInsets.all(12), prompt: true),
                  ]),
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        VerticalTitleValueSection(
                          title: (message != null) ? message : StringUtils.isNotEmpty(Auth2().authCard?.fullName) ? Auth2().authCard?.fullName : Auth2().fullName,
                          titleTextStyle: (message != null) ? Styles().textStyles?.getTextStyle("widget.message.regular.semi_fat") : null,
                          value: (message != null) ? null : Auth2().authCard?.uin,
                          valueTextStyle: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'),
                          hint: (warning != null) ? warning : null,
                          hintTextStyle: Styles().textStyles?.getTextStyle('widget.card.detail.tiny'),
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
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
    Analytics().logSelect(target: 'Illini ID', source: widget.runtimeType.toString());
    ICardHomeContentPanel.present(context, content: ICardContent.i_card);
  }
}

// HomeLibraryCardWalletWidget

class HomeLibraryCardWalletWidget extends StatefulWidget {
  final HomeFavorite? favorite;
  final StreamController<String>? updateController;

  HomeLibraryCardWalletWidget({Key? key, this.favorite, this.updateController}) : super(key: key);

  @override
  State<HomeLibraryCardWalletWidget> createState() => _HomeLibraryCardWalletWidgetState();
}

class _HomeLibraryCardWalletWidgetState extends State<HomeLibraryCardWalletWidget> implements NotificationsListener {
  String?        _libraryCode;
  MemoryImage?   _libraryBarcode;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
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

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if ((name == Auth2.notifyLoginChanged) || (name == Auth2.notifyCardChanged)) {
      _updateLibraryBarcode();
    }
  }

  @override
  Widget build(BuildContext context) {
    String? message;
    if (!Auth2().isOidcLoggedIn) {
      message = Localization().getStringEx('panel.browse.label.logged_out.library_card.short', 'You need to be logged in with your NetID to access Library Card.');
    }
    else if (StringUtils.isEmpty(Auth2().authCard?.libraryNumber)) {
      message = Localization().getStringEx('panel.browse.label.no_card.library_card', 'You need a valid Illini Identity card to access Library Card.');
    }

    return GestureDetector(onTap: _onTap, child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wallet.library_card.title', 'Library Card'), style: Styles().textStyles?.getTextStyle("widget.title.large.fat"))
                      ),
                    ),
                    HomeFavoriteButton(favorite: widget.favorite, style: FavoriteIconStyle.Button, padding: EdgeInsets.all(12), prompt: true),
                  ]),
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        (message != null) ?
                          VerticalTitleValueSection(
                            title: message,
                            titleTextStyle: Styles().textStyles?.getTextStyle("widget.message.regular.semi_fat"),
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ) :
                          Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8), child:
                            Container(decoration: BoxDecoration(border: Border(left: BorderSide(color: Styles().colors?.fillColorSecondary ?? Colors.transparent, width: 3))), child:
                              Padding(padding: EdgeInsets.only(left: 10), child:
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                                  Container(height: 50, decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    image: (_libraryBarcode != null) ? DecorationImage(fit: BoxFit.fill, image:_libraryBarcode! ,) : null,    
                                  )),
                                  Padding(padding: EdgeInsets.only(top: 8), child:
                                    Row(children: [Expanded(child: Text(Auth2().authCard?.libraryNumber ?? '', style: Styles().textStyles?.getTextStyle("widget.detail.small"), textAlign: TextAlign.center,))]),
                                  )
                                ],),
                              ),
                            ),
                          ),
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
    Analytics().logSelect(target: 'Library Card', source: widget.runtimeType.toString());
  }

  void _loadLibraryBarcode() {
    String? libraryCode = Auth2().authCard?.libraryNumber;
    if (0 < (libraryCode?.length ?? 0)) {
      NativeCommunicator().getBarcodeImageData({
        'content': libraryCode,
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
}