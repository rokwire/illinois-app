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
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as Core;
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/LocationServices.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';

import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/explore/ExploreConvergeDetailItem.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';

import 'package:illinois/ui/WebPanel.dart';
import 'package:url_launcher/url_launcher.dart';

class ExploreEventDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Event? event;
  final bool previewMode;
  final Core.Position? initialLocationData;
  final String? superEventTitle;
  final String? browseGroupId;

  ExploreEventDetailPanel({this.event, this.previewMode = false, this.initialLocationData, this.superEventTitle, this.browseGroupId});

  @override
  _EventDetailPanelState createState() =>
      _EventDetailPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes {
    return event?.analyticsAttributes;
  }
}

class _EventDetailPanelState extends State<ExploreEventDetailPanel>
  implements NotificationsListener {

  static final double _horizontalPadding = 24;

  //Maps
  Core.Position? _locationData;
  bool _addToGroupInProgress = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      LocationServices.notifyStatusChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    _addRecentItem();
    _locationData = widget.initialLocationData;
    _loadCurrentLocation().then((_){
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    _locationData = Auth2().privacyMatch(2) ? await LocationServices.instance.location : null;
  }

  void _updateCurrentLocation() {
    _loadCurrentLocation().then((_){
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                child: CustomScrollView(
                  scrollDirection: Axis.vertical,
                  slivers: <Widget>[
                    SliverToutHeaderBar(
                      context: context,
                      imageUrl: widget.event!.exploreImageURL,
                      leftTriangleColor: Colors.white
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate(
                          [
                        Stack(
                          children: <Widget>[
                            Container(
                                child: Column(
                                  children: <Widget>[
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        _buildPreviewHeader(),
                                        _exploreHeading(),
                                        Column(
                                          children: <Widget>[
                                            Padding(
                                                padding:
                                                EdgeInsets.symmetric(horizontal: 0),
                                                child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: <Widget>[
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                                                      color: Colors.white,
                                                      child:Column(
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: <Widget>[
                                                          _exploreTitle(),
                                                          _eventSponsor(),
                                                          _exploreDetails(),
                                                          _exploreSubTitle(),
                                                          _exploreContacts()
                                                        ])),
                                                      Container(
                                                        padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                                                        child: Column(children: [
                                                          _exploreDescription(),
                                                          _buildUrlButtons(),
                                                          _buildPreviewButtons(),
                                                          _buildGroupButtons(),
                                                      ],))
                                                    ]
                                                )),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                            )
                          ],
                        )
                      ],addSemanticIndexes:false),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: TabBarWidget(),
      );
  }

  Widget _exploreHeading() {
    String? category = widget.event?.category;
    bool isFavorite = Auth2().isFavorite(widget.event);
    bool starVisible = Auth2().canFavorite;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(left: _horizontalPadding), child: Row(
      children: <Widget>[
        Expanded(child:
          Text(
            (category != null) ? category.toUpperCase() : "",
            style: TextStyle(
                fontFamily: Styles().fontFamilies!.bold,
                fontSize: 14,
                color: Styles().colors!.fillColorPrimary,
                letterSpacing: 1),
          ),
        ),
        Visibility(visible: starVisible, child: Container(child: Padding(padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Analytics.instance.logSelect(target: "Favorite: ${widget.event?.title}");
                  Auth2().prefs?.toggleFavorite(widget.event);
                },
                child: Container(
                  padding: EdgeInsets.only(left: _horizontalPadding,top: 16, bottom: 12),
                  child:Semantics(
                    label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization()
                        .getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                    hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx(
                        'widget.card.button.favorite.on.hint', ''),
                    button: true,
                    child: Image.asset(isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png', excludeFromSemantics: true)
                )))
        )),)
      ],
    ),);
  }

  Widget _exploreTitle() {
    return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                widget.event!.exploreTitle!,
                style: TextStyle(
                    fontSize: 24,
                    color: Styles().colors!.fillColorPrimary),
              ),
            ),
          ],
        ));
  }

  Widget _eventSponsor() {
    String eventSponsorText = widget.event?.sponsor ?? '';
    bool sponsorVisible = AppString.isStringNotEmpty(eventSponsorText);
    return Visibility(visible: sponsorVisible, child: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                eventSponsorText,
                style: TextStyle(
                    fontSize: 16,
                    color: Styles().colors!.textBackground,
                    fontFamily: Styles().fontFamilies!.bold),
              ),
            ),
          ],
        )),)
    ;
  }

  Widget _exploreDetails() {
    List<Widget> details = [];

    Widget? time = _exploreTimeDetail();
    if (time != null) {
      details.add(time);
    }

    Widget? location = _exploreLocationDetail();
    if (location != null) {
      details.add(location);
    }

    Widget? price = _eventPriceDetail();
    if (price != null) {
      details.add(price);
    }

    Widget? privacy = _eventPrivacyDetail();
    if (privacy != null) {
      details.add(privacy);
    }

    Widget? converge = _buildConvergeContent();
    if (converge != null) {
      details.add(converge);
    }

    Widget? superEventLink = _superEventLink();
    if (superEventLink != null) {
      details.add(superEventLink);
    }


    Widget tags = _exploreTags();
    if(tags != null){
      details.add(tags);
    }

    return (0 < details.length)
        ? Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details))
        : Container();
  }

  Widget _divider(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: Container(
        height: 1,
        color: Styles().colors!.fillColorPrimaryTransparent015,
      ),
    );
  }

  Widget? _exploreTimeDetail() {
    String? displayTime = widget.event?.displayDateTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Semantics(
        label: displayTime,
          excludeSemantics: true,
          child:Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Image.asset('images/icon-calendar.png', excludeFromSemantics: true),
                ),
                Expanded(child: Text(displayTime,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies!.medium,
                        fontSize: 16,
                        color: Styles().colors!.textBackground))),
              ],
            ),
          )
      );
    } else {
      return null;
    }
  }

  Widget? _exploreLocationDetail() {
    String locationText = ExploreHelper.getLongDisplayLocation(widget.event, _locationData)??"";
    bool isVirtual = widget.event?.isVirtual ?? false;
    String eventType = isVirtual? Localization().getStringEx('panel.explore_detail.event_type.online', "Online event")! : Localization().getStringEx('panel.explore_detail.event_type.in_person', "In-person event")!;
    bool hasEventUrl = AppString.isStringNotEmpty(widget.event?.location?.description);
    bool isOnlineUnderlined = isVirtual && hasEventUrl;
    BoxDecoration underlineLocationDecoration = BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors!.fillColorSecondary!, width: 1)));
    String iconRes = isVirtual? "images/laptop.png" : "images/location.png" ;
    String locationId = AppString.getDefaultEmptyString(widget.event?.location?.locationId);
    bool isLocationIdUrl = Uri.tryParse(locationId)?.isAbsolute ?? false;
    String value = isVirtual ? locationId : locationText;
    bool isValueVisible = AppString.isStringNotEmpty(value) && (!isVirtual || !isLocationIdUrl);
    return GestureDetector(
        onTap: _onLocationDetailTapped,
        child: Semantics(
          label: "$eventType, $locationText",
          hint: isVirtual ? Localization().getStringEx('panel.explore_detail.button.virtual.hint', 'Double tap to open link') : Localization().getStringEx('panel.explore_detail.button.directions.hint', ''),
          button: true,
          excludeSemantics: true,
          child:Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child:Image.asset(iconRes, excludeFromSemantics: true),
                ),
                Container(decoration: (isOnlineUnderlined ? underlineLocationDecoration : null), padding: EdgeInsets.only(bottom: (isOnlineUnderlined ? 2 : 0)), child: Text(eventType,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies!.medium,
                        fontSize: 16,
                        color: Styles().colors!.textBackground)),),
              ]),
              Container(height: 4,),
              Visibility(visible: isValueVisible, child: Container(
                  padding: EdgeInsets.only(left: 30),
                  child: Container(
                      decoration: underlineLocationDecoration,
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text(
                        value,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies!.medium,
                            fontSize: 14,
                            color: Styles().colors!.fillColorPrimary),
                      ))))
            ],)
          )
        ),
      );
  }

  Widget? _eventPrivacyDetail() {
    String privacyText = (widget.event?.isGroupPrivate ?? false)
        ? Localization().getStringEx('panel.explore_detail.label.privacy.private.title', 'Private Event')!
        : Localization().getStringEx('panel.explore_detail.label.privacy.public.title', 'Public Event')!;
    return Semantics(
        label: Localization().getStringEx('panel.explore_detail.label.privacy.title', 'Privacy'),
        value: privacyText,
        excludeSemantics: true,
        child: Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Padding(padding: EdgeInsets.only(left: 1, right: 11), child: Image.asset('images/icon-privacy.png', excludeFromSemantics: true)),
                Expanded(
                    child: Text(privacyText, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)))
              ])
            ])));
  }
  
  Widget? _eventPriceDetail() {
    bool isFree = widget.event?.isEventFree ?? false;
    String priceText =isFree? "Free" : (widget.event?.cost ?? "Free");
    String? additionalDescription = isFree? widget.event?.cost : null;
    bool hasAdditionalDescription = AppString.isStringNotEmpty(additionalDescription);
    if ((priceText != null) && priceText.isNotEmpty) {
      return Semantics(
          label: Localization().getStringEx("panel.explore_detail.label.price.title","Price"),
          value: priceText,
          excludeSemantics: true,
          child:Padding(
            padding: EdgeInsets.only(bottom: 16),
              child:
              Column(children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: 10),
                      child:Image.asset('images/icon-cost.png', excludeFromSemantics: true),
                    ),
                      Expanded(child:Text(priceText,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies!.medium,
                            fontSize: 16,
                            color: Styles().colors!.textBackground))),

                    ]),
                    !hasAdditionalDescription? Container():
                    Container(
                      padding: EdgeInsets.only(left: 28),
                      child: Row(children: [
                      Expanded(child:Text(additionalDescription!,
                          style: TextStyle(
                              fontFamily: Styles().fontFamilies!.medium,
                              fontSize: 16,
                              color: Styles().colors!.textBackground))),

                    ])),
                  ],
                ),
          )
        );
    } else {
      return null;
    }
  }

  Widget? _superEventLink() {
    if (AppString.isStringEmpty(widget.superEventTitle)) {
      return null;
    }
    return GestureDetector(onTap: () {
      Navigator.pop(context);
    }, child: Semantics(
        excludeSemantics: true,
        child: Padding(
          padding: EdgeInsets.only(top: 8, bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 10), child: Image.asset('images/chevron-left.png', excludeFromSemantics: true),),
              Expanded(child: Text(widget.superEventTitle ?? '', style: TextStyle(fontFamily: Styles().fontFamilies!.medium,
                  fontSize: 16,
                  color: Styles().colors!.fillColorPrimary,
                  decoration: TextDecoration.underline,
                  decorationColor: Styles().colors!.fillColorSecondary))),
            ],
          ),
        )
    ),);
  }

  Widget _exploreTags(){
    if(widget.event?.tags != null){
      List<String> capitalizedTags = widget.event!.tags!.map((entry)=>'${entry[0].toUpperCase()}${entry.substring(1)}').toList();
      return Padding(
        padding: const EdgeInsets.only(left: 30),
        child: capitalizedTags != null && capitalizedTags.isNotEmpty ? Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: <Widget>[
                Expanded(child: Container(height: 1, color: Styles().colors!.surfaceAccent,),)
              ],),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(Localization().getStringEx('panel.explore_detail.label.related_tags', 'Related Tags:')!),
                Container(width: 5,),
                Expanded(
                  child: Text(capitalizedTags.join(', '),
                    style: TextStyle(
                      fontFamily: Styles().fontFamilies!.regular
                    ),
                  ),
                )
              ],
            ),
          ],
        ) : Container(),
      );
    }
    return Container();
  }

  Widget _exploreSubTitle() {
    String? subTitle = widget.event?.exploreSubTitle;
    if (AppString.isStringEmpty(subTitle)) {
      return Container();
    }
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          subTitle!,
          style: TextStyle(
              fontSize: 20,
              color: Styles().colors!.textBackground),
        ));
  }

  Widget _exploreContacts() {
    if (AppCollection.isCollectionEmpty(widget.event?.contacts)) {
      return Container();
    }
    List<Widget> contactList = [];
    contactList.add(Padding(
        padding: EdgeInsets.only(bottom: 5), child: Text(Localization().getStringEx('panel.explore_detail.label.contacts', 'Contacts:')!)));
    for (Contact? contact in widget.event!.contacts!) {
      String contactDetails = '';
      if (AppString.isStringNotEmpty(contact!.firstName)) {
        contactDetails += contact.firstName!;
      }
      if (AppString.isStringNotEmpty(contact.lastName)) {
        if (AppString.isStringNotEmpty(contactDetails)) {
          contactDetails += ' ';
        }
        contactDetails += contact.lastName!;
      }
      if (AppString.isStringNotEmpty(contact.organization)) {
        contactDetails += ' (${contact.organization})';
      }
      if (AppString.isStringNotEmpty(contact.email)) {
        if (AppString.isStringNotEmpty(contactDetails)) {
          contactDetails += ', ';
        }
        contactDetails += contact.email!;
      }
      if (AppString.isStringNotEmpty(contact.phone)) {
        if (AppString.isStringNotEmpty(contactDetails)) {
          contactDetails += ', ';
        }
        contactDetails += contact.phone!;
      }
      contactList.add(Padding(padding: EdgeInsets.only(bottom: 5), child: Text(contactDetails, style: TextStyle(fontFamily: Styles().fontFamilies!.regular))));
    }
    return Padding(padding: EdgeInsets.only(left: 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contactList));
  }

  Widget _exploreDescription() {
    String? longDescription = widget.event!.exploreLongDescription;
    bool showDescription = AppString.isStringNotEmpty(longDescription);
    if (!showDescription) {
      return Container();
    }
    // Html widget does not handle line breaks symbols \r\n. Replace them with <br/> so that they are properly shown in event description. #692
    String updatedDesc = longDescription!.replaceAll('\r\n', '<br/>');
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Html(
          data: updatedDesc,
          onLinkTap: (url, renderContext, attributes, element) => _launchUrl(url, context: context),
          style: { "body": Style(color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.medium, fontSize: FontSize(16), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
        ));
  }

  Widget _buildPreviewHeader(){
    return !widget.previewMode? Container():
    Container(
      color: Styles().colors!.fillColorPrimaryVariant,
      height: 56,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset('images/selected-orange.png'),
            Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                Localization().getStringEx('panel.explore_detail.label.event_preview', 'Event Preview')!,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: Styles().fontFamilies!.extraBold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUrlButtons() {
    List<Widget> buttons = <Widget>[];
    
    String? titleUrl = widget.event?.titleUrl;
    bool hasTitleUrl = AppString.isStringNotEmpty(titleUrl);

    String? registrationUrl = widget.event?.registrationUrl;
    bool hasRegistrationUrl = AppString.isStringNotEmpty(registrationUrl);

    if (hasTitleUrl) {
      buttons.add(Row(children:<Widget>[
        Expanded(child:
          Padding(padding: EdgeInsets.only(bottom: 6), child:
            ScalableRoundedButton(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              label: Localization().getStringEx('panel.explore_detail.button.visit_website.title', 'Visit website'),
              hint: Localization().getStringEx('panel.explore_detail.button.visit_website.hint', ''),
              backgroundColor: hasRegistrationUrl ? Styles().colors!.background : Colors.white,
              borderColor: hasRegistrationUrl ? Styles().colors!.fillColorPrimary: Styles().colors!.fillColorSecondary,
              rightIcon: hasRegistrationUrl ? Image.asset('images/external-link.png', color: Styles().colors!.fillColorPrimary, colorBlendMode: BlendMode.srcIn) : Image.asset('images/external-link.png'),
              textColor: Styles().colors!.fillColorPrimary,
              onTap: () {
                Analytics.instance.logSelect(target: "Website");
                _onTapWebButton(titleUrl, 'Website');
              },),
      ),),],),);
    }
    
    if (hasRegistrationUrl) {
      buttons.add(Row(children:<Widget>[
        Expanded(child:
        Padding(padding: EdgeInsets.only(bottom: 6), child:
          ScalableRoundedButton(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                label: Localization().getStringEx('panel.explore_detail.button.get_tickets.title', 'Register'),
                hint: Localization().getStringEx('panel.explore_detail.button.get_tickets.hint', ''),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorSecondary,
                rightIcon: Image.asset('images/external-link.png'),
                textColor: Styles().colors!.fillColorPrimary,
                onTap: () {
                Analytics.instance.logSelect(target: "Website");
                  _onTapGetTickets(registrationUrl);
                },),
      ),),],),);
    }

    return (0 < buttons.length) ? Column(children: buttons) : Container(width: 0, height: 0);
  }

  Widget? _buildConvergeContent() {
    int? eventConvergeScore = (widget.event != null) ? widget.event?.convergeScore : null;
    String? eventConvergeUrl = (widget.event != null) ? widget.event?.convergeUrl : null;
    bool hasConvergeScore = (eventConvergeScore != null) && eventConvergeScore>0;
    bool hasConvergeUrl = !AppString.isStringEmpty(eventConvergeUrl);
    bool hasConvergeContent = hasConvergeScore || hasConvergeUrl;

    return hasConvergeContent?
      Column(
      children:<Widget>[
      _divider(),
      Padding(padding: EdgeInsets.only(top: 10),child:
        ExploreConvergeDetailButton(eventConvergeScore: eventConvergeScore, eventConvergeUrl: eventConvergeUrl,)
      )
      ]
    ) : null;
  }

  Widget _buildPreviewButtons(){
    return !widget.previewMode? Container():
      Container(child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
              child: RoundedButton(
                label: Localization().getStringEx('panel.explore_detail.button.modify.title', 'Modify') ,
                hint: Localization().getStringEx('panel.explore_detail.button.modify.hint', '') ,
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorPrimary,
                textColor: Styles().colors!.fillColorPrimary,
                onTap: ()=>_onTapModify,
              )),
          Container(
            width: 6,
          ),
          Expanded(
              child: RoundedButton(
                label: Localization().getStringEx('panel.explore_detail.button.publish.title', 'Publish'),
                hint: Localization().getStringEx('panel.explore_detail.button.publish.hint', 'Publish'),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorSecondary,
                textColor: Styles().colors!.fillColorPrimary,
                onTap: ()=>_onTapPublish,
              ))
        ],
      ));
  }

  Widget _buildGroupButtons(){
    return (AppString.isStringEmpty(widget.browseGroupId) || (widget.event?.isGroupPrivate ?? false))? Container():
        Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child:
          Stack(
            children: [
              ScalableRoundedButton(
                label: Localization().getStringEx('panel.explore_detail.button.add_to_group.title', 'Add Event To Group') ,
                hint: Localization().getStringEx('panel.explore_detail.button.add_to_group.hint', '') ,
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorPrimary,
                textColor: Styles().colors!.fillColorPrimary,
                onTap: _onTapAddToGroup,
              ),
              Visibility(visible: _addToGroupInProgress,
                child: Container(
                  height: 48,
                  child: Align(alignment: Alignment.center,
                    child: SizedBox(height: 24, width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary), )
                    ),
                  ),
                ),
              ),
            ],
          )
        );
  }

  void _addRecentItem(){
    if(!widget.previewMode)
      RecentItems().addRecentItem(RecentItem.fromOriginalType(widget.event));
  }

  void _onTapGetTickets(String? ticketsUrl) {
    Analytics.instance.logSelect(target: "Tickets");
    if (PrivacyTicketsDialog.shouldConfirm) {
      PrivacyTicketsDialog.show(
          context, onContinueTap: () {
        _onTapWebButton(ticketsUrl, 'Tickets');
      });
    } else {
      _onTapWebButton(ticketsUrl, 'Tickets');
    }
  }

  void _onTapWebButton(String? url, String analyticsName){
    if(AppString.isStringNotEmpty(url)){
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) =>
                  WebPanel(
                      analyticsName: "WebPanel($analyticsName)",
                      url: url)));
    }
  }

  void _onLocationDetailTapped() {
    if((widget.event?.isVirtual?? false) == true){
      String? url = widget.event?.location?.description;
      if(AppString.isStringNotEmpty(url)) {
        _onTapWebButton(url, "Event Link ");
      }
    } else if(widget.event?.location?.latitude != null && widget.event?.location?.longitude != null) {
      Analytics.instance.logSelect(target: "Location Detail");
      NativeCommunicator().launchExploreMapDirections(target: widget.event);
    }
  }

  void _onTapModify() {
    Analytics.instance.logSelect(target: "Modify");
    Navigator.pop(context);
  }

  void _onTapAddToGroup() {
    Analytics.instance.logSelect(target: "Add To Group");
    setState(() {
      _addToGroupInProgress = true;
    });
    Groups().linkEventToGroup(groupId: widget.browseGroupId, eventId: widget.event?.id).then((value){
      setState(() {
        _addToGroupInProgress = true;
      });
      Navigator.pop(context, true);
    });
  }

  void _onTapPublish() async{
    Analytics.instance.logSelect(target: "Publish");
    ExploreService().postNewEvent(widget.event).then((String? eventId){
        if(eventId!=null){
          AppToast.show("Event successfully created");
          Navigator.pop(context,eventId!=null);
        }else {
          AppToast.show("Unable to create Event");
        }
    });
  }
  
  void _launchUrl(String? url, {BuildContext? context}) {
    if (AppString.isStringNotEmpty(url)) {
      if (AppUrl.launchInternal(url)) {
        Navigator.push(context!, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url!);
      }
    }
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == LocationServices.notifyStatusChanged) {
      _updateCurrentLocation();
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      _updateCurrentLocation();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setState(() {});
    }
  }
}
