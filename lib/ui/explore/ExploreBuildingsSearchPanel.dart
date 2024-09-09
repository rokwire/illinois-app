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
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/ui/explore/ExploreBuildingDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';


class ExploreBuildingsSearchPanel extends StatefulWidget {

  ExploreBuildingsSearchPanel({Key? key}) : super(key: key);

  @override
  _ExploreBuildingsSearchPanelState createState() => _ExploreBuildingsSearchPanelState();
}

class _ExploreBuildingsSearchPanelState extends State<ExploreBuildingsSearchPanel> {

  ScrollController _scrollController = ScrollController();
  TextEditingController _searchTextController = TextEditingController();
  FocusNode _searchTextNode = FocusNode();

  List<Building>? _buildings;
  String? _buildingsErrorText;
  int? _totalBuildingsCount;

  bool _searching = false;

  String? _searchText;

  @override
  void initState() {
    _searchTextController.text = '';

    super.initState();
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    _searchTextNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    PopScopeFix(onBack: _onHeaderBarBack, child: _buildScaffoldContent());

  Widget _buildScaffoldContent() =>
      Scaffold(
        appBar: HeaderBar(
          title: "Search",
          onLeading: _onHeaderBarBack,
        ),
        body: _buildPanelContent(),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: uiuc.TabBar(),
      );

  Widget _buildPanelContent() =>
    SingleChildScrollView(scrollDirection: Axis.vertical, controller: _scrollController, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Container(color: Styles().colors.white, child:
          _buildSearchBar(),
        ),
        _buildResultContent()
      ],),
      );

  Widget _buildSearchBar() => Container(decoration: _searchBarDecoration, padding: EdgeInsets.only(left: 16), child:
  Row(children: <Widget>[
    Expanded(child:
    _buildSearchTextField()
    ),
    _buildSearchImageButton('close-circle',
      label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
      hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
      onTap: _onTapClear,
    ),
    _buildSearchImageButton('search',
      label: Localization().getStringEx('panel.search.button.search.title', 'Search'),
      hint: Localization().getStringEx('panel.search.button.search.hint', ''),
      onTap: _onTapSearch,
    ),
  ],),
  );

  Decoration get _searchBarDecoration => BoxDecoration(
      color: Styles().colors.white,
      border: Border(bottom: BorderSide(color: Styles().colors.disabledTextColor, width: 1))
  );

  Widget _buildSearchTextField() => Semantics(
    label: Localization().getStringEx('panel.search.field.search.title', 'Search'),
    hint: Localization().getStringEx('panel.search.field.search.hint', ''),
    textField: true,
    excludeSemantics: true,
    child: TextField(
      controller: _searchTextController,
      focusNode: _searchTextNode,
      onChanged: (text) => _onTextChanged(text),
      onSubmitted: (_) => _onTapSearch(),
      autofocus: true,
      cursorColor: Styles().colors.fillColorSecondary,
      keyboardType: TextInputType.text,
      style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
    ),
  );

  Widget _buildSearchImageButton(String image, {String? label, String? hint, void Function()? onTap}) =>
      Semantics(label: label, hint: hint, button: true, excludeSemantics: true, child:
      InkWell(onTap: onTap, child:
      Padding(padding: EdgeInsets.all(12), child:
      Styles().images.getImage(image, excludeFromSemantics: true),
      ),
      ),
      );

  Widget _buildResultContent() {
    if (_searching) {
      return _buildLoadingContent();
    }
    else if (StringUtils.isEmpty(_searchText)) {
      return Container();
    }

    else if (_buildings == null) {
      return _buildMessageContent(_buildingsErrorText ?? Localization().getStringEx('logic.general.unknown_error', 'Unknown Error Occurred'),
          title: 'Failed'
      );
    }
    else if (_buildings?.length == 0) {
      return _buildMessageContent("There are no buildings matching the search text.");
    }
    else {
      return _buildListContent();
    }
  }

  Widget _buildListContent() {
    List<Widget> cardsList = <Widget>[];
    for (Building building in _buildings!) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: 8), child:
          ExploreCard(explore: building, onTap: () => _onTapBuilding(building), showTopBorder: true),
      ),);
    }
    return Padding(padding: EdgeInsets.all(8), child:
    Column(children:  cardsList,)
    );
  }

  Widget _buildLoadingContent() => Padding(padding: EdgeInsets.only(left: 32, right: 32, top: _screenHeight / 4, bottom: 3 * _screenHeight / 4), child:
  Center(child:
  CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
  ),
  );

  Widget _buildMessageContent(String message, { String? title }) =>
      Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
      Column(children: [
        (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
        Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
      ],),
      );

  double get _screenHeight => MediaQuery.of(context).size.height;

  void _onTapBuilding(Building building) {
    Analytics().logSelect(target: 'Building: ${building.name}');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreBuildingDetailPanel(building: building,)));
  }

  void _onTextChanged(String text) {
    if ((text.trim() != _searchText) && mounted) {
      setState(() {
        _searchText = null;
        _totalBuildingsCount = null;
        _buildings = null;
        _buildingsErrorText = null;
      });
    }
  }

  void _onTapClear() {
    Analytics().logSelect(target: "Clear");
    if (StringUtils.isEmpty(_searchTextController.text.trim())) {
      Navigator.of(context).pop("");
    }
    else if (mounted) {
      _searchTextController.text = '';
      _searchTextNode.requestFocus();
      setState(() {
        _searchText = null;
        _totalBuildingsCount = null;
        _buildings = null;
        _buildingsErrorText = null;
      });
    }
  }

  void _onTapSearch() {
    Analytics().logSelect(target: "Search");

    String searchText = _searchTextController.text.trim();
    if (searchText.isNotEmpty) {
      FocusScope.of(context).requestFocus(FocusNode());
      _search(searchText);
    }
  }
  void _onHeaderBarBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    Navigator.of(context).pop((0 < (_totalBuildingsCount ?? 0)) ? _searchText : null);
  }

  Future<void> _search(String searchText) async {
    if (searchText.isNotEmpty) {
      setState(() {
        _searchText = searchText;
        _searching = true;
      });
      List<Building>? buildings = await Gateway().searchBuildings(text: searchText);
      if (mounted) {
        setState(() {
          _searching = false;
          if (buildings != null) {
            _buildings = buildings;
          }
        });
      }
    }
  }

}