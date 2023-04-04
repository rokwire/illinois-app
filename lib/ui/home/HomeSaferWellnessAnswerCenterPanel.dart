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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Guide.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeSaferWellnessAnswerCenterPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Styles().colors!.background,
        appBar: HeaderBar(title: Localization().getStringEx("panel.home.safer.wellness_answer_center.header.title", "Answer Center")),
        body: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  _buildEntryCard(
                      title: Localization()
                          .getStringEx('panel.home.safer.wellness_answer_center.contacts.title', 'Contacts for Covid-19 Questions'),
                      description: Localization().getStringEx('panel.home.safer.wellness_answer_center.contacts.description',
                          'Find the right department for your particular question regarding Covid-19 rules, testing, software, etc.'),
                      onTapEntry: _onTapContacts),
                  Container(height: 14),
                  _buildEntryCard(
                      title: Localization().getStringEx('panel.home.safer.wellness_answer_center.faqs.title', 'Building Access FAQs'),
                      description: Localization().getStringEx('panel.home.safer.wellness_answer_center.faqs.description',
                          'See answers to common questions about building access.'),
                      onTapEntry: _onTapFaqs)
                ]))));
  }

  Widget _buildEntryCard({required String title, required String description, GestureTapCallback? onTapEntry}) {
    return Container(
        decoration: BoxDecoration(
            color: Styles().colors!.white,
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4))),
        clipBehavior: Clip.none,
        child: Stack(children: [
          GestureDetector(
              onTap: onTapEntry,
              child: Semantics(
                  button: true,
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                            padding: EdgeInsets.only(right: 17),
                            child: Text(StringUtils.ensureNotEmpty(title),
                                style: Styles().textStyles?.getTextStyle("widget.card.title.medium.extra_fat"))),
                        Container(height: 8),
                        Text(StringUtils.ensureNotEmpty(description),
                            style: Styles().textStyles?.getTextStyle("widget.card.detail.regular")
                        )
                      ])))),
          Container(color: Styles().colors!.accentColor3, height: 4)
        ]));
  }

  void _onTapContacts() {
    Analytics().logSelect(target: 'Contacts for Covid-19 Questions');
    String? contactsGuideId = Config().saferWellness['contacts_guide_id'];
    if (StringUtils.isNotEmpty(contactsGuideId)) {
      _launchGuideDeepLink(contactsGuideId!);
    }
  }

  void _onTapFaqs() {
    Analytics().logSelect(target: 'Building Access FAQs');
    String? faqsGuideId = Config().saferWellness['faqs_guide_id'];
    if (StringUtils.isNotEmpty(faqsGuideId)) {
      _launchGuideDeepLink(faqsGuideId!);
    }
  }

  void _launchGuideDeepLink(String guideId) {
    DeepLink().launchUrl('${Guide().guideDetailUrl}?guide_id=$guideId');
  }
}
