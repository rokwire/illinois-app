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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/LocationServices.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:location/location.dart' as Core;

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

class ExploreEventDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Event event;
  final bool previewMode;
  final Core.LocationData initialLocationData;
  final String superEventTitle;

  ExploreEventDetailPanel({this.event, this.previewMode = false, this.initialLocationData, this.superEventTitle});

  @override
  _EventDetailPanelState createState() =>
      _EventDetailPanelState();

  @override
  Map<String, dynamic> get analyticsPageAttributes {
    return event?.analyticsAttributes;
  }
}

class _EventDetailPanelState extends State<ExploreEventDetailPanel>
  implements NotificationsListener {

  static final double _horizontalPadding = 24;

  //Maps
  Core.LocationData _locationData;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      LocationServices.notifyStatusChanged,
      User.notifyPrivacyLevelChanged,
      User.notifyFavoritesUpdated,
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
    _locationData = User().privacyMatch(2) ? await LocationServices.instance.location : null;
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
                      imageUrl: widget.event.exploreImageURL,
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
                                                      _exploreSubTitle(),
                                                      _exploreDescription(),
                                                      _buildUrlButtons(),
                                                      _buildPreviewButtons(),
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
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: TabBarWidget(),
      );
  }

  Widget _exploreHeading() {
    String category = widget?.event?.category;
    bool isFavorite = User().isFavorite(widget.event);
    bool starVisible = User().favoritesStarVisible;
    return Padding(padding: EdgeInsets.only(top: 16, bottom: 12), child: Row(
      children: <Widget>[
        Expanded(child:
          Text(
            (category != null) ? category.toUpperCase() : "",
            style: TextStyle(
                fontFamily: Styles().fontFamilies.bold,
                fontSize: 14,
                color: Styles().colors.fillColorPrimary,
                letterSpacing: 1),
          ),
        ),
        Visibility(visible: starVisible, child: Container(child: Padding(padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Analytics.instance.logSelect(target: "Favorite");
                  User().switchFavorite(widget.event);
                },
                child: Semantics(
                    label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization()
                        .getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                    hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx(
                        'widget.card.button.favorite.on.hint', ''),
                    button: true,
                    child: Image.asset(isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png')
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
                widget.event.exploreTitle,
                style: TextStyle(
                    fontSize: 24,
                    color: Styles().colors.fillColorPrimary),
              ),
            ),
          ],
        ));
  }

  Widget _eventSponsor() {
    String eventSponsorText = widget?.event?.sponsor ?? '';
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
                    color: Styles().colors.textBackground,
                    fontFamily: Styles().fontFamilies.bold),
              ),
            ),
          ],
        )),)
    ;
  }

  Widget _exploreDetails() {
    List<Widget> details = List<Widget>();

    Widget time = _exploreTimeDetail();
    if (time != null) {
      details.add(time);
    }

    Widget location = _exploreLocationDetail();
    if (location != null) {
      details.add(location);
    }

    Widget price = _eventPriceDetail();
    if (price != null) {
      details.add(price);
    }

    Widget converge = _buildConvergeContent();
    if (converge != null) {
      details.add(converge);
    }

    Widget superEventLink = _superEventLink();
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
        color: Styles().colors.fillColorPrimaryTransparent015,
      ),
    );
  }

  Widget _exploreTimeDetail() {
    String displayTime = widget?.event?.displayDateTime;
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
                  child: Image.asset('images/icon-calendar.png'),
                ),
                Expanded(child: Text(displayTime,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.medium,
                        fontSize: 16,
                        color: Styles().colors.textBackground))),
              ],
            ),
          )
      );
    } else {
      return null;
    }
  }

  Widget _exploreLocationDetail() {
    String locationText = ExploreHelper.getLongDisplayLocation(widget.event, _locationData);
    if (!(widget?.event?.isVirtual ?? false) && widget?.event?.location != null && (locationText != null) && locationText.isNotEmpty) {
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
                  child:Image.asset('images/icon-location.png'),
                ),
                Expanded(child: Text(locationText,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.medium,
                        fontSize: 16,
                        color: Styles().colors.textBackground))),
              ],
            ),
          )
        ),
      );
    } else {
      return null;
    }
  }
  
  Widget _eventPriceDetail() {
    String priceText = widget?.event?.cost;
    if ((priceText != null) && priceText.isNotEmpty) {
      return Semantics(
          label: Localization().getStringEx("panel.explore_detail.label.price.title","Price"),
          value: priceText,
          excludeSemantics: true,
          child:Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child:Image.asset('images/icon-cost.png'),
                ),
                Expanded(child: Text(priceText,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.medium,
                        fontSize: 16,
                        color: Styles().colors.textBackground))),
              ],
            ),
          )
        );
    } else {
      return null;
    }
  }

  Widget _superEventLink() {
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
              Padding(padding: EdgeInsets.only(right: 10), child: Image.asset('images/chevron-left.png'),),
              Expanded(child: Text(widget.superEventTitle, style: TextStyle(fontFamily: Styles().fontFamilies.medium,
                  fontSize: 16,
                  color: Styles().colors.fillColorPrimary,
                  decoration: TextDecoration.underline,
                  decorationColor: Styles().colors.fillColorSecondary))),
            ],
          ),
        )
    ),);
  }

  Widget _exploreTags(){
    if(widget?.event?.tags != null){
      List<String> capitalizedTags = widget.event.tags.map((entry)=>'${entry[0].toUpperCase()}${entry.substring(1)}').toList();
      return Padding(
        padding: const EdgeInsets.only(left: 30),
        child: capitalizedTags != null && capitalizedTags.isNotEmpty ? Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: <Widget>[
                Expanded(child: Container(height: 1, color: Styles().colors.surfaceAccent,),)
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
                      fontFamily: Styles().fontFamilies.regular
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
    String subTitle = widget?.event?.exploreSubTitle;
    if (AppString.isStringEmpty(subTitle)) {
      return Container();
    }
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          subTitle,
          style: TextStyle(
              fontSize: 20,
              color: Styles().colors.textBackground),
        ));
  }

  Widget _exploreDescription() {
    String longDescription = widget.event.exploreLongDescription;
    bool showDescription = AppString.isStringNotEmpty(longDescription);
    if (!showDescription) {
      return Container();
    }
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: HtmlWidget(
          longDescription,
        ));
  }

  Widget _buildPreviewHeader(){
    return !widget.previewMode? Container():
    Container(
      color: Styles().colors.fillColorPrimaryVariant,
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
                    fontFamily: Styles().fontFamilies.extraBold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUrlButtons(){
    String ticketsUrl = widget?.event?.registrationUrl;
    String titleUrl = widget?.event?.titleUrl;

    return Container(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AppString.isStringEmpty(ticketsUrl)? Container():
          RoundedButton(
                label: Localization().getStringEx('panel.explore_detail.button.get_tickets.title', 'Get tickets'),
                hint: Localization().getStringEx('panel.explore_detail.button.get_tickets.hint', ''),
                backgroundColor: Colors.white,
                borderColor: Styles().colors.fillColorSecondary,
                textColor: Styles().colors.fillColorPrimary,
                onTap: () => _onTapGetTickets(ticketsUrl),
              ),
          Container(
            height: 6,
          ),
          AppString.isStringEmpty(titleUrl)? Container():
          RoundedButton(
                label: Localization().getStringEx('panel.explore_detail.button.visit_website.title', 'Visit website'),
                hint: Localization().getStringEx('panel.explore_detail.button.visit_website.hint', ''),
                backgroundColor: Colors.white,
                borderColor: Styles().colors.fillColorSecondary,
                textColor: Styles().colors.fillColorPrimary,
                onTap: (){
                  Analytics.instance.logSelect(target: "Website");
                  _onTapWebButton(titleUrl, 'Website');
                  },
              ),
          Container(
            height: 6,
          ),
        ],
      ));
  }

  Widget _buildConvergeContent() {
    int eventConvergeScore = (widget?.event != null) ? widget?.event?.convergeScore : null;
    String eventConvergeUrl = (widget?.event != null) ? widget?.event?.convergeUrl : null;
    bool hasConvergeScore = (eventConvergeScore != null) && eventConvergeScore>0;
    bool hasConvergeUrl = !AppString.isStringEmpty(eventConvergeUrl);
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
                borderColor: Styles().colors.fillColorPrimary,
                textColor: Styles().colors.fillColorPrimary,
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
                borderColor: Styles().colors.fillColorSecondary,
                textColor: Styles().colors.fillColorPrimary,
                onTap: ()=>_onTapPublish,
              ))
        ],
      ));
  }

  void _addRecentItem(){
    if(!widget.previewMode)
      RecentItems().addRecentItem(RecentItem.fromOriginalType(widget.event));
  }

  void _onTapGetTickets(String ticketsUrl) {
    Analytics.instance.logSelect(target: "Tickets");
    if (User().showTicketsConfirmationModal) {
      PrivacyTicketsDialog.show(
          context, onContinueTap: () {
        _onTapWebButton(ticketsUrl, 'Tickets');
      });
    } else {
      _onTapWebButton(ticketsUrl, 'Tickets');
    }
  }

  void _onTapWebButton(String url, String analyticsName){
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
    if(widget?.event?.location?.latitude != null && widget?.event?.location?.longitude != null) {
      Analytics.instance.logSelect(target: "Location Detail");
      NativeCommunicator().launchExploreMapDirections(target: widget.event);
    }
  }

  void _onTapModify() {
    Analytics.instance.logSelect(target: "Modify");
    Navigator.pop(context);
  }

  void _onTapPublish() async{
    Analytics.instance.logSelect(target: "Publish");
    ExploreService().postNewEvent(widget?.event).then((bool success){
        if(success){
          AppToast.show("Event successfully created");
          Navigator.pop(context,success);
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
    else if (name == User.notifyPrivacyLevelChanged) {
      _updateCurrentLocation();
    }
    else if (name == User.notifyFavoritesUpdated) {
      setState(() {});
    }
  }
}
