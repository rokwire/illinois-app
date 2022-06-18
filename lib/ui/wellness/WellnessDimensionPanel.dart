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
import 'package:illinois/ui/wellness/WellnessDimensionContentWidget.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WellnessDimensionPanel extends StatefulWidget {
  final Map<String, dynamic>? content;

  WellnessDimensionPanel({this.content});

  @override
  _WellnessDimensionPanelState createState() => _WellnessDimensionPanelState();
}

class _WellnessDimensionPanelState extends State<WellnessDimensionPanel> implements NotificationsListener {
  Map<String, dynamic>? _jsonContent;
  Map<String, dynamic>? _stringsContent;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Assets.notifyChanged]);
    _loadAssetsStrings();
    _loadContent();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  void _loadAssetsStrings() {
    _stringsContent = Assets()['wellness.strings'];
  }

  void _loadContent() {
    if (widget.content != null) {
      _jsonContent = widget.content;
    } else {
      _jsonContent = Assets()['wellness.panels.home'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors!.background,
      appBar: _buildStandardHeaderBar(),
      body: SingleChildScrollView(child: WellnessDimensionContentWidget(content: _jsonContent)),
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  PreferredSizeWidget _buildStandardHeaderBar() {
    String? headerTitleKey = MapPathKey.entry(_jsonContent, 'header.title');
    String headerTitle = Localization().getStringFromKeyMapping(headerTitleKey, _stringsContent)!;
    return PreferredSize(
        preferredSize: Size.fromHeight(132),
        child: AppBar(
          leading: Semantics(
              label: Localization().getStringEx('headerbar.back.title', 'Back'),
              hint: Localization().getStringEx('headerbar.back.hint', ''),
              button: true,
              excludeSemantics: true,
              child: IconButton(
                  icon: Image.asset('images/chevron-left-white.png'),
                  onPressed: () => _onTapBack(),)),
          flexibleSpace: Align(alignment: Alignment.bottomCenter, child: SingleChildScrollView(child:Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              _buildImage(_jsonContent, 'header.image'),
              Padding(
                padding: EdgeInsets.only(top: 12, bottom: 24),
                child: Semantics(label: headerTitle, hint:  Localization().getStringEx("app.common.heading.one.hint","Header 1"), header: true, excludeSemantics: true, child: Text(
                  headerTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24),
                )),
              )
            ],
          ))),
          centerTitle: true,
        ),
      );
  }

  Widget _buildImage(Map<String, dynamic>? json, String key) {
    String? imageName = MapPathKey.entry(json, key);
    if (StringUtils.isEmpty(imageName)) {
      return Container();
    }
    return Image.asset('images/$imageName', excludeFromSemantics: true,);
  }

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }

  /// NotificationListener

  @override
  void onNotification(String name, param) {
    if (name == Assets.notifyChanged) {
      if (mounted) {
        setState(() {
          _loadAssetsStrings();
          _loadContent();
        });
      }
    }
  }
}