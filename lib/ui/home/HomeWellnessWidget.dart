import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/ToDo.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/wellness/todo/WellnessCreateToDoItemPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
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
  List<ToDoItem>? _toDoItems;
  bool _loading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Wellness.notifyToDoItemCreated,
      Wellness.notifyToDoItemUpdated,
      Wellness.notifyToDoItemsDeleted,
    ]);
    _loadToDoItems();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.backgroundVariant, child:
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wellness.todo.title', 'MY TO-DO LIST'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 14))),
                      ),
                    HomeFavoriteButton(favorite: widget.favorite, style: HomeFavoriteStyle.Button, padding: EdgeInsets.all(12), prompt: true)
                  ])
                ),
                Container(color: Styles().colors!.backgroundVariant, height: 1,),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.all(16), child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text(Localization().getStringEx('widget.home.wellness.todo.items.today.label', 'TODAY\'S ITEMS'), textAlign: TextAlign.start, overflow: TextOverflow.ellipsis, style: TextStyle(color: Styles().colors!.fillColorSecondary, fontSize: 12, fontFamily: Styles().fontFamilies!.bold)))]),
                      Stack(alignment: Alignment.center, children: [
                        Visibility(visible: !_loading, child: _buildTodayItemsWidget()),
                        _buildLoadingIndicator()
                      ]),
                      Padding(padding: EdgeInsets.only(top: 15), child: Row(children: [Expanded(child: Text(Localization().getStringEx('widget.home.wellness.todo.items.unassigned.label', 'UNASSIGNED ITEMS'), textAlign: TextAlign.start, overflow: TextOverflow.ellipsis, style: TextStyle(color: Styles().colors!.fillColorSecondary, fontSize: 12, fontFamily: Styles().fontFamilies!.bold)))])),
                      Stack(alignment: Alignment.center, children: [
                        Visibility(visible: !_loading, child: _buildUnAssignedItemsWidget()),
                        _buildLoadingIndicator()
                      ]),
                      Padding(padding: EdgeInsets.only(top: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        RoundedButton(
                          label: Localization().getStringEx('widget.home.wellness.todo.items.add.button', 'Add Item'), borderColor: Styles().colors!.fillColorSecondary,
                          textColor: Styles().colors!.fillColorPrimary,
                          leftIcon: Image.asset('images/icon-add-14x14.png', color: Styles().colors!.fillColorPrimary),
                          iconPadding: 8, rightIconPadding: EdgeInsets.only(right: 8), fontSize: 14, contentWeight: 0, 
                          fontFamily: Styles().fontFamilies!.regular, padding: EdgeInsets.zero, onTap: _onTapAddItem),
                        GestureDetector(onTap: _onTapViewAll, child: Padding(padding: EdgeInsets.only(left: 15, top: 5, bottom: 5), child: Container(color: Colors.transparent, child: 
                          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                            Text(Localization().getStringEx('widget.home.wellness.todo.items.view_all.label', 'View all'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.semiBold, fontSize: 12)),
                            Padding(padding: EdgeInsets.only(left: 10), child: Image.asset('images/chevron-right.png'))
                          ])
                        )))
                      ]))
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

  Widget _buildLoadingIndicator() {
    return Visibility(visible: _loading, child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Styles().colors!.fillColorSecondary, strokeWidth: 2)));
  }

  Widget _buildTodayItemsWidget() {
    List<ToDoItem>? todayItems = _buildTodayItems();
    List<Widget> widgetList = <Widget>[];
    if (CollectionUtils.isNotEmpty(todayItems)) {
      for (ToDoItem item in todayItems!) {
        widgetList.add(_buildToDoItemWidget(item));
      }
    } else {
      widgetList.add(Text(Localization().getStringEx('widget.home.wellness.todo.items.today.empty.msg', 'You have no to-do items for today.'), style: TextStyle(color: Styles().colors!.textSurface, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)));
    }
    return Padding(padding: EdgeInsets.only(top: 2), child: Column(children: widgetList));
  }

  Widget _buildUnAssignedItemsWidget() {
    List<ToDoItem>? unAssignedItems = _buildUnAssignedItems();
    List<Widget> widgetList = <Widget>[];
    if (CollectionUtils.isNotEmpty(unAssignedItems)) {
      for (ToDoItem item in unAssignedItems!) {
        widgetList.add(_buildToDoItemWidget(item));
      }
    } else {
      widgetList.add(Text(Localization().getStringEx('widget.home.wellness.todo.items.unassigned.empty.msg', 'You have no unassigned to-do items.'), style: TextStyle(color: Styles().colors!.textSurface, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)));
    }
    return Padding(padding: EdgeInsets.only(top: 2), child: Column(children: widgetList));
  }

  Widget _buildToDoItemWidget(ToDoItem item) {
    final double completedWidgetSize = 20;
    Widget completedWidget = item.isCompleted ? Image.asset('images/example.png', color: Styles().colors!.textSurface, height: completedWidgetSize, width: completedWidgetSize, fit: BoxFit.fill) : Container(
            decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: Styles().colors!.textSurface!, width: 1)), height: completedWidgetSize, width: completedWidgetSize);
    return GestureDetector(onTap: () => _onTapToDoItem(item), child: Padding(padding: EdgeInsets.only(top: 10), child: Container(color: Colors.transparent, child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(right: 10), child: completedWidget),
      Expanded(child: Text(StringUtils.ensureNotEmpty(item.name), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start, style: TextStyle(color: Styles().colors!.textSurface, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)))
    ]))));
  }

  void _onTapToDoItem(ToDoItem item) {
    item.isCompleted = !item.isCompleted;
    Wellness().updateToDoItemCached(item).then((success) {
      if (!success) {
        AppAlert.showDialogResult(context, Localization().getStringEx('widget.home.wellness.todo.items.completed.failed.msg', 'Failed to update To-Do item.'));
      }
    });
  }

  void _onTapAddItem() {
    Analytics().logSelect(target: "Wellness To Do - Add Item");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessCreateToDoItemPanel()));
  }

  void _onTapViewAll() {
    Analytics().logSelect(target: "Wellness To Do - View all");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.todo)));
  }

  void _loadToDoItems() {
    _setLoading(true);
    Wellness().loadToDoItemsCached().then((items) {
      _toDoItems = items;
      _setLoading(false);
    });
  }

  void _refreshItems() {
    Wellness().loadToDoItemsCached().then((items) {
      _toDoItems = items;
      _updateState();
    });
  }

  void _setLoading(bool loading) {
    _loading = loading;
    _updateState();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  List<ToDoItem>? _buildTodayItems() {
    List<ToDoItem>? todayItems;
    if (CollectionUtils.isNotEmpty(_toDoItems)) {
      DateTime now = DateTime.now();
      todayItems = <ToDoItem>[];
      for (ToDoItem item in _toDoItems!) {
        DateTime? dueDate = item.dueDateTime;
        if (dueDate != null) {
          if ((dueDate.year == now.year) && (dueDate.month == now.month) && (dueDate.day == now.day)) {
            todayItems.add(item);
            if (todayItems.length == 3) { // return max 3 items
              break;
            }
          }
        }
      }
    }
    return todayItems;
  }

  List<ToDoItem>? _buildUnAssignedItems() {
    List<ToDoItem>? unAssignedItems;
    if (CollectionUtils.isNotEmpty(_toDoItems)) {
      unAssignedItems = <ToDoItem>[];
      for (ToDoItem item in _toDoItems!) {
        if (item.category == null) {
            unAssignedItems.add(item);
            if (unAssignedItems.length == 3) { // return max 3 items
              break;
            }
        }
      }
    }
    return unAssignedItems;
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if (name == Wellness.notifyToDoItemCreated) {
      _refreshItems();
    } else if (name == Wellness.notifyToDoItemUpdated) {
      _refreshItems();
    } else if (name == Wellness.notifyToDoItemsDeleted) {
      _refreshItems();
    }
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
                Container(color: Styles().colors!.backgroundVariant, child:
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                        Text(Localization().getStringEx('widget.home.wellness.rings.title', 'DAILY WELLNESS RINGS'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 14))),
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
