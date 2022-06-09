import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeToutWidget.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Browse2Panel extends StatefulWidget {

  Browse2Panel();

  @override
  _Browse2PanelState createState() => _Browse2PanelState();
}

class _Browse2PanelState extends State<Browse2Panel> with AutomaticKeepAliveClientMixin<Browse2Panel> implements NotificationsListener {

  List<String>? _contentCodes;
  Set<String> _expandedCodes = <String>{};

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      HomeToutWidget.notifyImageUpdate,
      Localization.notifyStringsUpdated,
      Styles.notifyChanged,
    ]);
    
    _contentCodes = JsonUtils.listStringsValue(FlexUI()['browse2']);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;


  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateContentCodes();
    } 
    else if((name == Auth2UserPrefs.notifyFavoritesChanged) ||
      (name == HomeToutWidget.notifyImageUpdate) ||
      (name == Localization.notifyStringsUpdated) ||
      (name == Styles.notifyChanged))
    {
      setState(() { });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.browse.label.title', 'Browse')),
      body: Column(children: <Widget>[
        Expanded(child:
          SingleChildScrollView(child:
            Column(children: _buildContentList(),)
          )
        ),
      ]),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: null,
    );
  }

  List<Widget> _buildContentList() {
    List<Widget> contentList = <Widget>[];

    String? toutImageUrl = Storage().homeToutImageUrl;
    if (toutImageUrl != null) {
      contentList.add(
        Image.network(toutImageUrl, semanticLabel: 'tout', loadingBuilder:(  BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          double imageWidth = MediaQuery.of(context).size.width;
          double imageHeight = imageWidth * 810 / 1080;
          return (loadingProgress != null) ? Container(color: Styles().colors?.fillColorPrimary, width: imageWidth, height: imageHeight, child:
            Center(child:
              CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors?.white), ) 
            ),
          ) : child;
        })
      );
    }

    List<Widget> sectionsList = <Widget>[];
    if (_contentCodes != null) {
      for (String code in _contentCodes!) {
        sectionsList.add(_BrowseSection(sectionId: code,
          expanded: _isExpanded(code),
          onExpand: () => _toggleExpanded(code),));
      }
    }

    if (sectionsList.isNotEmpty) {
      contentList.add(
        HomeSlantWidget(
          title: 'App Sections' /* TBD: Localization */,
          titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
          child: Column(children: sectionsList,),
        )    
      );
    }
    
    return contentList;
  }

  void _updateContentCodes() {
    List<String>?  contentCodes = JsonUtils.listStringsValue(FlexUI()['browse2']);
    if ((contentCodes != null) && !DeepCollectionEquality().equals(_contentCodes, contentCodes)) {
      if (mounted) {
        setState(() {
          _contentCodes = contentCodes;
        });
      }
    }
  }

  bool _isExpanded(String sectionId) => _expandedCodes.contains(sectionId);

  void _toggleExpanded(String sectionId) {
    if (mounted) {
      setState(() {
        if (_expandedCodes.contains(sectionId)) {
          _expandedCodes.remove(sectionId);
        }
        else {
          _expandedCodes.add(sectionId);
        }
      });
    }
  }
}

class _BrowseSection extends StatelessWidget {

  final String sectionId;
  final bool expanded;
  final void Function()? onExpand;
  final List<String>? _entriesCodes;
  final String? _favoriteCategory;

