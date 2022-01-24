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

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/deep_link.dart' as rokwire_deeplink;

class DeepLink extends rokwire_deeplink.DeepLink {
  
  // Singletone Factory
  
  @protected
  DeepLink.internal() : super.internal();

  factory DeepLink() {
    return ((rokwire_deeplink.DeepLink.instance is DeepLink) ? (rokwire_deeplink.DeepLink.instance as DeepLink) : (rokwire_deeplink.DeepLink.instance = DeepLink.internal()));
  }

  @override
  String? get appScheme => 'edu.illinois.rokwire';
  
  @override
  String? get appHost => 'rokwire.illinois.edu';
}
