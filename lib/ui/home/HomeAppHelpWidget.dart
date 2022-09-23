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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsVideoTutorialListPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeAppHelpWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeAppHelpWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.app_help.header.title',  'App Help');

  @override
  State<StatefulWidget> createState() => _HomeAppHelpWidgetState();
}

class _HomeAppHelpWidgetState extends HomeCompoundWidgetState<HomeAppHelpWidget> {

  @override String? get favoriteId => widget.favoriteId;
  @override String? get title => HomeAppHelpWidget.title;
  @override String? get emptyMessage => Localization().getStringEx("widget.home.app_help.text.empty.description", "Tap the \u2606 on items in App Help so you can quickly find them here.");

  @override
  Widget? widgetFromCode(String code) {
    if ((code == 'video_tutorials') && _canVideoTutorials) {
      return HomeCommandButton(
        title: ((_videoTutorialsCount > 1) ? Localization().getStringEx('widget.home.app_help.video_tutorials.button.title', 'Video Tutorials') : Localization().getStringEx('widget.home.app_help.video_tutorial.button.title', 'Video Tutorial')),
        description: Localization().getStringEx('widget.home.app_help.video_tutorial.button.description', 'Watch video tutorials to learn about app features.'),
        favorite: HomeFavorite(code, category: widget.favoriteId),
        onTap: _onVideoTutorials,
      );
    }
    else if ((code == 'feedback') && _canFeedback) {
      return HomeCommandButton(
        title: Localization().getStringEx('widget.home.app_help.feedback.button.title', 'Provide Feedback'),
        description: Localization().getStringEx('widget.home.app_help.feedback.button.description', 'Enjoying the app? Missing something? The University of Illinois Smart, Healthy Communities Initiative needs your ideas and input. Thank you!'),
        favorite: HomeFavorite(code, category: widget.favoriteId),
        onTap: _onFeedback,
      );
    }
    else if ((code == 'review') && _canReview) {
      return HomeCommandButton(
        title: Localization().getStringEx('widget.home.app_help.review.button.title', 'Submit Review'),
        description: Localization().getStringEx('widget.home.app_help.review.button.description', 'Rate this app. Tell others what you think.'),
        favorite: HomeFavorite(code, category: widget.favoriteId),
        onTap: _onReview,
      );
    }
    else if ((code == 'faqs') && _canFAQs) {
      return HomeCommandButton(
        title: Localization().getStringEx('widget.home.app_help.faqs.button.title', 'FAQs'),
        description: Localization().getStringEx('widget.home.app_help.faqs.button.description', 'Check your question in frequently asked questions.'),
        favorite: HomeFavorite(code, category: widget.favoriteId),
        onTap: _onFAQs,
      );
    }
    else {
      return null;
    }
  }

  int get _videoTutorialsCount {
    List<dynamic>? videos = Assets()['video_tutorials.videos'];
    return videos?.length ?? 0;
  }

  bool get _canVideoTutorials => (_videoTutorialsCount > 0);

  void _onVideoTutorials() {
    Analytics().logSelect(target: "Video Tutorial", source: widget.runtimeType.toString());
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widget.home.app_help.video_tutorial.label.offline', 'Video Tutorial not available while offline.'));
    }
    else if (_canVideoTutorials) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => SettingsVideoTutorialListPanel()));
    }
  }

  bool get _canFeedback => StringUtils.isNotEmpty(Config().feedbackUrl);

  void _onFeedback() {
    Analytics().logSelect(target: "Feebdack", source: widget.runtimeType.toString());
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widget.home.app_help.feedback.label.offline', 'Providing a Feedback is not available while offline.'));
    }
    else if (_canFeedback) {
      String email = Uri.encodeComponent(Auth2().email ?? '');
      String name =  Uri.encodeComponent(Auth2().fullName ?? '');
      String phone = Uri.encodeComponent(Auth2().phone ?? '');
      String feedbackUrl = "${Config().feedbackUrl}?email=$email&phone=$phone&name=$name";

      String? panelTitle = Localization().getStringEx('widget.home.app_help.feedback.panel.title', 'PROVIDE FEEDBACK');
      Navigator.push(
          context, CupertinoPageRoute(builder: (context) => WebPanel(url: feedbackUrl, title: panelTitle,)));
    }
  }

  bool get _canReview => true;

  void _onReview() {
    Analytics().logSelect(target: "Review", source: widget.runtimeType.toString());
    InAppReview.instance.openStoreListing(appStoreId: Config().appStoreId);
  }

  bool get _canFAQs => StringUtils.isNotEmpty(Config().faqsUrl);

  void _onFAQs() {
    Analytics().logSelect(target: "FAQs", source: widget.runtimeType.toString());

    if (_canFAQs) {
      String url = Config().faqsUrl!;
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else if (UrlUtils.launchInternal(url)){
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(
          url: url, title: Localization().getStringEx('widget.home.app_help.faqs.panel.title', 'FAQs'),
        )));
      }
      else {
        Uri? uri = Uri.tryParse(url);
        if (uri != null) {
          launchUrl(uri);
        }
      }
    }
  }

}

