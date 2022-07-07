
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Event.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';


class GroupEventDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Event? event;
  final Group? group;
  final bool previewMode;

  String? get groupId => group?.id;

  const GroupEventDetailPanel({Key? key,this.previewMode = false, this.event, this.group}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GroupEventDetailsPanelState();
  }

  @override
  Map<String, dynamic>? get analyticsPageAttributes {
    return group?.analyticsAttributes;
  }
}

class _GroupEventDetailsPanelState extends State<GroupEventDetailPanel> with NotificationsListener{
  List<Group> _adminGroups = [];
  Event? _event;
  Group? _currentlySelectedGroup;

  @override
  void initState() {
    _event = widget.event;
    Groups().loadGroups(contentType: GroupsContentType.my).then((groups) {
      if(groups?.isNotEmpty ?? false){
        _adminGroups = groups!.where((group) => group.currentUserIsAdmin).toList();
      }
      setState(() {});
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
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
      body: Column(children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eventImageHeader(),
                Container(
                  color: Styles().colors!.white,
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
                      _eventPrivacyDetail(),
                      _eventContacts(),
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
    String? imageUrl = widget.event?.eventImageUrl;
    return Container(
      height: 200,
      color: Styles().colors!.background,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          StringUtils.isNotEmpty(imageUrl) ?  Positioned.fill(child:Image.network(imageUrl ?? '', fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true)) : Container(),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors!.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.leftToRight),
            child: Container(
              height: 53,
            ),
          ),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors!.white),
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
                fontFamily: Styles().fontFamilies!.bold,
                fontSize: 14,
                color: Styles().colors!.fillColorPrimary,
                letterSpacing: 1),
          ),
          Container(height: 8,),
          Text(
            _event!.exploreTitle!,
            style: TextStyle(
                fontSize: 24,
                color: Styles().colors!.fillColorPrimary),
          ),
        ],
      )
    );
  }

  Widget _eventTimeDetail() {
    String? displayTime = _event?.displayDateTime;
    //Newly created groups pass time in the string
    if(StringUtils.isEmpty(displayTime?.trim())){
      if(_event?.startDateString !=null || _event?.endDateString != null){
        DateTime? startDate = DateTimeUtils.dateTimeFromString(_event?.startDateString, format: Event.serverRequestDateTimeFormat);
        DateTime? endDate = DateTimeUtils.dateTimeFromString(_event?.endDateString, format: Event.serverRequestDateTimeFormat);
        if(startDate !=null){
          displayTime = AppDateTime().formatDateTime(startDate, format: "MMM dd, yyyy");
        } else if(endDate != null){
          displayTime = AppDateTime().formatDateTime(endDate, format: "MMM dd, yyyy");
        }
      }
    }
    if (StringUtils.isNotEmpty(displayTime)) {
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
                Expanded(child: Text(displayTime!,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies!.medium,
                        fontSize: 16,
                        color: Styles().colors!.textBackground))),
              ],
            ),
          )
      );
    } else {
      return Container();
    }
  }

  Widget _eventLocationDetail() {
    String? locationText = _event?.getLongDisplayLocation(null); //TBD decide if we need distance calculation - pass _locationData
    bool isVirtual = _event?.isVirtual ?? false;
    String eventType = isVirtual? Localization().getStringEx('panel.groups_event_detail.label.online_event', "Online Event") : Localization().getStringEx('panel.groups_event_detail.label.in_person_event', "In-person event");
    bool hasEventUrl = StringUtils.isNotEmpty(_event?.location?.description);
    bool isOnlineUnderlined = isVirtual && hasEventUrl;
    BoxDecoration underlineLocationDecoration = BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors!.fillColorSecondary!, width: 1)));
    String iconRes = isVirtual? "images/laptop.png" : "images/location.png" ;
    String locationId = StringUtils.ensureNotEmpty(_event?.location?.locationId);
    bool isLocationIdUrl = Uri.tryParse(locationId)?.isAbsolute ?? false;
    String? value = isVirtual ? locationId : locationText;
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
                          child:Image.asset(iconRes),
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
                            value??"",
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

  Widget _eventPriceDetail() {
    bool isFree = _event?.isEventFree ?? false;
    String priceText =isFree? "Free" : (_event?.cost ?? "Free");
    String? additionalDescription = isFree? _event?.cost : null;
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
                      child:Image.asset('images/icon-cost.png'),
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
                    Expanded(child:Text(additionalDescription??"",
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
      return Container();
    }
  }

  Widget _eventPrivacyDetail() {
    String privacyText = _isPrivateGroupEvent
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
                Padding(padding: EdgeInsets.only(left: 1, right: 11), child: Image.asset('images/icon-privacy.png')),
                Expanded(
                    child: Text(privacyText, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)))
              ])
            ])));
  }

  Widget _eventContacts() {
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

  Widget _eventDescription() {
    String? longDescription = _event!.exploreLongDescription;
    bool showDescription = StringUtils.isNotEmpty(longDescription);
    if (!showDescription) {
      return Container();
    }
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Html(
          data: longDescription,
          onLinkTap: (url, renderContext, attributes, element) => _launchUrl(url, context: context),
          style: { "body": Style(color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.medium, fontSize: FontSize(16), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
      ));
  }

  Widget _eventUrlButtons(){
    List<Widget> buttons = <Widget>[];
    
    String? titleUrl = _event?.titleUrl;
    bool hasTitleUrl = StringUtils.isNotEmpty(titleUrl);

    String? registrationUrl = _event?.registrationUrl;
    bool hasRegistrationUrl = StringUtils.isNotEmpty(registrationUrl);

    if (hasTitleUrl) {
      buttons.add(Row(children:<Widget>[
        Expanded(child:
          Padding(padding: EdgeInsets.only(bottom: 6), child:
            RoundedButton(
              label: Localization().getStringEx('panel.groups_event_detail.button.visit_website.title', 'Visit website'),
              hint: Localization().getStringEx('panel.groups_event_detail.button.visit_website.hint', ''),
              backgroundColor: hasRegistrationUrl ? Styles().colors!.background : Colors.white,
              borderColor: hasRegistrationUrl ? Styles().colors!.fillColorPrimary: Styles().colors!.fillColorSecondary,
              rightIcon: hasRegistrationUrl ? Image.asset('images/external-link.png', color: Styles().colors!.fillColorPrimary, colorBlendMode: BlendMode.srcIn) : Image.asset('images/external-link.png'),
              textColor: Styles().colors!.fillColorPrimary,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              onTap: () {
                Analytics().logSelect(target: 'Event website');
                _onTapWebButton(titleUrl, analyticsName: 'Website');
              }),
      ),),],),);
    }
    
    if (hasRegistrationUrl) {
      buttons.add(Row(children:<Widget>[
        Expanded(child:
        Padding(padding: EdgeInsets.only(bottom: 6), child:
          RoundedButton(
            label: Localization().getStringEx('panel.groups_event_detail.button.get_tickets.title', 'Register'),
            hint: Localization().getStringEx('panel.groups_event_detail.button.get_tickets.hint', ''),
            backgroundColor: Colors.white,
            borderColor: Styles().colors!.fillColorSecondary,
            rightIcon: Image.asset('images/external-link.png'),
            textColor: Styles().colors!.fillColorPrimary,
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
      Visibility(visible: Auth2().canFavorite,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Analytics().logSelect(target: "Favorite: ${_event?.title}");
            Auth2().prefs?.toggleFavorite(_event);
            setState(() {});
          },
          child: Semantics(
              label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization()
                  .getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
              hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx(
                  'widget.card.button.favorite.on.hint', ''),
              button: true,
              child: Image.asset(isFavorite ? 'images/icon-star-white-transluent.png' : 'images/icon-star-white-frame-bold.png') //TBD selected image res
          )));
  }

  Widget _buildPreviewButtons(){
    return !(widget.previewMode)? Container():
    Container(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
            RibbonButton(
              label: Localization().getStringEx('panel.groups_event_detail.button.edit.title',  'Edit') ,
              hint: Localization().getStringEx('panel.groups_event_detail.button.edit.hint', '') ,
              leftIconAsset: "images/icon-edit.png",
              onTap: _onTapEdit,
            ),
        Container(
          height: 14,
        ),
        Container(
          height: 1,
          color: Styles().colors!.surfaceAccent,
        ),
        Container(
          height: 14,
        ),
        RibbonButton(
          label: Localization().getStringEx('panel.groups_event_detail.button.delete.title', "Delete Event"),
          hint:  Localization().getStringEx('panel.groups_event_detail.button.delete.hint', ""),
          leftIconAsset: "images/icon-leave-group.png",
          onTap: _onTapDelete,
        )
      ],
    ));
  }

  void _onTapEdit(){
    Analytics().logSelect(target: 'Edit Event');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreateEventPanel(group: widget.group, editEvent: _event, onEditTap: (BuildContext context, Event event, List<Member>? selection) {
      Groups().updateGroupEvents(event).then((String? id) {
        if (StringUtils.isNotEmpty(id)) {
          Groups().updateLinkedEventMembers(groupId: widget.groupId,eventId: event.id, toMembers: selection).then((success){
              if(success){
                Navigator.pop(context);
              } else {
                AppAlert.showDialogResult(context, "Unable to update event members");
              }
          }).catchError((_){
            AppAlert.showDialogResult(context, "Error Occurred while updating event members");
          });
        }
        else {
          AppAlert.showDialogResult(context, "Unable to update event");
        }
      }).catchError((_){
        AppAlert.showDialogResult(context, "Error Occurred while updating event");
      });
    },)));
  }

  void _onTapDelete(){
    Analytics().logSelect(target: 'Delete Event');
    showDialog(context: context, builder: (context)=>
        GroupsConfirmationDialog(
          message: Localization().getStringEx("panel.group_detail.message.delete_event.title",  "Are you sure you want to delete this event?"),
          buttonTitle:Localization().getStringEx("panel.group_detail.button.delete.title", "Delete"),
          onConfirmTap:(){_deleteEvent();})).then((value) => Navigator.pop(context));
  }

  void _deleteEvent(){
    Groups().deleteEventFromGroup(event: _event!, groupId: widget.groupId).then((value){
      Navigator.of(context).pop();
    });
  }

  void _onTapWebButton(String? url, { String? analyticsName }) {
    if (analyticsName != null) {
      Analytics().logSelect(target: analyticsName);
    }
    if(StringUtils.isNotEmpty(url)){
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url, analyticsName: "WebPanel($analyticsName)",)));
    }
  }

  void _onTapRegistration(String? registrationUrl) {
    Analytics().logSelect(target: "Registration");
    if (PrivacyTicketsDialog.shouldConfirm) {
      PrivacyTicketsDialog.show(context, onContinueTap: () {
        _onTapWebButton(registrationUrl);
      });
    } else {
      _onTapWebButton(registrationUrl);
    }
  }

  void _onLocationDetailTapped(){
    Analytics().logSelect(target: 'Event location/url');
    if((_event?.isVirtual?? false) == true){
      String? url = _event?.location?.description;
      if(StringUtils.isNotEmpty(url)) {
        _onTapWebButton(url, analyticsName: "Event Link");
      }
    } else if(_event?.location?.latitude != null && _event?.location?.longitude != null) {
      Analytics().logSelect(target: "Location Detail");
      NativeCommunicator().launchExploreMapDirections(target: _event);
    }
  }

  void _onOptionsTap(){
    Analytics().logSelect(target: 'Event options');
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
                            style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 12, fontFamily: Styles().fontFamilies!.bold),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            description,
                            style: TextStyle(color: Styles().colors!.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies!.regular),
                          ),
                        )
                      ],)
                  ),
                  GroupDropDownButton(
                    emptySelectionText: Localization().getStringEx('panel.groups_event_detail.button.select_group.title', "Select a group.."),
                    buttonHint: Localization().getStringEx('panel.groups_event_detail.button.select_group.hint', "Double tap to show categories options"),
                    items: _adminGroups,
                    constructTitle: (Group group) {
                      return group.title;
                      },
                    onValueChanged: (Group group) {
                      setState(() {
                        _currentlySelectedGroup = group;
                      });
                    }
                ),
                Container(height: 27,),
                RoundedButton(
                  label: Localization().getStringEx('panel.groups_event_detail.button.add.title', "ADD "),
                  backgroundColor: Colors.white,
                  borderColor: Styles().colors!.fillColorSecondary,
                  textColor: Styles().colors!.fillColorPrimary,
                  onTap: (){
                    Analytics().logSelect(target: 'Add');
                    setState(() {
                      if(_currentlySelectedGroup!=null) {
                        Log.d("Selected group: $_currentlySelectedGroup");
                        AppToast.show(
                            Localization().getStringEx('panel.groups_event_detail.label.link_result',  "Event has been linked to") + (_currentlySelectedGroup?.title ?? ""));
                        Groups().linkEventToGroup(groupId:_currentlySelectedGroup!.id,eventId: _event?.id);
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

  void _launchUrl(String? url, {BuildContext? context}) {
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context!, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url!);
      }
    }
  }

  bool get isFavorite => Auth2().isFavorite(_event);

  bool get _isPrivateGroupEvent => _event?.isGroupPrivate ?? false;

  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyGroupEventsUpdated) {
      Events().getEventById(_event?.eventId).then((event) {
        setState(() {
          if (event != null)
            event = _event;
        });
      });
    }
  }
}