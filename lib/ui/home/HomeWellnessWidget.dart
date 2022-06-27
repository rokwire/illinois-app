import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeWellnessWidget extends StatefulWidget {
  
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeWellnessWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.wellness.label.title', 'Wellness');

  @override
  State<HomeWellnessWidget> createState() => _HomeWellnessWidgetState();
}

class _HomeWellnessWidgetState extends State<HomeWellnessWidget> implements NotificationsListener {

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
      title: HomeWellnessWidget.title,
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
          if (code == 'todo') {
            contentEntry = HomeToDoWellnessWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
          }
          else if (code == 'rings') {
            contentEntry = HomeRingsWellnessWidget(favorite: HomeFavorite(code, category: widget.favoriteId), updateController: widget.updateController,);
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

  //  List<dynamic>? contentListCodes = FlexUI()['home.wellness'];

  Set<String>? _buildAvailableCodes() => JsonUtils.setStringsValue(FlexUI()['home.wellness']);

  void _updateAvailableCodes() {
    Set<String>? availableCodes = JsonUtils.setStringsValue(FlexUI()['home.wellness']);
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
      List<String>? fullContent = JsonUtils.listStringsValue(FlexUI().contentSourceEntry('home.wellness'));
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

// HomeToDoWellnessWidget

class HomeToDoWellnessWidget extends StatefulWidget {
  final Favorite? favorite;
  final StreamController<String>? updateController;

  HomeToDoWellnessWidget({Key? key, this.favorite, this.updateController}) : super(key: key);

  @override
  State<HomeToDoWellnessWidget> createState() => _HomeToDoWellnessWidgetState();
}

class _HomeToDoWellnessWidgetState extends State<HomeToDoWellnessWidget> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
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
                        Text('MY TODO LIST' /* TBD: Localization */, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))),
                      ),
                    HomeFavoriteButton(favorite: widget.favorite, style: HomeFavoriteStyle.Button, padding: EdgeInsets.all(12), prompt: true)
                  ])
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        VerticalTitleValueSection(
                          title: 'Wellness ToDo content goes',
                          value: 'HERE',
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
    Analytics().logSelect(target: 'Wellness ToDo');
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
  }
}

// HomeRingsWellnessWidget

class HomeRingsWellnessWidget extends StatefulWidget {
  final Favorite? favorite;
  final StreamController<String>? updateController;

  HomeRingsWellnessWidget({Key? key, this.favorite, this.updateController}) : super(key: key);

  @override
  State<HomeRingsWellnessWidget> createState() => _HomeRingsWellnessWidgetState();
}

class _HomeRingsWellnessWidgetState extends State<HomeRingsWellnessWidget> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
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
                        Text('DAILY WELLNESS RINGS' /* TBD: Localization */, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))),
                      ),
                    HomeFavoriteButton(favorite: widget.favorite, style: HomeFavoriteStyle.Button, padding: EdgeInsets.all(12), prompt: true)
                  ])
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        VerticalTitleValueSection(
                          title: 'Wellness Rings content goes',
                          value: 'HERE',
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
    Analytics().logSelect(target: 'Wellness Rings');
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
  }
}
