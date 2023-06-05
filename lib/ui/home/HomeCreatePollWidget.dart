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
  final StreamController<String>? updateController;

  HomeCreatePollWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx("widget.home_create_poll.heading.title", "Polls");

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
        HomeSlantWidget(favoriteId: widget.favoriteId,
          title: Localization().getStringEx("widget.home_create_poll.heading.title", "Polls"),
          titleIconKey: 'polls',
          flatHeight: 0, slantHeight: 0,
          childPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: _buildContent(),
      ));
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(Localization().getStringEx("widget.home_create_poll.text.title","Quickly Create and Share Polls."), style: Styles().textStyles?.getTextStyle("widget.title.large.extra_fat")),
        Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
        Text((_canCreatePoll?Localization().getStringEx("widget.home_create_poll.text.description","People in your Group can be notified to vote through the {{app_title}} app. Or you can give voters the four-digit poll number.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')) :
        Localization().getStringEx("widget.home_create_poll.text.description.login","You need to be logged in to create and share polls with people near you. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings.")),
          style: Styles().textStyles?.getTextStyle("widget.description.variant.regular")),),
        _buildButtons()
      ],);
  }

  Widget _buildButtons(){
    return _canCreatePoll?
    RoundedButton(
      label: Localization().getStringEx("widget.home_create_poll.button.create_poll.label","Create a Poll"),
      textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
      borderColor: Styles().colors!.fillColorSecondary,
      backgroundColor: Colors.white,
      contentWeight: 0.6,
      conentAlignment: MainAxisAlignment.start,
      onTap: _onCreatePoll,
    ) :
    Padding(padding: EdgeInsets.only(right: 120), child:
      RoundedButton(
        label: Localization().getStringEx("widget.home_create_poll.button.login.label","Login"),
        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
        borderColor: Styles().colors!.fillColorSecondary,
        backgroundColor: Colors.white,
        progress: _authLoading,
        onTap: _onLogin,
      ),
    );
  }

  void _onCreatePoll() {
    Analytics().logSelect(target: "Create Poll", source: widget.runtimeType.toString());
    CreatePollPanel.present(context);
  }

  bool get _canCreatePoll {
    return Auth2().isLoggedIn;
  }

  void _onLogin(){
    Analytics().logSelect(target: "Login", source: widget.runtimeType.toString());
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
