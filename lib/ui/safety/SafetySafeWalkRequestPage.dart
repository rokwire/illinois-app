
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/explore/ExploreMapPanel.dart';
import 'package:illinois/ui/explore/ExploreMapSelectLocationPanel.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:illinois/ui/safety/SafetyHomePanel.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:illinois/ui/widgets/QrCodePanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

enum _SafeWalkLocationType { current, map, saved }

class SafetySafeWalkRequestPage extends StatefulWidget with SafetyHomeContentPage {

  final Map<String, dynamic>? origin;
  final Map<String, dynamic>? destination;

  SafetySafeWalkRequestPage({super.key, this.origin, this.destination});

  // StatefulWidget

  @override
  State<StatefulWidget> createState() => _SafetySafeWalkRequestPageState();

  // SafetyHomeContentPage

  @override
  Color get safetyPageBackgroundColor => Styles().colors.fillColorPrimaryVariant;
}

class _SafetySafeWalkRequestPageState extends State<SafetySafeWalkRequestPage> {

  final GlobalKey<_SafetySafeWalkRequestCardState> _safeWalksCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) => Column(children: [
    _mainLayer(context),
    _detailsLayer(context),
  ],);

  Widget _mainLayer(BuildContext context) =>
    Container(decoration: _mainLayerDecoration, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.only(left: 24, top: 32), child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child:
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                Text(Localization().getStringEx('panel.safewalks_request.header.title', 'SafeWalks'), style: _titleTextStyle,)
              ),
            ),
            InkWell(onTap: () => _onTapOptions(context), child:
              Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16), child:
                Styles().images.getImage('more-white', excludeFromSemantics: true)
              )
            )
          ],),
        ),
        Padding(padding: EdgeInsets.only(left: 24, right: 16, bottom: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_subTitle1Text, style: _subTitleTextStyle,),
            Text(_subTitle2Text, style: _subTitleTextStyle,),
            Container(height: 12,),
            Text(_info1Text, style: _infoTextStyle,),
            Text(_info2Text, style: _infoTextStyle,),
            Container(height: 6,),
            Text(_info3Text, style: _infoTextStyle,),
          ])
        ),
        Stack(children: [
          Positioned.fill(child:
            Column(children: [
              Expanded(child:
                Container()
              ),
              CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background, horzDir: TriangleHorzDirection.rightToLeft), child:
                Container(height: 42,),
              ),
            ],)
          ),
          Padding(padding: EdgeInsets.only(left: 24, right: 24), child:
            SafetySafeWalkRequestCard(key: _safeWalksCardKey, origin: widget.origin, destination: widget.destination,),
          ),
        ],),
      ],)
    );

  Widget _detailsLayer(BuildContext context) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24,), child:
      Column( children: [
        HtmlWidget(_phoneDetailHtml,
          onTapUrl : (url) => _launchUrl(url, context: context, analyticsTarget: Config().safeWalkPhoneNumber),
          textStyle:  _htmlDetailTextStyle,
          customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
        ),
        Container(height: 24,),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: EdgeInsets.only(right: 6), child:
            Styles().images.getImage('info') ?? _detailIconSpacer,
          ),
          Expanded(child:
            Align(alignment: Alignment.topLeft, child:
            HtmlWidget(_safeRidesDetailHtml,
              onTapUrl : (url) => _launchUrl(url, context: context, analyticsTarget: 'SafeRides'),
              textStyle:  _htmlDetailTextStyle,
              customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
            ),
            ),
          )
        ],),
        Row(children: [
          Padding(padding: EdgeInsets.only(right: 6), child:
            Styles().images.getImage('settings') ?? _detailIconSpacer,
          ),
          Expanded(child:
            InkWell(onTap: () => _onTapLocationSettings(context), child:
              Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
                Text(Localization().getStringEx('panel.safewalks_request.detail.settings.text', 'My Location Settings'),
                  style:  Styles().textStyles.getTextStyle("widget.button.title.small.underline"),
                ),
              )
            )
          )
        ],),
      ],)
    );

  BoxDecoration get _mainLayerDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Styles().colors.fillColorPrimaryVariant,
        Styles().colors.gradientColorPrimary,
      ]
    )
  );

  Widget get _detailIconSpacer => SizedBox(width: 18, height: 18,);

  TextStyle? get _titleTextStyle => Styles().textStyles.getTextStyle('widget.heading.extra2_large.extra_fat');
  TextStyle? get _subTitleTextStyle => Styles().textStyles.getTextStyle('panel.safewalks_request.sub_title');
  TextStyle? get _infoTextStyle => Styles().textStyles.getTextStyle('panel.safewalks_request.info');

  static const String _safeWalkStartTimeMacro = '{{safewalk_start_time}}';
  static const String _safeWalkEndTimeMacro = '{{safewalk_end_time}}';
  static const String _safeWalkOrderIntervalMacro = '{{safewalk_order_interval}}';
  static const String _safeWalkPhoneNumberMacro = '{{safewalk_phone_number}}';
  static const String _safeRidesUrlMacro = '{{saferides_url}}';
  static const String _externalLinkMacro = '{{external_link_icon}}';

  String get _subTitle1Text =>
    Localization().getStringEx('panel.safewalks_request.sub_title1.text', 'Trust your instincts.');

  String get _subTitle2Text =>
    Localization().getStringEx('panel.safewalks_request.sub_title2.text', 'You never have to walk alone.');

  String get _info1Text =>
    Localization().getStringEx('panel.safewalks_request.info1.text', 'Request a student patrol officer to walk with you.');

  String get _info2Text =>
    Localization().getStringEx('panel.safewalks_request.info2.text', 'Please give at least $_safeWalkOrderIntervalMacro minutes\' notice.')
        .replaceAll(_safeWalkOrderIntervalMacro, Config().safeWalkOrderInterval ?? '15');

  String get _info3Text =>
    Localization().getStringEx('panel.safewalks_request.info3.text', 'Available $_safeWalkStartTimeMacro to $_safeWalkEndTimeMacro')
      .replaceAll(_safeWalkStartTimeMacro, Config().safeWalkStartTime ?? '9:00 p.m.')
      .replaceAll(_safeWalkEndTimeMacro, Config().safeWalkEndTime ?? '2:30 a.m.');

  TextStyle? get _htmlDetailTextStyle => Styles().textStyles.getTextStyle('widget.message.small');

  String get _phoneDetailHtml =>
    Localization().getStringEx('panel.safewalks_request.detail.phone.html', 'You can also schedule a walk by calling <a href=\'tel:$_safeWalkPhoneNumberMacro\'>$_safeWalkPhoneNumberMacro</a>.')
      .replaceAll(_safeWalkPhoneNumberMacro, Config().safeWalkPhoneNumber ?? '');

  String get _safeRidesDetailHtml =>
    Localization().getStringEx('panel.safewalks_request.detail.saferides.html', 'Looking for a ride instead? The Champaign-Urbana Mass Transit District offers limited <a href=\'$_safeRidesUrlMacro\'>SafeRides</a>&nbsp;<img src=\'asset:$_externalLinkMacro\' alt=\'\'/> at night..')
      .replaceAll(_safeRidesUrlMacro, Config().safeRidesAboutUrl ?? '')
      .replaceAll(_externalLinkMacro, 'images/external-link.png');

  void _onTapOptions(BuildContext context) {
    Analytics().logSelect(target: 'SafeWalks Options');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16), child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          RibbonButton(label: Localization().getStringEx('panel.safewalks_request.command.about.text', 'About SafeWalks'), rightIconKey: 'external-link', onTap: () => _onTapAboutSafeWalks(context)),
          RibbonButton(label: Localization().getStringEx('panel.safewalks_request.command.share.text', 'Share SafeWalks'), onTap: () => _onTapShareSafeWalks(context)),
          RibbonButton(label: Localization().getStringEx('panel.safewalks_request.command.safety_resources.text', 'Safety Resources'), onTap: () => _onTapCampusResources(context))
        ])
      ),
    );
  }

  void _onTapLocationSettings(BuildContext context) {
    Analytics().logSelect(target: Localization().getStringEx('panel.safewalks_request.detail.settings.text', 'My Location Settings', language: 'en'));
    SettingsHomePanel.present(context, content: SettingsContentType.maps);
  }

  static bool _launchUrl(String url, { required BuildContext context, String? analyticsTarget, bool launchInternal = false }) =>
    _SafetySafeWalkRequestCardState._launchUrl(url, context: context, analyticsTarget: analyticsTarget, launchInternal: launchInternal);

  void _onTapAboutSafeWalks(BuildContext context) {
    Analytics().logSelect(target: 'About SafeWalks');
    Navigator.pop(context);

    String? aboutUrl = Config().safeWalkAboutUrl;
    Uri? aboutUri = (aboutUrl != null) ? Uri.tryParse(aboutUrl) : null;
    if (aboutUri != null) {
      launchUrl(aboutUri);
    }
  }

  void _onTapShareSafeWalks(BuildContext context) {
    Analytics().logSelect(target: 'Share SafeWalks');
    _SafetySafeWalkRequestCardState? cardState = _safeWalksCardKey.currentState;
    if (cardState != null) {
      Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) =>
        QrCodePanel.fromSafeWalk(origin: cardState.originExploreLocation, destination: cardState.destinationExploreLocation, analyticsFeature: AnalyticsFeature.Safety,)
      ));
    }
  }

  void _onTapCampusResources(BuildContext context) {
    Analytics().logSelect(target: 'Campus Resources');
    Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
      contentList: Guide().safetyResourcesList,
      contentTitle: Localization().getStringEx('panel.guide_list.label.safety_resources.section', 'Safety Resources'),
      contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.safety_resources.empty", "There are no active Campus Safety Resources."),
      favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusSafetyResourceContentType),
    )));
  }
}

