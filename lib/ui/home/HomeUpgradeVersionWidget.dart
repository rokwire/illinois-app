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

import 'package:flutter/material.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeUpgradeVersionWidget extends StatefulWidget {
  @override
  _HomeUpgradeVersionWidgetState createState() => _HomeUpgradeVersionWidgetState();
}

class _HomeUpgradeVersionWidgetState extends State<HomeUpgradeVersionWidget> {

  @override
  Widget build(BuildContext context) {
    bool upgradeMessageWidgetVisible = _isUpgradeMessageWidgetVisible();
    return Visibility(
      visible: upgradeMessageWidgetVisible,
      child: Column(
        children: <Widget>[
          Container(
            color: Styles().colors!.lightGray,
            padding: EdgeInsets.only(left: 16, top: 12, right: 12, bottom: 24),
            child: Semantics(
                container: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 16),
                      child: Text(
                        Localization().getStringEx('widget.home_upgrade_version.text',
                            'Welcome to the latest version of Illinois. We recommend that you Sign out and then Sign in again to ensure that all features are available.'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 10,
                        style: TextStyle(
                          color: Color(0xff494949),
                          fontFamily: Styles().fontFamilies!.medium,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        RoundedButton(
                          label: Localization().getStringEx('widget.home_upgrade_version.button.got_it', 'Got It'),
                          textColor: Styles().colors!.fillColorPrimary,
                          borderColor: Styles().colors!.fillColorSecondary,
                          backgroundColor: Styles().colors!.white,
                          contentWeight: 0.0,
                          onTap: _onTapGotIt,
                        )
                      ],
                    )
                  ],
                )),
          ),
          Container(
            height: 1,
            color: Styles().colors!.fillColorPrimaryVariant,
          ),
        ],
      ),
    );
  }

  bool _isUpgradeMessageWidgetVisible() {
    String? lastUserLoginVersion = Storage().userLoginVersion;
    String? currentVersion = Config().appVersion;
    if (AppVersion.matchVersions(currentVersion, '1.2') &&
        ((lastUserLoginVersion == null) || (AppVersion.compareVersions(lastUserLoginVersion, currentVersion) < 0))) {
      return true;
    } else {
      return false;
    }
  }

  void _onTapGotIt() {
    setState(() {
      Storage().userLoginVersion = Config().appVersion;
    });
  }
}

