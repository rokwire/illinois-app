import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/events2/Event2AttendanceDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/auth2.dart' as pluginAuth;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2DetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final String? eventId;
  final Event2? event;
  final Position? userLocation;
  Event2DetailPanel({ this.event, this.eventId, this.userLocation});
  
  @override
  State<StatefulWidget> createState() => _Event2DetailPanelState();

  // AnalyticsPageAttributes

  @override
  Map<String, dynamic>? get analyticsPageAttributes => event?.analyticsAttributes;
}

class _Event2DetailPanelState extends State<Event2DetailPanel> implements NotificationsListener {
  Event2? _event;

  bool _authLoading = false; //TBD visualize
  bool _eventLoading = false; //TBD visualize

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Auth2.notifyLoginChanged,
    ]);
   _initEvent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() { });
    } else if(name == Auth2.notifyLoginChanged){
      _refreshEvent();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(body:
      Column(children: <Widget>[
        Expanded(child:
          CustomScrollView(slivers: <Widget>[
            SliverToutHeaderBar(
              flexImageUrl:  _event?.imageUrl,
              flexImageKey: 'event-detail-default',
              flexRightToLeftTriangleColor: Colors.white,
            ),
            SliverList(delegate:
              SliverChildListDelegate([
                Container(color: Styles().colors?.white, child:
                  Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _badgeWidget,
                    _categoriesWidget,
                    Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
                      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _titleWidget,
                        _sponsorWidget,
                        _detailsWidget,
                      ])
                    ),
                  ]),
                ),
                Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 24), child:
                  Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _descriptionWidget,
                  _buttonsWidget,
               ]))
              ], addSemanticIndexes:false)
            ),
          ])
        ),
      ])
    );
  }

  Widget get _badgeWidget => _event?.userRole == Event2UserRole.admin ?
  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
    Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Styles().colors!.fillColorSecondary, borderRadius: BorderRadius.all(Radius.circular(2)),), child:
      Semantics(label: event2UserRoleToString(_event?.userRole), excludeSemantics: true, child:
        Text(event2UserRoleToString(_event?.userRole)?.toUpperCase() ?? 'ADMIN', style:  Styles().textStyles?.getTextStyle('widget.heading.small'),)
  ))) : Container();


  Widget get _categoriesWidget => 
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 16, top: 16, bottom: 8), child:
          Text(_displayCategories?.join(', ') ?? '', overflow: TextOverflow.ellipsis, maxLines: 2, style: Styles().textStyles?.getTextStyle("widget.card.title.small.fat"))
        ),
      ),
      _favoriteButton
    ]);

  List<String>? get _displayCategories =>
    Events2().contentAttributes?.displaySelectedLabelsFromSelection(_event?.attributes, usage: ContentAttributeUsage.category);

  Widget get _favoriteButton {
    bool isFavorite = Auth2().isFavorite(_event);
    return Opacity(opacity: Auth2().canFavorite ? 1 : 0, child:
      Semantics(container: true,
        child: Semantics(
          label: isFavorite ?
            Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') :
            Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
          hint: isFavorite ?
            Localization().getStringEx('widget.card.button.favorite.off.hint', '') :
            Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
          button: true,
          child: InkWell(onTap: _onFavorite,
            child: Padding(padding: EdgeInsets.all(16),
              child: Styles().images?.getImage(isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true,)
            )
          ),
        ),
      )
    );
  }

  Widget get _titleWidget => Row(children: [
    Expanded(child: 
      Text(_event?.name ?? '', style: Styles().textStyles?.getTextStyle('widget.title.extra_large'), maxLines: 2,)
    ),
  ],);

  Widget get _sponsorWidget => StringUtils.isNotEmpty(_event?.sponsor) ? Padding(padding: EdgeInsets.only(top: 8), child:
    Row(children: [
      Expanded(child: 
        Text(_event?.sponsor ?? '', style: Styles().textStyles?.getTextStyle('widget.item.regular.fat'), maxLines: 2,)
      ),
    ],),
   ) : Container();

  Widget get _descriptionWidget => StringUtils.isNotEmpty(_event?.description) ? Padding(padding: EdgeInsets.only(top: 24, left: 10, right: 10), child:
       HtmlWidget(
          StringUtils.ensureNotEmpty(_event?.description),
          onTapUrl : (url) {_onLaunchUrl(url, context: context); return true;},
          textStyle: Styles().textStyles?.getTextStyle("widget.info.regular")
      )
  ) : Container();

  Widget get _detailsWidget {
    List<Widget> detailWidgets = <Widget>[
      ...?_dateDetailWidget,
      ...?_onlineDetailWidget,
      ...?_locationDetailWidget,
      ...?_priceDetailWidget,
      ...?_privacyDetailWidget,
      ...?_attendanceDetailWidget,
      ...?_contactsDetailWidget,
    ];

    return detailWidgets.isNotEmpty ? Padding(padding: EdgeInsets.only(top: 16), child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: detailWidgets,)
    ) : Container();
  }

  List<Widget>? get _dateDetailWidget {
    String? dateTime = _event?.longDisplayDate;
    return (dateTime != null) ? <Widget>[_buildTextDetailWidget(dateTime, 'calendar')] : null;
  }

  List<Widget>? get _onlineDetailWidget {
    if (_event?.online == true) {
      bool canLaunch = StringUtils.isNotEmpty(_event?.onlineDetails?.url);
      List<Widget> details = <Widget>[
        InkWell(onTap: canLaunch ? _onOnline : null, child:
          _buildTextDetailWidget('Online', 'laptop'),
        ),
      ];

      Widget onlineWidget = canLaunch ?
        Text(_event?.onlineDetails?.url ?? '', style: Styles().textStyles?.getTextStyle('widget.button.title.small.semi_bold.underline'),) :
        Text(_event?.onlineDetails?.url ?? '', style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'),);
      details.add(
        InkWell(onTap: canLaunch ? _onOnline : null, child:
          _buildDetailWidget(onlineWidget, 'laptop', iconVisible: false, contentPadding: EdgeInsets.zero)
        )
      );
      details.add( _detailSpacerWidget);

      return details;
    }
    return null;
  }

  List<Widget>? get _locationDetailWidget {
    if (_event?.inPerson == true) {

      bool canLocation = _event?.location?.isLocationCoordinateValid ?? false;
      
      List<Widget> details = <Widget>[
        InkWell(onTap: canLocation ? _onLocation : null, child:
          _buildTextDetailWidget('In Person', 'location'),
        ),
      ];

      String? locationText = (
        _event?.location?.displayName ??
        _event?.location?.displayAddress ??
        _event?.location?.displayCoordinates
      );
      if (locationText != null) {
        Widget locationWidget = canLocation ?
          Text(locationText, maxLines: 1, style: Styles().textStyles?.getTextStyle('widget.button.title.small.semi_bold.underline'),) :
          Text(locationText, maxLines: 1, style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'),);
        details.add(
          InkWell(onTap: canLocation ? _onLocation : null, child:
            _buildDetailWidget(locationWidget, 'location', iconVisible: false, contentPadding: EdgeInsets.zero)
          )
        );
        details.add( _detailSpacerWidget);
      }
      return details;
    }
    return null;
  }

  List<Widget>? get _priceDetailWidget{
    bool isFree = _event?.free ?? false;
    String priceText =isFree? "Free" : (_event?.cost ?? "Free");
    String? additionalDescription = isFree? _event?.cost : null;
    List<Widget>? details = priceText.isNotEmpty ? <Widget>[
      _buildTextDetailWidget(priceText, 'cost'),
    ] : null;
    
    if(details != null && StringUtils.isNotEmpty(additionalDescription)){
      details.add(Container(padding: EdgeInsets.only(left: 28), child:
        Row(children: [Expanded(child:
            Text(additionalDescription!, style: Styles().textStyles?.getTextStyle("widget.item.regular"))),
          ])));
    }
    details?.add( _detailSpacerWidget);

    return details;
  }

  List<Widget>? get _privacyDetailWidget{
    String privacyTypeTitle = _event?.private == true ?
      Localization().getStringEx('panel.explore_detail.label.privacy.private.title', 'Private Event') :
      Localization().getStringEx('panel.explore_detail.label.privacy.public.title', 'Public Event');

    return [_buildTextDetailWidget(privacyTypeTitle, "privacy"), _detailSpacerWidget];
  }

  List<Widget>? get _attendanceDetailWidget => <Widget>[
        InkWell(
            onTap: _onTapTakeAttendance,
            child: _buildTextDetailWidget(Localization().getStringEx('panel.event2.detail.take_attendance.title', 'Take Attendance'), 'qr', underlined: true)),
        _detailSpacerWidget
      ];

  List<Widget>? get _contactsDetailWidget{
    if(CollectionUtils.isEmpty(_event?.contacts))
      return null;

    List<Widget> contactList = [];
    contactList.add(Padding(
        padding: EdgeInsets.only(bottom: 5), child: Text(Localization().getStringEx('panel.explore_detail.label.contacts', 'Contacts:'))));

    for (Event2Contact? contact in _event!.contacts!) {
      String? details =  event2ContactToDisplayString(contact);
      if(StringUtils.isNotEmpty(details)){
        contactList.add(Padding(padding: EdgeInsets.only(bottom: 5), child:
          Text(details!, style: Styles().textStyles?.getTextStyle("widget.text.regular"))
        ));
      }
    }

    contactList.add( _detailSpacerWidget);

    return contactList;
  }

  Widget get _buttonsWidget {
    List<Widget> buttons = <Widget>[
      ...?_urlButtonWidget,
      ...?_registrationButtonWidget,
      ...?_logInButtonWidget
    ];

    return buttons.isNotEmpty ? Padding(padding: EdgeInsets.only(top: 16), child:
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: buttons,)
    ) : Container();
  }

  List<Widget>? get _urlButtonWidget => //TBD check if this is the proper url for this button
    StringUtils.isNotEmpty(_event?.eventUrl) ? <Widget>[_buildButtonWidget(
      title: Localization().getStringEx('panel.groups_event_detail.button.visit_website.title', 'Visit website'),
      hint: Localization().getStringEx('panel.groups_event_detail.button.visit_website.hint', ''),
      onTap: (){_onWebButton(_event?.eventUrl, analyticsName: 'Website');}
    )] : null;

  List<Widget>? get _logInButtonWidget{//TBD localize
    if(Auth2().isLoggedIn == true)
      return null;

    return (_event?.registrationDetails?.type == Event2RegistrationType.internal) ? <Widget>[_buildButtonWidget(
        title: Localization().getStringEx('panel.event2_detail.button.unregister.title', 'Log In to Register'),
        onTap: _onLogIn,
        externalLink: false,
        enabled: false
    )] : null;
  }

  List<Widget>? get _registrationButtonWidget{//TBD localize
    if(Auth2().isLoggedIn == false) //We can register only if logged in
      return null;

    if (_event?.registrationDetails?.type == Event2RegistrationType.internal) { //Require App registration
        if(_event?.userRole == Event2UserRole.participant){//Already registered
          return <Widget>[_buildButtonWidget(
              title: Localization().getStringEx('panel.event2_detail.button.unregister.title', 'Unregister me'),
              onTap: _onUnregister,
              externalLink: false,
              enabled: false
          )];
        } else if (_event?.userRole == null){//Not registered yet
          return <Widget>[_buildButtonWidget(
              title: Localization().getStringEx('panel.event2_detail.button.register.title', 'Register me'),
              onTap: _onRegister,
              externalLink: false
          )];
        }
    } else if(StringUtils.isNotEmpty(_event?.registrationDetails?.externalLink)){// else external registration
      if(_event?.userRole == null){ //TBD check if this is correct check or we don't know if the user is registered externally
        return <Widget>[_buildButtonWidget(
            title: Localization().getStringEx('panel.event2_detail.button.register.title', 'Register me'),
            onTap: _onExternalRegistration,
            externalLink: true
        )];
      }
    }

    return null; //not required
  }

  Widget get _detailSpacerWidget => Container(height: 8,);

  Widget _buildTextDetailWidget(String text, String iconKey, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
    bool iconVisible = true,
    bool underlined = false
  }) =>
    _buildDetailWidget(
      Text(text, maxLines: 1, style: Styles().textStyles?.getTextStyle(underlined ? 'widget.explore.card.detail.regular.underline' : 'widget.explore.card.detail.regular'),),
      iconKey,
      contentPadding: contentPadding,
      iconPadding: iconPadding,
      iconVisible: iconVisible
    );

  Widget _buildDetailWidget(Widget contentWidget, String iconKey, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
    bool iconVisible = true
  }) {
    List<Widget> contentList = <Widget>[];
    Widget? iconWidget = Styles().images?.getImage(iconKey, excludeFromSemantics: true);
    if (iconWidget != null) {
      contentList.add(Padding(padding: iconPadding, child:
        Opacity(opacity: iconVisible ? 1 : 0, child:
          iconWidget,
        )
      ));
    }
    contentList.add(Expanded(child:
      contentWidget
    ),);
    return Padding(padding: contentPadding, child:
      Row(children: contentList)
    );
  }

  Widget _buildButtonWidget({String? title,
    String? hint,
    bool enabled = true,
    bool externalLink = true,
    void Function()? onTap
  }) => StringUtils.isNotEmpty(title) ?
    Padding(padding: EdgeInsets.only(bottom: 6), child:
      Row(children:<Widget>[
        Expanded(child:
          RoundedButton(
              label: StringUtils.ensureNotEmpty(title),
              hint: hint,
              textStyle: enabled ? Styles().textStyles?.getTextStyle("widget.button.title.small.fat") : Styles().textStyles?.getTextStyle("widget.button.disabled.title.small.fat"),
              backgroundColor: enabled ? Colors.white : Styles().colors!.background,
              borderColor: enabled ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
              rightIcon:externalLink? Styles().images?.getImage(enabled ? 'external-link' : 'external-link-dark' ) : null,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              onTap: onTap ?? (){},
            contentWeight: 0.5,

          ),
        ),],)
      ) : Container();

  void _onLocation() {
    Analytics().logSelect(target: "Location Directions: ${_event?.name}");
    _event?.launchDirections();
  }

  void _onOnline() {
    Analytics().logSelect(target: "Online Url: ${_event?.name}");
  }

  void _onFavorite() {
    Analytics().logSelect(target: "Favorite: ${_event?.name}");
    Auth2().prefs?.toggleFavorite(_event);
  }

  void _onLaunchUrl(String? url, {BuildContext? context}) {
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

  void _onWebButton(String? url, { String? analyticsName }) {
    if (analyticsName != null) {
      Analytics().logSelect(target: analyticsName);
    }
    if(StringUtils.isNotEmpty(url)){
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url, analyticsName: "WebPanel($analyticsName)",)));
    }
  }

  void _onRegister(){
    if(_event?.id != null){
      Events2().registerToEvent(_event!.id!).then((value){
          if(value != null){ //success
            String? errorMessage = JsonUtils.stringValue(value);
            if(StringUtils.isNotEmpty(errorMessage)){
              Log.e(errorMessage);
            } else {
              _refreshEvent();
            }
          }
      });
    }
  }

  void _onUnregister(){
    if(_event?.id != null){
      Events2().unregisterFromEvent(_event!.id!).then((value){
        if(value != null){ //success
          String? errorMessage = JsonUtils.stringValue(value);
          if(StringUtils.isNotEmpty(errorMessage)){
            Log.e(errorMessage);
          } else {
            _refreshEvent();
          }
        }
      });
    }
  }

  void _onExternalRegistration(){
    if(StringUtils.isNotEmpty(_event?.registrationDetails?.externalLink))
       _onLaunchUrl(_event?.registrationDetails?.externalLink);
  }

  void _onLogIn(){
    Analytics().logSelect(target: "Log in");
    if (_authLoading != true) {
      setState(() { _authLoading = true; });
      Auth2().authenticateWithOidc().then((pluginAuth.Auth2OidcAuthenticateResult? result) {
        setStateIfMounted(() { _authLoading = false; });
          if (result != pluginAuth.Auth2OidcAuthenticateResult.succeeded) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      );
    }
  }

  void _onTapTakeAttendance() {
    Analytics().logSelect(target: 'Take Attendance');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2AttendanceDetailPanel(event: _event)));
  }

  //loading
  void _initEvent() async {
    _event = widget.event;

    if(_event == null && StringUtils.isEmpty(widget.eventId!)) {
      _eventLoading = true;
      _loadEvent().then((event) {
        _eventLoading = false;
        _event = event;
        setStateIfMounted(() { });
      });
    }
  }

  void _refreshEvent({bool visibleProgress = false}){
    _eventLoading = visibleProgress;

    _loadEvent().then((event) {
      _eventLoading = false;
      _event = event;
      setStateIfMounted(() { });
    });
  }

  Future<Event2?> _loadEvent() async {
    if(_eventLoading){
      // return Do we allow it?
    }

    String? eventId = _event?.id ?? widget.eventId;
    if(eventId != null) {
      return Events2().loadEvent(eventId);
    }
    return null;
  }

}
