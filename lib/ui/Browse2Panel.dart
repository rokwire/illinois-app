import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
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

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      HomeToutWidget.notifyImageUpdate,
      Localization.notifyStringsUpdated,
      Styles.notifyChanged,
    ]);
    
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
    if ((name == FlexUI.notifyChanged) ||
        (name == Auth2UserPrefs.notifyFavoritesChanged) ||
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
    List<String>? sectionsCodes = JsonUtils.listStringsValue(FlexUI()['browse2']);
    if (sectionsCodes != null) {
      for (String code in sectionsCodes) {
        sectionsList.add(_BrowseSection(sectionId: code));
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
}

class _BrowseSection extends StatefulWidget {

  final String sectionId;

  _BrowseSection({required this.sectionId});

  @override
  _BrowseSectionState createState() => _BrowseSectionState();
}

class _BrowseSectionState extends State<_BrowseSection> {

  bool _expanded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];
    contentList.add(_buildHeading());

    return Column(children: contentList,);
  }

  Widget _buildHeading() {
    return Padding(padding: EdgeInsets.only(bottom: 4), child:
      InkWell(onTap: _onExpand, child:
        Container(
          decoration: BoxDecoration(color: Styles().colors?.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),),
          padding: EdgeInsets.only(left: 16),
          child: Column(children: [
            Row(children: [
              Expanded(child:
                Padding(padding: EdgeInsets.only(top: 16), child:
                  Text('${widget.sectionId.toUpperCase()}', style: TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary))
                )
              ),
              _HomeSectionFavoriteButton(sectionId: widget.sectionId,)
            ],),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child:
                Padding(padding: EdgeInsets.only(bottom: 16), child:
                  Text('From academics and sporting events to arts and culture and more.', style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textSurface))
                )
              ),
              Semantics(label: _expanded ? 'Colapse' : 'Expand' /* TBD: Localization */, button: true, child:
                  Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
                    SizedBox(width: 18, height: 18, child:
                      Center(child:
                        _expanded ?
                          Image.asset('images/arrow-up-orange.png', excludeFromSemantics: true) :
                          Image.asset('images/arrow-down-orange.png', excludeFromSemantics: true),
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

  void _onExpand() {
    setState(() {
      _expanded = !_expanded;
    });
  }

}

class _HomeSectionFavoriteButton extends StatelessWidget {

  final String? sectionId;

  _HomeSectionFavoriteButton({this.sectionId});

  @override
  Widget build(BuildContext context) {
    return Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
      InkWell(onTap: () => _onFavorite(context), child:
        HomeFavoriteStar(selected: _isFavorite, style: HomeFavoriteStyle.Button,)
      ),
    );
  }

  bool? get _isFavorite => true;

  void _onFavorite(BuildContext context) {
    Analytics().logSelect(target: "Favorite: $sectionId");
  }
}
