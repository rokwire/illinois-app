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
import 'package:illinois/mainImpl.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SettingsLanguageContentWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsLanguageContentWidgetState();
}

class _SettingsLanguageContentWidgetState extends State<SettingsLanguageContentWidget> implements NotificationsListener {

  bool _localeChanged = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Localization.notifyLocaleChanged,
    ]);
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
    if (name == Localization.notifyLocaleChanged) {
      setStateIfMounted(() { });
      _localeChanged = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(decoration: _contentDecoration, child:
      Padding(padding: EdgeInsets.zero, child:
        Column(children: _buildLanguageOptions(),)
      )
    );
  }

  static BoxDecoration get _contentDecoration => BoxDecoration(
    color: Styles().colors?.white,
    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(4))
  );

  List<Widget> _buildLanguageOptions() {
    List<Widget> contentList = <Widget>[];
    contentList.add(_buildLanguageOption(Localization().getStringEx('panel.settings.home.language.system.title', 'Use System Language'), null));
    for (String code in Localization().supportedLanguages) {
      contentList.add(Divider(thickness: 0.3, color: Styles().colors?.mediumGray2,));
      contentList.add(_buildLanguageOption(Localization().getString('panel.settings.home.language.$code.title') ?? code, code));
    }
    return contentList;
    
  }

  Widget _buildLanguageOption(String name, String? code) {
    return Row(children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 16), child:
          Text(name, style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"),)
        )
      ),
      InkWell(onTap: () => _onLanguageOption(name, code), child:
        Padding(padding: EdgeInsets.all(16), child:
          Styles().images?.getImage((Localization().selectedLocale?.languageCode == code) ? 'check-circle-filled' : 'check-circle-outline-gray', excludeFromSemantics: true)
        )
      ),
    ],);
  }

  void _onLanguageOption(String name, String? code) {
    Analytics().logSelect(target: name);
    if ((Localization().selectedLocale?.languageCode != code)) {
      _localeChanged = false;
      Localization().setSelectedLocaleAsync((code != null) ? Locale(code) : null).then((_) {
        if (_localeChanged) {
          _launchSettingsLanguagePanel();
        }
        else {
          setStateIfMounted(() { });
        }
      });
    }
  }

  void _launchSettingsLanguagePanel() {
    Future.delayed(Duration(milliseconds: 500), (){
      BuildContext? context = App.instance?.currentContext;
      if (context != null) {
        SettingsHomeContentPanel.present(context,
          content: SettingsContent.language,
        );
      }
    });
  }

}
