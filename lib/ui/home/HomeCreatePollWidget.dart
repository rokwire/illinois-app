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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class HomeCreatePollWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<void>? refreshController;
  final HomeScrollableDragging? scrollableDragging;

  HomeCreatePollWidget({Key? key, this.favoriteId, this.refreshController, this.scrollableDragging}) : super(key: key);

  @override
  _HomeCreatePollWidgetState createState() => _HomeCreatePollWidgetState();
}

class _HomeCreatePollWidgetState extends State<HomeCreatePollWidget> implements NotificationsListener {
  bool _visible = true;
  bool _authLoading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, []);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Visibility(visible: _visible, child:
      HomeDropTargetWidget(favoriteId: widget.favoriteId, child:
        Semantics(container: true, child:
          Container( color: Styles().colors!.background, child:
            Row(children: <Widget>[Expanded(child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                _buildHeader(),
                _buildContent(),
              ]),
          )],)
    ))));
  }

  Widget _buildHeader() {
    return Container(color: Styles().colors!.fillColorPrimary, child:
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        
            Semantics(label: 'Drag Handle' /* TBD: Localization */, button: true, child:
              Draggable<HomeFavorite>(
                data: HomeFavorite(id: widget.favoriteId),
                onDragStarted: () { widget.scrollableDragging?.isDragging = true; },
                onDragEnd: (details) { widget.scrollableDragging?.isDragging = false; },
                onDraggableCanceled: (velocity, offset) { widget.scrollableDragging?.isDragging = false; },
                feedback: Container(color: Styles().colors!.fillColorPrimary!.withOpacity(0.8), child:
                  Row(children: <Widget>[
                    HomeSlantWidget.dragHandle,
                    Padding(padding: EdgeInsets.only(right: 24), child:
                      Text('Twitter', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20, decoration: TextDecoration.none, shadows: <Shadow>[
                        Shadow(color: Styles().colors!.fillColorPrimary!.withOpacity(0.5), offset: Offset(2, 2), blurRadius: 2, )
                      ] ),),
                    ),
                  ],),
                ),
                childWhenDragging: HomeSlantWidget.dragHandle,
                child: HomeSlantWidget.dragHandle
              ),
            ),

        Expanded(child: 
          Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
            Text(Localization().getStringEx("widget.home_create_poll.heading.title", "Polls"), style:
              TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20,),),),),
        
        /*Semantics(label: Localization().getStringEx("widget.home_create_poll.button.close.label","Close"), button: true, excludeSemantics: true, child:
          InkWell(onTap : _onClose, child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12), child:
              Image.asset('images/close-orange.png')))),*/

        Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Image.asset('images/icon-star-yellow.png', excludeFromSemantics: true,),
          )
        ),

      ],),);
  }

  Widget _buildContent() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30), child: 
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(Localization().getStringEx("widget.home_create_poll.text.title","Quickly Create and Share Polls."), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, ),),
        Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
        Text((_canCreatePoll?Localization().getStringEx("widget.home_create_poll.text.description","People near you will be notified to vote through the Illinois app or you can provide them with the 4 Digit Poll #."):
        Localization().getStringEx("widget.home_create_poll.text.description.login","You need to be logged in to create and share polls with people near you.")),
          style: TextStyle(color: Color(0xff494949), fontFamily: Styles().fontFamilies!.medium, fontSize: 16,),),),
        _buildButtons()
      ],),);
  }

  Widget _buildButtons(){
    return _canCreatePoll?
    RoundedButton(
      label: Localization().getStringEx("widget.home_create_poll.button.create_poll.label","Create a Poll"),
      textColor: Styles().colors!.fillColorPrimary,
      borderColor: Styles().colors!.fillColorSecondary,
      backgroundColor: Colors.white,
      contentWeight: 0.6,
      conentAlignment: MainAxisAlignment.start,
      onTap: _onCreatePoll,
    ) :
    Padding(padding: EdgeInsets.only(right: 120), child:
      RoundedButton(
        label: Localization().getStringEx("widget.home_create_poll.button.login.label","Login"),
//        height: 48,
        textColor: Styles().colors!.fillColorPrimary,
        borderColor: Styles().colors!.fillColorSecondary,
        backgroundColor: Colors.white,
        progress: _authLoading,
        onTap: _onLogin,
      ),
    );
  }

  void _onCreatePoll() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreatePollPanel()));

  }

  void _onClose() {
    setState(() {
      _visible = false;
    });
  }

  bool get _canCreatePoll {
    return Auth2().isLoggedIn;
  }

  void _onLogin(){
    Analytics().logSelect(target: "Login");
    if (_authLoading != true) {
      setState(() { _authLoading = true; });
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          setState(() { _authLoading = false; });
          if (result != Auth2OidcAuthenticateResult.succeeded) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }

  @override
  void onNotification(String name, param) {
  }
}
