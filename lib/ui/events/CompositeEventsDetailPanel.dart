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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart' as Core;
import 'package:illinois/ext/Event.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/events/EventsSchedulePanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';

import 'package:illinois/service/RecentItems.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/explore/ExploreConvergeDetailItem.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

import 'package:illinois/ui/WebPanel.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

class CompositeEventsDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {

  final Event? parentEvent;
  final Core.Position? initialLocationData;
  final Group? browseGroup;

  CompositeEventsDetailPanel({this.parentEvent, this.initialLocationData, this.browseGroup});

  @override
  _CompositeEventsDetailPanelState createState() => _CompositeEventsDetailPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => parentEvent?.analyticsAttributes;
}

class _CompositeEventsDetailPanelState extends State<CompositeEventsDetailPanel>
    implements NotificationsListener {

  static final double _horizontalPadding = 24;

  Core.Position? _locationData;
  bool              _addToGroupInProgress = false;

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
      setStateIfMounted(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.white,
              child: CustomScrollView(
                scrollDirection: Axis.vertical,
                slivers: <Widget>[
                  SliverToutHeaderBar(
                    flexImageUrl: widget.parentEvent?.eventImageUrl,
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                        [
                          Stack(
                            children: <Widget>[
                              Container(
                                  color: Colors.white,
                                  child: Column(
                                    children: <Widget>[
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Padding(padding: EdgeInsets.only(left: _horizontalPadding), child:_exploreHeading()),
                                          Column(
                                            children: <Widget>[
                                              Padding(
                                                  padding:
                                                  EdgeInsets.symmetric(horizontal: _horizontalPadding),
                                                  child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: <Widget>[
                                                        _exploreTitle(),
                                                        _eventSponsor(),
                                                        _exploreDetails(),
                                                        _buildUrlButtons()
                                                      ]
                                                  )
                                              ),
                                            ],
                                          ),
                                          _exploreDescription(),
                                          _buildEventsList(),
                                          _buildGroupButtons()
                                        ],
                                      ),
                                    ],
                                  )
                              )
                            ],
                          )
                        ],addSemanticIndexes:true),
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
    String? category = widget.parentEvent?.category;
    bool isFavorite = widget.parentEvent?.isFavorite ?? false;
    bool starVisible = Auth2().canFavorite;
    return Padding(padding: EdgeInsets.only(top: 16, bottom: 12), child: Row(
      children: <Widget>[
        Text(
          (category != null) ? category.toUpperCase() : "",
          style: Styles().textStyles?.getTextStyle("widget.title.small.fat.spaced")
        ),
        Expanded(child: Container()),
        Visibility(visible: starVisible, child: Container(child: Padding(padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTapHeaderStar,
                child: Semantics(
                    label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization()
                        .getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                    hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx(
                        'widget.card.button.favorite.on.hint', ''),
                    button: true,
                    child: Styles().images?.getImage(isFavorite ? 'star-filled' : 'star-outline-gray')
                ))
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
                widget.parentEvent!.exploreTitle!,
                style: Styles().textStyles?.getTextStyle("widget.title.extra_large")
              ),
            ),
          ],
        ));
  }

  Widget _eventSponsor() {
    String eventSponsorText = widget.parentEvent?.sponsor ?? '';
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

    Widget? converge =  _buildConvergeContent();
    if(converge!=null){
      details.add(converge);
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
    bool isParentSuper = widget.parentEvent?.isSuperEvent ?? false;
    String? displayTime = isParentSuper ? widget.parentEvent?.displaySuperDates : widget.parentEvent?.displayRecurringDates;
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
                  child: Styles().images?.getImage('calendar'),
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
    String? locationText = widget.parentEvent?.getLongDisplayLocation(_locationData);
    if ((widget.parentEvent?.displayAsInPerson ?? false) && widget.parentEvent?.location != null && (locationText != null) && locationText.isNotEmpty) {
      return GestureDetector(
        onTap: _onLocationDetailTapped,
        child: Semantics(
            label: locationText,
            hint: Localization().getStringEx('panel.explore_detail.button.directions.hint', ''),
            button: true,
            excludeSemantics: true,
            child:Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Styles().images?.getImage('location'), //Image.asset('images/icon-location.png'),
                  ),
                  Expanded(child: Text(locationText,
                      style: Styles().textStyles?.getTextStyle("widget.item.regular"))),
                ],
              ),
            )
        ),
      );
    } else {
      return null;
    }
  }

  Widget? _exploreOnlineDetail() {
    String? locationText = widget.parentEvent?.virtualEventUrl ?? widget.parentEvent?.location?.description;
    if ((widget.parentEvent?.displayAsVirtual ?? false) && widget.parentEvent?.location != null && (locationText != null) && locationText.isNotEmpty) {
      return GestureDetector(
        onTap: _onLocationDetailTapped,
        child: Semantics(
            label: locationText,
            hint: Localization().getStringEx('panel.explore_detail.button.directions.hint', ''),
            button: true,
            excludeSemantics: true,
            child:Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Styles().images?.getImage('laptop'), //TBD update icon res
                  ),
                  Expanded(child: Text(locationText,
                      style: Styles().textStyles?.getTextStyle("widget.item.regular"))),
                ],
              ),
            )
        ),
      );
    } else {
      return null;
    }
  }

  Widget? _eventPriceDetail() {
    String? priceText = widget.parentEvent?.cost;
    if ((priceText != null) && priceText.isNotEmpty) {
      return Semantics(
          excludeSemantics: true,
          child:Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Styles().images?.getImage('cost'),
                ),
                Expanded(child: Text(priceText,
                    style: Styles().textStyles?.getTextStyle("widget.item.regular"))),
              ],
            ),
          )
      );
    } else {
      return null;
    }
  }

  Widget? _exploreTags(){
    if(widget.parentEvent?.tags != null){
      List<String> capitalizedTags = widget.parentEvent!.tags!.map((entry)=>'${entry[0].toUpperCase()}${entry.substring(1)}').toList();
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
    return Container();
  }

  Widget _exploreDescription() {
    String? description = widget.parentEvent!.description;
    bool showDescription = StringUtils.isNotEmpty(description);
    if (!showDescription) {
      return Container();
    }
    return Container(padding: EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 24), color: Styles().colors!.background, child:
    HtmlWidget(
      StringUtils.ensureNotEmpty(description),
        onTapUrl : (url) {_launchUrl(url, 'Description'); return true;},
        textStyle: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
    )
      // Html(
      //   data: longDescription,
      //   onLinkTap: (url, renderContext, attributes, element) => _launchUrl(url, 'Description'),
      //   style: { "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(16), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
      // ),
    );
  }

  Widget _buildEventsList() {
    List<Event>? eventList = (widget.parentEvent?.isSuperEvent == true) ? widget.parentEvent?.featuredEvents : widget.parentEvent?.recurringEvents;
    return _EventsList(events: eventList, parentEvent: widget.parentEvent,);
  }

  Widget _buildUrlButtons() {
    Widget buttonsDivider = Container(height: 12);
    String? titleUrl = widget.parentEvent?.titleUrl;
    bool visitWebsiteVisible = StringUtils.isNotEmpty(titleUrl);
    String? ticketsUrl = widget.parentEvent?.registrationUrl;
    bool getTicketsVisible = StringUtils.isNotEmpty(ticketsUrl);

    String websiteLabel = Localization().getStringEx('panel.explore_detail.button.visit_website.title', 'Visit website');
    String? websiteHint = Localization().getStringEx('panel.explore_detail.button.visit_website.hint', '');

    Widget visitWebsiteButton = (widget.parentEvent?.isSuperEvent ?? false) ?
    Visibility(visible: visitWebsiteVisible, child: SmallRoundedButton(
      label: websiteLabel,
      hint: websiteHint,
      borderColor: Styles().colors!.fillColorPrimary,
      onTap: () => _onTapVisitWebsite(titleUrl),),) :
    Visibility(visible: visitWebsiteVisible, child: RoundedButton(
      label: websiteLabel,
      hint: websiteHint,
      textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
      backgroundColor: Colors.white,
      borderColor: Styles().colors!.fillColorSecondary,
      onTap: () => _onTapVisitWebsite(titleUrl),
    ),);

    return Container(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        visitWebsiteButton,
        Visibility(visible: visitWebsiteVisible, child: buttonsDivider),
        Visibility(visible: getTicketsVisible, child: RoundedButton(
          label: Localization().getStringEx('panel.explore_detail.button.get_tickets.title', 'Get tickets'),
          hint: Localization().getStringEx('panel.explore_detail.button.get_tickets.hint', ''),
          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
          backgroundColor: Colors.white,
          borderColor: Styles().colors!.fillColorSecondary,
          onTap: () => _onTapGetTickets(ticketsUrl),
        ),),
        Visibility(visible: getTicketsVisible, child: buttonsDivider)
      ],
    ));
  }

  void _onTapVisitWebsite(String? url) {
    Analytics().logSelect(target: "Website");
    _onTapWebButton(url, 'Website');
  }

  Widget? _buildConvergeContent() {
    int? eventConvergeScore = (widget.parentEvent != null) ? widget.parentEvent?.convergeScore : null;
    String? eventConvergeUrl = (widget.parentEvent != null) ? widget.parentEvent?.convergeUrl : null;
    bool hasConvergeScore = (eventConvergeScore != null) && eventConvergeScore>0;
    bool hasConvergeUrl = !StringUtils.isEmpty(eventConvergeUrl);
    bool hasConvergeContent = hasConvergeScore || hasConvergeUrl;

    return !hasConvergeContent? Container():
    Column(
        children:<Widget>[
          _divider(),
          Padding(padding: EdgeInsets.only(top: 10),child:
          ExploreConvergeDetailButton(eventConvergeScore: eventConvergeScore, eventConvergeUrl: eventConvergeUrl,)
          )
        ]
    );
  }

  void _addRecentItem() {
    RecentItems().addRecentItem(RecentItem.fromSource(widget.parentEvent));
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
                      analyticsSource: widget.parentEvent?.analyticsAttributes,
                      url: url)));
    }
  }

  void _onLocationDetailTapped(){
    if(widget.parentEvent?.location?.latitude != null && widget.parentEvent?.location?.longitude != null) {
      Analytics().logSelect(target: "Location Directions");
      widget.parentEvent?.launchDirections();
    }
  }

  void _onTapHeaderStar() {
    Analytics().logSelect(target: "Favorite: ${widget.parentEvent?.title}");
    widget.parentEvent?.toggleFavorite();
  }

  Widget _buildGroupButtons(){
    return StringUtils.isNotEmpty(widget.browseGroup?.id) ? Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child:
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
    ) : Container();
  }

  void _onTapAddToGroup() {
    Analytics().logSelect(target: "Add To Group");
    setState(() {
      _addToGroupInProgress = true;
    });
    Groups().linkEventToGroup(groupId: widget.browseGroup?.id, eventId: widget.parentEvent?.id).then((value){
      setState(() {
        _addToGroupInProgress = true;
      });
      Navigator.pop(context);
    });
  }

  void _launchUrl(String? url, String analyticsName) {
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(
          url: url,
          analyticsName: "WebPanel($analyticsName)",
          analyticsSource: widget.parentEvent?.analyticsAttributes,
        )));
      } else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri);
        }
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

