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
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsVideoTutorialPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeAppHelpWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeAppHelpWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widgets.home.app_help.header.title',  'App Help');

  @override
  State<StatefulWidget> createState() => _HomeAppHelpWidgetState();
}

class _HomeAppHelpWidgetState extends State<HomeAppHelpWidget> implements NotificationsListener{

  List<String>? _displayCodes;
  Set<String>? _availableCodes;

  @override
  void initState() {
    super.initState();

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
      title: Localization().getStringEx('widgets.home.app_help.header.title',  'App Help'),
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      child: Column(children: commandsList,),
      //flatHeight: 0, slantHeight: 0, childPadding: EdgeInsets.all(16),
    ) : Container();
  }

  List<Widget> _buildCommandsList() {
    List<Widget> contentList = <Widget>[];
    if (_displayCodes != null) {
      for (String code in _displayCodes!.reversed) {
        if ((_availableCodes == null) || _availableCodes!.contains(code)) {
          Widget? contentEntry;
          if ((code == 'video_tutorial') && _canVideoTutorial) {
            contentEntry = HomeCommandButton(
              title: Localization().getStringEx('widgets.home.app_help.video_tutorial.button.title', 'Video Tutorial'),
              description: Localization().getStringEx('widgets.home.app_help.video_tutorial.button.description', 'Play video tutorial to learn great new features.'),
              favorite: HomeFavorite(code, category: widget.favoriteId),
              onTap: _onVideoTutorial,
            );
          }
          else if ((code == 'feedback') && _canFeedback) {
            contentEntry = HomeCommandButton(
              title: Localization().getStringEx('widgets.home.app_help.feedback.button.title', 'Provide Feedback'),
              description: Localization().getStringEx('widgets.home.app_help.feedback.button.description', 'Enjoying the app? Missing something? The University of Illinois Smart, Healthy Communities Initiative needs your ideas and input. Thank you!'),
              favorite: HomeFavorite(code, category: widget.favoriteId),
              onTap: _onFeedback,
            );
          }
          else if ((code == 'faqs') && _canFAQs) {
            contentEntry = HomeCommandButton(
              title: Localization().getStringEx('widgets.home.app_help.faqs.button.title', 'FAQs'),
              description: Localization().getStringEx('widgets.home.app_help.faqs.button.description', 'Check your question in frequently asked questions.'),
              favorite: HomeFavorite(code, category: widget.favoriteId),
              onTap: _onFAQs,
            );
          }

          if (contentEntry != null) {
            if (contentList.isNotEmpty) {
              contentList.add(Container(height: 6,));
            }
            contentList.add(contentEntry);
          }
        }
      }

    }
   return contentList;
  }

  Set<String>? _buildAvailableCodes() => JsonUtils.setStringsValue(FlexUI()['home.app_help']);

  void _updateAvailableCodes() {
    Set<String>? availableCodes = JsonUtils.setStringsValue(FlexUI()['home.app_help']);
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
      List<String>? fullContent = JsonUtils.listStringsValue(FlexUI().contentSourceEntry('home.app_help'));
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

  bool get _canVideoTutorial => StringUtils.isNotEmpty(Config().videoTutorialUrl);

  void _onVideoTutorial() {
    Analytics().logSelect(target: "HomeAppHelpWidget: Video Tutorial");
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widgets.home.app_help.video_tutorial.label.offline', 'Video Tutorial not available while offline.'));
    }
    else if (_canVideoTutorial) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => SettingsVideoTutorialPanel()));
    }
  }

  bool get _canFeedback => StringUtils.isNotEmpty(Config().feedbackUrl);

  void _onFeedback() {
    Analytics().logSelect(target: "HomeAppHelpWidget: Feebdack");
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widgets.home.app_help.feedback.label.offline', 'Providing a Feedback is not available while offline.'));
    }
    else if (_canFeedback) {
      String email = Uri.encodeComponent(Auth2().email ?? '');
      String name =  Uri.encodeComponent(Auth2().fullName ?? '');
      String phone = Uri.encodeComponent(Auth2().phone ?? '');
      String feedbackUrl = "${Config().feedbackUrl}?email=$email&phone=$phone&name=$name";

      String? panelTitle = Localization().getStringEx('widgets.home.app_help.feedback.panel.title', 'PROVIDE FEEDBACK');
      Navigator.push(
          context, CupertinoPageRoute(builder: (context) => WebPanel(url: feedbackUrl, title: panelTitle,)));
    }
  }

  bool get _canFAQs => StringUtils.isNotEmpty(Config().faqsUrl);

  void _onFAQs() {
    Analytics().logSelect(target: "HomeAppHelpWidget: FAQs");

    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widgets.home.app_help.faqs.label.offline', 'FAQs is not available while offline.'));
    }
    else if (_canFAQs) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(
        url: Config().faqsUrl,
        title: Localization().getStringEx('widgets.home.app_help.faqs.panel.title', 'FAQs'),
      )));
    }
  }

}

