
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';


class GroupEventDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Event2? event;
  final Group? group;
  final bool previewMode;

  String? get groupId => group?.id;

  const GroupEventDetailPanel({Key? key,this.previewMode = false, this.group, this.event}) : super(key: key);

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
  Event2? _event;
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

    NotificationService().subscribe(this, [
      Groups.notifyGroupEventsUpdated,
      FlexUI.notifyChanged,
    ]);
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
                  icon: Styles().images?.getImage('more-white') ?? Container(),
                  onPressed:_onOptionsTap,
              ))
          )
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
                      _eventOnlineDetail(),
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
    String? imageUrl = widget.event?.imageUrl;
    return Container(
      height: 200,
      color: Styles().colors!.background,
      child:Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          StringUtils.isNotEmpty(imageUrl) ?  Positioned.fill(child: ModalImageHolder(child: Image.network(imageUrl ?? '', fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true))) : Container(),
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
    dynamic category = (_event?.attributes != null) ? _event?.attributes!['category'] : null;
    return Container(child:
        Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            JsonUtils.stringValue(category)?.toUpperCase() ?? "",
            style: Styles().textStyles?.getTextStyle("widget.title.light.small.fat.spaced")
          ),
          Container(height: 8,),
          Text(
            _event!.exploreTitle!,
            style: Styles().textStyles?.getTextStyle("widget.title.extra_large")
          ),
        ],
      )
    );
  }

  Widget _eventTimeDetail() {
    String? displayTime = _event?.longDisplayDateAndTime;
    //Newly created groups pass time in the string
    if(StringUtils.isEmpty(displayTime?.trim())){
      if(_event?.startTimeUtc !=null || _event?.endTimeUtc != null){
        DateTime? startDate = _event?.startTimeUtc?.toLocal();
        DateTime? endDate = _event?.endTimeUtc?.toLocal() ;
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
                  child: Styles().images?.getImage('calendar'),
                ),
                Expanded(child: Text(displayTime!,
                    style: Styles().textStyles?.getTextStyle("widget.item.regular"))),
              ],
            ),
          )
      );
    } else {
      return Container();
    }
  }

  Widget _eventLocationDetail() {
    if(!(widget.event?.isInPerson ?? false)){
      return Container();
    }
    String eventType = Localization().getStringEx('panel.explore_detail.event_type.in_person', "In-person event");
    BoxDecoration underlineLocationDecoration = BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors!.fillColorSecondary!, width: 1)));
    String iconKey = "location" ;
    String? locationId = widget.event?.location?.id;
    String? locationText = _event?.getLongDisplayLocation(null); // if we need distance calculation - pass _locationData
    String? value = locationId ?? locationText;
    bool isValueVisible = StringUtils.isNotEmpty(value);
    return GestureDetector(
      onTap: _onLocationDetailTapped,
      child: Semantics(
          label: "$eventType, $locationText",
          hint: Localization().getStringEx('panel.explore_detail.button.directions.hint', ''),
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
                          child: Styles().images?.getImage(iconKey, excludeFromSemantics: true),
                        ),
                        Container(decoration: (null), padding: EdgeInsets.only(bottom: (0)), child: Text(eventType,
                            style: Styles().textStyles?.getTextStyle("widget.item.regular")),),
                      ]),
                  Container(height: 4,),
                  Visibility(visible: isValueVisible, child: Container(
                      padding: EdgeInsets.only(left: 30),
                      child: Container(
                          decoration: underlineLocationDecoration,
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                            value??"",
                            style: Styles().textStyles?.getTextStyle("widget.title.small.semi_fat")
                          ))))
                ],)
          )
      ),
    );
  }

  Widget _eventOnlineDetail() {
    if(!(widget.event?.isOnline ?? false)){
      return Container();
    }

    String eventType = Localization().getStringEx('panel.explore_detail.event_type.online', "Online Event");
    BoxDecoration underlineLocationDecoration = BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors!.fillColorSecondary!, width: 1)));
    String iconKey = "laptop";
    String? virtualUrl = widget.event?.onlineDetails?.url;
    String locationDescription = StringUtils.ensureNotEmpty(widget.event?.location?.description);
    String? locationId = widget.event?.location?.id;
    String? urlFromLocation = locationId ??  locationDescription;
    bool isLocationIdUrl = Uri.tryParse(urlFromLocation)?.isAbsolute ?? false;
    String value = virtualUrl ??
        (isLocationIdUrl? urlFromLocation : "");

    bool isValueVisible = StringUtils.isNotEmpty(value);
    return GestureDetector(
      onTap: _onLocationDetailTapped,
      child: Semantics(
          label: "$eventType, $virtualUrl",
          hint: Localization().getStringEx('panel.explore_detail.button.virtual.hint', 'Double tap to open link'),
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
                          child: Styles().images?.getImage(iconKey, excludeFromSemantics: true),
                        ),
                        Container(decoration: (StringUtils.isNotEmpty(value) ? underlineLocationDecoration : null), padding: EdgeInsets.only(bottom: (StringUtils.isNotEmpty(value) ? 2 : 0)), child: Text(eventType,
                            style: Styles().textStyles?.getTextStyle("widget.item.regular")),),
                      ]),
                  Container(height: 4,),
                  Visibility(visible: isValueVisible, child: Container(
                      padding: EdgeInsets.only(left: 30),
                      child: Container(
                          decoration: underlineLocationDecoration,
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                            value,
                            style: Styles().textStyles?.getTextStyle("widget.title.small.semi_fat")
                          ))))
                ],)
          )
      ),
    );
  }

  Widget _eventPriceDetail() {
    bool isFree = _event?.free ?? false;
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
                      child: Styles().images?.getImage("cost"),
                    ),
                    Expanded(child:Text(priceText,
                        style: Styles().textStyles?.getTextStyle("widget.item.regular"))),

                  ]),
              !hasAdditionalDescription? Container():
              Container(
                  padding: EdgeInsets.only(left: 28),
                  child: Row(children: [
                    Expanded(child:Text(additionalDescription??"",
                        style: Styles().textStyles?.getTextStyle("widget.item.regular"))),

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
                Padding(padding: EdgeInsets.only(left: 1, right: 11), child: Styles().images?.getImage('privacy')),
                Expanded(
                    child: Text(privacyText, style: Styles().textStyles?.getTextStyle("widget.item.regular")))
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
    for (Event2Contact? contact in widget.event!.contacts!) {
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

  Widget _eventDescription() {
    String? description = _event!.description;
    bool showDescription = StringUtils.isNotEmpty(description);
    if (!showDescription) {
      return Container();
    }
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: HtmlWidget(
            StringUtils.ensureNotEmpty(description),
            onTapUrl : (url) {_launchUrl(url, context: context); return true;},
            textStyle: Styles().textStyles?.getTextStyle("widget.info.regular")
        ));
  }

  Widget _eventUrlButtons(){
    List<Widget> buttons = <Widget>[];
    
    String? titleUrl = _event?.eventUrl;
    bool hasTitleUrl = StringUtils.isNotEmpty(titleUrl);

    String? registrationUrl = _event?.registrationDetails?.externalLink; //TBD Internal App Registration
    bool hasRegistrationUrl = StringUtils.isNotEmpty(registrationUrl);

    if (hasTitleUrl) {
      buttons.add(Row(children:<Widget>[
        Expanded(child:
          Padding(padding: EdgeInsets.only(bottom: 6), child:
            RoundedButton(
              label: Localization().getStringEx('panel.groups_event_detail.button.visit_website.title', 'Visit website'),
              hint: Localization().getStringEx('panel.groups_event_detail.button.visit_website.hint', ''),
              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
              backgroundColor: hasRegistrationUrl ? Styles().colors!.background : Colors.white,
              borderColor: hasRegistrationUrl ? Styles().colors!.fillColorPrimary: Styles().colors!.fillColorSecondary,
              rightIcon: Styles().images?.getImage(hasRegistrationUrl ? 'external-link-dark' : 'external-link'),
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
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
            backgroundColor: Colors.white,
            borderColor: Styles().colors!.fillColorSecondary,
            rightIcon: Styles().images?.getImage('external-link'),
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
            Analytics().logSelect(target: "Favorite: ${_event?.name}");
            Auth2().prefs?.toggleFavorite(_event);
            setState(() {});
          },
          child: Semantics(
              label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization()
                  .getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
              hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx(
                  'widget.card.button.favorite.on.hint', ''),
              button: true,
              child: Styles().images?.getImage(isFavorite ? 'star-filled' : 'star-outline-gray')
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
              leftIconKey: "edit",
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
          leftIconKey: "trash",
          onTap: _onTapDelete,
        )
      ],
    ));
  }

  void _onTapEdit(){
    Analytics().logSelect(target: 'Edit Event');
    Navigator.push(context, MaterialPageRoute(builder: (context) => Event2CreatePanel(event: widget.event,
    //     event2Updater: Event2Updater(
    //     buildWidget: (context) => Container(
    //       child: RoundedButton( label: "Edit Members Selection",
    //         onTap: (){
    //           //TBD open Members Selection Panel
    //         },
    //       )
    //     ),
    //   onUpdated: (BuildContext context, Event2? event, /*List<Member>? selection*/) {
    //     //TBD Members selection
    //     List<Member>? memberSelection = null;
    //       if(event!=null){
    //         Groups().updateGroupEvents(event).then((String? id) {
    //           if (StringUtils.isNotEmpty(id)) {
    //             Groups().updateLinkedEventMembers(groupId: widget.groupId,eventId: event.id, toMembers: memberSelection).then((success){
    //                 if(success){
    //                   Navigator.pop(context);
    //                 } else {
    //                   AppAlert.showDialogResult(context, "Unable to update event members");
    //                 }
    //             }).catchError((_){
    //               AppAlert.showDialogResult(context, "Error Occurred while updating event members");
    //             });
    //           }
    //           else {
    //             AppAlert.showDialogResult(context, "Unable to update event");
    //           }
    //         }).catchError((_){
    //           AppAlert.showDialogResult(context, "Error Occurred while updating event");
    //         });
    // }})
    )));
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
    if(_event != null) {
      Groups().deleteEventForGroupV3(eventId: _event?.id, groupId: widget.groupId)
        .then((bool value) {
          if (value) {
            Navigator.of(context).pop();
          }
          else {
            AppAlert.showDialogResult(context, Localization().getStringEx('panel.group_detail.event.delete.failed.msg', 'Failed to delete event.'));
          }
        });
    }
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
    if((_event?.isOnline?? false) == true){
      String? url = _event?.onlineDetails?.url;
      if(StringUtils.isNotEmpty(url)) {
        _onTapWebButton(url, analyticsName: "Event Link");
      }
    } else if(_event?.location?.latitude != null && _event?.location?.longitude != null) {
      Analytics().logSelect(target: "Location Directions");
      _event?.launchDirections();
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
                          child: Text(title,
                            style: Styles().textStyles?.getTextStyle("widget.title.tiny")
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            description,
                            style: Styles().textStyles?.getTextStyle("widget.item.small.thin")
                          ),
                        )
                      ],)
                  ),
                  GroupDropDownButton(
                    emptySelectionText: Localization().getStringEx('panel.groups_event_detail.button.select_group.title', "Select a group"),
                    buttonHint: Localization().getStringEx('panel.groups_event_detail.button.select_group.hint', "Double tap to show categories options"),
                    items: _adminGroups,
                    constructTitle: (dynamic group) {
                      return group is Group ? group.title : "N/A";
                      },
                    onValueChanged: (dynamic group) {
                      setState(() {
                        _currentlySelectedGroup = group;
                      });
                    }
                ),
                Container(height: 27,),
                RoundedButton(
                  label: Localization().getStringEx('panel.groups_event_detail.button.add.title', "ADD "),
                  textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                  backgroundColor: Colors.white,
                  borderColor: Styles().colors!.fillColorSecondary,
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
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri);
        }
      }
    }
  }

  bool get isFavorite => Auth2().isFavorite(_event);

  bool get _isPrivateGroupEvent => _event?.private ?? false;

  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyGroupEventsUpdated) {
      if(_event?.id != null) {
        Events2().loadEvent(_event!.id!).then((event) {
          setStateIfMounted(() {
            if (event != null)
              event = _event;
          });
        });
      }
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() { });
    }
  }
}