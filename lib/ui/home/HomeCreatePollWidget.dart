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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';

class HomeCreatePollWidget extends StatefulWidget {
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

    return Visibility(visible: _visible, child: Semantics(container: true, child:Container(
        color: Styles().colors.background,
        child: Row(children: <Widget>[Expanded(child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _buildHeader(),
            _buildContent(),
          ]),
/*          Container(alignment: Alignment.topRight, child: Semantics(
              label: Localization().getStringEx("widget.home_create_poll.button.close.label","Close"),
              button: true,
              excludeSemantics: true,
              child: InkWell(
                  onTap : _onClose,
                  child: Container(width: 48, height: 48, alignment: Alignment.center, child: Image.asset('images/close-orange.png'))))),
*/
        )],)
    )));
  }

  Widget _buildHeader() {
    return Container(color: Styles().colors.fillColorPrimary, child:
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: 
          Padding(padding: EdgeInsets.only(left: 20, top: 10, bottom: 10), child:
            Text(Localization().getStringEx("widget.home_create_poll.heading.title", "Polls"), style:
              TextStyle(color: Styles().colors.white, fontFamily: Styles().fontFamilies.extraBold, fontSize: 20,),),),),
        Semantics(label: Localization().getStringEx("widget.home_create_poll.button.close.label","Close"), button: true, excludeSemantics: true, child:
          InkWell(onTap : _onClose, child:
            Container(width: 48, height: 56, alignment: Alignment.center, child:
              Image.asset('images/close-orange.png')))),

      ],),);
  }

  Widget _buildContent() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30), child: 
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(Localization().getStringEx("widget.home_create_poll.text.title","Quickly create and share polls."), style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, ),),
        Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
        Text(_canCreatePoll?Localization().getStringEx("widget.home_create_poll.text.description","People near you will be notified to vote through the Illinois app or you can provide them with the 4 Digit Poll #."):
        Localization().getStringEx("widget.home_create_poll.text.description.login","You need to be logged in to create and share polls with people near you."),
          style: TextStyle(color: Color(0xff494949), fontFamily: Styles().fontFamilies.medium, fontSize: 16,),),),
        _buildButtons()
      ],),);
  }

  Widget _buildButtons(){
    return _canCreatePoll?
    Padding(padding: EdgeInsets.only(right: 120), child:
    ScalableRoundedButton(
      label: Localization().getStringEx("widget.home_create_poll.button.create_poll.label","Create a poll"),
      padding: EdgeInsets.symmetric(horizontal: 16),
      textColor: Styles().colors.fillColorPrimary,
      borderColor: Styles().colors.fillColorSecondary,
      backgroundColor: Colors.white,
      onTap: _onCreatePoll,
    )) :
    Padding(padding: EdgeInsets.only(right: 120), child:
    Stack(children: <Widget>[
      ScalableRoundedButton(
        label: Localization().getStringEx("widget.home_create_poll.button.login.label","Login"),
//        height: 48,
        padding: EdgeInsets.symmetric(horizontal: 16),
        textColor: Styles().colors.fillColorPrimary,
        borderColor: Styles().colors.fillColorSecondary,
        backgroundColor: Colors.white,
        onTap: _onLogin,
      ),
      Visibility(visible: _authLoading,
        child: Container(
          height: 48,
          child: Align(alignment: Alignment.center,
            child: SizedBox(height: 24, width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), )
            ),
          ),
        ),
      ),
    ],),
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
    if (!_authLoading) {
      setState(() { _authLoading = true; });
      Auth2().authenticateWithOidc().then((_) {
        if (mounted) {
          setState(() { _authLoading = false; });
        }
      });
    }
  }

  @override
  void onNotification(String name, param) {
  }
}
