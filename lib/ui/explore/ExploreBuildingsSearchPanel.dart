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
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Building.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/ui/explore/ExploreBuildingDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';


class ExploreBuildingsSearchPanel extends StatefulWidget {

  final ExploreSelectLocationBuilder? selectLocationBuilder;
  final ExploreSelectCardBuilder? cardBuilder;
  final Position? initialLocationData;

  ExploreBuildingsSearchPanel({super.key, this.cardBuilder, this.selectLocationBuilder, this.initialLocationData});

  @override
  _ExploreBuildingsSearchPanelState createState() => _ExploreBuildingsSearchPanelState();
}

class _ExploreBuildingsSearchPanelState extends State<ExploreBuildingsSearchPanel> {

  ScrollController _scrollController = ScrollController();
  TextEditingController _searchTextController = TextEditingController();
  FocusNode _searchTextNode = FocusNode();

  String? _searchText;
  List<Building>? _buildings;
  bool _searching = false;
  bool _canClear = false;
  bool _canSearch = false;

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
    Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.search_building.header.title', 'Search'),
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
    if (_canClear)
      _buildSearchImageButton('close',
        label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
        hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
        onTap: _onTapClear,
      ),
    if (_canSearch)
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

  Widget _buildSearchTextField() =>
    /* WEB: Unable to type in web TextField with Semantics*
    Semantics(
    label: Localization().getStringEx('panel.search.field.search.title', 'Search'),
    hint: Localization().getStringEx('panel.search.field.search.hint', ''),
    textField: true,
    excludeSemantics: true,
    child:*/ TextField(
      controller: _searchTextController,
      focusNode: _searchTextNode,
      onChanged: (text) => _onTextChanged(text),
      onSubmitted: (_) => _onTapSearch(),
      autofocus: true,
      autocorrect: false,
      cursorColor: Styles().colors.fillColorSecondary,
      keyboardType: TextInputType.text,
      style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
    // ),
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
      return _buildMessageContent(Localization().getStringEx('panel.search_building.result.error.label', 'Failed to search buildings.'),);
    }
    else if (_buildings?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.search_building.result.empty.label', 'No buildings found.'));
    }
    else {
      return _buildListContent();
    }
  }

  Widget _buildListContent() {
    List<Widget> cardsList = <Widget>[];
    for (Building building in _buildings!) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: 8), child:
        _buildListCard(building),
      ),);
    }
    return Padding(padding: EdgeInsets.all(8), child:
      Column(children:  cardsList,)
    );
  }

  Widget _buildListCard(Building building) => widget.cardBuilder?.call(context, building) ??
    ExploreCard(explore: building,
      locationData: widget.initialLocationData,
      selectLocationBuilder: widget.selectLocationBuilder,
      onTap: () => _onTapBuilding(building)
    );

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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreBuildingDetailPanel(
      building: building,
      selectLocationBuilder: widget.selectLocationBuilder,
    )));
  }

  void _onTextChanged(String text) {
    if ((_searchText != null) && (text.trim() != _searchText) && mounted) {
      setState(() {
        _searchText = null;
        _buildings = null;
      });
    }

    bool canSearch = text.isNotEmpty;
    bool canClear = text.isNotEmpty;
    if ((_canSearch != canSearch) || (_canClear != canClear)) {
      setState(() {
        _canSearch = canSearch;
        _canClear = canClear;
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
        _buildings = null;
        _canSearch = false;
        _canClear = false;
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