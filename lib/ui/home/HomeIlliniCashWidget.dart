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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/ui/settings/SettingsAddIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section.dart';

class HomeIlliniCashWidget extends StatefulWidget {
  HomeIlliniCashWidget();

  @override
  State<HomeIlliniCashWidget> createState() => _HomeIlliniCashWidgetState();
}

class _HomeIlliniCashWidgetState extends State<HomeIlliniCashWidget> implements NotificationsListener {
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
      Container(margin: EdgeInsets.only(left: 16, right: 16, bottom: 20), decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.fillColorPrimary, child:
                  Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(Localization().getStringEx('widget.home.illini_cash.title', 'Illini Cash'), style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20))),
                      Row(children: <Widget>[
                        Padding(padding: EdgeInsets.only(right: 8), child:
                          Text(Localization().getStringEx('widget.home.common.button.view.title', 'View'), style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 16))),
                        Image.asset('images/chevron-right-white.png', excludeFromSemantics: true)
                      ])
                    ])
                  ),
                ),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        VerticalTitleValueSection(
                          title: Localization().getStringEx('widget.home.illini_cash.label.current_balance', 'Current Illini Cash Balance'),
                          value: IlliniCash().ballance?.balanceDisplayText ?? '\$0.00',
                        )
                      ),
                      Semantics(button: true, excludeSemantics: true, label: Localization().getStringEx('widget.home.illini_cash.button.add_illini_cash.title', 'Add Illini Cash'), hint: Localization().getStringEx('widget.home.illini_cash.button.add_illini_cash.hint', ''), child:
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
    Navigator.push(
        context,
        CupertinoPageRoute(
            settings: RouteSettings(name: SettingsIlliniCashPanel.routeName), builder: (context) => SettingsIlliniCashPanel()));
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
