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
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/ui/widgets/flexcontent_widget.dart' as rokwire;

class FlexContentWidget extends rokwire.FlexContentWidget {
  FlexContentWidget({Key? key, String? assetsKey, Map<String, dynamic>? jsonContent, void Function(BuildContext context)? onClose }) :
    super(key: key, assetsKey: assetsKey, jsonContent: jsonContent, onClose: onClose);

  static FlexContentWidget? fromAssets(dynamic assetsKey, { void Function(BuildContext context)? onClose }) {
    Map<String, dynamic>? jsonContent = JsonUtils.mapValue(Assets()[assetsKey]);
    return (jsonContent != null) ? FlexContentWidget(assetsKey: assetsKey, jsonContent: jsonContent, onClose: onClose) : null;
  }

  @override
  void onTapButton(BuildContext context, Map<String, dynamic> button) {
    Analytics().logSelect(target: "Flex Content: ${JsonUtils.stringValue(button['title'])}");
    super.onTapButton(context, button);
  }

  @protected
  void launchInternal(BuildContext context, String url, { String? title }) =>
    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => WebPanel(url: url, title: title)));

  @override
  String get closeButtonLabel => Localization().getStringEx("widget.flex_content.button.close.label", "Close");
  
  @override
  String get closeButtonHint => Localization().getStringEx("widget.flex_content.button.close.hint", "");

  @override
  String? get closeButtonAsset => 'images/close-orange.png';

  @override
  void onTapClose(rokwire.FlexContentWidgetState state) {
    Analytics().logSelect(target: "Flex Content: Close");
    super.onTapClose(state);
  }
}