  _BrowseSection({Key? key, required this.sectionId, this.expanded = false, this.onExpand}) :
    _entriesCodes = JsonUtils.listStringsValue(FlexUI()['browse2.$sectionId']),
    _favoriteCategory = (FlexUI().contentSourceEntry('home.$sectionId') != null) ? sectionId : null,
    super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];
    contentList.add(_buildHeading());
    contentList.add(_buildEntries());
    return Column(children: contentList,);
  }

  Widget _buildHeading() {
    return Padding(padding: EdgeInsets.only(bottom: 4), child:
      InkWell(onTap: _onTapExpand, child:
        Container(
          decoration: BoxDecoration(color: Styles().colors?.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),),
          padding: EdgeInsets.only(left: 16),
          child: Column(children: [
            Row(children: [
              Expanded(child:
                Padding(padding: EdgeInsets.only(top: 16), child:
                  Text(_title, style: TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary))
                )
              ),
              _hasContent ?
                _BrowseFavoriteButton(sectionId: sectionId, selected: _isSectionFavorite, onToggle: _toggleSectionFavorite,) :
                Container()
            ],),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child:
                Padding(padding: EdgeInsets.only(bottom: 16), child:
                  Text(_description, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textSurface))
                )
              ),
              Semantics(label: expanded ? 'Colapse' : 'Expand' /* TBD: Localization */, button: true, child:
                  Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
                    SizedBox(width: 18, height: 18, child:
                      Center(child:
                        _hasContent ? (
                          expanded ?
                            Image.asset('images/arrow-up-orange.png', excludeFromSemantics: true) :
                            Image.asset('images/arrow-down-orange.png', excludeFromSemantics: true)
                        ) : Container()
                      ),
                    )
                  ),
              ),
            ],)
          ],)
        ),
      ),
    );
  }

  Widget _buildEntries() {
      List<Widget> entriesList = <Widget>[];
      if (expanded && (_entriesCodes != null)) {
        for (String code in _entriesCodes!) {
          entriesList.add(_BrowseEntry(
            sectionId: sectionId,
            entryId: code,
            favoriteCategory: _favoriteCategory,
          ));
        }
      }
      return entriesList.isNotEmpty ? Padding(padding: EdgeInsets.only(left: 24), child:
        Column(children: entriesList,)
      ) : Container();
  }

  String get _title => StringUtils.capitalize(sectionId, allWords: true, splitDelimiter: '_', joinDelimiter: ' ');
  String get _description => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit est et ante maximus.';

  bool get _hasContent => (_entriesCodes?.isNotEmpty ?? false);

  void _onTapExpand() {
    if (_hasContent && (onExpand != null)) {
      onExpand!();
    }
  }

  bool? get _isSectionFavorite {
    int favCount = 0, unfavCount = 0;
    if (_entriesCodes?.isNotEmpty ?? false) {
      for (String code in _entriesCodes!) {
        if (Auth2().prefs?.isFavorite(HomeFavorite(code, category: _favoriteCategory)) ?? false) {
          favCount++;
        }
        else {
          unfavCount++;
        }
      }
      if ((favCount == _entriesCodes!.length)) {
        return true;
      }
      else if (unfavCount == _entriesCodes!.length) {
        return false;
      }
    }
    return null;
  }

  void _toggleSectionFavorite() {
    Analytics().logSelect(target: "Favorite: $sectionId");
    if (_isSectionFavorite == true) {
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: _favoriteCategory), LinkedHashSet<String>());
    }
    else {
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: _favoriteCategory), LinkedHashSet<String>.from(_entriesCodes?.reversed ?? <String>[]));
    }
  }

}

class _BrowseEntry extends StatelessWidget {

  final String sectionId;
  final String entryId;
  final String? favoriteCategory;

  _BrowseEntry({required this.sectionId, required this.entryId, this.favoriteCategory});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: 4), child:
      InkWell(onTap: _onTap, child:
        Container(
          decoration: BoxDecoration(color: Styles().colors?.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),),
          padding: EdgeInsets.zero,
          child: 
            Row(children: [
              _BrowseFavoriteButton(
                sectionId: sectionId,
                entryId: entryId,
                selected: Auth2().prefs?.isFavorite(HomeFavorite(entryId, category: favoriteCategory)) ?? false,
                onToggle: () => Auth2().prefs?.toggleFavorite(HomeFavorite(entryId, category: favoriteCategory))
              ),
              Expanded(child:
                Text(_title, style: TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary)),
              ),
              Padding(padding: EdgeInsets.only(right: 16), child:
                Image.asset('images/chevron-right.png'),
              ),
            ],),
        ),
      ),
    );
  }

  String get _title => StringUtils.capitalize(entryId, allWords: true, splitDelimiter: '_', joinDelimiter: ' ');

  void _onTap() {
    
  }
}

class _BrowseFavoriteButton extends StatelessWidget {

  final String? sectionId;
  final String? entryId;
  final bool? selected;
  final void Function()? onToggle;

  _BrowseFavoriteButton({this.sectionId, this.entryId, this.selected, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
      InkWell(onTap: onToggle, child:
        HomeFavoriteStar(selected: selected, style: HomeFavoriteStyle.Button,)
      ),
    );
  }
}

