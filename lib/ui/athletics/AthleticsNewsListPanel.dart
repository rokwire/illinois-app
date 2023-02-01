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
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/Sports.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/athletics/AthleticsNewsCard.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'AthleticsNewsArticlePanel.dart';

class AthleticsNewsListPanel extends StatefulWidget {
  final String? sportName;

  AthleticsNewsListPanel({this.sportName});

  @override
  _AthleticsNewsListPanelState createState() => _AthleticsNewsListPanelState();
}

class _AthleticsNewsListPanelState extends State<AthleticsNewsListPanel>{
  static const Color backgroundColor = Color.fromRGBO(19, 41, 75, 0.15);
  bool _loading = false;
  List<News>? _news;
  List<News>? _displayNews;

  //filters
  late List<String> _filters;
  bool _filterOptionsVisible = false;
  int _selectedFilterIndex = 0;
  ScrollController _scrollController = new ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(
          title: Localization().getStringEx('panel.athletics_news_list.header.title', 'News'),
        ),
        body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
            Expanded(child: Stack( children: <Widget>[Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionRibbonHeader(
                      title: Localization().getStringEx("panel.athletics_news_list.title", 'Athletics News'),
                      titleIconKey: 'news'),
                  Container(
                    //height: 28 + 20*(MediaQuery.of(context).textScaleFactor),
                    child:Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                      child: Row( mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget> [
                          _buildFilterLabel(),
                          Expanded(
                            child: Padding(padding: EdgeInsets.only(top: 2),child:_wrapWithBottomBorder(Styles().colors!.fillColorSecondaryVariant!, FilterSelector(
                              title: _filters[_selectedFilterIndex],
                              active: _filterOptionsVisible,
                              expanded: true,
                              onTap: () => _onFilterTypeClicked(),)),
                          ))
                        ]
                      )
                  ),
                ),

                Expanded(
                    child: Container(
                      color: backgroundColor,
                      child: Center(
                        child: Stack(children: <Widget>[
                          _buildListView(),
                          _buildDimmedContainer()
                        ],),
                      ),
                    )
                )
                ],),
              _buildFilterValuesContainer()
              ],),),
            ]),
            backgroundColor: Styles().colors!.background,
            bottomNavigationBar: uiuc.TabBar(),
          );
  }

  @override
  void initState() {
    _initFilter();
    _loadNews();
    super.initState();
  }

  _initFilter() async{
    _filters = [];
   _filters.add(Localization().getStringEx("panel.athletics_news_list.label.all_news.title", "All Athletics News"));
    List<SportDefinition> sportTypes = Sports().sports!;
   sportTypes.forEach((SportDefinition type){
      ListUtils.add(_filters, type.name);
   });
    if (StringUtils.isNotEmpty(widget.sportName)) {
      int initialSelectedFilterIndex = (widget.sportName != null) ? _filters.indexOf(widget.sportName!) : -1;
      if (initialSelectedFilterIndex >= 0 &&
          initialSelectedFilterIndex < _filters.length) {
        _selectedFilterIndex = initialSelectedFilterIndex;
      }
    }
  }

  _loadNews() async{
    _setLoading(true);
    _news = await Sports().loadNews(null,0);
    setState(() {
      _filterNews();
      _setLoading(false);
    });
  }

  //Build UI
  Widget _buildListView() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    int newsCount = (_displayNews != null) ? _displayNews!.length : 0;
    if (newsCount > 0) {
      return ListView.separated(
        separatorBuilder: (context, index) => Divider(color: Colors.transparent,),
        itemCount: newsCount,
        itemBuilder: (context, index) {

          News news = _displayNews![index];

          return StringUtils.isNotEmpty(news.imageUrl) ? ImageSlantHeader(
            imageUrl: news.imageUrl,
            slantImageColor: Styles().colors!.fillColorPrimaryTransparent03,
            slantImageKey:  'slant-dark',
            child: _buildAthleticsNewsCard(news)
          ) : _buildAthleticsNewsCard(news);
        },
        controller: _scrollController,
      );
    } else {
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "No news articles for this team",
              textAlign: TextAlign.center,
            )]);
    }
  }

  Widget _buildAthleticsNewsCard(News news ) {
    return Padding(padding: EdgeInsets.only(top: 16, left: 16, right: 16), child:
      AthleticsNewsCard(news: news, onTap: () => _onNewsTap(news)),
    );
  }

  Widget _buildDimmedContainer() {
    return Visibility(visible: _filterOptionsVisible,
        child: Container(color: Color(0x99000000)));
  }

  Widget _buildFilterValuesContainer() {

    List<String> filterValues = _filters;
    return Visibility(visible: _filterOptionsVisible, child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 95, bottom: 40),
        child: Container(decoration: BoxDecoration(
          color: Styles().colors!.fillColorSecondary,
          borderRadius: BorderRadius.circular(5.0),), child: Padding(
          padding: EdgeInsets.only(top: 2),
          child: Container(color: Colors.white,
            child: ListView.separated(shrinkWrap: true, separatorBuilder: (context, index) =>
                Divider(
                  height: 1,
                  color: Styles().colors!.fillColorPrimaryTransparent03,
                ),
              itemCount: filterValues.length,
              itemBuilder: (context, index) {
                return FilterListItem(title: filterValues[index],
                  selected: (index == _selectedFilterIndex),


                  onTap: () => _onFilterValueClick(index),);
              },
              controller: _scrollController,),),),)),);
  }

  SportDefinition? getSPortTypeByIndex(int index){
    int typeIndex = index - 1; //predefined values which are not sportType
    List<SportDefinition>? sportTypes = Sports().sports;
    if(typeIndex>=0 && typeIndex<sportTypes!.length) {
      return sportTypes[typeIndex];
    }

    return null;
  }

  Widget _buildFilterLabel(){
    return _wrapWithBottomBorder(Styles().colors!.surfaceAccent!,
        Padding(padding: EdgeInsets.only(top: 14),
        child:Text(Localization().getStringEx("panel.athletics_news_list.label.filter_by", "Filter by"),
          style: TextStyle(
          fontSize: 16,
          color: Styles().colors!.textBackground,
        fontFamily: Styles().fontFamilies!.regular
    )),));
  }

  Widget _wrapWithBottomBorder(Color color, Widget child){
    //Use custom width to stretch the filter button to fill the layout (otherwise the mainAxisSize: MainAxisSize.max, don't work)
    return Padding(padding: EdgeInsets.only(right: 4, left: 4),
        child:Container(
            decoration: BoxDecoration(
                border:Border(
                  bottom:
                  BorderSide(
                      color: color,
                      width: 2,
                      style: BorderStyle.solid),
                )),
            child: Padding(padding: EdgeInsets.only( bottom: 6),child: child)));
  }

  _setLoading(bool loading){
    setState(() {
      _loading = loading;
    });
  }

  //Click listeners
  void _onNewsTap(News news) {
    Analytics().logSelect(target: "news: "+news.title!);
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => AthleticsNewsArticlePanel(article: news)));
  }

  void _onFilterTypeClicked() {
    Analytics().logSelect(target: "Filter");
    setState(() {
        _filterOptionsVisible = !_filterOptionsVisible;
    });
  }

  void _onFilterValueClick(int newValueIndex) {
    Analytics().logSelect(target: "Filter: ${_filters[newValueIndex]}") ;
    setState(() {
      _selectedFilterIndex = newValueIndex;
      _filterOptionsVisible = false;
      _filterNews();
    });
  }

  void _filterNews() async{
    switch(_selectedFilterIndex){
      case 0: {
        _displayNews = _news; // "All Athletics News"
        break;
      }

      default: {
          _displayNews = [];
          _loading = true;
          _displayNews = await Sports().loadNews(getSPortTypeByIndex(_selectedFilterIndex)?.shortName ?? null,0);
          setState(() {
            _loading = false;
          });
      }
    }

  }

}

