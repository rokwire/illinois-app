
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:neom/ext/Favorite.dart';
import 'package:neom/model/Analytics.dart';
import 'package:neom/model/Explore.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/Guide.dart';
import 'package:neom/ui/SavedPanel.dart';
import 'package:neom/ui/WebPanel.dart';
import 'package:neom/ui/explore/ExploreMapPanel.dart';
import 'package:neom/ui/explore/ExploreMapSelectLocationPanel.dart';
import 'package:neom/ui/guide/GuideListPanel.dart';
import 'package:neom/ui/safety/SafetyHomePanel.dart';
import 'package:neom/ui/settings/SettingsHomeContentPanel.dart';
import 'package:neom/ui/widgets/QrCodePanel.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

enum _SafeWalkLocationType { current, map, saved }

class SafetySafeWalkRequestPage extends StatelessWidget with SafetyHomeContentPage {

  final Map<String, dynamic>? origin;
  final Map<String, dynamic>? destination;
  final GlobalKey<_SafetySafeWalkRequestCardState> _safeWalksCardKey = GlobalKey();

  SafetySafeWalkRequestPage({super.key, this.origin, this.destination});

  @override
  Widget build(BuildContext context) => Column(children: [
    _mainLayer(context),
    _detailsLayer(context),
  ],);

  @override
  Color get safetyPageBackgroundColor => Styles().colors.fillColorPrimaryVariant;
  
  Widget _mainLayer(BuildContext context) => Container(color: safetyPageBackgroundColor, child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(left: 16, top: 32), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
              Text(Localization().getStringEx('panel.safewalks_request.header.title', 'SafeWalks'), style: _titleTextStyle,)
            ),
          ),
          InkWell(onTap: () => _onTapOptions(context), child:
            Padding(padding: EdgeInsets.all(16), child:
              Styles().images.getImage('more-white', excludeFromSemantics: true)
            )
          )
        ],),
      ),
      Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
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
        Padding(padding: EdgeInsets.only(left: 16, right: 16), child:
          SafetySafeWalkRequestCard(key: _safeWalksCardKey, origin: origin, destination: destination,),
        ),
      ],),
    ],)
  );

  Widget _detailsLayer(BuildContext context) => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16,), child:
    Column( children: [
      HtmlWidget(_phoneDetailHtml,
        onTapUrl : (url) { _onTapLink(url, context: context, analyticsTarget: Config().safeWalkPhoneNumber); return true;},
        textStyle:  Styles().textStyles.getTextStyle("widget.message.small"),
        customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
      ),
      Container(height: 24,),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.only(right: 6), child:
          Styles().images.getImage('info') ?? _detailIconSpacer,
        ),
        Expanded(child:
          HtmlWidget(_safeRidesDetailHtml,
            onTapUrl : (url) { _onTapLink(url, context: context, analyticsTarget: 'SafeRides'); return true;},
            textStyle:  Styles().textStyles.getTextStyle("widget.message.small"),
            customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
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

  String get _phoneDetailHtml =>
    Localization().getStringEx('panel.safewalks_request.detail.phone.html', 'You can also schedule a walk by calling <a href=\'tel:$_safeWalkPhoneNumberMacro\'>$_safeWalkPhoneNumberMacro</a>.')
      .replaceAll(_safeWalkPhoneNumberMacro, Config().safeWalkPhoneNumber ?? '');

  String get _safeRidesDetailHtml =>
    Localization().getStringEx('panel.safewalks_request.detail.saferides.html', 'Looking for a ride instead? The Champaign-Urbana Mass Transit District offers limited <a href=\'$_safeRidesUrlMacro\'>SafeRides</a>&nbsp;<img src=\'asset:$_externalLinkMacro\' alt=\'\'/> at night..')
      .replaceAll(_safeRidesUrlMacro, Guide().detailUrl(Config().safeRidesGuideId, analyticsFeature: AnalyticsFeature.Safety))
      .replaceAll(_externalLinkMacro, 'images/external-link.png');

  void _onTapOptions(BuildContext context) {
    Analytics().logSelect(target: 'SafeWalks Options');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
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
    SettingsHomeContentPanel.present(context, content: SettingsContent.maps);
  }

  void _onTapLink(String url, { required BuildContext context, String? analyticsTarget, bool launchInternal = false }) {
    Analytics().logSelect(target: analyticsTarget ?? url);
    if (url.isNotEmpty) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else if (launchInternal && UrlUtils.launchInternal(url)){
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      }
      else {
        Uri? uri = Uri.tryParse(url);
        if (uri != null) {
          launchUrl(uri, mode: (Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault));
        }
      }
    }
  }

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
      contentTitle: Localization().getStringEx('panel.guide_list.label.campus_safety_resources.section', 'Safety Resources'),
      contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.campus_safety_resources.empty", "There are no active Campus Safety Resources."),
      favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusSafetyResourceContentType),
    )));
  }
}

