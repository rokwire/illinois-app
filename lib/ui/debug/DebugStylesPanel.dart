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
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DebugStylesPanel extends StatefulWidget {
  _DebugStylesPanelState createState() => _DebugStylesPanelState();
}

class _DebugStylesPanelState extends State<DebugStylesPanel> implements NotificationsListener {

  TextEditingController? _debugContentController;
  TextEditingController? _contentContentController;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Styles.notifyChanged
    ]);
    _contentContentController = TextEditingController(text: JsonUtils.encode(Styles().contentMap, prettify: true) ?? '');
    _debugContentController = TextEditingController(text: JsonUtils.encode(Styles().debugMap, prettify: true) ?? '');
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _contentContentController?.dispose();
    _debugContentController?.dispose();

    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Styles.notifyChanged) {
      _contentContentController!.text = JsonUtils.encode(Styles().contentMap, prettify: true) ?? '';
      _debugContentController!.text = JsonUtils.encode(Styles().debugMap, prettify: true) ?? '';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors!.surface,
      appBar: HeaderBar( title: "Styles", ),
      body: Padding(padding: EdgeInsets.all(16), child:
        SafeArea(child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Content:', style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.fillColorPrimary)),
            Expanded(child:
              TextField(
                maxLines: 1024,
                controller: _contentContentController,
                readOnly: true,
                autocorrect: false,
                decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
                style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground,),
              ),
            ),
            Container(height: 8,),
            Text('Debug:', style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.fillColorPrimary)),
            Expanded(child:
              TextField(
                maxLines: 1024,
                controller: _debugContentController,
                autocorrect: false,
                decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
                style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground,),
              ),
            ),
            Padding(padding: EdgeInsets.only(top: 16, bottom: 16), child:
              RoundedButton(label: "Apply", backgroundColor: Styles().colors?.white, fontSize: 16.0, textColor: Styles().colors?.fillColorPrimary, borderColor: Styles().colors?.fillColorPrimary, onTap: _onTapApply),
            ),
          ],),
        ),
      ),
    );
  }

  void _onTapApply() {
    String? debugContent = _debugContentController?.text;
    if (StringUtils.isNotEmpty(debugContent)) {
      Map<String, dynamic>? debugStyles = JsonUtils.decodeMap(debugContent);
      if (debugStyles != null) {
        Styles().debugMap = debugStyles;
      }
      else {
        AppAlert.showDialogResult(context, 'Invalid JSON content');
      }
    }
    else {
      Styles().debugMap = null;
    }
  }
}


