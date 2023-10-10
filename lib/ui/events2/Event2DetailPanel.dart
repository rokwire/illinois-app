import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Survey.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/DeviceCalendar.dart';
import 'package:illinois/service/RecentItems.dart';
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
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2DetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Event2? event;
  final String? eventId;
  final Event2? superEvent;
  final Survey? survey;
  final Position? userLocation;
  final Event2Selector? eventSelector;
  Event2DetailPanel({ this.event, this.eventId, this.superEvent, this.survey, this.userLocation, this.eventSelector});
  
  @override
  State<StatefulWidget> createState() => _Event2DetailPanelState();

  // AnalyticsPageAttributes

  @override
  Map<String, dynamic>? get analyticsPageAttributes => event?.analyticsAttributes;
}

class _Event2DetailPanelState extends State<Event2DetailPanel> implements NotificationsListener, Event2SelectorDataProvider {

  Event2? _event;
  Survey? _survey;
  bool? _hasSurveyResponse;
  Event2PersonsResult? _persons;
  Event2? _superEvent;

  List<Event2>? _linkedEvents;
  bool _linkedEventsLoading = false;
  int? _totalLinkedEventsCount;
  bool _extendingLinkedEvents = false;
  bool? _lastPageLoadedAllLinkedEvents;
  static const int _linkedEventsPageLength = 20;

  ScrollController _scrollController = ScrollController();

  // Keep a copy of the user position in the State because it gets cleared somehow in the widget
  // when sending the appliction to background in iOS.
  Position? _userLocation;

  bool _authLoading = false;
  bool _registrationLoading = false;
  bool _eventLoading = false;
  bool _eventProcessing = false;
  bool _registrationLaunching = false;
  bool _websiteLaunching = false;
  bool _onlineLaunching = false;

