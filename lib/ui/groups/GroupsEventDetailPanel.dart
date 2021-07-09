
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';


class GroupEventDetailPanel extends StatefulWidget{
  final Event event;
  final String groupId;
  final bool previewMode;

  const GroupEventDetailPanel({Key key,this.previewMode = false, this.event, this.groupId}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GroupEventDetailsPanelState();
  }
}

class _GroupEventDetailsPanelState extends State<GroupEventDetailPanel> with NotificationsListener{
  List<Group> _adminGroups;
  Event _event;

  Group _currentlySelectedGroup;
  List<Group> _linkedGroups;

  @override
  void initState() {
    _event = widget.event;
    _linkedGroups = []; //TBD preload if necessary
    Groups().loadGroups(myGroups: true).then((groups) {
      setState(() {
        _adminGroups = groups;
      });
    });

    NotificationService().subscribe(this, [Groups.notifyGroupEventsUpdated]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: HeaderBackButton(),
        actions: [
          _buildFavoritesButton(),
          Visibility(
            visible: !_isPrivateGroupEvent,
            child: Semantics(
                label: Localization().getStringEx('panel.groups_event_detail.button.options.title', 'Options'),
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  icon: Image.asset(
                    'images/groups-more-inactive.png',
                  ),
                  onPressed:_onOptionsTap,
              )))
        ],
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
      body: Column(children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eventImageHeader(),
                Container(
                  color: Styles().colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _eventTitle(),
                      Container(height: 7,),
                      _eventTimeDetail(),
                      Container(height: 12,),
                      _eventLocationDetail(),
                      Container(height: 8,),
                      _eventPriceDetail(),
                      Container(height: 20,),
                      _buildPreviewButtons(),
                      Container(height: 20,),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      _eventDescription(),
                      _eventUrlButtons(),
                      Container(height: 40,)
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _eventImageHeader(){
    return Container(
      height: 200,
      color: Styles().colors.background,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          AppString.isStringNotEmpty(_event?.imageURL) ?  Positioned.fill(child:Image.network(widget.event?.imageURL, fit: BoxFit.cover, headers: Network.appAuthHeaders,)) : Container(),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondaryTransparent05, left: false),
            child: Container(
              height: 53,
            ),
          ),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors.white),
            child: Container(
              height: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTitle(){
    return Container(child:
        Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _event?.category?.toUpperCase() ?? "",
            style: TextStyle(
                fontFamily: Styles().fontFamilies.bold,
                fontSize: 14,
                color: Styles().colors.fillColorPrimary,
                letterSpacing: 1),
          ),
          Container(height: 8,),
          Text(
            _event.exploreTitle,
            style: TextStyle(
                fontSize: 24,
                color: Styles().colors.fillColorPrimary),
          ),
        ],
      )
    );
  }

  Widget _eventTimeDetail() {
    String displayTime = _event?.displayDateTime;
    //Newly created groups pass time in the string
    if(AppString.isStringEmpty(displayTime?.trim())){
      if(_event?.startDateString !=null || _event?.endDateString != null){
        DateTime startDate = AppDateTime().dateTimeFromString(_event?.startDateString, format: AppDateTime.eventsServerCreateDateTimeFormat);
        DateTime endDate = AppDateTime().dateTimeFromString(_event?.endDateString, format: AppDateTime.eventsServerCreateDateTimeFormat);
        if(startDate !=null){
          displayTime = AppDateTime().formatDateTime(startDate, format: "MMM dd, yyyy");
        } else if(endDate != null){
          displayTime = AppDateTime().formatDateTime(endDate, format: "MMM dd, yyyy");
        }
      }
    }
    if (AppString.isStringNotEmpty(displayTime)) {
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
      return Container();
    }
  }

