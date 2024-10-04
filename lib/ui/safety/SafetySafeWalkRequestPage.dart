
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/explore/ExploreMapPanel.dart';
import 'package:illinois/ui/explore/ExploreMapSelectLocationPanel.dart';
import 'package:illinois/ui/safety/SafetyHomePanel.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
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

  @override
  Widget build(BuildContext context) => Column(children: [
    _mainLayer,
    _detailsLayer(context),
  ],);

  @override
  Color get safetyPageBackgroundColor => Styles().colors.fillColorPrimaryVariant;
  
  Widget get _mainLayer => Container(color: safetyPageBackgroundColor, child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(left: 16, top: 32), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
              Text(Localization().getStringEx('panel.safewalks_request.header.title', 'SafeWalks'), style: _titleTextStyle,)
            ),
          ),
          InkWell(onTap: _onTapMore, child:
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
          SafetySafeWalkRequestCard(),
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
    Localization().getStringEx('panel.safewalks_request.info2.text', 'Please give at least 15 minutes\' notice.');

  String get _info3Text =>
    Localization().getStringEx('panel.safewalks_request.info3.text', 'Available $_safeWalkStartTimeMacro to $_safeWalkEndTimeMacro')
      .replaceAll(_safeWalkStartTimeMacro, Config().safeWalkStartTime ?? '')
      .replaceAll(_safeWalkEndTimeMacro, Config().safeWalkEndTime ?? '');

  String get _phoneDetailHtml =>
    Localization().getStringEx('panel.safewalks_request.detail.phone.html', 'You can also schedule a walk by calling <a href=\'tel:$_safeWalkPhoneNumberMacro\'>$_safeWalkPhoneNumberMacro</a>.')
      .replaceAll(_safeWalkPhoneNumberMacro, Config().safeWalkPhoneNumber ?? '');

  String get _safeRidesDetailHtml =>
    Localization().getStringEx('panel.safewalks_request.detail.saferides.html', 'Looking for a ride instead? The Champaign-Urbana Mass Transit District offers limited <a href=\'$_safeRidesUrlMacro\'>SafeRides</a>&nbsp;<img src=\'asset:$_externalLinkMacro\' alt=\'\'/> at night..')
      .replaceAll(_safeRidesUrlMacro, Guide().detailUrl(Config().safeRidesGuideId, analyticsFeature: AnalyticsFeature.Safety))
      .replaceAll(_externalLinkMacro, 'images/external-link.png');

  void _onTapMore() {

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
}

class SafetySafeWalkRequestCard extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SafetySafeWalkRequestCardState();
}

class _SafetySafeWalkRequestCardState extends State<SafetySafeWalkRequestCard> {
  dynamic _originLocation, _destinationLocation;
  bool _originProgress = false, _destinationProgress = false;

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _cardDecoration, padding: EdgeInsets.all(16), child:
      Column(children: [
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
              text: _locationDescription(_originLocation),
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
              text: _locationDescription(_destinationLocation),
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
                  padding: EdgeInsets.symmetric(vertical: 8),
                  leftIcon: Styles().images.getImage('paper-plane'),
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
    color: Styles().colors.background,
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

  String? _locationDescription(dynamic location) {
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

  /*Explore? _locationExplore(dynamic location) {
    if (location is Explore) {
      return location;
    }
    else if (location is Position) {
      return ExplorePOI(location: ExploreLocation(
        name: Localization().getStringEx('panel.explore.item.location.name', 'Location'),
        latitude: location.latitude,
        longitude: location.longitude,
      ));
    }
    else {
      return null;
    }
  }*/

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

  void _onTapSend() {
    Analytics().logSelect(target: 'Start with a Text');
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
