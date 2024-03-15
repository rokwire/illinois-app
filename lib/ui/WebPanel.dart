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

import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'package:rokwire_plugin/ui/panels/web_panel.dart' as rokwire;

class WebPanel extends rokwire.WebPanel implements AnalyticsPageName, AnalyticsPageAttributes {
  final String? analyticsName;
  final Map<String, dynamic>? analyticsSource;

  WebPanel({Key? key, String? url, String? title, this.analyticsName, this.analyticsSource, bool showTabBar = true}) :
    super(key: key, url: url, title: title, headerBar: HeaderBar(title: title), tabBar: showTabBar ? uiuc.TabBar() : null);

  @override
  String? get analyticsPageName {
    return analyticsName;
  }

  @override
  Map<String, dynamic> get analyticsPageAttributes {
    return {
      Analytics.LogAttributeUrl : url,
      Analytics.LogAttributeSource: analyticsSource,
    };
  }

  @protected
  Widget buildOfflineStatus(BuildContext context) {
    return buildStatus(context,
        title: Localization().getStringEx("panel.web.offline.title", "Web Content Not Available"),
        message: Localization().getStringEx("panel.web.offline.message", "You need to be online in order to access web content. Please check your Internet connection."),
    );
  }

  @protected
  Widget buildTrackingDisabledStatus(BuildContext context) {
    return buildStatus(context,
        title: Localization().getStringEx("panel.web.tracking_disabled.title", "Web Content Blocked"),
        message: sprintf(Localization().getStringEx("panel.web.tracking_disabled.message", "You have opted to deny cookie usage for web content in this app, therefore we have blocked access to web sites. If you change your mind, change your preference <a href='%s'>here</a>. Your phone Settings may also need to have Privacy > Tracking enabled."), [appSettingsUrl]),
    );
  }
}

