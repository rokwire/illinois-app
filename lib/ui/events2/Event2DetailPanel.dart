import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Survey.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/DeviceCalendar.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/events2/Event2AttendanceTakerPanel.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/events2/Event2QrCodePanel.dart';
import 'package:illinois/ui/events2/Event2SetupAttendancePanel.dart';
import 'package:illinois/ui/events2/Event2SetupRegistrationPanel.dart';
import 'package:illinois/ui/events2/Event2SetupSurveyPanel.dart';
import 'package:illinois/ui/events2/Event2SurveyResponsesPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/auth2.dart' as pluginAuth;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2DetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Event2? event;
  final String? eventId;
  final Survey? survey;
  final Position? userLocation;
  Event2DetailPanel({ this.event, this.eventId, this.survey, this.userLocation});
  
  @override
  State<StatefulWidget> createState() => _Event2DetailPanelState();

  // AnalyticsPageAttributes

  @override
  Map<String, dynamic>? get analyticsPageAttributes => event?.analyticsAttributes;
}

class _Event2DetailPanelState extends State<Event2DetailPanel> implements NotificationsListener {

  Event2? _event;
  Event2PersonsResult? _persons;
  Survey? _survey;

  // Keep a copy of the user position in the State because it gets cleared somehow in the widget
  // when sending the appliction to background in iOS.
  Position? _userLocation;