class SafetySafeWalkRequestCard extends StatefulWidget {

  final Widget? headerWidget;
  final Color? backgroundColor;
  final Map<String, dynamic>? origin;
  final Map<String, dynamic>? destination;

  SafetySafeWalkRequestCard({super.key, this.headerWidget, this.backgroundColor, this.origin, this.destination});

  @override
  State<StatefulWidget> createState() => _SafetySafeWalkRequestCardState();
}

class _SafetySafeWalkRequestCardState extends State<SafetySafeWalkRequestCard> {
  static const String _safeWalkUserNameMacro = '{{safewalk_user_name}}';
  static const String _safeWalkOriginMacro = '{{safewalk_origin}}';
  static const String _safeWalkDestinationMacro = '{{safewalk_destination}}';

  dynamic _originLocation, _destinationLocation;
  bool _originProgress = false, _destinationProgress = false;

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
            Padding(padding: EdgeInsets.only(right: 8), child:
              _detailIconSpacer,
            ),
            Expanded(child:
              Center(child:
                RoundedButton(
                  label: Localization().getStringEx('widget.safewalks_request.start.title', 'Start with a Text'),
                  //textStyle: _sendEnabled ? Styles().textStyles.getTextStyle("widget.button.title.large.fat") : Styles().textStyles.getTextStyle("widget.button.disabled.title.large.fat"),
                  //borderColor: _sendEnabled ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  leftIcon: Styles().images.getImage('paper-plane'), //, color: _sendEnabled ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent),
                  leftIconPadding: EdgeInsets.only(left: 12, right: 8),
                  rightIconPadding: EdgeInsets.only(left: 16),
                  contentWeight: -1,
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
            style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
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
    ):
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
      ],)
    );

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: widget.backgroundColor ?? Styles().colors.background,
    border: Border.all(color: Styles().colors.mediumGray2, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(16))
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

  TextStyle? get _titleTextStyle => Styles().textStyles.getTextStyle('widget.title.medium.fat');
  TextStyle? get _dropDownItemTextStyle => Styles().textStyles.getTextStyle('widget.title.medium.semi_fat');

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
          ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.service_disabled.title', 'Location Services not enabled.'));
        }
        else if (status == LocationServicesStatus.permissionDenied) {
          ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.service_denied.title', 'Location Services access denied.'));
        }
        else {
          ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.service_not_available.title', 'Location Services not available.'));
        }
      }
    }

  }

  Future<dynamic> _provideMapLocation(dynamic location, { void Function(bool)? updateProgress }) async =>
    Navigator.push<Explore>(context, CupertinoPageRoute(builder: (context) => ExploreMapSelectLocationPanel(
      mapType: ExploreMapType.Buildings,
      /*selectedExplore: _locationExplore(location),*/
    )));

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

  void _onTapSend() {
    Analytics().logSelect(target: 'Start with a Text');
    if (_originLocation == null) {
      ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.missing.origin.title', 'Please select your current location.'));
    }
    else if (_destinationLocation == null) {
      ExploreMessagePopup.show(context, Localization().getStringEx('widget.safewalks_request.message.missing.destination.title', 'Please select your destination.'));
    }
    else  {
      String message = Localization().getStringEx('panel.safewalks_request.message.text', 'Hi, my name is $_safeWalkUserNameMacro and I\'d like to request a SafeWalk.\n\nMy Current Location:\n$_safeWalkOriginMacro\n\nMy Destination:\n$_safeWalkDestinationMacro')
        .replaceAll(_safeWalkUserNameMacro, Auth2().account?.authType?.uiucUser?.firstName ?? Auth2().profile?.firstName ?? Localization().getStringEx('widget.safewalks_request.unknown.user.text', 'Anonymous User'))
        .replaceAll(_safeWalkOriginMacro, _locationLongDescription(_originLocation) ?? Localization().getStringEx('widget.safewalks_request.unknown.location.text', 'Unknwon'))
        .replaceAll(_safeWalkDestinationMacro, _locationLongDescription(_destinationLocation) ?? Localization().getStringEx('widget.safewalks_request.unknown.location.text', 'Unknwon'));
      String url = "sms:${Config().safeWalkTextNumber}?body=" + Uri.encodeComponent(message);
      Uri? uri = Uri.tryParse(url);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }
}

String? _safeWalkLocationTypeToDisplayString(_SafeWalkLocationType? locationType) {
  switch (locationType) {
    case _SafeWalkLocationType.current: return Localization().getStringEx('widget.safewalks_request.location.current.title', 'Use My Location');
    case _SafeWalkLocationType.map: return Localization().getStringEx('widget.safewalks_request.location.map.title', 'Search Maps');
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

  // ignore: unused_element
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
