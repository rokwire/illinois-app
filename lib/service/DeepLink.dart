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

import 'package:illinois/service/NotificationService.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:uni_links/uni_links.dart';

class DeepLink with Service {
  
  static const String ROKWIRE_SCHEME = 'edu.illinois.rokwire';
  static const String ROKWIRE_HOST = 'rokwire.illinois.edu';
  static const String ROKWIRE_URL = '$ROKWIRE_SCHEME://$ROKWIRE_HOST';
  
  static const String notifyUri  = "edu.illinois.rokwire.deeplink.uri";

  static final DeepLink _deepLink = DeepLink._internal();

  factory DeepLink() {
    return _deepLink;
  }

  DeepLink._internal();

  @override
  Future<void> initService() async {

    // 1. Initial Uri
    getInitialUri().then((uri) {
      if (uri != null) {
        NotificationService().notify(notifyUri, uri);
      }
    });

    // 2. Updated uri
    uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        NotificationService().notify(notifyUri, uri);
      }
    });

    await super.initService();
  }

  static bool isRokwireUri(Uri? uri) => (uri?.scheme == ROKWIRE_SCHEME) && (uri?.host == ROKWIRE_HOST);
  static bool isRokwireUrl(String? url) =>  isRokwireUri((url != null) ? Uri.tryParse(url) : null);
  static void launchUrl(String? url) => launchUri((url != null) ? Uri.tryParse(url) : null);

  static void launchUri(Uri? uri) {
    if (uri != null) {
      NotificationService().notify(notifyUri, uri);
    }
  }
}
