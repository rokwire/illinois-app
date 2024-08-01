// Copyright 2024 Board of Trustees of the University of Illinois.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/cupertino.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:neom/service/Assistant.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AssistantFaqsContentWidget extends StatefulWidget {
  AssistantFaqsContentWidget();

  @override
  State<AssistantFaqsContentWidget> createState() => _AssistantFaqsContentWidgetState();
}

class _AssistantFaqsContentWidgetState extends State<AssistantFaqsContentWidget> implements NotificationsListener {

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Assistant.notifyFaqsContentChanged,
    ]);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
        child: Padding(
            padding: EdgeInsets.all(20),
            child: SafeArea(child: SingleChildScrollView(
                child: HtmlWidget(_faqsContent,
                    onTapUrl: (url) {
                      _launchUrl(url);
                      return true;
                    },
                    textStyle: Styles().textStyles.getTextStyle('widget.detail.light.regular'),
                    customStylesBuilder: (element) {
                      if (element.localName == "h3") {
                        String fontFamilyName = Styles().textStyles.getTextStyle('widget.detail.regular.fat')?.fontFamily.toString() ?? '';
                        String fontSize = Styles().textStyles.getTextStyle('widget.detail.regular.fat')?.fontSize.toString() ?? '0';
                        return {'font-size': '${fontSize}px', 'font-family': fontFamilyName};
                      } else {
                        return null;
                      }
                    })))));
  }

  void _launchUrl(String? url) async {
    if (StringUtils.isNotEmpty(url)) {
      if (StringUtils.isNotEmpty(url)) {
        Uri? uri = Uri.tryParse(url!);
        if ((uri != null) && (await canLaunchUrl(uri))) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }

  String get _faqsContent {
    String? faqs = Assistant().faqs;
    if (StringUtils.isEmpty(faqs)) {
      faqs = Localization().getStringEx('panel.assistant.faqs.missing.msg', 'No FAQs available.');
    }
    return faqs!;
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == Assistant.notifyFaqsContentChanged) {
      setStateIfMounted((){});
    }
  }
}
