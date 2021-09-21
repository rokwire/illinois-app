import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/service/StudentGuide.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/guide/StudentGuideEntryCard.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentGuideDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final String guideEntryId;
  StudentGuideDetailPanel({ this.guideEntryId });

  @override
  _StudentGuideDetailPanelState createState() => _StudentGuideDetailPanelState();

  @override
  Map<String, dynamic> get analyticsPageAttributes {
    Map<String, dynamic> guideEntry = StudentGuide().entryById(guideEntryId);
    return {
      Analytics.LogAttributeStudentGuideId : guideEntryId,
      Analytics.LogAttributeStudentGuideTitle : AppJson.stringValue(StudentGuide().entryTitle(guideEntry, stripHtmlTags: true)),
      Analytics.LogAttributeStudentGuideCategory :  AppJson.stringValue(StudentGuide().entryValue(guideEntry, 'category')),
      Analytics.LogAttributeStudentGuideSection :  AppJson.stringValue(StudentGuide().entryValue(guideEntry, 'section')),
    };
  }
}

class _StudentGuideDetailPanelState extends State<StudentGuideDetailPanel> implements NotificationsListener {

  Map<String, dynamic> _guideEntry;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      StudentGuide.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);
    _guideEntry = StudentGuide().entryById(widget.guideEntryId);
    _isFavorite = Auth2().isFavorite(StudentGuideFavorite(id: widget.guideEntryId));
    
    RecentItems().addRecentItem(RecentItem.fromStudentGuideItem(_guideEntry));
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == StudentGuide.notifyChanged) {
      setState(() {
        _guideEntry = StudentGuide().entryById(widget.guideEntryId);
      });
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setState(() {
        _isFavorite = Auth2().isFavorite(StudentGuideFavorite(id: widget.guideEntryId));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String headerTitle;
    Widget contentWidget;
    if (_guideEntry != null) {
      headerTitle = AppJson.stringValue(StudentGuide().entryValue(_guideEntry, 'header_title'));
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
                    Image.asset(_isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png', excludeFromSemantics: true,)
                  )
            ),),),),
          ],)
        ),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.all(32), child:
        Center(child:
          Text(Localization().getStringEx('panel.student_guide_detail.label.content.empty', 'Empty guide content'), style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
        ,)
      );
    }

    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(headerTitle ?? '', style: TextStyle(color: Styles().colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
      ),
      body: Column(children: <Widget>[
          Expanded(child:
            contentWidget
          ),
          TabBarWidget(),
        ],),
      backgroundColor: Styles().colors.background,
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

    String category = AppJson.stringValue(StudentGuide().entryValue(_guideEntry, 'category'));
    contentList.add(
      Padding(padding: EdgeInsets.only(bottom: 8), child:
        Semantics(hint: "Heading", child:Text(category?.toUpperCase() ?? '', style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)),
    ),);

    String titleHtml = AppJson.stringValue(StudentGuide().entryValue(_guideEntry, 'detail_title')) ?? AppJson.stringValue(StudentGuide().entryValue(_guideEntry, 'title'));
    if (AppString.isStringNotEmpty(titleHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Html(data: titleHtml,
            onLinkTap: (url, context, attributes, element) => _onTapLink(url),
            style: { "body": Style(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.extraBold, fontSize: FontSize(36), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
      ),);
    }
    
    DateTime date = StudentGuide().isEntryReminder(_guideEntry) ? StudentGuide().reminderDate(_guideEntry) : null;
    if (date != null) {
      String dateString = AppDateTime().formatDateTime(StudentGuide().reminderDate(_guideEntry), format: 'MMM dd', ignoreTimeZone: true);
      contentList.add(
        Padding(padding: EdgeInsets.zero, child:
          Text(dateString ?? '',
            style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.medium),),
      ),);
    }

    String descriptionHtml = AppJson.stringValue(StudentGuide().entryValue(_guideEntry, 'detail_description')) ?? AppJson.stringValue(StudentGuide().entryValue(_guideEntry, 'description'));
    if (AppString.isStringNotEmpty(descriptionHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Html(data: descriptionHtml,
            onLinkTap: (url, context, attributes, element) => _onTapLink(url),
            style: { "body": Style(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
      ),),);
    }


    List<dynamic> links = AppJson.listValue(StudentGuide().entryValue(_guideEntry, 'links'));
    if (links != null) {
      for (dynamic link in links) {
        if (link is Map) {
          String text = AppJson.stringValue(link['text']);
          String icon = AppJson.stringValue(link['icon']);
          String url = AppJson.stringValue(link['url']);
          Uri uri = (url != null) ? Uri.tryParse(url) : null;
          bool hasUri = AppString.isStringNotEmpty(uri?.scheme);

          Map<String, dynamic> location = AppJson.mapValue(link['location']);
          Map<String, dynamic> locationGps = (location != null) ? AppJson.mapValue(location['location']) : null;
          bool hasLocation = (locationGps != null) && (locationGps['latitude'] != null) && (locationGps['longitude'] != null);

          if ((text != null) && (hasUri || hasLocation)) {

            contentList.add(Semantics(button: true, child:
              GestureDetector(onTap: () => hasLocation ? _onTapLocation(location) : (hasUri ? _onTapLink(url) : _nop()), child:
                Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    (icon != null) ? Padding(padding: EdgeInsets.only(top: 2), child: Image.network(icon, width: 20, height: 20, excludeFromSemantics: true,),) : Container(width: 24, height: 24),
                    Expanded(child:
                      Padding(padding: EdgeInsets.only(left: 8), child:
                        Text(text, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies.regular, decoration: TextDecoration.underline, decorationColor: Styles().colors.fillColorSecondary))
                      ),
                    ),
                  ],)
              ),)));
          }
        }
      }
    }

    return (0 < contentList.length) ? 
      Container(color: Styles().colors.white, padding: EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 16), child:
        Row(children: [
          Expanded(child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList),
          ),
        ],)
      ) :
      Container();
  }

  Widget _buildImage() {
    String imageUrl = AppJson.stringValue(StudentGuide().entryValue(_guideEntry, 'image'));
    Uri imageUri = (imageUrl != null) ? Uri.tryParse(imageUrl) : null;
    if (AppString.isStringNotEmpty(imageUri?.scheme)) {
      return Stack(alignment: Alignment.bottomCenter, children: [
        Container(color: Styles().colors.white, padding: EdgeInsets.all(16), child:
          Row(children: [
            Expanded(child:
              Column(children: [
                Image.network(imageUrl, excludeFromSemantics: true,),
              ]),
            ),
          ],)
        ),
        Container(color: Styles().colors.background, height: 48, width: MediaQuery.of(context).size.width),
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

    String title = AppJson.stringValue(StudentGuide().entryValue(_guideEntry, 'sub_details_title'));
    if (AppString.isStringNotEmpty(title)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Text(title ?? '', style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 36, fontFamily: Styles().fontFamilies.bold),),
      ),);
    }

    String descriptionHtml = AppJson.stringValue(StudentGuide().entryValue(_guideEntry, 'sub_details_description'));
    if (AppString.isStringNotEmpty(descriptionHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Html(data: descriptionHtml,
            onLinkTap: (url, context, attributes, element) => _onTapLink(url),
            style: { "body": Style(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
      ),),);
    }

    List<dynamic> subDetails = AppJson.listValue(StudentGuide().entryValue(_guideEntry, 'sub_details'));
    if (subDetails != null) {
      for (dynamic subDetail in subDetails) {
        if (subDetail is Map) {
          String sectionHtml = AppJson.stringValue(subDetail['section']);
          if (AppString.isStringNotEmpty(sectionHtml)) {
            contentList.add(
              Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child:
                Html(data: sectionHtml,
                  onLinkTap: (url, context, attributes, element) => _onTapLink(url),
                  style: { "body": Style(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
            ),),);
          }

          List<dynamic> entries = AppJson.listValue(subDetail['entries']);
          if (entries != null) {
            for (dynamic entry in entries) {
              if (entry is Map) {
                String headingHtml = AppJson.stringValue(entry['heading']);
                if (AppString.isStringNotEmpty(headingHtml)) {
                  contentList.add(
                    Padding(padding: EdgeInsets.only(top: 4, bottom: 8), child:
                      Html(data: headingHtml,
                        onLinkTap: (url, context, attributes, element) => _onTapLink(url),
                        style: { "body": Style(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
                  ),),);
                }

                List<dynamic> numbers = AppJson.listValue(entry['numbers']);
                if (numbers != null) {

                  Map<String, dynamic> number = AppJson.mapValue(entry['number']);
                  String numberTextFormat = ((number != null) ? AppJson.stringValue(number['text']) : null) ?? '%d.';
                  Color numberColor = ((number != null) ? AppColor.fromHex(AppJson.stringValue(number['color'])) : null) ?? Styles().colors.textBackground;
                  
                  Map<String, dynamic> numberFont = (number != null) ? AppJson.mapValue(number['font']) : null;
                  double numberFontSize = ((numberFont != null) ? AppJson.doubleValue(numberFont['size']) : null) ?? 20;
                  String numberFontFamilyCode = (numberFont != null) ? AppJson.stringValue(numberFont['family']) : null;
                  String numberFontFamily = Styles().fontFamilies.fromCode(numberFontFamilyCode) ?? Styles().fontFamilies.regular;

                  Map<String, dynamic> numberPadding = (number != null) ? AppJson.mapValue(number['padding']) : null;
                  double numberLeftPadding = ((numberPadding != null) ? AppJson.doubleValue(numberPadding['left']) : null) ?? 16;
                  double numberRightPadding = ((numberPadding != null) ? AppJson.doubleValue(numberPadding['right']) : null) ?? 8;
                  double numberTopPadding = ((numberPadding != null) ? AppJson.doubleValue(numberPadding['top']) : null) ?? 2;
                  double numberBottomPadding = ((numberPadding != null) ? AppJson.doubleValue(numberPadding['bottom']) : null) ?? 2;

                  for (int numberIndex = 0; numberIndex < numbers.length; numberIndex++) {
                    dynamic numberHtml = numbers[numberIndex];
                    if ((numberHtml is String) && (0 < numberHtml.length)) {
                      contentList.add(
                        Padding(padding: EdgeInsets.only(top: numberTopPadding, bottom: numberBottomPadding), child:
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(padding: EdgeInsets.only(left: numberLeftPadding, right: numberRightPadding), child:
                              Text(sprintf(numberTextFormat, numberIndex + 1), style: TextStyle(color: numberColor, fontSize: numberFontSize, fontFamily: numberFontFamily),),),
                            Expanded(child:
                              Html(data: numberHtml,
                              onLinkTap: (url, context, attributes, element) => _onTapLink(url),
                                style: { "body": Style(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
                            ),),
                          ],)
                        ),
                      );
                    }
                  }
                }

                List<dynamic> bullets = AppJson.listValue(entry['bullets']);
                if (bullets != null) {
                  Map<String, dynamic> bullet = AppJson.mapValue(entry['bullet']);
                  String bulletText = ((bullet != null) ? AppJson.stringValue(bullet['text']) : null) ?? '\u2022';
                  Color bulletColor = ((bullet != null) ? AppColor.fromHex(AppJson.stringValue(bullet['color'])) : null) ?? Styles().colors.textBackground;
                  
                  Map<String, dynamic> bulletFont = (bullet != null) ? AppJson.mapValue(bullet['font']) : null;
                  double bulletFontSize = ((bulletFont != null) ? AppJson.doubleValue(bulletFont['size']) : null) ?? 20;
                  String bulletFontFamilyCode = (bulletFont != null) ? AppJson.stringValue(bulletFont['family']) : null;
                  String bulletFontFamily = Styles().fontFamilies.fromCode(bulletFontFamilyCode) ?? Styles().fontFamilies.regular;

                  Map<String, dynamic> bulletPadding = (bullet != null) ? AppJson.mapValue(bullet['padding']) : null;
                  double bulletLeftPadding = ((bulletPadding != null) ? AppJson.doubleValue(bulletPadding['left']) : null) ?? 16;
                  double bulletRightPadding = ((bulletPadding != null) ? AppJson.doubleValue(bulletPadding['right']) : null) ?? 8;
                  double bulletTopPadding = ((bulletPadding != null) ? AppJson.doubleValue(bulletPadding['top']) : null) ?? 2;
                  double bulletBottomPadding = ((bulletPadding != null) ? AppJson.doubleValue(bulletPadding['bottom']) : null) ?? 2;

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
                                style: { "body": Style(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
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

    List<dynamic> buttons = AppJson.listValue(StudentGuide().entryValue(_guideEntry, 'buttons'));
    if (buttons != null) {
      List<Widget> buttonWidgets = <Widget>[];
      for (dynamic button in buttons) {
        if (button is Map) {
          String text = AppJson.stringValue(button['text']);
          String url = AppJson.stringValue(button['url']);
          Uri uri = (url != null) ? Uri.tryParse(url) : null;

          if (AppString.isStringNotEmpty(text) && AppString.isStringNotEmpty(uri?.scheme)) {
            buttonWidgets.add(
              Padding(padding: EdgeInsets.only(top: 16), child:
                RoundedButton(label: text,
                  backgroundColor: Styles().colors.white,
                  textColor: Styles().colors.fillColorPrimary,
                  fontFamily: Styles().fontFamilies.bold,
                  fontSize: 16,
                  padding: EdgeInsets.symmetric(horizontal: 32, ),
                  borderColor: Styles().colors.fillColorSecondary,
                  borderWidth: 2,
                  height: 48,
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

    return ((contentList != null) && (0 < contentList.length)) ?
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
    List<Widget> contentList;
    List<dynamic> related = AppJson.listValue(StudentGuide().entryValue(_guideEntry, 'related'));
    if (related != null) {
      contentList = <Widget>[];
      for (dynamic relatedEntry in related) {
        Map<String, dynamic> guideEntry;
        if (relatedEntry is Map) {
          guideEntry = relatedEntry;
        }
        else if (relatedEntry is String) {
          guideEntry = StudentGuide().entryById(relatedEntry);
        }
        if (guideEntry != null) {
          contentList.add(
            Padding(padding: EdgeInsets.only(bottom: 16), child:
              StudentGuideEntryCard(guideEntry)
          ),);
        }
      }
    }

    return ((contentList != null) && (0 < contentList.length)) ?
      Container(padding: EdgeInsets.symmetric(vertical: 16), child:
        SectionTitlePrimary(title: "Related",
          iconPath: 'images/icon-related.png',
          children: contentList,
      )) :
      Container();

  }

  void _onTapFavorite() {
    String title = StudentGuide().entryTitle(_guideEntry, stripHtmlTags: true);
    Analytics.instance.logSelect(target: "Favorite: $title");
    Auth2().prefs?.toggleFavorite(StudentGuideFavorite(id: StudentGuide().entryId(_guideEntry), title: title, ));
  }

  void _onTapLink(String url) {
    if (AppString.isStringNotEmpty(url)) {
      if (AppUrl.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url);
      }
    }
  }

  void _onTapLocation(Map<String, dynamic> location) {
    NativeCommunicator().launchMapDirections(jsonData: location);
  }

  void _nop() {
  }

}