  bool _authLoading = false;
  bool _registrationLoading = false;
  bool _eventLoading = false;
  bool _eventProcessing = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Auth2.notifyLoginChanged,
      Events2.notifyUpdated,
    ]);

    _event = widget.event;
    _survey = widget.survey;
    _initEvent();

    if ((_userLocation = widget.userLocation) == null) {
      Event2HomePanel.getUserLocationIfAvailable().then((Position? userLocation) {
        setStateIfMounted(() {
          _userLocation = userLocation;
        });
      });
    }

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
    } else if (name == Auth2.notifyLoginChanged){
      _refreshEvent(progress: (bool value) => (_eventProcessing = value));
    }
    else if (name == Events2.notifyUpdated) {
      _updateEventIfNeeded(param);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body:
      Column(children: <Widget>[
        Expanded(child: _content),
      ])
    );
  }

  Widget get _content => _eventLoading ? _loadingContent : _eventContent;

  Widget get _loadingContent {
      return Center(child:
          SizedBox(width: 32, height: 32, child:
            CircularProgressIndicator(color: Styles().colors?.fillColorSecondary,)
          )
        );
  }

  Widget get _eventContent =>
  RefreshIndicator(onRefresh: _refreshEvent, child:
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
          Divider(height: 1, color: Styles().colors!.fillColorPrimaryTransparent03,),
        ]),
        ),
        Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 24), child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _descriptionWidget,
          _buttonsWidget,
        ]))
      ], addSemanticIndexes:false)
      ),
    ]));

  Widget get _badgeWidget => _isAdmin ?
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
      Stack(children: [
        _favoriteButton,
        _processingWidget,
      ],)
    ]);

  List<String>? get _displayCategories =>
    Events2().contentAttributes?.displaySelectedLabelsFromSelection(_event?.attributes, usage: ContentAttributeUsage.category);

  Widget get _favoriteButton {
    bool isFavorite = Auth2().isFavorite(_event);
    return Opacity(opacity: (Auth2().canFavorite && !_eventProcessing) ? 1 : 0, child:
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

  Widget get _processingWidget => Visibility(visible: _eventProcessing, child:
    Positioned.fill(child:
      Center(child:
        SizedBox(width: 18, height: 18, child:
          CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 2,),
        ),
      ),
    ),
  );

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
      ...?_speakerDetailWidget,
      ...?_priceDetailWidget,
      ...?_privacyDetailWidget,
      ...?_addToCalendarButton,
      ...?_adminSettingsButtonWidget,
      ...?_attendanceDetailWidget,
      ...?_contactsDetailWidget,
      ...?_detailsInfoWidget,
    ];

    return detailWidgets.isNotEmpty ? Padding(padding: EdgeInsets.only(top: 16), child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: detailWidgets,)
    ) : Container();
  }

  List<Widget>? get _dateDetailWidget {
    String? dateTime = _event?.longDisplayDate;
    return (dateTime != null) ? <Widget>[
        _buildTextDetailWidget(dateTime, 'calendar'),
      _detailSpacerWidget
    ] : null;
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
        Text(_event?.onlineDetails?.url ?? '', style: Styles().textStyles?.getTextStyle('widget.button.title.small.semi_fat.underline'),) :
        Text(_event?.onlineDetails?.url ?? '', style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'),);
      details.add(
        InkWell(onTap: canLaunch ? _onOnline : null, child:
          _buildDetailWidget(onlineWidget, 'laptop', iconVisible: false, detailPadding: EdgeInsets.zero)
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

      TextStyle? textDetailStyle = Styles().textStyles?.getTextStyle(canLocation ?
        'widget.explore.card.detail.regular.underline' : 'widget.explore.card.detail.regular');
      
      List<Widget> details = <Widget>[
        _buildTextDetailWidget('In Person', 'location'),
      ];

      String? locationText = (
        _event?.location?.displayName ??
        _event?.location?.displayAddress ??
        _event?.location?.displayCoordinates
      );
      if (locationText != null) {
        details.add(
          _buildDetailWidget(Text(locationText, maxLines: 1, style: textDetailStyle), 'location', iconVisible: false, detailPadding: EdgeInsets.zero)
        );
      }

      String? distanceText = _event?.getDisplayDistance(_userLocation);
      if (distanceText != null) {
        details.add(
          _buildDetailWidget(Text(distanceText, maxLines: 1, style: textDetailStyle,), 'location', iconVisible: false, detailPadding: EdgeInsets.zero)
        );
      }

      if (canLocation) {
        return <Widget>[
          InkWell(onTap: _onLocation, child:
            Column(children: details,)
          ),
          _detailSpacerWidget
        ];
      }
      else {
        details.add(_detailSpacerWidget);
        return details;
      }
    }
    return null;
  }

  List<Widget>? get _speakerDetailWidget => StringUtils.isNotEmpty(_event?.speaker) ? <Widget> [
    _buildTextDetailWidget("${_event?.speaker} (speaker)", "person"),
    _detailSpacerWidget
  ] : null;

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

  List<Widget>? get _attendanceDetailWidget {
    if (_isAdmin || _isAttendanceTaker) {
      return <Widget>[
        InkWell(
            onTap: _onTapTakeAttendance,
            child: _buildTextDetailWidget(Localization().getStringEx('panel.event2.detail.take_attendance.title', 'Take Attendance'), 'qr', underlined: true)),
        _detailSpacerWidget
      ];
    } else {
      return null;
    }
  }

  List<Widget>? get _detailsInfoWidget {
    
    String? description;
    bool hasRegistration = _event?.registrationDetails?.requiresRegistration ?? false;
    bool hasAttendance = _event?.attendanceDetails?.isNotEmpty ?? false;
    bool hasSurvey = (_isParticipant || _isAttendee) && hasAttendance && (_survey != null);
    int surveyHours = _event?.surveyDetails?.hoursAfterEvent ?? 0;

    if (hasRegistration) {
      if (hasAttendance) {
        if (hasSurvey) {
          switch (surveyHours) {
            case 0:  description = Localization().getStringEx('panel.event2.detail.survey.description.reg.att.svy.none', 'This event requires Registering, Attendance will be taken and you will receive a Notification with a Follow up Survey after this event.'); break;
            case 1:  description = Localization().getStringEx('panel.event2.detail.survey.description.reg.att.svy.single', 'This event requires Registering, Attendance will be taken and you will receive a Notification with a Follow up Survey 1 hour after this event.'); break;
            default: description = Localization().getStringEx('panel.event2.detail.survey.description.reg.att.svy.multi', 'This event requires Registering, Attendance will be taken and you will receive a Notification with a Follow up Survey {{hours}} hours after this event.').replaceAll('{{hours}}', surveyHours.toString()); break;
          }
        }
        else {
          description = Localization().getStringEx('panel.event2.detail.survey.description.reg.att', 'This event requires Registering and Attendance will be taken.'); 
        }
      }
      else {
        description = Localization().getStringEx('panel.event2.detail.survey.description.reg', 'Registration is required for this event.'); 
      }
    }
    else {
      if (hasAttendance) {
        if (hasSurvey) {
          switch (surveyHours) {
            case 0:  description = Localization().getStringEx('panel.event2.detail.survey.description.att.svy.none', 'Attendance will be taken at this event and you will receive a Notification with a Follow up Survey after this event.'); break;
            case 1:  description = Localization().getStringEx('panel.event2.detail.survey.description.att.svy.single', 'Attendance will be taken at this event and you will receive a Notification with a Follow up Survey 1 hour after this event.'); break;
            default: description = Localization().getStringEx('panel.event2.detail.survey.description.att.svy.multi', 'Attendance will be taken at this event and you will receive a Notification with a Follow up Survey {{hours}} hours after this event.').replaceAll('{{hours}}', surveyHours.toString()); break;
          }
        }
        else {
          description = Localization().getStringEx('panel.event2.detail.survey.description.att', 'Attendance will be taken at this event.'); 
        }
      }
      else {
        // No registration or attendance
      }
    }

    return (description != null) ?<Widget>[
      _buildTextDetailWidget(description, 'info',
        textStyle: 'widget.info.regular.thin.italic', iconPadding: const EdgeInsets.only(right: 6),
        maxLines: 3,
      ),
      _detailSpacerWidget
    ] : null;
  }

  List<Widget>? get _contactsDetailWidget{
    if(CollectionUtils.isEmpty(_event?.contacts))
      return null;

    List<Widget> contactList = [];
    contactList.add(_buildTextDetailWidget("Contacts", "person"));

    for (Event2Contact? contact in _event!.contacts!) {
      String? details =  event2ContactToDisplayString(contact);
      if(StringUtils.isNotEmpty(details)){
      contactList.add(
          _buildDetailWidget(
        // Text(details?? '', style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular.underline')),
              RichText(textScaleFactor: MediaQuery.textScaleFactorOf(context), text:
                TextSpan(style: Styles().textStyles?.getTextStyle("widget.explore.card.detail.regular"), children: <TextSpan>[
                  TextSpan(text: StringUtils.isNotEmpty(contact?.firstName)?"${contact?.firstName}, " : ""),
                  TextSpan(text: StringUtils.isNotEmpty(contact?.lastName)?"${contact?.lastName}, " : ""),
                  TextSpan(text: StringUtils.isNotEmpty(contact?.organization)?"${contact?.organization}, " : ""),
                  TextSpan(text: StringUtils.isNotEmpty(contact?.email)?"${contact?.email}, " : "", style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular.underline'), recognizer: TapGestureRecognizer()..onTap = () => _onContactEmail(contact?.email),),
                  TextSpan(text: StringUtils.isNotEmpty(contact?.phone)?"${contact?.phone}, " : "", style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular.underline'), recognizer: TapGestureRecognizer()..onTap = () => _onContactPhone(contact?.phone),),
            ])),
            'person', iconVisible: false, detailPadding: EdgeInsets.zero));
      }
    }

    contactList.add( _detailSpacerWidget);

    return contactList;
  }

  List<Widget>? get _adminSettingsButtonWidget => _isAdmin? <Widget>[
    InkWell(onTap: _onAdminSettings, child:
       _buildTextDetailWidget("Event Admin Actions", "settings", underlined: true)),
    _detailSpacerWidget
  ] : null;

  List<Widget>? get _addToCalendarButton => <Widget>[
    InkWell(onTap: _onAddToCalendar, child:
       _buildTextDetailWidget("Add to Calendar", "event-save-to-calendar", underlined: true)),
    _detailSpacerWidget
  ];

  Widget get _buttonsWidget {
    List<Widget> buttons = <Widget>[
      ...?_followUpSurveyButtonWidget,
      ...?_urlButtonWidget,
      ...?_registrationButtonWidget,
      ...?_logInButtonWidget,
    ];

    return buttons.isNotEmpty ? Padding(padding: EdgeInsets.only(top: 16), child:
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: buttons,)
    ) : Container();
  }

  List<Widget>? get _urlButtonWidget =>
    StringUtils.isNotEmpty(_event?.eventUrl) ? <Widget>[_buildButtonWidget(//TBD remove loading from here
      title: Localization().getStringEx('panel.groups_event_detail.button.visit_website.title', 'Visit website'),
      hint: Localization().getStringEx('panel.groups_event_detail.button.visit_website.hint', ''),
      onTap: (){_onWebButton(_event?.eventUrl, analyticsName: 'Website');}
    )] : null;

  List<Widget>? get _logInButtonWidget{
    if(Auth2().isLoggedIn == true)
      return null;

    return (_event?.registrationDetails?.type == Event2RegistrationType.internal) ? <Widget>[_buildButtonWidget(
        title: Localization().getStringEx('panel.event2_detail.button.unregister.title', 'Log In to Register'),
        onTap: _onLogIn,
        externalLink: false,
        enabled: false,
        progress: _authLoading
    )] : null;
  }

  List<Widget>? get _registrationButtonWidget{
    if(Auth2().isLoggedIn == false) //We can register only if logged in
      return null;

    if (_event?.registrationDetails?.type == Event2RegistrationType.internal) { //Require App registration
        if( _event?.userRole == Event2UserRole.participant){//Already registered
          return <Widget>[_buildButtonWidget(
              title: Localization().getStringEx('panel.event2_detail.button.unregister.title', 'Unregister me'),
              onTap: _onUnregister,
              externalLink: false,
              progress: _registrationLoading
          )];
        } else if (_event?.userRole == null){//Not registered yet
          return <Widget>[_buildButtonWidget(
              title: Localization().getStringEx('panel.event2_detail.button.register.title', 'Register me'),
              onTap: _onRegister,
              externalLink: false,
              progress: _registrationLoading,
          )];
        }
    } else if(StringUtils.isNotEmpty(_event?.registrationDetails?.externalLink)){// else external registration
      // if(_event?.userRole == null){ //TBD check if this is correct check or we don't know if the user is registered externally
        return <Widget>[_buildButtonWidget(
            title: Localization().getStringEx('panel.event2_detail.button.register.title', 'Register me'),
            onTap: _onExternalRegistration,
            externalLink: true
        )];
      // }
    }

    return null; //not required
  }

  List<Widget>? get _followUpSurveyButtonWidget{
    bool loggedIn = Auth2().isLoggedIn;
    bool attendee = _isAttendee;
    bool surveyAvailable = _event?.isSurveyAvailable ?? false;
    if (loggedIn && attendee && (_survey != null) && (surveyAvailable)) {
      return <Widget>[_buildButtonWidget(
          title: Localization().getStringEx('panel.event2_detail.button.follow_up_survey.title', 'Take Survey'),
          onTap: _onFollowUpSurvey,
          externalLink: false,
      )];
    }

    return null;
  }

  Widget get _adminSettingsWidget  =>
      Padding(padding: EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16), child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSettingButton(title: "Edit event", onTap: _onSettingEditEvent),
          _buildSettingButton(title: "Promote this event", onTap: _onSettingPromote),
          _buildSettingButton(title: "Event registration", onTap: _onSettingEventRegistration),
          _buildSettingButton(title: "Event attendance", onTap: _onSettingAttendance),
          _buildSettingButton(title: "Event follow-up survey", onTap: _onSettingSurvey),
          _buildSettingButton(title: _survey != null ? "Event follow-up survey responses" : null, onTap: _onSettingSurveyResponses),
          _buildSettingButton(title: "Delete event", onTap: _onSettingDeleteEvent),
        ],)
    );

  Widget get _detailSpacerWidget => Container(height: 8,);

  Widget _buildTextDetailWidget(String text, String iconKey, {
    String textStyle = 'widget.info.medium',
    EdgeInsetsGeometry detailPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6, top: 2, bottom: 2),
    bool iconVisible = true, bool underlined = false, int maxLines = 1,
  }) =>
    _buildDetailWidget(
      Text(text,
        style: Styles().textStyles?.getTextStyle(underlined ? '$textStyle.underline' : textStyle),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
      iconKey,
      detailPadding: detailPadding,
      iconPadding: iconPadding,
      iconVisible: iconVisible
    );

  Widget _buildDetailWidget(Widget contentWidget, String iconKey, {
    EdgeInsetsGeometry detailPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6, top: 2, bottom: 2),
    bool iconVisible = true
  }) {
    List<Widget> contentList = <Widget>[];
    Widget? iconWidget = Styles().images?.getImage(iconKey, excludeFromSemantics: true);
    if (iconWidget != null) {
      contentList.add(Opacity(opacity: iconVisible ? 1 : 0, child:
        Padding(padding: iconPadding, child:
          iconWidget,
        )
      ));
    }
    contentList.add(Expanded(child:
      contentWidget
    ),);
    return Padding(padding: detailPadding, child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: contentList)
    );
  }

  Widget _buildButtonWidget({String? title,
    String? hint,
    bool enabled = true,
    bool externalLink = true,
    bool progress = false,
    void Function()? onTap,
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
            progress: progress,
            contentWeight: 0.5,
          ),
        ),
        ] )
      ) : Container();
  
  Widget _buildSettingButton({String? title, VoidCallback? onTap}) =>  StringUtils.isNotEmpty(title) ?
    Padding(padding: EdgeInsets.only(bottom: 6),
      child: RibbonButton(
        label: title ?? "",
        onTap: () {
          Navigator.of(context).pop();
          if(onTap!=null)
            onTap();
        }),
    ) : Container();

  //Actions
  void _onLocation() {
    Analytics().logSelect(target: "Location Directions: ${_event?.name}");
    _event?.launchDirections();
  }

  void _onOnline() {
    Analytics().logSelect(target: "Online Url: ${_event?.name}");
    String? url = _event?.onlineDetails?.url;
    if(StringUtils.isNotEmpty(url)){
      _onLaunchUrl(url);
    }
  }

  void _onFavorite() {
    Analytics().logSelect(target: "Favorite: ${_event?.name}");
    Auth2().prefs?.toggleFavorite(_event);
  }

  void _onLaunchUrl(String? url, {BuildContext? context}) {
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context ?? this.context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
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

  void _onRegister() {
    Analytics().logSelect(target: 'Register me');
    _performRegistration(Events2().registerToEvent);
  }

  void _onUnregister() {
    Analytics().logSelect(target: 'Unregister me');
    _performRegistration(Events2().unregisterFromEvent);
  }

  void _performRegistration(Future<dynamic> Function(String eventId) registrationApi) {
    if ((_eventId != null) && !_registrationLoading) {
        setStateIfMounted(() {
          _registrationLoading = true;
        });

      registrationApi(_eventId!).then((result) {
        if (mounted) {
          if (result is Event2) {
            setState(() {
              _event = result;
              _registrationLoading = false;
            });
          }
          else {
            setState(() {
              _registrationLoading = false;
            });
            Event2Popup.showErrorResult(context, result);
          }
        }
      });
    }
  }

  void _onExternalRegistration(){
    Analytics().logSelect(target: 'Register me');
    if(StringUtils.isNotEmpty(_event?.registrationDetails?.externalLink))
       _onLaunchUrl(_event?.registrationDetails?.externalLink);
  }

  void _onFollowUpSurvey(){
    Analytics().logSelect(target: "Follow up survey");
    Surveys().loadSurveyResponses(surveyIDs: [_survey!.id]).then((List<SurveyResponse>? responses) {
      if (CollectionUtils.isEmpty(responses)) {
        Survey displaySurvey = Survey.fromOther(_survey!);
        displaySurvey.replaceKey('event_name', _event?.name);
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: displaySurvey)));
      }
    });
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
  void _onAddToCalendar(){
      DeviceCalendar().addToCalendar(_event);
  }

  void _onContactEmail(String? email){
    if(StringUtils.isNotEmpty(email)) {
      String link = "mailto:$email";
      _onLaunchUrl(link);
    }
  }

  void _onContactPhone(String? phone){
    if(StringUtils.isNotEmpty(phone)) {
      String link = "tel:$phone";
      _onLaunchUrl(link);
    }
  }

  void _onAdminSettings(){
    Analytics().logSelect(target: "Admin settings");
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return _adminSettingsWidget;
        });
  }

  void _onSettingEditEvent(){
    Analytics().logSelect(target: "Edit event");
    Navigator.push<Event2SetupSurveyParam?>(context, CupertinoPageRoute(builder: (context) => Event2CreatePanel(event: _event, survey: _survey,))).then((Event2SetupSurveyParam? result) {
      if (result != null) {
        setStateIfMounted(() {
          if (result.event != null) {
            _event = result.event;
          }
          _survey = result.survey;
        });
      }
    });
  }

  void _onSettingPromote(){
    Analytics().logSelect(target: "Promote Event", attributes: _event?.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2QrCodePanel(event: _event)));
  }

  void _onSettingEventRegistration(){
    Analytics().logSelect(target: "Event Registration");
    Navigator.push<Event2?>(context, CupertinoPageRoute(builder: (context) => Event2SetupRegistrationPanel(
      event: _event,
    ))).then((Event2? event) {
      if (event != null)
      setStateIfMounted(() {
        _event = event;
      });
    });
  }

  void _onSettingAttendance(){
    Analytics().logSelect(target: "Event Attendance");
    Navigator.push<Event2?>(context, CupertinoPageRoute(builder: (context) => Event2SetupAttendancePanel(
      event: _event,
    ))).then((Event2? event) {
      if (event != null)
      setStateIfMounted(() {
        _event = event;
      });
    });
  }

  void _onSettingSurvey(){
    Analytics().logSelect(target: "Event Survey");
    Navigator.push<Event2SetupSurveyParam?>(context, CupertinoPageRoute(builder: (context) => Event2SetupSurveyPanel(
      surveyParam: Event2SetupSurveyParam(
        event: _event,
        survey: _survey,
      ),
    ))).then((Event2SetupSurveyParam? surveyParam) {
      if (surveyParam != null) {
        setStateIfMounted(() {
          if (surveyParam.event != null) {
            _event = surveyParam.event;
          }
          _survey = surveyParam.survey;
        });
      }
    });
  }

  void _onSettingSurveyResponses() {
    Analytics().logSelect(target: "Event Survey Responses");
    Navigator.push<Event2SetupSurveyParam?>(context, CupertinoPageRoute(builder: (context) => Event2SurveyResponsesPanel(
      surveyId: _survey?.id,
      eventName: _event?.name,
    )));
  }

  void _onSettingDeleteEvent(){
    Analytics().logSelect(target: 'Delete Event');

    if (_eventId != null) {
      Event2Popup.showPrompt(context,
        Localization().getStringEx('panel.event2.detail.general.prompt.delete.title', 'Delete'),
        Localization().getStringEx('panel.event2.detail.general.prompt.delete.message', 'Are you sure you want to delete this event and all data associated with it? This action cannot be undone.'),
      ).then((bool? result) {
        if (result == true) {
          setStateIfMounted(() {
            _eventProcessing = true;
          });

          Events2().deleteEvent(_eventId!).then((result) {
            if (mounted) {
              setState(() {
                _eventProcessing = false;
              });
                
              if (result == true) {
                Navigator.pop(context);
              }
              else {
                Event2Popup.showErrorResult(context, result);
              }
            }
          });
        }
      });
    }
  }

  void _onTapTakeAttendance() {
    Analytics().logSelect(target: 'Take Attendance');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2AttendanceTakerPanel(_event)));
  }

  //loading

  Future<void> _initEvent() async {
    
    String? eventId = widget.event?.id ?? widget.eventId;

    Event2? event, theEvent;
    if (_event != null) {
      theEvent = _event;
    }
    else if (StringUtils.isNotEmpty(widget.eventId) && mounted) {
      setState(() {
        _eventLoading = true;
      });
      theEvent = event = await Events2().loadEvent(widget.eventId!);
    }

    Event2PersonsResult? persons;
    if ((_persons == null) && (eventId != null) && (
         (theEvent?.registrationDetails?.type == Event2RegistrationType.internal) ||
         (theEvent?.attendanceDetails?.isNotEmpty ?? false)
        ) && mounted) {
      setState(() {
        _eventLoading = true;
      });
      persons = await Events2().loadEventPeople(eventId);
    }

    Survey? survey;
    if ((_survey == null) && (eventId != null) &&
        (theEvent?.surveyDetails?.isNotEmpty ?? false) &&
        mounted
    ) {
      setState(() {
        _eventLoading = true;
      });
      survey = await Surveys().loadEvent2Survey(eventId);
    }

    setStateIfMounted(() {
      _eventLoading = false;
      if (event != null) {
        _event = event;
      }
      if (persons != null) {
        _persons = persons;
      }
      if (survey != null) {
        _survey = survey;
      }
    });
  }

  Future<void> _refreshEvent({void Function(bool)? progress}) async {
    String? eventId = widget.event?.id ?? widget.eventId;
    if ((eventId != null) && mounted) {
      
      if (progress != null) {
        setState(() {
          progress(true);
        });
      }

      List<Future<dynamic>> futures = [
        Events2().loadEvent(eventId),
      ];
      
      int? peopleIndex = ((_event?.registrationDetails?.type == Event2RegistrationType.internal) || (_event?.attendanceDetails?.isNotEmpty ?? false)) ? futures.length : null;
      if (peopleIndex != null) {
        futures.add(Events2().loadEventPeople(eventId));
      }

      int? surveyIndex = (_event?.surveyDetails?.isNotEmpty ?? false) ? futures.length : null;
      if (surveyIndex != null) {
        futures.add(Surveys().loadEvent2Survey(eventId));
      }

      List<dynamic> results = await Future.wait(futures);
      Event2? event = ((0 < results.length) && (results[0] is Event2)) ? results[0] : null;
      Event2PersonsResult? persons = ((peopleIndex != null) && (peopleIndex < results.length) && (results[peopleIndex] is Event2PersonsResult)) ? results[peopleIndex] : null;
      Survey? survey = ((surveyIndex != null) && (surveyIndex < results.length) && (results[surveyIndex] is Survey)) ? results[surveyIndex] : null;

      futures.clear();

      // Handle the case if after refreshing event the registrationDetails/attendanceDetails require loading persons
      int? peopleIndex2 = ((peopleIndex == null) && ((event?.registrationDetails?.type == Event2RegistrationType.internal) || (event?.attendanceDetails?.isNotEmpty ?? false))) ? futures.length : null;
      if (peopleIndex2 != null) {
        futures.add(Events2().loadEventPeople(eventId));
      }

      // Handle the case if after refreshing event the surveyDetails get not empty
      int? surveyIndex2 = ((surveyIndex == null) && (event?.surveyDetails?.isNotEmpty ?? false)) ? futures.length : null;
      if (surveyIndex2 != null) {
        futures.add(Surveys().loadEvent2Survey(eventId));
      }

      if (futures.isNotEmpty) {
        results = await Future.wait(futures);
        if ((peopleIndex2 != null) && (peopleIndex2 < results.length) && (results[peopleIndex2] is Event2PersonsResult)) {
          persons = results[peopleIndex2];
        }
        if ((surveyIndex2 != null) && (surveyIndex2 < results.length) && (results[surveyIndex2] is Survey)) {
          survey = results[surveyIndex2];
        }
      }

      setStateIfMounted(() {
        if (progress != null) {
          progress(false);
        }
        if (event != null) {
          _event = event;
        }
        if (persons != null) {
          _persons = persons;
        }
        if (survey != null) {
          _survey = survey;
        }
      });
    }
  }

  void _updateEventIfNeeded(Event2? event) {
    if ((event != null) && (event.id == _eventId) && mounted) {
      setState(() {
        _event = event;
      });
    }
  }

  //Event getters
  bool get _isAdmin =>  _event?.userRole == Event2UserRole.admin;
  bool get _isAttendanceTaker =>  _event?.userRole == Event2UserRole.attendanceTaker;
  bool get _isParticipant =>  _event?.userRole == Event2UserRole.participant;
  bool get _isAttendee => (_persons?.attendees?.indexWhere((person) => person.identifier?.accountId == Auth2().accountId) ?? -1) > -1;

  String? get _eventId => widget.event?.id ?? widget.eventId;

}
