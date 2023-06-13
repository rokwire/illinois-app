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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart' as Core;
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Event.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/location_services.dart';
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

class ExploreEventDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Event? event;
  final bool previewMode;
  final Core.Position? initialLocationData;
  final String? superEventTitle;
  final Group? browseGroup;

  ExploreEventDetailPanel({this.event, this.previewMode = false, this.initialLocationData, this.superEventTitle, this.browseGroup});

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
      FlexUI.notifyChanged,
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
    _locationData = FlexUI().isLocationServicesAvailable ? await LocationServices().location : null;
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
            style: Styles().textStyles?.getTextStyle("widget.title.small.fat.spaced")
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
                    child: Styles().images?.getImage(isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true)
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
                style: Styles().textStyles?.getTextStyle("widget.title.extra_large")
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
                style: Styles().textStyles?.getTextStyle("widget.item.regular.fat")
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

    Widget? online = _exploreOnlineDetail();
    if (online != null) {
      details.add(online);
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
                  child: Styles().images?.getImage('calendar', excludeFromSemantics: true),
                ),
                Expanded(child: Text(displayTime,
                    style: Styles().textStyles?.getTextStyle("widget.item.regular"))),
              ],
            ),
          )
      );
    } else {
      return null;
    }
  }

  Widget? _exploreLocationDetail() {
    if(!(widget.event?.displayAsInPerson ?? false)){
      return null;
    }
    String eventType = Localization().getStringEx('panel.explore_detail.event_type.in_person', "In-person event");
    String locationText = widget.event?.getLongDisplayLocation(_locationData) ?? "";
    bool canHandleLocation = (widget.event?.location?.isLocationCoordinateValid == true);
    TextStyle? locationTextStyle = canHandleLocation ? Styles().textStyles?.getTextStyle("widget.button.title.small.semi_fat.underline") : Styles().textStyles?.getTextStyle("widget.button.title.small.semi_fat");
    String semanticsLabel = "$eventType, $locationText";
    String semanticsHint = Localization().getStringEx('panel.explore_detail.button.directions.hint', '');
    
    return GestureDetector(onTap: canHandleLocation ? _onLocationDetailTapped : null, child:
      Semantics(label: semanticsLabel, hint: semanticsHint, button: canHandleLocation, excludeSemantics: true, child:
        Padding(padding: EdgeInsets.only(bottom: 8), child:
          Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 10), child:
                Styles().images?.getImage("location", excludeFromSemantics: true),
              ),
              Text(eventType, style: Styles().textStyles?.getTextStyle("widget.item.regular")),
            ]),
            Container(height: 4,),
            Visibility(visible: StringUtils.isNotEmpty(locationText), child:
              Container(padding: EdgeInsets.only(left: 30), child:
                Text(locationText, style: locationTextStyle)
              )
            )
          ],)
        )
      ),
    );
  }

  Widget? _exploreOnlineDetail() {
    if(!(widget.event?.displayAsVirtual ?? false)){
      return null;
    }

    String eventType = Localization().getStringEx('panel.explore_detail.event_type.online', "Online Event");
    String? virtualUrl = widget.event?.virtualEventUrl;
    String? locationDescription = widget.event?.location?.description;
    String? linkUrl = virtualUrl ?? (UrlUtils.isValidUrl(locationDescription) ? locationDescription : null);
    bool canHandleLink = StringUtils.isNotEmpty(linkUrl);
    String semanticsLabel = "$eventType, $virtualUrl";
    String semanticsHint = Localization().getStringEx('panel.explore_detail.button.virtual.hint', 'Double tap to open link');

    return GestureDetector(onTap: canHandleLink ? (() => _onTapWebButton(linkUrl, "Event Link ")) : null, child:
      Semantics(label: semanticsLabel, hint: semanticsHint, button: true, excludeSemantics: true, child:
        Padding(padding: EdgeInsets.only(bottom: 8), child:
          Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 10), child:
                Styles().images?.getImage("laptop", excludeFromSemantics: true),
              ),
              Text(eventType, style: Styles().textStyles?.getTextStyle("widget.item.regular")),
            ]),
            Container(height: 4,),
            Visibility(visible: canHandleLink, child:
              Container(padding: EdgeInsets.only(left: 30), child:
                Text(linkUrl ?? '', style: Styles().textStyles?.getTextStyle("widget.button.title.small.semi_fat.underline"))
              ),
            ),
          ],),
        ),
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
                Padding(padding: EdgeInsets.only(left: 1, right: 11), child: Styles().images?.getImage('privacy', excludeFromSemantics: true)),
                Expanded(
                    child: Text(privacyText, style: Styles().textStyles?.getTextStyle("widget.item.regular")))
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
                      child: Styles().images?.getImage('cost', excludeFromSemantics: true),
                    ),
                      Expanded(child:Text(priceText,
                        style: Styles().textStyles?.getTextStyle("widget.item.regular"))),

                    ]),
                    !hasAdditionalDescription? Container():
                    Container(
                      padding: EdgeInsets.only(left: 28),
                      child: Row(children: [
                      Expanded(child:Text(additionalDescription!,
                          style: Styles().textStyles?.getTextStyle("widget.item.regular"))),

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
              Padding(padding: EdgeInsets.only(right: 10), child: Styles().images?.getImage('chevron-left-bold', excludeFromSemantics: true)),
              Expanded(child: Text(widget.superEventTitle ?? '', style: Styles().textStyles?.getTextStyle("widget.button.title.medium.underline"))),
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
                    style: Styles().textStyles?.getTextStyle("widget.text.regular")
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
      contactList.add(Padding(padding: EdgeInsets.only(bottom: 5), child: Text(contactDetails, style: Styles().textStyles?.getTextStyle("widget.text.regular"))));
    }
    return Padding(padding: EdgeInsets.only(left: 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contactList));
  }

  Widget _exploreDescription() {
    String? description = widget.event!.description;
    bool showDescription = StringUtils.isNotEmpty(description);
    if (!showDescription) {
      return Container();
    }
    // Html widget does not handle line breaks symbols \r\n. Replace them with <br/> so that they are properly shown in event description. #692
    String updatedDesc = description!.replaceAll('\r\n', '<br/>');
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: HtmlWidget(
            updatedDesc,
            onTapUrl : (url) { _onTapWebButton(url, 'Description'); return true; },
            textStyle:  Styles().textStyles?.getTextStyle("widget.info.regular"),
        )
    );
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
            Styles().images?.getImage('check-circle-filled') ?? Container(),
            Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                Localization().getStringEx('panel.explore_detail.label.event_preview', 'Event Preview'),
                style: Styles().textStyles?.getTextStyle("widget.heading.large.extra_fat")
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
              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
              backgroundColor: hasRegistrationUrl ? Styles().colors!.background : Colors.white,
              borderColor: hasRegistrationUrl ? Styles().colors!.fillColorPrimary: Styles().colors!.fillColorSecondary,
              rightIcon: Styles().images?.getImage(hasRegistrationUrl ? 'external-link-dark' : 'external-link'),
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
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorSecondary,
                rightIcon: Styles().images?.getImage('external-link'),
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
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorPrimary,
                onTap: ()=>_onTapModify,
              )),
          Container(
            width: 6,
          ),
          Expanded(
              child: RoundedButton(
                label: Localization().getStringEx('panel.explore_detail.button.publish.title', 'Publish'),
                hint: Localization().getStringEx('panel.explore_detail.button.publish.hint', 'Publish'),
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorSecondary,
                onTap: ()=>_onTapPublish,
              ))
        ],
      ));
  }

  Widget _buildGroupButtons(){
    return (StringUtils.isNotEmpty(widget.browseGroup?.id) && ((widget.browseGroup?.researchProject == true) || !(widget.event?.isGroupPrivate ?? false))) ?
        Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              RoundedButton(
                label: (widget.browseGroup?.researchProject == true) ?
                  Localization().getStringEx('panel.explore_detail.button.add_to_project.title', 'Add Event To Project') :
                  Localization().getStringEx('panel.explore_detail.button.add_to_group.title', 'Add Event To Group'),
                hint: (widget.browseGroup?.researchProject == true) ?
                  Localization().getStringEx('panel.explore_detail.button.add_to_project.hint', '') :
                  Localization().getStringEx('panel.explore_detail.button.add_to_group.hint', ''),
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                backgroundColor: Colors.white,
                borderColor: Styles().colors!.fillColorPrimary,
                progress: _addToGroupInProgress,
                onTap: _onTapAddToGroup,
              ),
              Container(height: 6,),
              GroupMembersSelectionWidget(
                selectedMembers: _groupMembersSelection,
                groupId: widget.browseGroup?.id,
                onSelectionChanged: (members){
                  setState(() {
                    _groupMembersSelection = members;
                  });
                },),
            ],
          )
        ) : Container();
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
    Analytics().logSelect(target: "$analyticsName ($url)");
    UrlUtils.launchExternal(url);
  }

  void _onLocationDetailTapped() {
    Analytics().logSelect(target: "Location Directions");
    widget.event?.launchDirections();
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
    Groups().linkEventToGroup(groupId: widget.browseGroup?.id, eventId: widget.event?.id, toMembers: _groupMembersSelection).then((value){
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
  
  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == LocationServices.notifyStatusChanged) {
      _updateCurrentLocation();
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      setStateIfMounted(() {});
      _updateCurrentLocation();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() {});
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
      _updateCurrentLocation();
    }
  }
}
