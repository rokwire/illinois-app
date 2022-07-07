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
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Event.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

import 'package:illinois/service/RecentItems.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/explore/ExploreConvergeDetailItem.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

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
  _EventDetailPanelState createState() => _EventDetailPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => event?.analyticsAttributes;
}

class _EventDetailPanelState extends State<ExploreEventDetailPanel>
  implements NotificationsListener {

  static final double _horizontalPadding = 24;

  //Maps
  Core.Position? _locationData;
  bool _addToGroupInProgress = false;

  //Groups
  List<Member>? _groupMembersSelection;

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
    _locationData = Auth2().privacyMatch(2) ? await LocationServices().location : null;
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
                      flexImageUrl: widget.event?.eventImageUrl,
                      flexRightToLeftTriangleColor: Colors.white,
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
        bottomNavigationBar: uiuc.TabBar(),
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
                  Analytics().logSelect(target: "Favorite: ${widget.event?.title}");
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
                    child: Image.asset(isFavorite ? 'images/icon-star-blue.png' : 'images/icon-star-gray-frame-thin.png', excludeFromSemantics: true)
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
    bool sponsorVisible = StringUtils.isNotEmpty(eventSponsorText);
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


    Widget? tags = _exploreTags();
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
    String locationText = widget.event?.getLongDisplayLocation(_locationData)??"";
    bool isVirtual = widget.event?.isVirtual ?? false;
    String eventType = isVirtual? Localization().getStringEx('panel.explore_detail.event_type.online', "Online Event") : Localization().getStringEx('panel.explore_detail.event_type.in_person', "In-person event");
    bool hasEventUrl = StringUtils.isNotEmpty(widget.event?.location?.description);
    bool isOnlineUnderlined = isVirtual && hasEventUrl;
    BoxDecoration underlineLocationDecoration = BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors!.fillColorSecondary!, width: 1)));
    String iconRes = isVirtual? "images/laptop.png" : "images/location.png" ;
    String locationId = StringUtils.ensureNotEmpty(widget.event?.location?.locationId);
    bool isLocationIdUrl = Uri.tryParse(locationId)?.isAbsolute ?? false;
    String value = isVirtual ? locationId : locationText;
    bool isValueVisible = StringUtils.isNotEmpty(value) && (!isVirtual || !isLocationIdUrl);
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
        ? Localization().getStringEx('panel.explore_detail.label.privacy.private.title', 'Private Event')
        : Localization().getStringEx('panel.explore_detail.label.privacy.public.title', 'Public Event');
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
    bool hasAdditionalDescription = StringUtils.isNotEmpty(additionalDescription);
    if (priceText.isNotEmpty) {
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
    if (StringUtils.isEmpty(widget.superEventTitle)) {
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

  Widget? _exploreTags(){
    if(widget.event?.tags != null){
      List<String> capitalizedTags = widget.event!.tags!.map((entry)=>'${entry[0].toUpperCase()}${entry.substring(1)}').toList();
      return Padding(
        padding: const EdgeInsets.only(left: 30),
        child: capitalizedTags.isNotEmpty ? Column(
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
                Text(Localization().getStringEx('panel.explore_detail.label.related_tags', 'Related Tags:')),
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
    return null;
  }

  Widget _exploreSubTitle() {
    String? subTitle = widget.event?.exploreSubTitle;
    if (StringUtils.isEmpty(subTitle)) {
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
    if (CollectionUtils.isEmpty(widget.event?.contacts)) {
      return Container();
    }
    List<Widget> contactList = [];
    contactList.add(Padding(
        padding: EdgeInsets.only(bottom: 5), child: Text(Localization().getStringEx('panel.explore_detail.label.contacts', 'Contacts:'))));
    for (Contact? contact in widget.event!.contacts!) {
      String contactDetails = '';
      if (StringUtils.isNotEmpty(contact!.firstName)) {
        contactDetails += contact.firstName!;
      }
      if (StringUtils.isNotEmpty(contact.lastName)) {
        if (StringUtils.isNotEmpty(contactDetails)) {
          contactDetails += ' ';
        }
        contactDetails += contact.lastName!;
      }
      if (StringUtils.isNotEmpty(contact.organization)) {
        contactDetails += ' (${contact.organization})';
      }
      if (StringUtils.isNotEmpty(contact.email)) {
        if (StringUtils.isNotEmpty(contactDetails)) {
          contactDetails += ', ';
        }
        contactDetails += contact.email!;
      }
      if (StringUtils.isNotEmpty(contact.phone)) {
        if (StringUtils.isNotEmpty(contactDetails)) {
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
    bool showDescription = StringUtils.isNotEmpty(longDescription);
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
                Localization().getStringEx('panel.explore_detail.label.event_preview', 'Event Preview'),
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
    bool hasTitleUrl = StringUtils.isNotEmpty(titleUrl);

    String? registrationUrl = widget.event?.registrationUrl;
    bool hasRegistrationUrl = StringUtils.isNotEmpty(registrationUrl);

    if (hasTitleUrl) {
      buttons.add(Row(children:<Widget>[
        Expanded(child:
          Padding(padding: EdgeInsets.only(bottom: 6), child:
            RoundedButton(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              label: Localization().getStringEx('panel.explore_detail.button.visit_website.title', 'Visit website'),
              hint: Localization().getStringEx('panel.explore_detail.button.visit_website.hint', ''),
              backgroundColor: hasRegistrationUrl ? Styles().colors!.background : Colors.white,
              borderColor: hasRegistrationUrl ? Styles().colors!.fillColorPrimary: Styles().colors!.fillColorSecondary,
              rightIcon: hasRegistrationUrl ? Image.asset('images/external-link.png', color: Styles().colors!.fillColorPrimary, colorBlendMode: BlendMode.srcIn) : Image.asset('images/external-link.png'),
              textColor: Styles().colors!.fillColorPrimary,
              onTap: () {
                Analytics().logSelect(target: "Website");
                _onTapWebButton(titleUrl, 'Website');
              },),
      ),),],),);
    }
    
    if (hasRegistrationUrl) {
      buttons.add(Row(children:<Widget>[
        Expanded(child:
        Padding(padding: EdgeInsets.only(bottom: 6), child:
          RoundedButton(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                label: Localization().getStringEx('panel.explore_detail.button.get_tickets.title', 'Register'),
                hint: Localization().getStringEx('panel.explore_detail.button.get_tickets.hint', ''),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorSecondary,
                rightIcon: Image.asset('images/external-link.png'),
                textColor: Styles().colors!.fillColorPrimary,
                onTap: () {
                Analytics().logSelect(target: "Website");
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
    bool hasConvergeUrl = !StringUtils.isEmpty(eventConvergeUrl);
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
                label: Localization().getStringEx('panel.explore_detail.button.modify.title', 'Modify'),
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
    return (StringUtils.isEmpty(widget.browseGroupId) || (widget.event?.isGroupPrivate ?? false))? Container():
        Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              RoundedButton(
                label: Localization().getStringEx('panel.explore_detail.button.add_to_group.title', 'Add Event To Group'),
                hint: Localization().getStringEx('panel.explore_detail.button.add_to_group.hint', ''),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorPrimary,
                textColor: Styles().colors!.fillColorPrimary,
                progress: _addToGroupInProgress,
                onTap: _onTapAddToGroup,
              ),
              Container(height: 6,),
              GroupMembersSelectionWidget(
                selectedMembers: _groupMembersSelection,
                groupId: widget.browseGroupId,
                onSelectionChanged: (members){
                  setState(() {
                    _groupMembersSelection = members;
                  });
                },),
            ],
          )
        );
  }

  void _addRecentItem(){
    if(!widget.previewMode)
      RecentItems().addRecentItem(RecentItem.fromSource(widget.event));
  }

  void _onTapGetTickets(String? ticketsUrl) {
    Analytics().logSelect(target: "Tickets");
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
    if(StringUtils.isNotEmpty(url)){
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
      if(StringUtils.isNotEmpty(url)) {
        _onTapWebButton(url, "Event Link ");
      }
    } else if(widget.event?.location?.latitude != null && widget.event?.location?.longitude != null) {
      Analytics().logSelect(target: "Location Detail");
      NativeCommunicator().launchExploreMapDirections(target: widget.event);
    }
  }

  void _onTapModify() {
    Analytics().logSelect(target: "Modify");
    Navigator.pop(context);
  }

  void _onTapAddToGroup() {
    Analytics().logSelect(target: "Add To Group");
    setState(() {
      _addToGroupInProgress = true;
    });
    Groups().linkEventToGroup(groupId: widget.browseGroupId, eventId: widget.event?.id, toMembers: _groupMembersSelection).then((value){
      setState(() {
        _addToGroupInProgress = true;
      });
      Navigator.pop(context, true);
    });
  }

  void _onTapPublish() async{
    Analytics().logSelect(target: "Publish");
    Events().postNewEvent(widget.event).then((String? eventId){
        if(eventId!=null){
          AppToast.show("Event successfully created");
          Navigator.pop(context,true);
        }else {
          AppToast.show("Unable to create Event");
        }
    });
  }
  
  void _launchUrl(String? url, {BuildContext? context}) {
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
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