  Widget _eventLocationDetail() {
    String locationText = ExploreHelper.getLongDisplayLocation(_event, null); //TBD decide if we need distance calculation - pass _locationData
    bool isVirtual = _event?.isVirtual ?? false;
    String eventType = isVirtual? Localization().getStringEx('panel.groups_event_detail.label.online_event', "Online event") : Localization().getStringEx('panel.groups_event_detail.label.in_person_event', "In-person event");
    bool hasEventUrl = AppString.isStringNotEmpty(_event?.location?.description);
    bool isOnlineUnderlined = isVirtual && hasEventUrl;
    BoxDecoration underlineLocationDecoration = BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.fillColorSecondary, width: 1)));
    String iconRes = isVirtual? "images/laptop.png" : "images/location.png" ;
    String locationId = AppString.getDefaultEmptyString(value: _event?.location?.locationId);
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
                          child:Image.asset(iconRes),
                        ),
                        Container(decoration: (isOnlineUnderlined ? underlineLocationDecoration : null), padding: EdgeInsets.only(bottom: (isOnlineUnderlined ? 2 : 0)), child: Text(eventType,
                            style: TextStyle(
                                fontFamily: Styles().fontFamilies.medium,
                                fontSize: 16,
                                color: Styles().colors.textBackground)),),
                      ]),
                  Container(height: 4,),
                  Visibility(visible: isValueVisible, child: Container(
                      padding: EdgeInsets.only(left: 30),
                      child: Container(
                          decoration: underlineLocationDecoration,
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                            value??"",
                            style: TextStyle(
                                fontFamily: Styles().fontFamilies.medium,
                                fontSize: 14,
                                color: Styles().colors.fillColorPrimary),
                          ))))
                ],)
          )
      ),
    );
  }

  Widget _eventPriceDetail() {
    bool isFree = _event?.isEventFree ?? false;
    String priceText =isFree? "Free" : (_event?.cost ?? "Free");
    String additionalDescription = isFree? _event?.cost : null;
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
                      child:Image.asset('images/icon-cost.png'),
                    ),
                    Expanded(child:Text(priceText,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies.medium,
                            fontSize: 16,
                            color: Styles().colors.textBackground))),

                  ]),
              !hasAdditionalDescription? Container():
              Container(
                  padding: EdgeInsets.only(left: 28),
                  child: Row(children: [
                    Expanded(child:Text(additionalDescription??"",
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies.medium,
                            fontSize: 16,
                            color: Styles().colors.textBackground))),

                  ])),
            ],
            ),
          )
      );
    } else {
      return Container();
    }
  }

  Widget _eventDescription() {
    String longDescription = _event.exploreLongDescription;
    bool showDescription = AppString.isStringNotEmpty(longDescription);
    if (!showDescription) {
      return Container();
    }
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: HtmlWidget(longDescription, textStyle: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies.medium, color: Styles().colors.textSurface)));
  }

  Widget _eventUrlButtons(){
    List<Widget> buttons = <Widget>[];
    
    String titleUrl = _event?.titleUrl;
    bool hasTitleUrl = AppString.isStringNotEmpty(titleUrl);

    String registrationUrl = _event?.registrationUrl;
    bool hasRegistrationUrl = AppString.isStringNotEmpty(registrationUrl);

    if (hasTitleUrl) {
      buttons.add(Row(children:<Widget>[
        Expanded(child:
          Padding(padding: EdgeInsets.only(bottom: 6), child:
            ScalableRoundedButton(
              label: Localization().getStringEx('panel.groups_event_detail.button.visit_website.title', 'Visit website'),
              hint: Localization().getStringEx('panel.groups_event_detail.button.visit_website.hint', ''),
              backgroundColor: hasRegistrationUrl ? Styles().colors.background : Colors.white,
              borderColor: hasRegistrationUrl ? Styles().colors.fillColorPrimary: Styles().colors.fillColorSecondary,
              rightIcon: hasRegistrationUrl ? Image.asset('images/external-link.png', color: Styles().colors.fillColorPrimary, colorBlendMode: BlendMode.srcIn) : Image.asset('images/external-link.png'),
              textColor: Styles().colors.fillColorPrimary,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              onTap: () {
                _onTapWebButton(titleUrl, analyticsName: 'Website');
              }),
      ),),],),);
    }
    
    if (hasRegistrationUrl) {
      buttons.add(Row(children:<Widget>[
        Expanded(child:
        Padding(padding: EdgeInsets.only(bottom: 6), child:
          ScalableRoundedButton(
            label: Localization().getStringEx('panel.groups_event_detail.button.get_tickets.title', 'Register'),
            hint: Localization().getStringEx('panel.groups_event_detail.button.get_tickets.hint', ''),
            backgroundColor: Colors.white,
            borderColor: Styles().colors.fillColorSecondary,
            rightIcon: Image.asset('images/external-link.png'),
            textColor: Styles().colors.fillColorPrimary,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            onTap: () {
              _onTapRegistration(registrationUrl);
            }),
      ),),],),);
    }

    return (0 < buttons.length) ? Column(children: buttons) : Container(width: 0, height: 0);
  }

  Widget _buildFavoritesButton(){
    return
      GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Analytics.instance.logSelect(target: "Favorite");
            User().switchFavorite(_event);
            setState(() {});
          },
          child: Semantics(
              label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization()
                  .getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
              hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx(
                  'widget.card.button.favorite.on.hint', ''),
              button: true,
              child: Image.asset(isFavorite ? 'images/icon-star-solid.png' : 'images/icon-favorites-white.png') //TBD selected image res
          ));
  }

  Widget _buildPreviewButtons(){
    return !(widget.previewMode)? Container():
    Container(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
            RibbonButton(
              leftIcon: "images/icon-edit.png",
              label: Localization().getStringEx('panel.groups_event_detail.button.edit.title',  'Edit') ,
              hint: Localization().getStringEx('panel.groups_event_detail.button.edit.hint', '') ,
              padding: EdgeInsets.zero,
              onTap: _onTapEdit,
            ),
        Container(
          height: 14,
        ),
        Container(
          height: 1,
          color: Styles().colors.surfaceAccent,
        ),
        Container(
          height: 14,
        ),
        RibbonButton(
          leftIcon: "images/icon-leave-group.png",
          label: Localization().getStringEx('panel.groups_event_detail.button.delete.title', "Delete Event"),
          hint:  Localization().getStringEx('panel.groups_event_detail.button.delete.hint', ""),
          padding: EdgeInsets.zero,
          onTap: _onTapDelete,
        )
      ],
    ));
  }

  void _onTapEdit(){
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreateEventPanel(editEvent: _event, onEditTap: (BuildContext context, Event event) {
      Groups().updateGroupEvents(event).then((String id) {
        if (AppString.isStringNotEmpty(id)) {
          Navigator.pop(context);
        }
        else {
          AppAlert.showDialogResult(context, "Unable to update event");
        }
      });
    },)));
  }

  void _onTapDelete(){
    showDialog(context: context, builder: (context)=>
        GroupsConfirmationDialog(
          message: Localization().getStringEx("panel.group_detail.message.delete_event.title",  "Are you sure you want to delete this event?"),
          buttonTitle:Localization().getStringEx("panel.group_detail.button.delete.title", "Delete"),
          onConfirmTap:(){_deleteEvent();})).then((value) => Navigator.pop(context));
  }

  void _deleteEvent(){
    Groups().deleteEventFromGroup(event: _event, groupId: widget?.groupId).then((value){
      Navigator.of(context).pop();
    });
  }

  void _onTapWebButton(String url, { String analyticsName }) {
    if (analyticsName != null) {
      Analytics.instance.logSelect(target: analyticsName);
    }
    if(AppString.isStringNotEmpty(url)){
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url, analyticsName: "WebPanel($analyticsName)",)));
    }
  }

  void _onTapRegistration(String registrationUrl) {
    Analytics.instance.logSelect(target: "Registration");
    if (User().showTicketsConfirmationModal) {
      PrivacyTicketsDialog.show(context, onContinueTap: () {
        _onTapWebButton(registrationUrl);
      });
    } else {
      _onTapWebButton(registrationUrl);
    }
  }

  void _onLocationDetailTapped(){
    if((_event?.isVirtual?? false) == true){
      String url = _event?.location?.description;
      if(AppString.isStringNotEmpty(url)) {
        _onTapWebButton(url, analyticsName: "Event Link");
      }
    } else if(_event?.location?.latitude != null && _event?.location?.longitude != null) {
      Analytics.instance.logSelect(target: "Location Detail");
      NativeCommunicator().launchExploreMapDirections(target: _event);
    }
  }

  void _onOptionsTap(){
    if(_isPrivateGroupEvent){
      return;
    }

    String title =  Localization().getStringEx('panel.groups_event_detail.label.options.add_event', "ADD EVENT");
    String description= Localization().getStringEx('panel.groups_event_detail.label.options.choose_group', "Choose a group you’re an admin for");
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context){
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16,vertical: 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(height: 16,),
                Container(
                    padding: EdgeInsets.only(bottom: 8, top:16),
                    child:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Semantics(
                          label: title,
                          hint: title,
                          header: true,
                          excludeSemantics: true,
                          child:
                          Text(
                            title,
                            style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 12, fontFamily: Styles().fontFamilies.bold),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            description,
                            style: TextStyle(color: Styles().colors.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies.regular),
                          ),
                        )
                      ],)
                  ),
                  GroupDropDownButton(
                    emptySelectionText: Localization().getStringEx('panel.groups_event_detail.button.select_group.title', "Select a group.."),
                    buttonHint: Localization().getStringEx('panel.groups_event_detail.button.select_group.hint', "Double tap to show categories options"),
                    items: _adminGroups,
                    constructTitle: (item) {
                      Group group = item as Group;
                      return group?.title;
                      },
                    onValueChanged: (Group group) {
                      setState(() {
                        _currentlySelectedGroup = group;
                      });
                    }
                ),
                Container(height: 27,),
                ScalableRoundedButton(
                  label: Localization().getStringEx('panel.groups_event_detail.button.add.title', "ADD "),
                  backgroundColor: Colors.white,
                  borderColor: Styles().colors.fillColorSecondary,
                  textColor: Styles().colors.fillColorPrimary,
                  onTap: (){
                    setState(() {
                      //TBD proper add and update
                      if(_currentlySelectedGroup!=null) {
                        _linkedGroups.add(_currentlySelectedGroup);
                        Log.d("Selected group: $_currentlySelectedGroup");
                        AppToast.show(
                            Localization().getStringEx('panel.groups_event_detail.label.link_result',  "Event has been linked to")+ _currentlySelectedGroup?.title??"");
                        Groups().linkEventToGroup(groupId:_currentlySelectedGroup.id,eventId: _event?.id);
                      }
                    });
                  },
                ),
                Container(height: 8,)
              ],
            ),
          );
        }
    );
  }

  bool get isFavorite => User().isFavorite(_event);

  bool get _isPrivateGroupEvent => _event?.isGroupPrivate ?? false;

  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyGroupEventsUpdated) {
      ExploreService().getEventById(_event?.eventId).then((event) {
        setState(() {
          if (event != null)
            event = _event;
        });
      });
    }
  }
}