import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/service/Guide.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/guide/GuideEntryCard.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

class GuideDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final String? guideEntryId;
  GuideDetailPanel({ this.guideEntryId });

  @override
  _GuideDetailPanelState createState() => _GuideDetailPanelState();

  @override
  Map<String, dynamic> get analyticsPageAttributes {
    Map<String, dynamic>? guideEntry = Guide().entryById(guideEntryId);
    return {
      Analytics.LogAttributeGuideId : guideEntryId,
      Analytics.LogAttributeGuideTitle : JsonUtils.stringValue(Guide().entryTitle(guideEntry, stripHtmlTags: true)),
      Analytics.LogAttributeGuide : JsonUtils.stringValue(Guide().entryValue(guideEntry, 'guide')),
      Analytics.LogAttributeGuideCategory :  JsonUtils.stringValue(Guide().entryValue(guideEntry, 'category')),
      Analytics.LogAttributeGuideSection :  JsonUtils.stringValue(Guide().entryValue(guideEntry, 'section')),
    };
  }
}

class _GuideDetailPanelState extends State<GuideDetailPanel> implements NotificationsListener {

  Map<String, dynamic>? _guideEntry;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Guide.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);
    _guideEntry = Guide().entryById(widget.guideEntryId);
    _isFavorite = Auth2().isFavorite(GuideFavorite(id: widget.guideEntryId));
    
    RecentItems().addRecentItem(RecentItem.fromGuideItem(_guideEntry));
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Guide.notifyChanged) {
      setState(() {
        _guideEntry = Guide().entryById(widget.guideEntryId);
      });
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setState(() {
        _isFavorite = Auth2().isFavorite(GuideFavorite(id: widget.guideEntryId));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? headerTitle;
    Widget contentWidget;
    if (_guideEntry != null) {
      headerTitle = JsonUtils.stringValue(Guide().entryValue(_guideEntry, 'header_title'));
      contentWidget = SingleChildScrollView(child:
        SafeArea(child:
          Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children:
              _buildContent()
            ),
            Visibility(visible: Auth2().canFavorite, child:
              Align(alignment: Alignment.topRight, child:
              Semantics(
                label: _isFavorite
                    ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                    : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                hint: _isFavorite
                    ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                    : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                button: true,
                child: GestureDetector(onTap: _onTapFavorite, child:
                  Container(padding: EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 16), child:
                    Image.asset(_isFavorite ? 'images/icon-star-blue.png' : 'images/icon-star-gray-frame-thin.png', excludeFromSemantics: true,)
                  )
            ),),),),
          ],)
        ),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.all(32), child:
        Center(child:
          Text(Localization().getStringEx('panel.guide_detail.label.content.empty', 'Empty guide content'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold),)
        ,)
      );
    }

    return Scaffold(
      appBar: HeaderBar(title: headerTitle),
      body: Column(children: <Widget>[
          Expanded(child:
            contentWidget
          ),
          uiuc.TabBar(),
        ],),
      backgroundColor: Styles().colors!.background,
    );
  }

  List<Widget> _buildContent() {
    List<Widget> contentList = <Widget>[
      _buildHeading(),
      _buildImage(),
      _buildDetails(),
      _buildRelated(),
    ];
    return contentList;
  }

  Widget _buildHeading() {
    List<Widget> contentList = <Widget>[];

    String? category = JsonUtils.stringValue(Guide().entryValue(_guideEntry, 'category'));
    contentList.add(
      Padding(padding: EdgeInsets.only(bottom: 8), child:
        Semantics(hint: "Heading", child:Text(category?.toUpperCase() ?? '', style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold),)),
    ),);

    String? titleHtml = JsonUtils.stringValue(Guide().entryValue(_guideEntry, 'detail_title')) ?? JsonUtils.stringValue(Guide().entryValue(_guideEntry, 'title'));
    if (StringUtils.isNotEmpty(titleHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Html(data: titleHtml,
            onLinkTap: (url, context, attributes, element) => _onTapLink(url),
            style: { "body": Style(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: FontSize(36), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
      ),);
    }
    
    DateTime? date = Guide().isEntryReminder(_guideEntry) ? Guide().reminderDate(_guideEntry) : null;
    if (date != null) {
      String? dateString = AppDateTime().formatDateTime(Guide().reminderDate(_guideEntry), format: 'MMM dd', ignoreTimeZone: true);
      contentList.add(
        Padding(padding: EdgeInsets.zero, child:
          Text(dateString ?? '',
            style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.medium),),
      ),);
    }

    String? descriptionHtml = JsonUtils.stringValue(Guide().entryValue(_guideEntry, 'detail_description')) ?? JsonUtils.stringValue(Guide().entryValue(_guideEntry, 'description'));
    if (StringUtils.isNotEmpty(descriptionHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Html(data: descriptionHtml,
            onLinkTap: (url, context, attributes, element) => _onTapLink(url),
            style: { "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
      ),),);
    }


    List<dynamic>? links = JsonUtils.listValue(Guide().entryValue(_guideEntry, 'links'));
    if (links != null) {
      for (dynamic link in links) {
        if (link is Map) {
          String? text = JsonUtils.stringValue(link['text']);
          String? icon = JsonUtils.stringValue(link['icon']);
          String? url = JsonUtils.stringValue(link['url']);
          Uri? uri = (url != null) ? Uri.tryParse(url) : null;
          bool hasUri = StringUtils.isNotEmpty(uri?.scheme);

          Map<String, dynamic>? location = JsonUtils.mapValue(link['location']);
          Map<String, dynamic>? locationGps = (location != null) ? JsonUtils.mapValue(location['location']) : null;
          bool hasLocation = (locationGps != null) && (locationGps['latitude'] != null) && (locationGps['longitude'] != null);

          if ((text != null) && (hasUri || hasLocation)) {

            contentList.add(Semantics(button: true, child:
              GestureDetector(onTap: () => hasLocation ? _onTapLocation(location) : (hasUri ? _onTapLink(url) : _nop()), child:
                Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    (icon != null) ? Padding(padding: EdgeInsets.only(top: 2), child: Image.network(icon, width: 20, height: 20, excludeFromSemantics: true,),) : Container(width: 24, height: 24),
                    Expanded(child:
                      Padding(padding: EdgeInsets.only(left: 8), child:
                        Text(text, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.regular, decoration: TextDecoration.underline, decorationColor: Styles().colors!.fillColorSecondary))
                      ),
                    ),
                  ],)
              ),)));
          }
        }
      }
    }

    String? costHtml = JsonUtils.stringValue(Guide().entryValue(_guideEntry, 'cost'));
    if (StringUtils.isNotEmpty(costHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.only(top: 15, bottom: 5), child:
          Html(data: costHtml,
            onLinkTap: (url, context, attributes, element) => _onTapLink(url),
            style: { "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
      ),),);
    }

    return (0 < contentList.length) ? 
      Container(color: Styles().colors!.white, padding: EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 16), child:
        Row(children: [
          Expanded(child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList),
          ),
        ],)
      ) :
      Container();
  }

  Widget _buildImage() {
    String? imageUrl = JsonUtils.stringValue(Guide().entryValue(_guideEntry, 'image'));
    Uri? imageUri = (imageUrl != null) ? Uri.tryParse(imageUrl) : null;
    if (StringUtils.isNotEmpty(imageUri?.scheme)) {
      return Stack(alignment: Alignment.bottomCenter, children: [
        Container(color: Styles().colors!.white, padding: EdgeInsets.all(16), child:
          Row(children: [
            Expanded(child:
              Column(children: [
                Image.network(imageUrl!, excludeFromSemantics: true,),
              ]),
            ),
          ],)
        ),
        Container(color: Styles().colors!.background, height: 48, width: MediaQuery.of(context).size.width),
        Container(padding: EdgeInsets.all(16), child:
          Row(children: [
            Expanded(child:
              Column(children: [
                Image.network(imageUrl, excludeFromSemantics: true,),
              ]),
            ),
          ],)
        ),
      ],);
    }
    else {
      return Container();
    }
  }

  Widget _buildDetails() {
    List<Widget> contentList = <Widget>[];

    String? title = JsonUtils.stringValue(Guide().entryValue(_guideEntry, 'sub_details_title'));
    if (StringUtils.isNotEmpty(title)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Text(title ?? '', style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 36, fontFamily: Styles().fontFamilies!.bold),),
      ),);
    }

    String? descriptionHtml = JsonUtils.stringValue(Guide().entryValue(_guideEntry, 'sub_details_description'));
    if (StringUtils.isNotEmpty(descriptionHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Html(data: descriptionHtml,
            onLinkTap: (url, context, attributes, element) => _onTapLink(url),
            style: { "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
      ),),);
    }

    List<dynamic>? subDetails = JsonUtils.listValue(Guide().entryValue(_guideEntry, 'sub_details'));
    if (subDetails != null) {
      for (dynamic subDetail in subDetails) {
        if (subDetail is Map) {
          String? sectionHtml = JsonUtils.stringValue(subDetail['section']);
          if (StringUtils.isNotEmpty(sectionHtml)) {
            contentList.add(
              Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child:
                Html(data: sectionHtml,
                  onLinkTap: (url, context, attributes, element) => _onTapLink(url),
                  style: { "body": Style(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
            ),),);
          }

          List<dynamic>? entries = JsonUtils.listValue(subDetail['entries']);
          if (entries != null) {
            for (dynamic entry in entries) {
              if (entry is Map) {
                String? headingHtml = JsonUtils.stringValue(entry['heading']);
                if (StringUtils.isNotEmpty(headingHtml)) {
                  contentList.add(
                    Padding(padding: EdgeInsets.only(top: 4, bottom: 8), child:
                      Html(data: headingHtml,
                        onLinkTap: (url, context, attributes, element) => _onTapLink(url),
                        style: { "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
                  ),),);
                }

                List<dynamic>? numbers = JsonUtils.listValue(entry['numbers']);
                if (numbers != null) {

                  Map<String, dynamic>? number = JsonUtils.mapValue(entry['number']);
                  String numberTextFormat = ((number != null) ? JsonUtils.stringValue(number['text']) : null) ?? '%d.';
                  Color? numberColor = ((number != null) ? ColorUtils.fromHex(JsonUtils.stringValue(number['color'])) : null) ?? Styles().colors!.textBackground;
                  
                  Map<String, dynamic>? numberFont = (number != null) ? JsonUtils.mapValue(number['font']) : null;
                  double numberFontSize = ((numberFont != null) ? JsonUtils.doubleValue(numberFont['size']) : null) ?? 20;
                  String? numberFontFamilyCode = (numberFont != null) ? JsonUtils.stringValue(numberFont['family']) : null;
                  String? numberFontFamily = Styles().fontFamilies!.fromCode(numberFontFamilyCode) ?? Styles().fontFamilies!.regular;

                  Map<String, dynamic>? numberPadding = (number != null) ? JsonUtils.mapValue(number['padding']) : null;
                  double numberLeftPadding = ((numberPadding != null) ? JsonUtils.doubleValue(numberPadding['left']) : null) ?? 16;
                  double numberRightPadding = ((numberPadding != null) ? JsonUtils.doubleValue(numberPadding['right']) : null) ?? 8;
                  double numberTopPadding = ((numberPadding != null) ? JsonUtils.doubleValue(numberPadding['top']) : null) ?? 2;
                  double numberBottomPadding = ((numberPadding != null) ? JsonUtils.doubleValue(numberPadding['bottom']) : null) ?? 2;

                  for (int numberIndex = 0; numberIndex < numbers.length; numberIndex++) {
                    dynamic numberHtml = numbers[numberIndex];
                    if ((numberHtml is String) && (0 < numberHtml.length)) {
                      contentList.add(
                        Padding(padding: EdgeInsets.only(top: numberTopPadding, bottom: numberBottomPadding), child:
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(padding: EdgeInsets.only(left: numberLeftPadding, right: numberRightPadding), child:
                              Text(sprintf(numberTextFormat, [numberIndex + 1]), style: TextStyle(color: numberColor, fontSize: numberFontSize, fontFamily: numberFontFamily),),),
                            Expanded(child:
                              Html(data: numberHtml,
                              onLinkTap: (url, context, attributes, element) => _onTapLink(url),
                                style: { "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
                            ),),
                          ],)
                        ),
                      );
                    }
                  }
                }

                List<dynamic>? bullets = JsonUtils.listValue(entry['bullets']);
                if (bullets != null) {
                  Map<String, dynamic>? bullet = JsonUtils.mapValue(entry['bullet']);
                  String bulletText = ((bullet != null) ? JsonUtils.stringValue(bullet['text']) : null) ?? '\u2022';
                  Color? bulletColor = ((bullet != null) ? ColorUtils.fromHex(JsonUtils.stringValue(bullet['color'])) : null) ?? Styles().colors!.textBackground;
                  
                  Map<String, dynamic>? bulletFont = (bullet != null) ? JsonUtils.mapValue(bullet['font']) : null;
                  double bulletFontSize = ((bulletFont != null) ? JsonUtils.doubleValue(bulletFont['size']) : null) ?? 20;
                  String? bulletFontFamilyCode = (bulletFont != null) ? JsonUtils.stringValue(bulletFont['family']) : null;
                  String? bulletFontFamily = Styles().fontFamilies!.fromCode(bulletFontFamilyCode) ?? Styles().fontFamilies!.regular;

                  Map<String, dynamic>? bulletPadding = (bullet != null) ? JsonUtils.mapValue(bullet['padding']) : null;
                  double bulletLeftPadding = ((bulletPadding != null) ? JsonUtils.doubleValue(bulletPadding['left']) : null) ?? 16;
                  double bulletRightPadding = ((bulletPadding != null) ? JsonUtils.doubleValue(bulletPadding['right']) : null) ?? 8;
                  double bulletTopPadding = ((bulletPadding != null) ? JsonUtils.doubleValue(bulletPadding['top']) : null) ?? 2;
                  double bulletBottomPadding = ((bulletPadding != null) ? JsonUtils.doubleValue(bulletPadding['bottom']) : null) ?? 2;

                  for (dynamic bulletHtml in bullets) {
                    if ((bulletHtml is String) && (0 < bulletHtml.length)) {
                      contentList.add(
                        Padding(padding: EdgeInsets.only(top: bulletTopPadding, bottom: bulletBottomPadding), child:
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(padding: EdgeInsets.only(left: bulletLeftPadding, right: bulletRightPadding), child:
                              Text(bulletText, style: TextStyle(color: bulletColor, fontSize: bulletFontSize, fontFamily: bulletFontFamily),),),
                            Expanded(child:
                              Html(data: bulletHtml,
                              onLinkTap: (url, context, attributes, element) => _onTapLink(url),
                                style: { "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
                            ),),
                          ],)
                        ),
                      );
                    }
                  }
                }

              }
            }
          }
        }
      }
    }

    List<dynamic>? buttons = JsonUtils.listValue(Guide().entryValue(_guideEntry, 'buttons'));
    if (buttons != null) {
      List<Widget> buttonWidgets = <Widget>[];
      for (dynamic button in buttons) {
        if (button is Map) {
          String? text = JsonUtils.stringValue(button['text']);
          String? url = JsonUtils.stringValue(button['url']);
          Uri? uri = (url != null) ? Uri.tryParse(url) : null;

          if (StringUtils.isNotEmpty(text) && StringUtils.isNotEmpty(uri?.scheme)) {
            buttonWidgets.add(
              Padding(padding: EdgeInsets.only(top: 16), child:
                RoundedButton(label: text ?? '',
                  backgroundColor: Styles().colors!.white,
                  textColor: Styles().colors!.fillColorPrimary,
                  fontFamily: Styles().fontFamilies!.bold,
                  fontSize: 16,
                  borderColor: Styles().colors!.fillColorSecondary,
                  borderWidth: 2,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onTap:() { _onTapLink(url);  }
                )              
              ),
            );
          }
        }
      }
      if (buttonWidgets.isNotEmpty) {
        contentList.add(Padding(padding: EdgeInsets.only(top: 16), child:
          Column(children: buttonWidgets)
        ),);
      }

    }

    return (0 < contentList.length) ?
      Container(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32), child:
        Row(children: [
          Expanded(child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList),
          ),
        ],)
      ) :
      Container();
  }

  Widget _buildRelated() {
    List<Widget>? contentList;
    List<dynamic>? related = JsonUtils.listValue(Guide().entryValue(_guideEntry, 'related'));
    if (related != null) {
      contentList = <Widget>[];
      for (dynamic relatedEntry in related) {
        Map<String, dynamic>? guideEntry;
        if (relatedEntry is Map) {
          guideEntry = JsonUtils.mapValue(relatedEntry);
        }
        else if (relatedEntry is String) {
          guideEntry = Guide().entryById(relatedEntry);
        }
        if (guideEntry != null) {
          contentList.add(
            Padding(padding: EdgeInsets.only(bottom: 16), child:
              GuideEntryCard(guideEntry)
          ),);
        }
      }
    }

    return ((contentList != null) && (0 < contentList.length)) ?
      Container(padding: EdgeInsets.symmetric(vertical: 16), child:
        SectionSlantHeader(title: "Related",
          titleIconAsset: 'images/icon-related.png',
          children: contentList,
      )) :
      Container();

  }

  void _onTapFavorite() {
    String? title = Guide().entryTitle(_guideEntry, stripHtmlTags: true);
    Analytics().logSelect(target: "Favorite: $title");
    Auth2().prefs?.toggleFavorite(GuideFavorite(id: Guide().entryId(_guideEntry)));
  }

  void _onTapLink(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url!);
      }
    }
  }

  void _onTapLocation(Map<String, dynamic>? location) {
    NativeCommunicator().launchMapDirections(jsonData: location);
  }

  void _nop() {
  }

}