class _EventsList extends StatefulWidget {

  final List<Event>? events;
  final Event? parentEvent;

  _EventsList({this.events, this.parentEvent});

  _EventsListState createState() => _EventsListState();
}

class _EventsListState extends State<_EventsList>{

  static final int _minVisibleItems = 5;

  @override
  Widget build(BuildContext context) {
    String titleKey = (widget.parentEvent?.isSuperEvent == true)
        ? "panel.explore_detail.super_event.schedule.heading.title"
        : "panel.explore_detail.recurring_event.schedule.heading.title";
    return SectionSlantHeader(
        title: Localization().getStringEx(titleKey, "Event Schedule"),
        slantImageKey: "slant-dark",
        slantColor: Styles().colors!.backgroundVariant,
        titleTextStyle: Styles().textStyles?.getTextStyle("widget.title.large.extra_fat"),
        children: _buildListItems()
    );
  }

  List<Widget> _buildListItems() {
    List<Widget> listItems = [];
    bool? isParentSuper = widget.parentEvent!.isSuperEvent;
    if (CollectionUtils.isNotEmpty(widget.events)) {
      for (Event? event in widget.events!) {
        listItems.add(_EventEntry(event: event, parentEvent: widget.parentEvent,));
        if (isParentSuper! && (listItems.length >= _minVisibleItems)) {
          break;
        }
      }
    }
    if (isParentSuper!) {
      listItems.add(_buildFullScheduleButton());
    }
    return listItems;
  }

