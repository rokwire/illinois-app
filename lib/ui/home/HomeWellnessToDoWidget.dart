import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/ToDo.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/academics/AcademicsHomePanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/wellness/todo/WellnessToDoItemDetailPanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeWellnessToDoWidget extends StatefulWidget {
  
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeWellnessToDoWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.wellness.todo.title', 'My To-Do List');

  @override
  State<HomeWellnessToDoWidget> createState() => _HomeWellnessToDoWidgetState();
}

class _HomeWellnessToDoWidgetState extends State<HomeWellnessToDoWidget> implements NotificationsListener {

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
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeWellnessToDoWidget.title,
      titleIconKey: 'todo',
      childPadding: HomeSlantWidget.defaultChildPadding,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return GestureDetector(child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8), child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text(Localization().getStringEx('widget.home.wellness.todo.items.today.label', 'TODAY\'S ITEMS'), textAlign: TextAlign.start, overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("widget.label.tiny.fat")))]),
                      Stack(alignment: Alignment.center, children: [
                        Visibility(visible: !_loading, child: _buildTodayItemsWidget()),
                        _buildLoadingIndicator()
                      ]),
                      Padding(padding: EdgeInsets.only(top: 15), child: Row(children: [Expanded(child: Text(Localization().getStringEx('widget.home.wellness.todo.items.unassigned.label', 'UNASSIGNED ITEMS'), textAlign: TextAlign.start, overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("widget.label.tiny.fat")))])),
                      Stack(alignment: Alignment.center, children: [
                        Visibility(visible: !_loading, child: _buildUnAssignedItemsWidget()),
                        _buildLoadingIndicator()
                      ]),
                      Padding(padding: EdgeInsets.only(top: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        RoundedButton(
                          label: Localization().getStringEx('widget.home.wellness.todo.items.add.button', 'Add Item'), borderColor: Styles().colors!.fillColorSecondary,
                            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.small"),
                          leftIcon: Styles().images?.getImage('plus-circle', excludeFromSemantics: true),
                          iconPadding: 8, rightIconPadding: EdgeInsets.only(right: 8), contentWeight: 0, padding: EdgeInsets.zero, onTap: _onTapAddItem),
                        LinkButton(
                          title: Localization().getStringEx('widget.home.wellness.todo.items.view_all.label', 'View All'),
                          hint: Localization().getStringEx('widget.home.wellness.todo.items.view_all.hint', 'Tap to view all To Do items'),
                          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.small.semi_fat.underline"),
                          onTap: _onTapViewAll,
                        ),
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
      widgetList.add(Text(Localization().getStringEx('widget.home.wellness.todo.items.today.empty.msg', 'You have no to-do items for today.'), style: Styles().textStyles?.getTextStyle("widget.info.small")));
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
      widgetList.add(Text(Localization().getStringEx('widget.home.wellness.todo.items.unassigned.empty.msg', 'You have no unassigned to-do items.'), style: Styles().textStyles?.getTextStyle("widget.info.small")));
    }
    return Padding(padding: EdgeInsets.only(top: 2), child: Column(children: widgetList));
  }

  Widget _buildToDoItemWidget(ToDoItem item) {
    Widget? completedWidget = Styles().images?.getImage(item.isCompleted ? 'check-circle-outline-gray-white' : 'circle-outline-white', color: Styles().colors?.fillColorSecondary , excludeFromSemantics: true);
    return GestureDetector(onTap: () => _onTapToDoItem(item), child: Padding(padding: EdgeInsets.only(top: 10), child: Container(color: Colors.transparent, child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(right: 10), child: completedWidget),
      Expanded(child: Text(StringUtils.ensureNotEmpty(item.name), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start, style: Styles().textStyles?.getTextStyle("widget.info.small")))
    ]))));
  }

  void _onTapToDoItem(ToDoItem item) {
    Analytics().logWellnessToDo(
      action: item.isCompleted ? Analytics.LogWellnessActionUncomplete : Analytics.LogWellnessActionComplete,
      source: widget.runtimeType.toString(),
      item: item);
    item.isCompleted = !item.isCompleted;
    Wellness().updateToDoItem(item).then((success) {
      if (!success) {
        AppAlert.showDialogResult(context, Localization().getStringEx('widget.home.wellness.todo.items.completed.failed.msg', 'Failed to update To-Do item.'));
      }
    });
  }

  void _onTapAddItem() {
    Analytics().logSelect(target: "Add Item", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessToDoItemDetailPanel()));
  }

  void _onTapViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AcademicsHomePanel(content: AcademicsContent.todo_list)));
  }

  void _loadToDoItems() {
    _setLoading(true);
    Wellness().loadToDoItems().then((items) {
      _toDoItems = items;
      _setLoading(false);
    });
  }

  void _refreshItems() {
    Wellness().loadToDoItems().then((items) {
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
