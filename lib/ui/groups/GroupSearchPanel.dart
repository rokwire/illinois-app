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
import 'package:flutter/material.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';

class GroupsSearchPanel extends StatefulWidget {
  @override
  _GroupsSearchPanelState createState() => _GroupsSearchPanelState();
}

class _GroupsSearchPanelState extends State<GroupsSearchPanel> {
  TextEditingController _textEditingController = TextEditingController();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx("panel.groups_search.header.title", "Search"),
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0),
        ),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(left: 16),
            color: Colors.white,
            height: 48,
            child: Row(
              children: <Widget>[
                Flexible(
                    child:
                    Semantics(
                      label: Localization().getStringEx('panel.groups_search.field.search.title', 'Search'),
                      hint: Localization().getStringEx('panel.groups_search.field.search.hint', ''),
                      textField: true,
                      excludeSemantics: true,
                      child: TextField(
                        controller: _textEditingController,
                        onChanged: (text) => _onTextChanged(text),
                        onSubmitted: (_) => _onTapSearch(),
                        autofocus: true,
                        cursorColor: Styles().colors.fillColorSecondary,
                        keyboardType: TextInputType.text,
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: Styles().fontFamilies.regular,
                            color: Styles().colors.textBackground),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    )
                ),
                Semantics(
                    label: Localization().getStringEx('panel.groups_search.button.clear.title', 'Clear'),
                    hint: Localization().getStringEx('panel.groups_search.button.clear.hint', ''),
                    button: true,
                    excludeSemantics: true,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: GestureDetector(
                        onTap: _onTapClear,
                        child: Image.asset(
                          'images/icon-x-orange.png',
                          width: 25,
                          height: 25,
                        ),
                      ),
                    )
                ),
                Semantics(
                  label: Localization().getStringEx('panel.groups_search.button.search.title', 'Search'),
                  hint: Localization().getStringEx('panel.groups_search.button.search.hint', ''),
                  button: true,
                  excludeSemantics: true,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: _onTapSearch,
                      child: Image.asset(
                        'images/icon-search.png',
                        color: Styles().colors.fillColorSecondary,
                        width: 25,
                        height: 25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 24),
            child: Text("TBD",
              style: TextStyle(
                  fontSize: 16,
                  fontFamily: Styles().fontFamilies.regular,
                  color: Styles().colors.textBackground),
            ),
          ),
          _buildListViewWidget()
        ],
      ),
    );
  }

  Widget _buildListViewWidget() {
    //TBD
    return Container();
  }

  void _onTapSearch(){
    //TBD
  }

  void _onTapClear(){
    //TBD
  }

  void _onTextChanged(String text){
    //TBD
  }
}