  Widget _buildFullScheduleButton() {
    String titleFormat = Localization().getStringEx("panel.explore_detail.button.see_super_events.title", "All %s");
    String title = sprintf(titleFormat, [widget.parentEvent!.title]);
    return Column(
      children: <Widget>[
        Semantics(
          label: title,
          button: true,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: _onTapFullSchedule,
            child: Container(
              color: Styles().colors!.fillColorPrimary,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1, style: Styles().textStyles?.getTextStyle("widget.colourful_button.title.accent")),
                    ),
                    Styles().images?.getImage('chevron-right-bold') ?? Container(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onTapFullSchedule() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => EventsSchedulePanel(superEvent: widget.parentEvent)));
  }
}

class _EventEntry extends StatelessWidget {

  final Event? event;
  final Event? parentEvent;

  _EventEntry({this.event, this.parentEvent});

  @override
  Widget build(BuildContext context) {
    bool isFavorite = Auth2().isFavorite(event);
    bool starVisible = Auth2().canFavorite;
    String title = ((parentEvent?.isSuperEvent == true) ? event?.title : event?.displayDate) ?? '';
    String subTitle = ((parentEvent?.isSuperEvent == true) ? event?.displaySuperTime : event?.displayStartEndTime) ?? '';
    return GestureDetector(onTap: () => _onTapEvent(context), child: Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1.0), borderRadius: BorderRadius.circular(4.0),
      ),
      child: Padding(padding: EdgeInsets.all(16), child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"),),
              Text(subTitle, overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Styles().textStyles?.getTextStyle("widget.item.small"))
            ],),),
          Visibility(
            visible: starVisible, child: Container(child: Padding(padding: EdgeInsets.only(left: 24),
              child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Analytics().logSelect(target: "Favorite: ${event?.title}");
                    Auth2().prefs?.toggleFavorite(event);
                  },
                  child: Semantics(
                      label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization()
                          .getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                      hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx(
                          'widget.card.button.favorite.on.hint', ''),
                      button: true,
                      child: Styles().images?.getImage(isFavorite ? 'star-filled': 'star-outline-gray')
                  ))
          )),)
        ],),),
    ),);
  }

  void _onTapEvent(BuildContext context) {
    if (parentEvent?.isSuperEvent == true) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreEventDetailPanel(event: event, superEventTitle: parentEvent!.title)));
    }
  }
}
