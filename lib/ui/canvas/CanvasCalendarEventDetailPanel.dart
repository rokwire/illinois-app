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
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCalendarEventDetailPanel extends StatefulWidget {
  final CanvasCalendarEvent event;
  CanvasCalendarEventDetailPanel({required this.event});

  @override
  _CanvasCalendarEventDetailPanelState createState() => _CanvasCalendarEventDetailPanelState();
}

class _CanvasCalendarEventDetailPanelState extends State<CanvasCalendarEventDetailPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
          context: context,
          titleWidget: Text(Localization().getStringEx('panel.canvas_calendar_event.header.title', 'Calendar Event')!,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0))),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(StringUtils.ensureNotEmpty(widget.event.title),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 22,
                            color: Styles().colors!.fillColorSecondaryTransparent05,
                            fontFamily: Styles().fontFamilies!.medium)))
              ]),
              Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Localization().getStringEx('panel.canvas_calendar_event.calendar.label', 'Calendar:')!,
                        style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)),
                    Expanded(child: Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(StringUtils.ensureNotEmpty(widget.event.contextName), maxLines: 5, overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface))))
                  ])),
              Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Localization().getStringEx('panel.canvas_calendar_event.date_time.label', 'Date & Time:')!,
                        style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)),
                    Expanded(child: Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(StringUtils.ensureNotEmpty(widget.event.displayDateTime), maxLines: 3, overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface))))
                  ]))
            ])));
  }
}
