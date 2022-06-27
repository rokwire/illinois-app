import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:collection/collection.dart';
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
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
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

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.wallet.label.title', 'Wallet');

  @override
  State<HomeWalletWidget> createState() => _HomeWalletWidgetState();
}

class _HomeWalletWidgetState extends State<HomeWalletWidget> implements NotificationsListener {

  List<String>? _displayCodes;
  Set<String>? _availableCodes;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
        }
      });
    }

    _availableCodes = _buildAvailableCodes();
    _displayCodes = _buildDisplayCodes();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateAvailableCodes();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updateDisplayCodes();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> commandsList = _buildCommandsList();
    return commandsList.isNotEmpty ? HomeSlantWidget(favoriteId: widget.favoriteId,
      title: Localization().getStringEx('widget.home.wallet.label.title', 'Wallet'),
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      child: Column(children: commandsList,),
    ) : Container();
  }

  List<Widget> _buildCommandsList() {
    List<Widget> contentList = <Widget>[];
    if (_displayCodes != null) {
      for (String code in _displayCodes!.reversed) {
        if ((_availableCodes == null) || _availableCodes!.contains(code)) {
          Widget? contentEntry;
          if (code == 'illini_cash_card') {
            contentEntry = HomeIlliniCashWalletWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
          }
          else if (code == 'meal_plan_card') {
            contentEntry = HomeMealPlanWalletWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
          }
          else if (code == 'bus_pass_card') {
            contentEntry = HomeBusPassWalletWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
          }
          else if (code == 'illini_id_card') {
            contentEntry = HomeIlliniIdWalletWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
          }
          else if (code == 'library_card') {
            contentEntry = HomeLibraryCardWalletWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
          }

          if (contentEntry != null) {
            if (contentList.isNotEmpty) {
              contentList.add(Container(height: 8,));
            }
            contentList.add(contentEntry);
          }
        }
      }
    }
    return contentList;
  }

  //  List<dynamic>? contentListCodes = FlexUI()['home.wallet'];

  Set<String>? _buildAvailableCodes() => JsonUtils.setStringsValue(FlexUI()['home.wallet']);

  void _updateAvailableCodes() {
    Set<String>? availableCodes = JsonUtils.setStringsValue(FlexUI()['home.wallet']);
    if ((availableCodes != null) && !DeepCollectionEquality().equals(_availableCodes, availableCodes) && mounted) {
      setState(() {
        _availableCodes = availableCodes;
      });
    }
  }

  List<String>? _buildDisplayCodes() {
    LinkedHashSet<String>? favorites = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName(category: widget.favoriteId));
    if (favorites == null) {
      // Build a default set of favorites
      List<String>? fullContent = JsonUtils.listStringsValue(FlexUI().contentSourceEntry('home.wallet'));
      if (fullContent != null) {
        favorites = LinkedHashSet<String>.from(fullContent.reversed);
        Future.delayed(Duration(), () {
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: widget.favoriteId), favorites);
        });
      }
    }
    
    return (favorites != null) ? List.from(favorites) : null;
  }

  void _updateDisplayCodes() {
    List<String>? displayCodes = _buildDisplayCodes();
    if ((displayCodes != null) && !DeepCollectionEquality().equals(_displayCodes, displayCodes) && mounted) {
      setState(() {
        _displayCodes = displayCodes;
      });
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wallet.illini_cash.title', 'Illini Cash'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))),
                      ),
                    HomeFavoriteButton(favorite: widget.favorite, style: FavoriteIconStyle.Button, padding: EdgeInsets.all(12), prompt: true)
                  ])
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
                      Visibility(visible: SettingsAddIlliniCashPanel.canPresent, child:
                        Semantics(button: true, excludeSemantics: true, label: Localization().getStringEx('widget.home.wallet.illini_cash.button.add_illini_cash.title', 'Add Illini Cash'), hint: Localization().getStringEx('widget.home.wallet.illini_cash.button.add_illini_cash.hint', ''), child:
                          IconButton(color: Styles().colors!.fillColorPrimary, icon: Image.asset('images/button-plus-orange.png', excludeFromSemantics: true), onPressed: _onTapPlus)
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
    Analytics().logSelect(target: 'Illini Cash');
    SettingsIlliniCashPanel.present(context);
  }

  void _onTapPlus() {
    Analytics().logSelect(target: "Add Illini Cash");
    SettingsAddIlliniCashPanel.present(context);
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wallet.meal_plan.title', 'Meal Plan'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))
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
    SettingsMealPlanPanel.present(context);
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wallet.bus_pass.title', 'MTD Bus Pass'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))
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
                          title: Auth2().authCard?.role ?? '',
                          titleTextStyle: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 24, color: Styles().colors?.fillColorPrimary),
                          value: StringUtils.isNotEmpty(Auth2().authCard?.expirationDate) ? sprintf(Localization().getStringEx('widget.home.wallet.bus_pass.label.card_expires.text', 'Card Expires: %s'), [Auth2().authCard?.expirationDate ?? '']) : '',
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
    MTDBusPassPanel.present(context);
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wallet.illini_id.title', 'Illini ID'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))
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
                        VerticalTitleValueSection(
                          title: StringUtils.isNotEmpty(Auth2().authCard?.fullName) ? Auth2().authCard?.fullName : Auth2().fullName,
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
     IDCardPanel.present(context);
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wallet.library_card.title', 'Library Card'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))
                      ),
                    ),
                    HomeFavoriteButton(favorite: widget.favorite, style: FavoriteIconStyle.Button, padding: EdgeInsets.all(12), prompt: true),
                  ]),
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

