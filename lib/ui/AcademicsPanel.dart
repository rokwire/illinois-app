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
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AcademicsPanel extends StatefulWidget {

  AcademicsPanel();

  @override
  _AcademicsPanelState createState() => _AcademicsPanelState();
}

class _AcademicsPanelState extends State<AcademicsPanel> with AutomaticKeepAliveClientMixin<AcademicsPanel> implements NotificationsListener {
  
  @override
  void initState() {
    NotificationService().subscribe(this, [
    ]);

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
  }

  // AutomaticKeepAliveClientMixin
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.academics.header.title', 'Academics')),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(children: <Widget>[
          Expanded(child:
            _buildContent(),
          ),
        ]),
        
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: null,
    );
  }

  // Widgets

  Widget _buildContent() {
      return _buildTBD();
  }

  Widget _buildTBD() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text("Whoops! Nothing to see here.", style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary),),
        Container(height:8),
        Text("Panel content will be filled shortly in the future.", style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
        Expanded(child: Container(), flex: 3),
    ],),);
  }

  Future<void>_onPullToRefresh() async {
  }
}
