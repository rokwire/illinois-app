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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/model/Reminder.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Reminders.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class HomeCampusRemindersWidget extends StatefulWidget {
  final StreamController<void> refreshController;

  HomeCampusRemindersWidget({this.refreshController});

  @override
  _HomeCampusRemindersWidgetState createState() => _HomeCampusRemindersWidgetState();
}

class _HomeCampusRemindersWidgetState extends State<HomeCampusRemindersWidget> implements NotificationsListener {
  List<Reminder> _reminders;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, Reminders.notifyChanged);
    if (widget.refreshController != null) {
      widget.refreshController.stream.listen((_) {
        _loadReminders();
      });
    }
    _loadReminders();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: AppCollection.isCollectionNotEmpty(_reminders),
      child: Container(
          child: Column(children: [
            _SectionListLayout(
              title: Localization().getStringEx('widget.home_campus_reminders.label.campus_reminders', 'CAMPUS REMINDERS'),
              titlePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              titleStyle: TextStyle(color: Styles().colors.white, fontSize: 14, letterSpacing: 1.0, fontFamily: Styles().fontFamilies.bold),
              widgets: _buildReminders(),
            ),
            Padding(padding: EdgeInsets.only(top: 24, bottom: 32), child:

            ScalableSmallRoundedButton(
              label: _showAll
                  ? Localization().getStringEx("widget.section_list.button.show_less.label", "Show less")
                  : Localization().getStringEx("widget.section_list.button.show_more.label", "Show more"),
              onTap: () => _onShowMoreTap(),
            ),)
          ])),
    );
  }

  List<Widget> _buildReminders() {
    List<Widget> widgets = new List();
    if (_reminders?.isNotEmpty ?? false) {
      _reminders.forEach((Reminder reminder) {
        widgets.add(_reminders.last != reminder
            ? _HomeReminderItemCard(reminder: reminder)
            : _HomeReminderItemCard(reminder: reminder, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4))));
      });
    }

    return widgets;
  }

  void _onShowMoreTap() {
    Analytics.instance.logSelect(target: "Campus Reminders Show " + (_showAll ? "less" : "more"));
    _showAll = !_showAll;
    _loadReminders();
  }

  void _loadReminders() {
    _reminders = _showAll ? Reminders().getAllUpcomingReminders() : Reminders().getReminders();
    setState(() {});
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Reminders.notifyChanged) {
      _loadReminders();
    }
  }
}

class _SectionListLayout extends StatelessWidget {
  final List<Widget> widgets;
  final String title;
  final TextStyle titleStyle;
  final EdgeInsetsGeometry titlePadding;
  final Function viewMoreTap;

  const _SectionListLayout({
    Key key,
    this.widgets,
    this.title,
    this.viewMoreTap,
    this.titleStyle,
    this.titlePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: viewMoreTap,
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
              //Header
              Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Styles().colors.fillColorPrimary, borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                  child: Semantics(
                      label: title,
                      header: true,
                      excludeSemantics: true,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                        Expanded(
                            child: Padding(
                              padding: titlePadding,
                              child: Text(
                                title,
                                style: titleStyle ?? TextStyle(color: Styles().colors.white, fontSize: 24),
                              ),
                            )),
                        viewMoreTap == null
                            ? Container()
                            : Container(
                            child: Text(Localization().getStringEx("widget.section_list.button.view_more.label", "View more"),
                                style: TextStyle(color: Styles().colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.regular))),
                        viewMoreTap == null
                            ? Container()
                            : Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Image.asset('images/chevron-right.png'))
                      ]))),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Styles().colors.white,
                  border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
                ),
                child: Padding(padding: EdgeInsets.all(0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets)),
              )
            ])));
  }
}

class _HomeReminderItemCard extends StatefulWidget {
  final Reminder _reminder;
  final BorderRadius _borderRadius;
  final bool _showHeader;
  final Color _headerColor;

  const _HomeReminderItemCard({Key key, Reminder reminder, BorderRadius borderRadius, bool showHeader = false, Color headerColor})
      : _reminder = reminder,
        _borderRadius = borderRadius,
        _showHeader = showHeader,
        _headerColor = headerColor,
        super(key: key);

  @override
  _HomeReminderItemCardState createState() => _HomeReminderItemCardState();
}

class _HomeReminderItemCardState extends State<_HomeReminderItemCard> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, User.notifyFavoritesUpdated);
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
    if (name == User.notifyFavoritesUpdated) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget._reminder == null) {
      return Container();
    }
    bool favorite = User().isFavorite(widget._reminder);
    double headerHeight = 7;

    return Semantics(
        label: Localization().getStringEx('widget.reminder_item_card.text.reminder', 'Reminder'),
        child: Column(
          children: <Widget>[
            Visibility(
              visible: widget._showHeader,
              child: Container(
                height: headerHeight,
                color: widget._headerColor ?? Styles().colors.fillColorSecondary,
              ),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Styles().colors.surfaceAccent, width: 0), borderRadius: widget._borderRadius),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Flex(
                    direction: Axis.vertical,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              widget._reminder.label,
                              style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),
                            ),
                          ),
                          Visibility(
                            visible: User().favoritesStarVisible,
                            child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  String reminder = widget._reminder.id;
                                  Analytics.instance.logSelect(target: "Favorite Reminder: $reminder");
                                  User().switchFavorite(widget._reminder);
                                },
                                child: Semantics(
                                    label: favorite
                                        ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                                        : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                                    hint: favorite
                                        ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                                        : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                                    button: true,
                                    excludeSemantics: true,
                                    child: Container(
                                        child: Padding(
                                            padding: EdgeInsets.only(left: 24),
                                            child: Image.asset(favorite ? 'images/icon-star-selected.png' : 'images/icon-star.png'))))),
                          )
                        ],
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(widget._reminder.displayDate, style: TextStyle(color: Styles().colors.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies.medium)),
                  )
                ]),
              ),
            )
          ],
        ));
  }
}