  List<String>? _displayCategories;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Auth2.notifyLoginChanged,
      Events2.notifyUpdated,
    ]);
    _scrollController.addListener(_scrollListener);
    _event = widget.event;
    _superEvent = widget.superEvent;
    _survey = widget.survey;
    _displayCategories = _buildDisplayCategories(widget.event);
    _initEvent();
    _initSelector();

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
    widget.eventSelector?.dispose(this);
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
    CustomScrollView(controller: _scrollController, slivers: <Widget>[
      SliverToutHeaderBar(
        title: _event?.name,
        flexImageUrl:  _event?.imageUrl,
        flexImageKey: 'event-detail-default',
        flexRightToLeftTriangleColor: Colors.white,
      ),
      SliverList(delegate:
      SliverChildListDelegate([
        Container(color: Styles().colors?.white, child:
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _roleBadgeWidget,
            _contentHeadingWidget,
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
          ])),
        _linkedEventsWidget,
      ], addSemanticIndexes:false)
      ),
    ]));

  Widget get _roleBadgeWidget {
    String? label = _isAdmin ? Localization().getStringEx('panel.event2.detail.general.admin.title', 'ADMIN') : null;
    return (label != null) ? Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Styles().colors!.fillColorSecondary, borderRadius: BorderRadius.all(Radius.circular(2)),), child:
        Semantics(label: event2UserRoleToString(_event?.userRole), excludeSemantics: true, child:
          Text(event2UserRoleToString(_event?.userRole)?.toUpperCase() ?? 'ADMIN', style:  Styles().textStyles?.getTextStyle('widget.heading.small'),)
    ))) : Container();
  }


  Widget get _contentHeadingWidget => 
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 16, top: _hasDisplayCategories ? 16 : 8, bottom: 8), child:
          _hasDisplayCategories ? _categoriesContentWidget : _titleContentWidget,
        ),
      ),
      _groupingBadgeWidget,
      Stack(children: [
        _favoriteButton,
        _processingWidget,
      ],)
    ]);

  Widget get _categoriesContentWidget =>
    Text(_displayCategories?.join(', ') ?? '', overflow: TextOverflow.ellipsis, maxLines: 2, style: Styles().textStyles?.getTextStyle("widget.card.title.small.fat"));

  static List<String>? _buildDisplayCategories(Event2? event) =>
    Events2().contentAttributes?.displaySelectedLabelsFromSelection(event?.attributes, usage: ContentAttributeUsage.category);

  Widget get _groupingBadgeWidget {
    String? badgeLabel;
    if (_event?.isSuperEvent == true) {
      badgeLabel = Localization().getStringEx('panel.event2.detail.general.super_event.abbreviation.title', 'Multi'); // composite
    }
    else if (_event?.isRecurring == true) {
      badgeLabel = Localization().getStringEx('panel.event2.detail.general.recurrence.abbreviation.title', 'Repeats');
    }
    return (badgeLabel != null) ? Padding(padding: EdgeInsets.only(top: 16), child:
      Container(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Styles().colors!.fillColorSecondary, borderRadius: BorderRadius.all(Radius.circular(2)),), child:
        Semantics(label: badgeLabel, excludeSemantics: true, child:
          Text(badgeLabel, style:  Styles().textStyles?.getTextStyle('widget.heading.small'),)
    ))) : Container();
  }

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

  Widget get _titleWidget => _hasDisplayCategories ?
    Row(children: [
      Expanded(child:
        _titleContentWidget
      ),
    ],) : Container();

  Widget get _titleContentWidget =>
    Text(_event?.name ?? '', style: Styles().textStyles?.getTextStyle('widget.title.extra_large'));

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
          onTapUrl : (url) { _launchUrl(url, context: context); return true; },
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
      ...?_superEventDetailWidget,
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
    String? dateTime = _event?.longDisplayDateAndTime;
    return (dateTime != null) ? <Widget>[
        _buildTextDetailWidget(dateTime, 'calendar'),
      _detailSpacerWidget
    ] : null;
  }

  List<Widget>? get _onlineDetailWidget {
    if (_event?.isOnline == true) {
      bool canLaunch = StringUtils.isNotEmpty(_event?.onlineDetails?.url);
      List<Widget> details = <Widget>[
        InkWell(onTap: canLaunch ? _onOnline : null, child:
          _buildTextDetailWidget(Localization().getStringEx('panel.event2.detail.general.online.title', 'Online'), 'laptop', showProgress: _onlineLaunching),
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
    if (_event?.isInPerson == true) {

      bool canLocation = _event?.location?.isLocationCoordinateValid ?? false;

      String textDetailStyleName = canLocation ?
        'widget.explore.card.detail.regular.underline' : 'widget.explore.card.detail.regular';
      TextStyle? textDetailStyle = Styles().textStyles?.getTextStyle(textDetailStyleName);
      
      List<Widget> details = <Widget>[
        _buildTextDetailWidget(Localization().getStringEx('panel.event2.detail.general.in_person.title', 'In Person'), 'location',
          textStyle: textDetailStyle
        ),
      ];

      String? locationText = _event?.location?.displayName ?? _event?.location?.displayAddress ?? _event?.location?.displayDescription; // ?? _event?.location?.displayCoordinates;
      if (locationText != null) {
        details.add(
          _buildDetailWidget(Text(locationText, maxLines: 1, style: textDetailStyle), 'location',
            iconVisible: false,
            detailPadding: EdgeInsets.zero
          )
        );
      }

      String? distanceText = _event?.getDisplayDistance(_userLocation);
      if (distanceText != null) {
        details.add(
          _buildDetailWidget(Text(distanceText, maxLines: 1, style: textDetailStyle,), 'location',
            iconVisible: false,
            detailPadding: EdgeInsets.zero
          )
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
    _buildTextDetailWidget("${_event?.speaker} (speaker)", "person",),
    _detailSpacerWidget
  ] : null;

  List<Widget>? get _priceDetailWidget{
    List<Widget>? details = <Widget>[];
    if (_event?.free != false) {
      details.add(_buildTextDetailWidget(Localization().getStringEx('panel.event2.detail.general.free.title', 'Free'), 'cost'));
      if (StringUtils.isNotEmpty(_event?.cost)) {
        details.add(_buildTextDetailWidget(_event?.cost ?? '', 'cost',
          textStyle: Styles().textStyles?.getTextStyle('widget.info.regular.thin'),
          iconVisible: false,
          maxLines: 2,
          detailPadding: EdgeInsets.zero
        ));
      }
    }
    else if (StringUtils.isNotEmpty(_event?.cost)) {
      details.add(_buildTextDetailWidget(_event?.cost ?? '', 'cost'));
    }
    details.add( _detailSpacerWidget);
    return details;
  }

  List<Widget>? get _privacyDetailWidget{
    String privacyTypeTitle = _event?.private == true ?
      Localization().getStringEx('panel.explore_detail.label.privacy.private.title', 'Private Event') :
      Localization().getStringEx('panel.explore_detail.label.privacy.public.title', 'Public Event');

    return [_buildTextDetailWidget(privacyTypeTitle, "privacy"), _detailSpacerWidget];
  }

  List<Widget>? get _superEventDetailWidget => (_superEvent != null) ? <Widget> [
    InkWell(onTap: _onSuperEvent, child:
      _buildTextDetailWidget(_superEvent?.name ?? '', "event",
        underlined: true,
        maxLines: 2,
      ),
    ),
    _detailSpacerWidget
  ] : null;


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
    bool hasSurvey = (_event?.hasSurvey ?? false) && (_survey != null);
    bool showSurvey = (_isAttendee || _isAdmin) && hasAttendance && hasSurvey;
    int surveyHours = _event?.surveyDetails?.hoursAfterEvent ?? 0;
    bool registrationAvailable = (_event?.registrationDetails?.isRegistrationAvailable(_persons?.registrationOccupancy) != false);

    if (hasRegistration) {
      if (hasAttendance) {
        if (showSurvey) {
          if (_isAdmin) {
            description = registrationAvailable ?
              Localization().getStringEx('panel.event2.detail.survey.description.reg.att.svy.admin', 'This event requires registration. Attendance will be taken and a follow-up survey will be sent.') :
              Localization().getStringEx('panel.event2.detail.survey.description.reg.full.att.svy.admin', 'This event requires registration and its capacity is reached. Attendance will be taken and a follow-up survey will be sent.');
          }
          else switch (surveyHours) {
            case 0:  description = registrationAvailable ?
              Localization().getStringEx('panel.event2.detail.survey.description.reg.att.svy.none', 'This event requires registration. Attendance will be taken and you will receive a notification with a follow-up survey after this event.') :
              Localization().getStringEx('panel.event2.detail.survey.description.reg.full.att.svy.none', 'This event requires registration and its capacity is reached. Attendance will be taken and you will receive a notification with a follow-up survey after this event.'); break;
            case 1:  description = registrationAvailable ?
              Localization().getStringEx('panel.event2.detail.survey.description.reg.att.svy.single', 'This event requires registration. Attendance will be taken and you will receive a notification with a follow-up survey 1 hour after the event.') :
              Localization().getStringEx('panel.event2.detail.survey.description.reg.full.att.svy.single', 'This event requires registration and its capacity is reached. Attendance will be taken and you will receive a notification with a follow-up survey 1 hour after the event.'); break;
            default: description = (registrationAvailable ?
              Localization().getStringEx('panel.event2.detail.survey.description.reg.att.svy.multi', 'This event requires registration. Attendance will be taken and you will receive a notification with a follow-up survey {{hours}} hours after the event.') :
              Localization().getStringEx('panel.event2.detail.survey.description.reg.full.att.svy.multi', 'This event requires registration and its capacity is reached. Attendance will be taken and you will receive a notification with a follow-up survey {{hours}} hours after the event.')).replaceAll('{{hours}}', surveyHours.toString()); break;
          }
        }
        else {
          description = registrationAvailable ?
            Localization().getStringEx('panel.event2.detail.survey.description.reg.att', 'This event requires registration, and attendance will be taken.') :
            Localization().getStringEx('panel.event2.detail.survey.description.reg.full.att', 'This event requires registration, its capacity is reached, and attendance will be taken.'); 
        }
      }
      else {
        description = registrationAvailable ?
          Localization().getStringEx('panel.event2.detail.survey.description.reg', 'Registration is required for this event.') :
          Localization().getStringEx('panel.event2.detail.survey.description.reg.full', 'Registration is required for this event and its capacity is reached.');  
      }
    }
    else {
      if (hasAttendance) {
        if (showSurvey) {
          if (_isAdmin) {
            description = Localization().getStringEx('panel.event2.detail.survey.description.att.svy.admin', 'Attendance will be taken at this event, and a follow-up survey will be sent.');
          }
          else switch (surveyHours) {
            case 0:  description = Localization().getStringEx('panel.event2.detail.survey.description.att.svy.none', 'Attendance will be taken at this event and you will receive a notification with a follow-up survey after the event.'); break;
            case 1:  description = Localization().getStringEx('panel.event2.detail.survey.description.att.svy.single', 'Attendance will be taken at this event, and you will receive a notification with a follow-up survey 1 hour after the event..'); break;
            default: description = Localization().getStringEx('panel.event2.detail.survey.description.att.svy.multi', 'Attendance will be taken at this event, and you will receive a notification with a follow-up survey {{hours}} hours after the event.').replaceAll('{{hours}}', surveyHours.toString()); break;
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
        textStyle: Styles().textStyles?.getTextStyle('widget.info.regular.thin.italic') ,
        iconPadding: const EdgeInsets.only(right: 6),
        maxLines: 5,
      ),
      _detailSpacerWidget
    ] : null;
  }

  List<Widget>? get _contactsDetailWidget{
    if(CollectionUtils.isEmpty(_event?.contacts))
      return null;

    List<Widget> contactList = [];
    contactList.add(_buildTextDetailWidget(Localization().getStringEx('panel.event2.detail.general.contacts.title', 'Contacts'), 'person'));

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
       _buildTextDetailWidget(Localization().getStringEx('panel.event2.detail.general.admin_settings.title', 'Event Admin Settings'), 'settings', underlined: true)),
    _detailSpacerWidget
  ] : null;

  List<Widget>? get _addToCalendarButton => <Widget>[
    InkWell(onTap: _onAddToCalendar, child:
       _buildTextDetailWidget(Localization().getStringEx('panel.event2.detail.general.add_to_calendar.title', 'Add to Calendar'), 'event-save-to-calendar', underlined: true)),
    _detailSpacerWidget
  ];

  Widget get _buttonsWidget {
    List<Widget> buttons = <Widget>[
      ...?_followUpSurveyButtonWidget,
      ...?_urlButtonWidget,
      ...?_registrationButtonWidget,
      ...?_logInButtonWidget,
      ...?_selectorWidget,
    ];

    return buttons.isNotEmpty ? Padding(padding: EdgeInsets.only(top: 16), child:
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: buttons,)
    ) : Container();
  }

  List<Widget>? get _urlButtonWidget =>
    StringUtils.isNotEmpty(_event?.eventUrl) ? <Widget>[_buildButtonWidget(//TBD remove loading from here
      title: Localization().getStringEx('panel.groups_event_detail.button.visit_website.title', 'Visit website'),
      hint: Localization().getStringEx('panel.groups_event_detail.button.visit_website.hint', ''),
      externalLink: true,
      progress: _websiteLaunching,
      onTap: _onWebsiteButton,
    )] : null;

  List<Widget>? get _logInButtonWidget{
    if(Auth2().isLoggedIn == true)
      return null;

    return _isInternalRegistrationAvailable ? <Widget>[_buildButtonWidget(
        title: Localization().getStringEx('panel.event2.detail.button.login.register.title', 'Log In to Register'),
        onTap: _onLogIn,
        progress: _authLoading
    )] : null;
  }

  List<Widget>? get _registrationButtonWidget{
    if (Auth2().isLoggedIn == false) //We can register only if logged in
      return null;

    //Do not register/unregoster to past events
    DateTime? startTimeUtc = _event?.startTimeUtc;
    if ((startTimeUtc != null) && DateTime.now().toUtc().isAfter(startTimeUtc))
      return null;

    if (_event?.registrationDetails?.type == Event2RegistrationType.internal) { // Require App registration
        if (_event?.userRole == Event2UserRole.participant) {// Already registered
          return <Widget>[_buildButtonWidget(
              title: Localization().getStringEx('panel.event2.detail.button.unregister.title', 'Unregister'),
              onTap: _onUnregister,
              progress: _registrationLoading
          )];
        } else if ((_event?.userRole == null) && _isInternalRegistrationAvailable) { // Not registered yet and has available capacity
          return <Widget>[_buildButtonWidget(
              title: Localization().getStringEx('panel.event2.detail.button.register.title', 'Register'),
              onTap: _onRegister,
              progress: _registrationLoading,
          )];
        }
    } else if (StringUtils.isNotEmpty(_event?.registrationDetails?.externalLink)) { // else external registration
      // if (_event?.userRole == null){ //TBD check if this is correct check or we don't know if the user is registered externally
        return <Widget>[_buildButtonWidget(
            title: Localization().getStringEx('panel.event2.detail.button.register.title', 'Register'),
            onTap: _onExternalRegistration,
            progress: _registrationLaunching,
            externalLink: true
        )];
      // }
    }

    return null; //not required
  }

  List<Widget>? get _followUpSurveyButtonWidget{
    if (Auth2().isLoggedIn && _isAttendee && (_survey != null) && (_event?.isSurveyAvailable ?? false)) {
      return <Widget>[_hasSurveyResponse == false ? _buildButtonWidget(
          title: Localization().getStringEx('panel.event2.detail.survey.button.follow_up_survey.title', 'Take Survey'),
          onTap: _onFollowUpSurvey,
      ) : _buildTextDetailWidget(Localization().getStringEx('panel.event2.detail.survey.button.follow_up_survey.completed.message', 'You have completed this event\'s survey'), 'check', maxLines: 2)];
    }

    return null;
  }

  Widget get _linkedEventsWidget => (_event?.hasLinkedEvents == true) ? SectionSlantHeader(
      title: _linkedEventsSectionTitle,
      slantImageKey: "slant-dark",
      slantColor: Styles().colors!.backgroundVariant,
      titleTextStyle: Styles().textStyles?.getTextStyle("widget.title.large.extra_fat"),
      progressWidget: _linkedEventsProgress,
      children: !_linkedEventsLoading ? _linkedEventsContent : [Row(children: [Expanded(child: Container())],)],
  ) : Container();


  String get _linkedEventsSectionTitle {
    if (_event?.isSuperEvent == true) {
      return Localization().getStringEx('panel.event2.detail.general.super_event.list.title', 'Multiple events');
    }
    else if (_event?.isRecurring == true) {
      return Localization().getStringEx('panel.event2.detail.general.recurrence.list.title', 'This event repeats');
    }
    else {
      return '';
    }
  }

  Widget? get _linkedEventsProgress => _linkedEventsLoading ? SizedBox(width: 24, height: 24, child:
    CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
  ) : null;

  List<Widget> get _linkedEventsContent {
    List<Widget> cardWidgets = [];
    if (_linkedEvents != null) {
      for (Event2 linkedEvent in _linkedEvents!) {
        if (linkedEvent.id != _event?.id) {
          cardWidgets.add(Padding(padding: EdgeInsets.only(bottom: 8), child:
            Event2Card(linkedEvent,
              displayMode: Event2CardDisplayMode.link,
              linkType: _event?.grouping?.type,
              onTap: () => _onLinkedEvent(linkedEvent),
            ),
          ));
        }
      }
      if (_extendingLinkedEvents) {
        cardWidgets.add(Padding(padding: EdgeInsets.only(top: cardWidgets.isNotEmpty ? 8 : 0), child: _extendingLinkedEventsIndicator));
      }
    }
    if (cardWidgets.isEmpty) {
      String? message;
      if (_event?.isSuperEvent == true) {
        // Event Schedule
        message = (_linkedEvents != null) ?
          Localization().getStringEx('panel.event2.detail.linked_events.super_event.empty.message', 'There are no scheduled upcoming events.') :
          Localization().getStringEx('panel.event2.detail.linked_events.super_event.failed.message', 'Failed to load events schedule.');
      }
      else if (_event?.isRecurring == true) {
        // Available Times
        message = (_linkedEvents != null) ?
          Localization().getStringEx('panel.event2.detail.linked_events.recurrence.failed.message', 'There are no upcoming available times.') :
          Localization().getStringEx('panel.event2.detail.linked_events.recurrence.failed.message', 'Failed to load available times.');
      }
      cardWidgets.add(_linkedEventsMessageCard(message ?? ''));
    }
    return cardWidgets;
  }

  Widget _linkedEventsMessageCard(String message) => Container(decoration: Event2Card.linkContentDecoration, child:
    ClipRRect(borderRadius: Event2Card.linkContentBorderRadius, child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24), child:
        Row(children: [
          Expanded(child:
            Text(message, style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"), textAlign: TextAlign.center,),
          )
        ],)
      )
    )
  );

  Widget get _extendingLinkedEventsIndicator => Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Align(
          alignment: Alignment.center,
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary)))));

  List<Widget>? get _selectorWidget {
      Widget? customSelectorWidget = widget.eventSelector?.buildWidget(this);
      return customSelectorWidget != null ? <Widget> [customSelectorWidget] : null;
  }

  Widget get _adminSettingsWidget  =>
      Padding(padding: EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16), child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSettingButton(title: "Edit event", onTap: _onSettingEditEvent),
          _buildSettingButton(title: "Promote this event", onTap: _onSettingPromote),
          _buildSettingButton(title: "Event registration", onTap: _onSettingEventRegistration),
          _buildSettingButton(title: "Event attendance", onTap: _onSettingAttendance),
          _buildSettingButton(title: _event?.attendanceDetails?.isNotEmpty == true ? "Event follow-up survey" : null, onTap: _onSettingSurvey),
          _buildSettingButton(title: _event?.hasSurvey == true ? "Event follow-up survey responses" : null, onTap: _onSettingSurveyResponses),
          _buildSettingButton(title: "Delete event", onTap: _onSettingDeleteEvent),
        ],)
    );

  Widget get _detailSpacerWidget => Container(height: 8,);

  Widget _buildTextDetailWidget(String text, String iconKey, {
    TextStyle? textStyle, // 'widget.info.medium' : 'widget.info.medium.underline'
    int? maxLines = 1, TextOverflow? overflow = TextOverflow.ellipsis,
    EdgeInsetsGeometry detailPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6, top: 2, bottom: 2),
    bool iconVisible = true, bool showProgress = false, bool underlined = false,
  }) =>
    _buildDetailWidget(
      Text(text,
        style: textStyle ?? Styles().textStyles?.getTextStyle(underlined ? 'widget.info.medium.underline' : 'widget.info.medium'),
        maxLines: maxLines,
        overflow: overflow,
      ),
      iconKey,
      detailPadding: detailPadding,
      iconPadding: iconPadding,
      iconVisible: iconVisible,
      showProgress: showProgress,
    );

  Widget _buildDetailWidget(Widget contentWidget, String iconKey, {
    EdgeInsetsGeometry detailPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6, top: 2, bottom: 2),
    bool iconVisible = true,
    bool showProgress = false,
  }) {
    List<Widget> contentList = <Widget>[];
    Widget? iconWidget = Styles().images?.getImage(iconKey, excludeFromSemantics: true);
    if (iconWidget != null) {
      contentList.add(Padding(padding: iconPadding, child: showProgress ?
        Stack(children: [
          Opacity(opacity: 0, child: iconWidget),
          Positioned.fill(child:
            Padding(padding: EdgeInsets.all(2), child:
              CircularProgressIndicator(strokeWidth: 2, color: Styles().colors?.fillColorSecondary,)
            ),
          )
        ],) : Opacity(opacity: iconVisible ? 1 : 0, child: iconWidget),
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
    bool externalLink = false,
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
    _launchUrl(_event?.onlineDetails?.url, updateProgress: (bool value) => setStateDelayedIfMounted(() { _onlineLaunching = value; }));
  }

  void _onFavorite() {
    Analytics().logSelect(target: "Favorite: ${_event?.name}");
    Auth2().prefs?.toggleFavorite(_event);
  }

  void _launchUrl(String? url, { BuildContext? context, void Function(bool progress)? updateProgress }) {
    Uri? uri = UrlUtils.parseUri(url);
    if (uri != null) {
      if (updateProgress != null) {
        updateProgress(true);
      }
      UrlUtils.fixUriAsync(uri).then((Uri? fixedUri) {
        if (updateProgress != null) {
          updateProgress(false);
        }
        launchUrl(fixedUri ?? uri, mode: Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault).then((bool result) {
          if (result == false) {
            Event2Popup.showMessage(context ?? this.context, message: Localization().getStringEx('panel.event2.detail.launch.url.failed.message', 'Failed to launch URL.'));
          }
        });
      });
    }
    else {
      Event2Popup.showMessage(context ?? this.context, message: Localization().getStringEx('panel.event2.detail.parse.url.failed.message', 'Failed to parse URL.'));
    }
  }

  void _onWebsiteButton() {
    Analytics().logSelect(target: 'Website');
    _launchUrl(_event?.eventUrl, updateProgress: (bool value) => setStateDelayedIfMounted(() { _websiteLaunching = value; }));
  }

  void _onLinkedEvent(Event2 event) {
    Analytics().logSelect(target: event.name);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event,
      userLocation: _userLocation,
      eventSelector:  widget.eventSelector,
      superEvent: (_event?.isSuperEvent == true) ? _event : null,
    )));
  }

  void _onSuperEvent() {
    Analytics().logSelect(target: _superEvent?.name);
    if (widget.superEvent?.id == _superEvent?.id) {
      Navigator.of(context).pop();
    }
    else {
      Navigator.of(context).push(CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: _superEvent,
        userLocation: _userLocation,
        eventSelector:  widget.eventSelector,
      )));
    }
  }

  void _onRegister() {
    Analytics().logSelect(target: 'Register me');
    _performRegistration(Events2().registerToEvent,
        onSuccess: (Event2 event) {
          if(!Auth2().isFavorite(event)){ //Show only if it's not favorite yet
            AppAlert.showConfirmationDialog(buildContext: context,
                message: Localization().getStringEx("panel.event2.detail.star_event.dialog.message", "Do you want to also Star this event?"),
                positiveCallback: ()=> _onFavorite()
            );
          }
    });
  }

  void _onUnregister() {
    Analytics().logSelect(target: 'Unregister me');
    _performRegistration(Events2().unregisterFromEvent);
  }

  void _performRegistration(Future<dynamic> Function(String eventId) registrationApi, {Function(Event2 event)? onSuccess}) {
    if ((_eventId != null) && !_registrationLoading) {
        setStateIfMounted(() {
          _registrationLoading = true;
        });

      registrationApi(_eventId!).then((result) {
        if (mounted) {
          if (result is Event2) {
            Events2().loadEventPeople(_eventId!).then((Event2PersonsResult? persons) {
              setState(() {
                _event = result;
                _persons = persons;
                _registrationLoading = false;
              });
              onSuccess?.call(result);
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
    _launchUrl(_event?.registrationDetails?.externalLink, updateProgress: (bool value) => setStateDelayedIfMounted(() { _registrationLaunching = value; }));
  }

  void _onFollowUpSurvey(){
    Analytics().logSelect(target: "Follow up survey");
    Survey displaySurvey = Survey.fromOther(_survey!);
    displaySurvey.replaceKey('event_name', _event?.name);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: displaySurvey, onComplete: _onCompleteSurvey)));
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
      _launchUrl("mailto:$email");
    }
  }

  void _onContactPhone(String? phone){
    if(StringUtils.isNotEmpty(phone)) {
      _launchUrl("tel:$phone");
    }
  }

  void _onCompleteSurvey(dynamic result) {
    if (result is SurveyResponse && result.id.isNotEmpty) {
      setStateIfMounted(() {
        _hasSurveyResponse = true;
      });
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
    Navigator.push<Event2SetupSurveyParam?>(context, CupertinoPageRoute(builder: (context) => Event2CreatePanel(event: _event, survey: _survey, eventSelector: widget.eventSelector,))).then((Event2SetupSurveyParam? result) {
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
    
    if ((_event == null) && (StringUtils.isNotEmpty(widget.eventId) && mounted)) {
      // Show loading progress only if we need to load the event.
      setState(() {
        _eventLoading = true;
      });
      Event2? event = await Events2().loadEvent(widget.eventId!);
      setStateIfMounted(() {
        _eventLoading = false;
      });
      if (event != null) {
        List<String>? displayCategories = _buildDisplayCategories(event);
        setStateIfMounted(() {
          _event = event;
          _selectorEvent = event;
          _displayCategories = displayCategories;
        });
      }
    }

    if (_event != null) {
      RecentItems().addRecentItem(RecentItem.fromSource(_event));
    }

    // Load additional stuff that we need for this event.
    String? eventId = _event?.id;
    if ((eventId != null) && mounted) {
      
      List<Future<dynamic>> futures = [];

      // We need the survey and persons only if event has a survey attached.

      int? surveyIndex = ((_event?.hasSurvey == true) && (_survey == null)) ? futures.length : null;
      if (surveyIndex != null) {
        futures.add(Surveys().loadEvent2Survey(eventId));
      }

      int? surveyResponseIndex = ((_event?.hasSurvey == true) && (_survey?.id != null)) ? futures.length : null;
      if (surveyResponseIndex != null) {
        futures.add(Surveys().loadUserSurveyResponses(surveyIDs: [_survey!.id]));
      }

      int? peopleIndex = (((_event?.hasSurvey == true) || (_event?.registrationDetails?.type == Event2RegistrationType.internal)) && (_persons == null)) ? futures.length : null;
      if (peopleIndex != null) {
        futures.add(Events2().loadEventPeople(eventId));
      }

      Event2Grouping? linkedEventsGrouping = _event?.linkedEventsGroupingQuery;
      int? linkedEventsIndex = ((linkedEventsGrouping != null) && (_linkedEvents == null)) ? futures.length : null;
      if (linkedEventsIndex != null) {
        futures.add(Events2().loadEvents(Events2Query(grouping: linkedEventsGrouping, limit: _linkedEventsPageLength)));
        //TMP: futures.add(Events2().loadEvents(Events2Query(searchText: 'Prairie')));
        setState(() {
          _linkedEventsLoading = true;
        });
      }

      int? superEventIndex = ((_event?.isSuperEventChild == true) && (_superEvent == null)) ? futures.length : null;
      if (superEventIndex != null) {
        futures.add(Events2().loadEvent(_event?.grouping?.superEventId ?? ''));
      }

      if (futures.isNotEmpty) {
        List<dynamic> results = await Future.wait(futures);
        Survey? survey = ((surveyIndex != null) && (surveyIndex < results.length) && (results[surveyIndex] is Survey)) ? results[surveyIndex] : null;
        List<SurveyResponse>? surveyResponses = ((surveyResponseIndex != null) && (surveyResponseIndex < results.length) && (results[surveyResponseIndex] is List<SurveyResponse>)) ? results[surveyResponseIndex] : null;
        Event2PersonsResult? persons = ((peopleIndex != null) && (peopleIndex < results.length) && (results[peopleIndex] is Event2PersonsResult)) ? results[peopleIndex] : null;
        Events2ListResult? linkedEventsResult = ((linkedEventsIndex != null) && (linkedEventsIndex < results.length) && (results[linkedEventsIndex] is Events2ListResult)) ? results[linkedEventsIndex] : null;
        Event2? superEvent = ((superEventIndex != null) && (superEventIndex < results.length) && (results[superEventIndex] is Event2)) ? results[superEventIndex] : null;

        // Handle searching for survey responses if the event survey was just loaded
        if ((_event?.hasSurvey == true) && (surveyResponseIndex == null) && (survey?.id != null)) {
          surveyResponses = await Surveys().loadUserSurveyResponses(surveyIDs: [survey!.id]);
        }

        setStateIfMounted(() {
          _eventLoading = false;
          _linkedEventsLoading = false;
          if (survey != null) {
            _survey = survey;
          }
          if (surveyResponses != null) {
            _hasSurveyResponse = surveyResponses.isNotEmpty;
          }
          if (persons != null) {
            _persons = persons;
          }
          if (linkedEventsResult?.events != null) {
            _linkedEvents = linkedEventsResult?.events;
            _lastPageLoadedAllLinkedEvents = (linkedEventsResult!.events!.length >= _linkedEventsPageLength);
            if (linkedEventsResult.totalCount != null) {
              _totalLinkedEventsCount = linkedEventsResult.totalCount;
            }
          }
          if (superEvent != null) {
            _superEvent = superEvent;
          }
        });
      }
    }
  }

  Future<void> _refreshEvent({void Function(bool)? progress}) async {
    String? eventId = widget.event?.id ?? widget.eventId;
    if ((eventId != null) && mounted) {
      
      if (progress != null) {
        setState(() {
          progress(true);
        });
      }

      Event2? event = await Events2().loadEvent(eventId);
      if (mounted) {
        if (event != null) {

          List<Future<dynamic>> futures = [];

          // We need the survey only if event has a survey attached.
          int? surveyIndex = event.hasSurvey ? futures.length : null;
          if (surveyIndex != null) {
            futures.add(Surveys().loadEvent2Survey(eventId));
          }

          // We need the persons only if event has a survey attached.
          int? peopleIndex = event.hasSurvey ? futures.length : null;
          if (peopleIndex != null) {
            futures.add(Events2().loadEventPeople(eventId));
          }

          Event2Grouping? linkedEventsGrouping = event.linkedEventsGroupingQuery;
          int? linkedEventsIndex = (linkedEventsGrouping != null) ? futures.length : null;
          if (linkedEventsIndex != null) {
            futures.add(Events2().loadEvents(Events2Query(grouping: linkedEventsGrouping, limit: (_linkedEvents?.length ?? _linkedEventsPageLength))));
          }

          int? superEventIndex = event.isSuperEventChild ? futures.length : null;
          if (superEventIndex != null) {
            futures.add(Events2().loadEvent(event.grouping?.superEventId ?? ''));
          }

          if (futures.isNotEmpty) {
            List<dynamic> results = await Future.wait(futures);
            Survey? survey = ((surveyIndex != null) && (surveyIndex < results.length) && (results[surveyIndex] is Survey)) ? results[surveyIndex] : null;
            Event2PersonsResult? persons = ((peopleIndex != null) && (peopleIndex < results.length) && (results[peopleIndex] is Event2PersonsResult)) ? results[peopleIndex] : null;
            Events2ListResult? linkedEventsResult = ((linkedEventsIndex != null) && (linkedEventsIndex < results.length) && (results[linkedEventsIndex] is Events2ListResult)) ? results[linkedEventsIndex] : null;
            Event2? superEvent = ((superEventIndex != null) && (superEventIndex < results.length) && (results[superEventIndex] is Event2)) ? results[superEventIndex] : null;

            // Handle searching for existing survey responses
            String? surveyId = survey?.id;
            List<SurveyResponse>? surveyResponses = (event.hasSurvey && (surveyId != null) && mounted) ? await Surveys().loadUserSurveyResponses(surveyIDs: [surveyId]) : null;

            // build display categories
            List<String>? displayCategories = _buildDisplayCategories(event);

            setStateIfMounted(() {
              if (progress != null) {
                progress(false);
              }
              _event = event;
              _selectorEvent = event;
              _displayCategories = displayCategories;
              
              _survey = survey;

              if (persons != null) {
                _persons = persons;
              }
              if (surveyResponses != null) {
                _hasSurveyResponse = surveyResponses.isNotEmpty;
              }
              if (linkedEventsResult?.events != null) {
                _linkedEvents = linkedEventsResult?.events;
                _lastPageLoadedAllLinkedEvents = (linkedEventsResult!.events!.length >= _linkedEventsPageLength);
                if (linkedEventsResult.totalCount != null) {
                  _totalLinkedEventsCount = linkedEventsResult.totalCount;
                }
              }
              if (superEvent != null) {
                _superEvent = superEvent;
              }
            });
          }
          else if (progress != null) {
            setState(() {
              progress(true);
            });
          }
        }
        else if (progress != null) {
          setState(() {
            progress(true);
          });
        }
      }
    }
  }

  void _updateEventIfNeeded(Event2? event) {
    if ((event != null) && (event.id == _eventId) && mounted) {
      setState(() {
        _event = event;
        _selectorEvent = event;
      });
    }
  }

  void _scrollListener() {
    if ((_event?.hasLinkedEvents == true) &&
        (_scrollController.offset >= _scrollController.position.maxScrollExtent) &&
        (_hasMoreLinkedEvents != false) &&
        !_linkedEventsLoading &&
        !_extendingLinkedEvents) {
      _extendLinkedEvents();
    }
  }

  Future<void> _extendLinkedEvents() async {
    Event2Grouping? linkedEventsGrouping = _event?.linkedEventsGroupingQuery;
    if ((linkedEventsGrouping != null) && !_linkedEventsLoading && !_extendingLinkedEvents) {
      setStateIfMounted(() {
        _extendingLinkedEvents = true;
      });
      Events2ListResult? linkedEventsListResult = await Events2().loadEvents(Events2Query(grouping: linkedEventsGrouping, offset: _linkedEvents?.length ?? 0, limit: _linkedEventsPageLength));
      List<Event2>? events = linkedEventsListResult?.events;
      int? totalCount = linkedEventsListResult?.totalCount;

      if (mounted && _extendingLinkedEvents && !_linkedEventsLoading) {
        setState(() {
          if (events != null) {
            if (_linkedEvents != null) {
              _linkedEvents?.addAll(events);
            } else {
              _linkedEvents = List<Event2>.from(events);
            }
            _lastPageLoadedAllLinkedEvents = (events.length >= _linkedEventsPageLength);
          }
          if (totalCount != null) {
            _totalLinkedEventsCount = totalCount;
          }
          _extendingLinkedEvents = false;
        });
      }
    }
  }

  //Event getters
  bool get _isAdmin =>  _event?.userRole == Event2UserRole.admin;
  bool get _isAttendanceTaker =>  _event?.userRole == Event2UserRole.attendanceTaker;
  //bool get _isParticipant =>  _event?.userRole == Event2UserRole.participant;
  bool get _isAttendee => (_persons?.attendees?.indexWhere((person) => person.identifier?.accountId == Auth2().accountId) ?? -1) > -1;
  bool get _hasDisplayCategories => (_displayCategories?.isNotEmpty == true);
  bool get _isInternalRegistrationAvailable => (_event?.registrationDetails?.type == Event2RegistrationType.internal) &&
    (_event?.registrationDetails?.isRegistrationAvailable(_persons?.registrationOccupancy) == true);
  bool? get _hasMoreLinkedEvents => (_totalLinkedEventsCount != null) ? ((_linkedEvents?.length ?? 0) < _totalLinkedEventsCount!) : _lastPageLoadedAllLinkedEvents;

  String? get _eventId => widget.event?.id ?? widget.eventId;

  //Event to Group Binding support
  @override
  Event2SelectorData? selectorData;

  void _initSelector(){
    widget.eventSelector?.init(this);
    selectorData?.event = _event;
  }

  void set _selectorEvent(Event2 event) => selectorData?.event = event;
}

extension _Event2Ext on Event2 {

  Event2Grouping? get linkedEventsGroupingQuery {
    if (isSuperEvent) {
      return Event2Grouping.superEvent(id);
    }
    else if (isRecurring) {
      return Event2Grouping.recurrence(grouping?.recurrenceId);
    }
    else {
      return null;
    }
  }
}

//EventSelector Interface
abstract class Event2Selector<T extends Event2SelectorData> {
  final T data; //Pass initial data (containing group etc)

  Event2Selector(this.data);

  void init(State state){
    if( (state is Event2SelectorDataProvider)){
      ( state as Event2SelectorDataProvider).selectorData = data; // Hook the data to the DataProvider (pass initial data)
    }
  }

  void dispose(State state){}

  Widget? buildWidget(State state); //Provide custom layout to perform selection

  Future<void> prepareSelection(State state) async {} //Call whatever API we need before performing the selection

  Future<dynamic> Function(Event2 source)? event2SelectorServiceAPI() => null;

  Future<void> performSelection(State state) async {} //Call the bind API

  void finishSelection(State state) {} //Go Back to the initial flow panel

}

abstract class Event2SelectorDataProvider <T extends Event2SelectorData>{
  void set selectorData(T? data);
  T? get selectorData; //Mechanism to write to the data from the Provider[EventPanel] (passing selected event etc)
}

class Event2SelectorData{
  Map<String, dynamic> data;
  Event2SelectorData({required this.data});

  void set event(Event2? event) => data["event"] = event;
  Event2? get event {
    dynamic eventData = data["event"];
    return (eventData is Event2)? eventData : null;
  }
}