class SafetySafeWalkRequestCard extends StatefulWidget {

  final Widget? headerWidget;
  final Color? backgroundColor;
  final BorderRadius borderRadius;
  final Map<String, dynamic>? origin;
  final Map<String, dynamic>? destination;

  SafetySafeWalkRequestCard({super.key, this.headerWidget, this.backgroundColor, this.borderRadius = const BorderRadius.all(const Radius.circular(16)), this.origin, this.destination});

  @override
  State<StatefulWidget> createState() => _SafetySafeWalkRequestCardState();
}

class _SafetySafeWalkRequestCardState extends State<SafetySafeWalkRequestCard> {
  static const String _safeWalkUserNameMacro = '{{safewalk_user_name}}';
  static const String _safeWalkOriginMacro = '{{safewalk_origin}}';
  static const String _safeWalkOriginUrlMacro = '{{safewalk_origin_url}}';
  static const String _safeWalkDestinationMacro = '{{safewalk_destination}}';
  static const String _safeWalkDestinationUrlMacro = '{{safewalk_destination_url}}';

  dynamic _originLocation, _destinationLocation;
  bool _originProgress = false, _destinationProgress = false, _sendProgress = false;

  @override
  void initState() {
    _originLocation = _locationFromJson(widget.origin);
    _destinationLocation = _locationFromJson(widget.destination);
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _cardDecoration, padding: EdgeInsets.all(16), child:
      Column(children: [

        if (widget.headerWidget != null)
          widget.headerWidget ?? Container(),

        Row(children: [
          Padding(padding: EdgeInsets.only(right: 8), child:
            _detailIconSpacer,
          ),
          Expanded(child:
            Text(Localization().getStringEx('widget.safewalks_request.origin.title', 'Current Location'), style: _titleTextStyle,),
          ),
        ],),

        Row(children: [
          Padding(padding: EdgeInsets.only(right: 8), child:
            Styles().images.getImage('person', size: _detailIconSize) ?? _detailIconSpacer,
          ),
          Expanded(child:
            _dropdownButton(
              text: _locationShortDescription(_originLocation),
              progress: _originProgress,
              items: _originDropDownItems,
              onChanged: _onTapOriginLocationType,
            ),
          ),
        ],),

        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Padding(padding: EdgeInsets.only(left: _detailIconSize / 2, right: _detailIconSize / 2 + 7), child:
            CustomPaint(size: Size(1, 16 + MediaQuery.of(context).textScaler.scale(_titleTextStyle?.fontSize ?? 18)), painter:
              _VerticalDashedLinePainter(dashColor: Styles().colors.fillColorPrimary),
            )
          ),
          Expanded(child:
            Text(Localization().getStringEx('widget.safewalks_request.destination.title', 'Destination'), style: _titleTextStyle,),
          ),
        ],),

        Row(children: [
          Padding(padding: EdgeInsets.only(right: 8), child:
            Styles().images.getImage('location', size: _detailIconSize) ?? _detailIconSpacer,
          ),
          Expanded(child:
            _dropdownButton(
              text: _locationShortDescription(_destinationLocation),
              progress: _destinationProgress,
              items: _destinationDropDownItems,
              onChanged: _onTapDestinationLocationType,
            ),
          ),
        ],),

        Padding(padding: EdgeInsets.only(top: 24, bottom: 8), child:
          Row(children: [
            //Padding(padding: EdgeInsets.only(right: 8), child: _detailIconSpacer,),
            Expanded(child:
              Center(child:
                RoundedButton(
                  label: Localization().getStringEx('widget.safewalks_request.start.title', 'Start with a Text'),
                  //textStyle: _sendEnabled ? Styles().textStyles.getTextStyle("widget.button.title.large.fat") : Styles().textStyles.getTextStyle("widget.button.disabled.title.large.fat"),
                  //borderColor: _sendEnabled ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.small.fat"),
                  padding: EdgeInsets.symmetric(vertical: 8),
                  leftIcon: Styles().images.getImage('paper-plane', size: _sendIconSize),
                  leftIconPadding: EdgeInsets.symmetric(horizontal: 12),
                  rightIconPadding: EdgeInsets.only(left: 24),
                  contentWeight: -1,
                  progress: _sendProgress,
                  onTap: _onTapSend,
                )
              )
            ),
          ],),
        )
      ],)
    );

  Widget _dropdownButton({ String? text, bool? progress, required List<DropdownMenuItem<_SafeWalkLocationType>> items, void Function(_SafeWalkLocationType?)? onChanged }) =>
    Container(decoration: _dropdownButtonDecoration, child:
      Padding(padding: EdgeInsets.only(left: 12, right: 8, top: 2, bottom: 2), child:
        DropdownButtonHideUnderline(child:
          DropdownButton<_SafeWalkLocationType>(
            icon: Styles().images.getImage('chevron-down'),
            isExpanded: true,
            style: _dropDownItemTextStyle,
            dropdownColor: Styles().colors.surface,
            hint: _dropdownButtonHint(text: text, progress: progress),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );

  Widget? _dropdownButtonHint({String? text, bool? progress}) => (progress == true) ?
    Center(child:
      SizedBox(width: 18, height: 18, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 2,)
      )
    ) :
    Text(text ?? '', style: _dropDownItemTextStyle,);

  Widget _dropDownItemWidget({String? title, Widget? icon}) =>
    Semantics(label: title, excludeSemantics: true, container:true, child:
      Row(children: [
        Padding(padding: EdgeInsets.only(right: 8), child:
          icon ?? _detailIconSpacer,
        ),
        Expanded(child:
          Text(title ?? '', style: _dropDownItemTextStyle,),
        ),
      ],),
    );

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: widget.backgroundColor ?? Styles().colors.background,
    //border: Border.all(color: Styles().colors.mediumGray2, width: 1),
    borderRadius: widget.borderRadius,
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
  );

  BoxDecoration get _dropdownButtonDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(5))
  );

  List<DropdownMenuItem<_SafeWalkLocationType>> get _originDropDownItems => _locationTypeDropDownWidgets(<_SafeWalkLocationType>[
    _SafeWalkLocationType.current,
    _SafeWalkLocationType.map,
    _SafeWalkLocationType.saved,
  ]);

  List<DropdownMenuItem<_SafeWalkLocationType>> get _destinationDropDownItems => _locationTypeDropDownWidgets(<_SafeWalkLocationType>[
    _SafeWalkLocationType.map,
    _SafeWalkLocationType.saved,
  ]);

  List<DropdownMenuItem<_SafeWalkLocationType>> _locationTypeDropDownWidgets(List<_SafeWalkLocationType> locationTypes) =>
    locationTypes.map(_locationTypeDropDownItem).toList();

  DropdownMenuItem<_SafeWalkLocationType> _locationTypeDropDownItem(_SafeWalkLocationType locationType) =>
    DropdownMenuItem<_SafeWalkLocationType>(value: locationType, child: _locationTypeDropDownWidget(locationType));

  Widget _locationTypeDropDownWidget(_SafeWalkLocationType locationType) =>
    _dropDownItemWidget(
      title: _safeWalkLocationTypeToDisplayString(locationType),
      icon: _safeWalkLocationTypeDisplayIcon(locationType),
    );

  TextStyle? get _titleTextStyle => Styles().textStyles.getTextStyle('widget.title.small.fat');
  TextStyle? get _dropDownItemTextStyle => Styles().textStyles.getTextStyle('widget.title.small.semi_fat');

  double get _sendIconSize => 14;
  double get _detailIconSize => 18;
  Widget get _detailIconSpacer => SizedBox(width: _detailIconSize, height: _detailIconSize,);

  void _updateOriginProgress(bool value) => setState((){
    _originProgress = value;
  });

  void _updateDestinationProgress(bool value) => setState((){
    _destinationProgress = value;
  });

  Future<dynamic> _provideLocation(_SafeWalkLocationType? locationType, { dynamic locationValue, void Function(bool)? updateProgress }) async {
    if (locationType == _SafeWalkLocationType.current) {
      return _provideCurrentLocation(updateProgress: updateProgress);
    }
    else if (locationType == _SafeWalkLocationType.map) {
      return _provideMapLocation(locationValue, updateProgress: updateProgress);
    }
    else if (locationType == _SafeWalkLocationType.saved) {
      return _provideSavedLocation();
    }
  }

  Future<dynamic> _provideCurrentLocation({ void Function(bool)? updateProgress }) async {
    updateProgress?.call(true);
    LocationServicesStatus? status = await LocationServices().status;
    if ((status == LocationServicesStatus.serviceDisabled) && mounted) {
      status = await LocationServices().requestService();
    }
    if ((status == LocationServicesStatus.permissionNotDetermined) && mounted) {
      status = await LocationServices().requestPermission();
    }
    if (mounted) {
      if (status == LocationServicesStatus.permissionAllowed) {
        Position? position = await LocationServices().location;
        updateProgress?.call(false);
        return position;
      }
      else {
        updateProgress?.call(false);
        if (status == LocationServicesStatus.permissionNotDetermined) {
          ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.location.service.disabled.title', 'Location Services not enabled.'));
        }
        else if (status == LocationServicesStatus.permissionDenied) {
          ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.location.service.denied.title', 'Location Services access denied.'));
        }
        else {
          ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.service_not_available.title', 'Location Services not available.'));
        }
      }
    }

  }

  Future<dynamic> _provideMapLocation(dynamic location, { void Function(bool)? updateProgress }) async =>
    ExploreMapSelectLocationPanel.push(context,
      mapType: ExploreMapType.Buildings,
      /*selectedExplore: _locationExplore(location),*/
    );

  Future<dynamic> _provideSavedLocation() async =>
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SavedPanel(
      favoriteCategories: [ExplorePOI.favoriteKeyName],
      onTapFavorite: (Favorite favorite) {
        Navigator.pop(context, favorite);
      },
    )));

  String? _locationShortDescription(dynamic location) {
    if (location is Position) {
      return "[${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}]";
    }
    else if (location is Explore) {
      return location.exploreTitle;
    }
    else if (location is Favorite) {
      return location.favoriteTitle;
    }
    else {
      return null;
    }
  }

  String? _locationLongDescription(dynamic location) {
    if (location is Position) {
      return "Map [${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}]";
    }
    else if (location is Explore) {
      String? name = location.exploreLocation?.building ?? location.exploreTitle;
      String? address;
      if (StringUtils.isNotEmpty(location.exploreLocation?.address) &&
        StringUtils.isNotEmpty(location.exploreLocation?.city) &&
        StringUtils.isNotEmpty(location.exploreLocation?.state) &&
        StringUtils.isNotEmpty(location.exploreLocation?.zip))
      {
        address = "${location.exploreLocation?.address}\n${location.exploreLocation?.city}, ${location.exploreLocation?.state} ${location.exploreLocation?.zip}";
      }
      else if (StringUtils.isNotEmpty(location.exploreLocation?.description)) {
        address = location.exploreLocation?.description;
      }
      else if ((location.exploreLocation?.longitude != null) && (location.exploreLocation?.longitude != null)) {
        address = "Map [${location.exploreLocation?.latitude?.toStringAsFixed(6)}, ${location.exploreLocation?.longitude?.toStringAsFixed(6)}]";
      }
      if (StringUtils.isNotEmpty(address)) {
        return StringUtils.isNotEmpty(name) ? "$name\n$address" : address;  
      }
      else {
        return name;
      }
    }
    else if (location is Favorite) {
      return location.favoriteTitle;
    }
    else {
      return null;
    }
  }

  Future<String?> _locationUrl(dynamic location) =>
    GeoMapUtils.locationUrl(_locationUrlSource(location));

  dynamic _locationUrlSource(dynamic location) {
    if (location is Position) {
      return LatLng(location.latitude, location.longitude);
    }
    else if (location is Explore) {
      return location.exploreLocation?.exploreLocationMapCoordinate ?? location.exploreLocation?.displayAddress;
    }
    else {
      return null;
    }
  }

  Map<String, dynamic>? get originExploreLocation => _locationToJson(_originLocation);
  Map<String, dynamic>? get destinationExploreLocation => _locationToJson(_destinationLocation);

  Map<String, dynamic>? _locationToJson(dynamic location) {
    if (location is Position) {
      return location.toJson();
    }
    else if (location is Explore) {
      return location.exploreLocation?.toJson();
    }
    else {
      return null;
    }
  }

  dynamic _locationFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    else if ((json['latitude'] != null) && (json['longitude'] != null) && (json['timestamp'] != null)) {
      return Position.fromMap(json);
    }
    else {
      ExploreLocation? location = ExploreLocation.fromJson(json);
      return (location != null) ? ExplorePOI(name: location.building ?? location.name, location: location) : null;
    }
  }

  void _onTapOriginLocationType(_SafeWalkLocationType? locationType) {
    Analytics().logSelect(target: "Origin: ${_safeWalkLocationTypeToDisplayString(locationType)}");
    _provideLocation(locationType, locationValue: _originLocation, updateProgress: _updateOriginProgress).then((result){
      if ((result != null) && mounted) {
        setState(() {
          _originLocation = result;
        });
      }
    });
  }

  void _onTapDestinationLocationType(_SafeWalkLocationType? locationType) {
    Analytics().logSelect(target: "Destination: ${_safeWalkLocationTypeToDisplayString(locationType)}");
    _provideLocation(locationType, locationValue: _destinationLocation, updateProgress: _updateDestinationProgress).then((result){
      if ((result != null) && mounted) {
        setState(() {
          _destinationLocation = result;
        });
      }
    });
  }

  //bool get _sendEnabled => (_originLocation != null) && (_destinationLocation != null);

  void _onTapSend() async {
    Analytics().logSelect(target: 'Start with a Text', feature: AnalyticsFeature.Safety);
    if (_sendProgress != true) {
      if (_isSafeWalkInWorkHours == false) {
        ExploreMessagePopup.show(context, _safeWalkOutOfWorkHoursHtml, onTapUrl: (String url) => _launchUrl(url, context: context, analyticsTarget: Config().safeWalkPhoneNumber));
      }
      else if (_originLocation == null) {
        ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.missing.origin.title', 'Please select your current location.'));
      }
      else if (_destinationLocation == null) {
        ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.missing.destination.title', 'Please select your destination.'));
      }
      else if (Config().safeWalkTextNumber == null) {
        ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.missing.recipient.title', 'Unable to send text message, recipient number is not available.'));
      }
      else {
        String messageSource = Auth2().isOidcLoggedIn ?
          Localization().getStringEx('widget.safewalks_request.message.sms.logged_in.text', 'Hi, my name is $_safeWalkUserNameMacro and I\'d like to request a SafeWalk.\n\nMy Current Location:\n$_safeWalkOriginMacro\n$_safeWalkOriginUrlMacro\n\nMy Destination:\n$_safeWalkDestinationMacro\n$_safeWalkDestinationUrlMacro') :
          Localization().getStringEx('widget.safewalks_request.message.sms.logged_out.text', 'Hi, I\'d like to request a SafeWalk.\n\nMy Current Location:\n$_safeWalkOriginMacro\n$_safeWalkOriginUrlMacro\n\nMy Destination:\n$_safeWalkDestinationMacro\n$_safeWalkDestinationUrlMacro');
        String message = messageSource
          .replaceAll(_safeWalkUserNameMacro, Auth2().account?.authType?.uiucUser?.firstName ?? Auth2().profile?.firstName ?? Localization().getStringEx('widget.safewalks_request.unknown.user.text', 'Unauthenticated User'))
          .replaceAll(_safeWalkOriginMacro, _locationLongDescription(_originLocation) ?? Localization().getStringEx('widget.safewalks_request.unknown.location.text', 'Unknwon'))
          .replaceAll(_safeWalkOriginUrlMacro, await _locationUrl(_originLocation) ?? '')
          .replaceAll(_safeWalkDestinationMacro, _locationLongDescription(_destinationLocation) ?? Localization().getStringEx('widget.safewalks_request.unknown.location.text', 'Unknwon'))
          .replaceAll(_safeWalkDestinationUrlMacro, await _locationUrl(_destinationLocation) ?? '');

        String url = "sms:${Config().safeWalkTextNumber}?body=" + Uri.encodeComponent(message);
        Uri? uri = Uri.tryParse(url);
        if (uri == null) {
          ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.internal.error.title', 'Unable to send text message, internal error occured.'));
        }
        else {
          setState(() {
            _sendProgress = true;
          });

          canLaunchUrl(uri).then((bool result){
            if (mounted) {
              setState(() {
                _sendProgress = false;
              });

              if (result != true) {
                ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.sms.service.not_available.title', 'Unable to send text message, messaging service not available.'));
              }
              else {
                launchUrl(uri);
              }
            }
          });

        }
      }
    }
  }

  bool? get _isSafeWalkInWorkHours {
    int? startTimeInterval = Config().safeWalkStartTimeInterval;
    int? endTimeInterval = Config().safeWalkEndTimeInterval;
    DateTime? currentDateTimeUni = DateTimeUni.nowUni(); // ?? DateTime.now();
    if ((currentDateTimeUni != null) && (startTimeInterval != null) && (endTimeInterval != null)) {
      int currentTimeInterval = currentDateTimeUni.hour * 60 + currentDateTimeUni.minute;
      return (startTimeInterval <= endTimeInterval) ?
        ((startTimeInterval <= currentTimeInterval) && (currentTimeInterval <= endTimeInterval)) :
        ((startTimeInterval <= currentTimeInterval) || (currentTimeInterval <= endTimeInterval));
    }
    return null;
  }

  static const String _safeWalkPhoneNumberMacro = '{{safewalk_phone_number}}';

  String get _safeWalkOutOfWorkHoursHtml =>
    Localization().getStringEx('widget.safewalks_request.message.service.worktime.out_of_hours.html', '<b>SafeWalks is not available at this time.</b><br>For more information, call <a href=\'tel:$_safeWalkPhoneNumberMacro\'>$_safeWalkPhoneNumberMacro</a>.')
      .replaceAll(_safeWalkPhoneNumberMacro, Config().safeWalkPhoneNumber ?? '');
  
  static bool _launchUrl(String url, { required BuildContext context, String? analyticsTarget, bool launchInternal = false }) {
    Analytics().logSelect(target: analyticsTarget ?? url);
    if (url.isNotEmpty) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        bool tryInternal = launchInternal && UrlUtils.canLaunchInternal(url);
        AppLaunchUrl.launch(context: context, url: url, tryInternal: tryInternal);
      }
      return true;
    }
    else {
      return false;
    }
  }
}

