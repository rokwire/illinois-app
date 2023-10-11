/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

//TBD: DD - populate the faqs from a resource
class ICardFaqsContentWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ICardFaqsContentWidgetState();
}

class _ICardFaqsContentWidgetState extends State<ICardFaqsContentWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(left: 16, top: 80, right: 16, bottom: 16),
        child: Column(children: [
          _buildFaqEntry(
              question: Localization()
                  .getStringEx('panel.icard.content.faqs.mobile_card.usage.question', 'Where can I use Illini ID on campus?'),
              answer: null),
          _buildFaqEntry(
              question: Localization().getStringEx(
                  'panel.icard.content.faqs.mobile_card.not_working.question', "Why doesn't my mobile access work when I try ot use it?"),
              answer: null),
          _buildFaqEntry(
              question: Localization()
                  .getStringEx('panel.icard.content.faqs.mobile_card.track_locations.question', "Does mobile access track my locations?"),
              answer: null)
        ]));
  }

  Widget _buildFaqEntry({String? question, String? answer}) {
    return InkWell(
        onTap: _onTapQuestion,
        child: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Container(
                decoration: BoxDecoration(color: Styles().colors?.lightGray, borderRadius: BorderRadius.circular(5)),
                padding: EdgeInsets.all(16),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        child: Text(StringUtils.ensureNotEmpty(question),
                            textAlign: TextAlign.start,
                            maxLines: 10,
                            style: Styles().textStyles?.getTextStyle('panel.icard.content.faqs.mobile_card.usage.question'))),
                    Padding(padding: EdgeInsets.only(left: 10), child: Styles().images?.getImage('icon-down-blue') ?? Container())
                  ])
                ]))));
  }

  void _onTapQuestion() {
    //TBD: DD - implement question tap when we know the content
  }
}