String? _safeWalkLocationTypeToDisplayString(_SafeWalkLocationType? locationType) {
  switch (locationType) {
    case _SafeWalkLocationType.current: return Localization().getStringEx('widget.safewalks_request.location.current.title', 'Use My Location');
    case _SafeWalkLocationType.map: return Localization().getStringEx('widget.safewalks_request.location.map.title', 'Search Map');
    case _SafeWalkLocationType.saved: return Localization().getStringEx('widget.safewalks_request.location.saved.title', 'View Saved Locations');
    default: return null;
  }
}

Widget? _safeWalkLocationTypeDisplayIcon(_SafeWalkLocationType? locationType) {
  switch (locationType) {
    case _SafeWalkLocationType.current: return Styles().images.getImage('location', color: Styles().colors.fillColorPrimary);
    case _SafeWalkLocationType.map: return Styles().images.getImage('search', color: Styles().colors.fillColorPrimary);
    case _SafeWalkLocationType.saved: return Styles().images.getImage('star-filled', color: Styles().colors.fillColorPrimary);
    default: return null;
  }
}

class _VerticalDashedLinePainter extends CustomPainter {
  final double dashHeight;
  final double dashSpace;
  final Color dashColor;

  // ignore: unused_element_parameter
  _VerticalDashedLinePainter({this.dashHeight = 5, this.dashSpace = 3, this.dashColor = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dashColor
      ..strokeWidth = size.width;
    for (double startY = 0; startY < size.height; startY += dashHeight + dashSpace) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
