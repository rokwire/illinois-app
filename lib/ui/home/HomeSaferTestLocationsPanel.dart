
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as Core;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/utils/utils.dart';

/////////////////////////////////////////////
// HomeSaferTestLocationsPanel

class HomeSaferTestLocationsPanel extends StatefulWidget {
  _HomeSaferTestLocationsPanelState createState() => _HomeSaferTestLocationsPanelState();
}

/////////////////////////////////////////////
// _HomeSaferTestLocationsPanelState

class _HomeSaferTestLocationsPanelState extends State<HomeSaferTestLocationsPanel>{
  
  List<HealthServiceLocation>? _locations;
  Core.Position? _currentLocation;
  bool? _loadingLocations;
  String? _statusString;

  @override
  void initState() {
    _loadingLocations = true;
    _loadLocations().then((List<HealthServiceLocation>? locations) {
      if (mounted) {
        if (locations == null) {
          setState(() {
            _loadingLocations = false;
            _statusString = Localization().getStringEx("panel.home.safer.test_locations.error.locations.text", "Failed to load locations");
          });
        }
        else if (locations.isEmpty) {
          setState(() {
            _loadingLocations = false;
            _statusString = Localization().getStringEx("panel.home.safer.test_locations.no_locations.text", "No available locations");
          });
        }
        else {
          _sortLocations(locations).then((_) {
            if (mounted) {
              setState(() {
                _loadingLocations = false;
                _locations = locations;
              });
            }
          });
        }
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;
    
    if (_loadingLocations == true) {
      contentWidget = _buildLoading();
    }
    else if (_statusString != null) {
      contentWidget = _buildStatus(_statusString!);
    }
    else if (CollectionUtils.isEmpty(_locations)) {
      contentWidget = _buildStatus(Localization().getStringEx("panel.home.safer.test_locations.no_locations.text", "No Locations found for selected provider and county") );
    }
    else {
      contentWidget = ListView.builder(
        itemCount: _locations!.length,
        itemBuilder: (BuildContext context, int index) {
          return _TestLocation(testLocation: _locations![index], /*distance: distance,*/);
        },
      );
    }

    return Scaffold(
      backgroundColor: Styles().colors!.background,
      appBar: HeaderBar(title: Localization().getStringEx("panel.home.safer.test_locations.header.title", "Test Locations"),),
      body: SafeArea(child:
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
          Column(children: [
            Expanded(child: contentWidget),
          ],),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child:
      Column(children: [
        Expanded(flex: 1, child: Container()),
        Center(child: CircularProgressIndicator(),),
        Expanded(flex: 3, child: Container()),
      ],),);
  }

  Widget _buildStatus(String text) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child:
      Column(children: [
        Expanded(flex: 1, child: Container()),
        Text(text, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.large.thin")),
        Expanded(flex: 3, child: Container()),
      ],),);
  }

  Future<List<HealthServiceLocation>?> _loadLocations() async {
    String? contentUrl = Config().contentUrl;
    if ((contentUrl != null)) {
      String url = "$contentUrl/health_locations";
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? HealthServiceLocation.listFromJson(JsonUtils.decode(response!.body)) : null;
    }
    return null;
  }

  Future<void> _sortLocations(List<HealthServiceLocation>? locations) async {
    
    if ((locations != null) && (1 < locations.length)) {
      
      // Ensure current location, if available
      if (_currentLocation == null) {
        LocationServicesStatus? status = await LocationServices().status;
        if (status == LocationServicesStatus.permissionNotDetermined) {
          status = await LocationServices().requestPermission();
        }
        if (status == LocationServicesStatus.permissionAllowed) {
          _currentLocation = await LocationServices().location;
        }
      }

      // Sort by current location, if available
      if (_currentLocation != null) {
        locations.sort((fistLocation, secondLocation) {
          if ((fistLocation.latitude != null) && (fistLocation.longitude != null)) {
            if ((secondLocation.latitude != null) && (secondLocation.longitude != null)) {
              double firstDistance = Geolocator.distanceBetween(fistLocation.latitude!, fistLocation.longitude!, _currentLocation!.latitude, _currentLocation!.longitude);
              double secondDistance = Geolocator.distanceBetween(secondLocation.latitude!, secondLocation.longitude!, _currentLocation!.latitude, _currentLocation!.longitude);
              return firstDistance.compareTo(secondDistance);
            }
            else {
              return 1; // (fistLocation > secondLocation)
            }
          }
          else {
            if ((secondLocation.latitude != null) && (secondLocation.longitude != null)) {
              return -1; // (fistLocation < secondLocation)
            }
            else {
              return 0; // fistLocation == secondLocation == null
            }
          }
        });
      }
    }
  }
}

///////////////////////////////
// _TestLocation

class _TestLocation extends StatelessWidget {
  final HealthServiceLocation? testLocation;
  final double? distance;

  // ignore: unused_element
  _TestLocation({this.testLocation, this.distance});

  @override
  Widget build(BuildContext context) {
    
    bool canLocation = (testLocation?.latitude != null) && (testLocation?.longitude != null);
    TextStyle? textStyle = Styles().textStyles?.getTextStyle("widget.info.regular.thin");
    TextStyle? linkStyle = Styles().textStyles?.getTextStyle("widget.home.link_button.regular.accent.underline");

    List<Widget> locationContent = <Widget>[
      Styles().images?.getImage('location', excludeFromSemantics: true) ?? Container(),
      Container(width: 8),
    ];

    if ((distance != null) && (distance! > 0)) {
      String distanceText = distance!.toStringAsFixed(2) + Localization().getStringEx("panel.home.safer.test_locations.distance.text", "mi away");
      locationContent.add(Text(distanceText, style: textStyle,));
      if (canLocation) {
        String directionsText = Localization().getStringEx("panel.home.safer.test_locations.distance.directions.text", "get directions");
        locationContent.addAll(<Widget>[
          Text(" (", style: textStyle,),
          Text(directionsText, style: linkStyle,),
          Text(")", style: textStyle,),
        ]);
      }
    }
    else if (testLocation?.fullAddress != null) {
      locationContent.add(
        Text(testLocation!.fullAddress, style: canLocation ? linkStyle : textStyle,
      ));
    }
    else {
      String unknownLocationText = Localization().getStringEx("panel.home.safer.test_locations.location.unknown", "unknown location");
      locationContent.add(
        Text(unknownLocationText, style: canLocation ? linkStyle : textStyle,
      ));
    }

    return
      Semantics(button: false, container: true, child:
        Container(
        margin: EdgeInsets.only(top: 8, bottom: 8),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
            color: Styles().colors!.surface,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(testLocation?.name ?? "", style: Styles().textStyles?.getTextStyle("widget.detail.large.extra_fat")),
            Semantics(button: true,
            child: GestureDetector(
              onTap: _onTapAddress,
              child: Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                    children: locationContent,
                  )
                ),
            )),
            /*Semantics(label: Localization().getStringEx("panel.home.safer.test_locations.call.hint","Call"), button: true, child:
            GestureDetector(
              onTap: _onTapContact,
              child:
              Container(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                children: <Widget>[
                  Image.asset('images/icon-phone.png', excludeFromSemantics: true,),
                  Container(width: 8,),
                  Text(
                    testLocation?.contact ??Localization().getStringEx("panel.home.safer.test_locations.label.contact.title", "Contact"),
                    style: TextStyle(
                      fontFamily: Styles().fontFamilies.regular,
                      fontSize: 16,
                      color: Styles().colors.textSurface,
                    ),
                  )
                ],
              ))
            )),*/
              // Hide wait times #1099
              //_buildWaitTime(),
              Semantics(explicitChildNodes:true,button: false, child:
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Styles().images?.getImage('time', excludeFromSemantics: true) ?? Container(),
                  Container(width: 8,),
                  Expanded(child:
                    _buildWorkTime(),
                  )
                ],
              )
            )
          ],
          ),
        )
      );
  }

  /* Hide wait times
  Widget _buildWaitTime(){
    if(!_isLocationOpen){
      return Container();
    }

    HealthLocationWaitTimeColor? waitTimeColor = testLocation!.waitTimeColor;
    bool isWaitTimeAvailable = (waitTimeColor == HealthLocationWaitTimeColor.red) ||
        (waitTimeColor == HealthLocationWaitTimeColor.yellow) ||
        (waitTimeColor == HealthLocationWaitTimeColor.green);
    String? waitTimeText = "";
    if(isWaitTimeAvailable)  {
      if(waitTimeColor == HealthLocationWaitTimeColor.red){
        waitTimeText = Localization().getStringEx('panel.home.safer.test_locations.wait_time.status.label.red', 'Long wait time');
      } else if(waitTimeColor == HealthLocationWaitTimeColor.yellow){
        waitTimeText = Localization().getStringEx('panel.home.safer.test_locations.wait_time.status.label.yellow', 'Medium wait time');
      } else if(waitTimeColor == HealthLocationWaitTimeColor.green){
        waitTimeText = Localization().getStringEx('panel.home.safer.test_locations.wait_time.status.label.green', 'Short wait time');
      }
    } else {
      {
        waitTimeText = Localization().getStringEx(
            'panel.home.safer.test_locations.wait_time.unavailable',
            'Unknown wait time');
      }
    }
    return Container(
        padding: EdgeInsets.only(top: 4),
        child: Row(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(color: HealthServiceLocation.waitTimeColorHex(waitTimeColor), shape: BoxShape.circle),
                  ),
                ),
                Text(
                  waitTimeText!,
                  style: TextStyle(
                    fontFamily: Styles().fontFamilies!.regular,
                    fontSize: 16,
                    color: Styles().colors!.textSurface,
                  ),
                )
              ],
            )
          ],
        ));
  }*/

  Widget _buildWorkTime(){
    List<HealthLocationDayOfOperation> items = [];
    HealthLocationDayOfOperation? period;
    LinkedHashMap<int,HealthLocationDayOfOperation> workingPeriods;
    List<HealthLocationDayOfOperation>? workTimes = testLocation?.daysOfOperation;
    if(workTimes?.isNotEmpty ?? false){
      workingPeriods = LinkedHashMap<int,HealthLocationDayOfOperation>.fromIterable(workTimes!, key: (period) => period.weekDay ?? 0);
      items = workingPeriods.values.toList();
      period = _determineTodayPeriod(workingPeriods);
      if ((period == null) || !period.isOpen) {
        period = _findNextPeriod(workingPeriods);  
      }
    } else {
      return Container(
        child: Text(Localization().getStringEx("panel.home.safer.test_locations.work_time.unknown","Unknown working time"))
      );
    }

    return DropdownButton<HealthLocationDayOfOperation>(
      isExpanded: true,
      isDense: false,
      underline: Container(),
      value: period,
      onChanged: (value){},
      icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
      selectedItemBuilder:(context){
        return items.map<Widget>((entry){
          return Row(
            children: <Widget>[
              Expanded(child:
              Text(
                _getPeriodText(entry, workingPeriods),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat")
              ),)
            ],
          );
        }).toList();
      },
      items: items.map((entry){
        return DropdownMenuItem<HealthLocationDayOfOperation>(
          value: entry,
          child: Text(
//            _getPeriodText(entry, activePeriod),
            entry.displayString,
            style: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat")
          ),
        );
      }).toList(),
    );
  }

  String _getPeriodText(HealthLocationDayOfOperation? period, LinkedHashMap<int,HealthLocationDayOfOperation> workingPeriods){
    String? openText = Localization().getStringEx("panel.home.safer.test_locations.work_time.open_until","Open until");
    String? closedText = Localization().getStringEx("panel.home.safer.test_locations.work_time.closed_until","Closed until");
    if((period != null) && period.isOpen){ //This is the active Period
      String? end = period.closeTime;
      return "$openText $end";
    } else {
      //Closed until the next open period
      HealthLocationDayOfOperation? nextPeriod = _findNextPeriod(workingPeriods);
      String nextOpenTime = nextPeriod!=null? nextPeriod.name! +" "+nextPeriod.openTime! : " ";
      return "$closedText $nextOpenTime";
    }
  }

  HealthLocationDayOfOperation? _determineTodayPeriod(LinkedHashMap<int,HealthLocationDayOfOperation>? workingPeriods){
    int currentWeekDay = DateTime.now().weekday;
    return workingPeriods!=null? workingPeriods[currentWeekDay] : null;
  }

  HealthLocationDayOfOperation? _findNextPeriod(
      LinkedHashMap<int, HealthLocationDayOfOperation>? workingPeriods) {
    if (workingPeriods != null && workingPeriods.isNotEmpty) {
      // First, check if the current day period will open today
      int currentWeekDay = DateTime.now().weekday;
      HealthLocationDayOfOperation? period = workingPeriods[currentWeekDay];
      if ((period != null) && period.willOpen) return period;

      // Modulus math works better with 0 based indexes, and flutter uses 1 based
      // weekdays
      int currentWeekDay0 = currentWeekDay - 1;
      for (int offset = 1; offset < 7; offset++) {
        // Take the current day (0 based), add the offset we want to check,
        // modulus 7 to wrap it around in the array, and add 1 to get the flutter
        // weekday index.
        int offsetDay = ((currentWeekDay0 + offset) % 7) + 1;

        period = workingPeriods[offsetDay];
        if (period != null) return period;
      }

      //If there is no nex period - return the fist element
      return workingPeriods.values.toList()[0];
    }
    return null;
  }

  /*void _onTapContact() async{
    await url_launcher.launch("tel:"+testLocation?.contact ?? "");
  }*/

  void _onTapAddress(){
    Analytics().logSelect(target: "COVID-19 Test Location");
    double? lat = testLocation?.latitude;
    double? lng = testLocation?.longitude;
    if ((lat != null) && (lng != null)) {
      NativeCommunicator().launchMap(
          target: {
            'latitude': testLocation?.latitude,
            'longitude': testLocation?.longitude,
            'zoom': 17,
          },
          markers: [{
            'name': testLocation?.name,
            'description': testLocation?.fullAddress,
            'latitude': testLocation?.latitude,
            'longitude': testLocation?.longitude,
          }]);
    }
  }


  /* Hide wait times
  bool get _isLocationOpen{
    HealthLocationDayOfOperation? todayPeriod;
    if(CollectionUtils.isNotEmpty(testLocation?.daysOfOperation)) {
      todayPeriod = _determineTodayPeriod(
          LinkedHashMap<int, HealthLocationDayOfOperation>.fromIterable(
              testLocation!.daysOfOperation!, key: (period) => period.weekDay ?? 0));
    }

    return todayPeriod?.isOpen ?? false;
  }
  */
}

///////////////////////////////
// HealthServiceLocation

class HealthServiceLocation {
  final String? id;
  final String? name;
  final String? contact;
  final String? city;
  final String? address1;
  final String? address2;
  final String? state;
  final String? country;
  final String? zip;
  final String? url;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final HealthLocationWaitTimeColor? waitTimeColor;
  final List<HealthLocationDayOfOperation>? daysOfOperation;
  
  HealthServiceLocation({this.id, this.name, this.contact, this.city, this.address1, this.address2, this.state, this.country, this.zip, this.url, this.notes, this.latitude, this.longitude, this.waitTimeColor, this.daysOfOperation});

  static HealthServiceLocation? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? HealthServiceLocation(
      id: json['_id'],
      name: json['name'],
      contact: json["contact"],
      city: json["city"],
      state: json["state"],
      country: json["country"],
      address1: json["address_1"],
      address2: json["address_2"],
      zip: json["zip"],
      url: json["url"],
      notes: json["notes"],
      latitude: JsonUtils.doubleValue(json["latitude"]),
      longitude: JsonUtils.doubleValue(json["longitude"]),
      waitTimeColor: HealthServiceLocation.waitTimeColorFromString(json['wait_time_color']),
      daysOfOperation: HealthLocationDayOfOperation.listFromJson(json['days_of_operation']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'contact': contact,
      'city': city,
      'state': state,
      'country': country,
      'address_1': address1,
      'address_2': address2,
      'zip': zip,
      'url': url,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'wait_time_color': HealthServiceLocation.waitTimeColorToKeyString(waitTimeColor),
    };
  }

  String get fullAddress{
    String address = "";
    address = address1?? "";
    if(address2?.isNotEmpty?? false) {
      address += address.isNotEmpty ? ", " : "";
      address += address2!;
    }
    if(city?.isNotEmpty?? false) {
      address += address.isNotEmpty ? ", " : "";
      address += city!;
    }
    if(state?.isNotEmpty?? false) {
      address += address.isNotEmpty ? ", " : "";
      address += state!;
    }
    return address;
  }

  static List<HealthServiceLocation>? listFromJson(List<dynamic>? json) {
    List<HealthServiceLocation>? values;
    if (json != null) {
      values = <HealthServiceLocation>[];
      for (dynamic entry in json) {
        ListUtils.add(values, HealthServiceLocation.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<HealthServiceLocation>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (HealthServiceLocation value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }

  static HealthLocationWaitTimeColor? waitTimeColorFromString(String? colorString) {
    if (colorString == 'red') {
      return HealthLocationWaitTimeColor.red;
    } else if (colorString == 'yellow') {
      return HealthLocationWaitTimeColor.yellow;
    } else if (colorString == 'green') {
      return HealthLocationWaitTimeColor.green;
    } else if (colorString == 'grey') {
      return HealthLocationWaitTimeColor.grey;
    } else {
      return null;
    }
  }

  static String? waitTimeColorToKeyString(HealthLocationWaitTimeColor? color) {
    switch (color) {
      case HealthLocationWaitTimeColor.red:
        return 'red';
      case HealthLocationWaitTimeColor.yellow:
        return 'yellow';
      case HealthLocationWaitTimeColor.green:
        return 'green';
      case HealthLocationWaitTimeColor.grey:
        return 'grey';
      default:
        return null;
    }
  }

  static Color? waitTimeColorHex(HealthLocationWaitTimeColor? color) {
    switch (color) {
      case HealthLocationWaitTimeColor.red:
        return Styles().colors!.saferLocationWaitTimeColorRed;
      case HealthLocationWaitTimeColor.yellow:
        return Styles().colors!.saferLocationWaitTimeColorYellow;
      case HealthLocationWaitTimeColor.green:
        return Styles().colors!.saferLocationWaitTimeColorGreen;
      default:
        return Styles().colors!.saferLocationWaitTimeColorGrey;
    }
  }
}

///////////////////////////////
// HealthLocationDayOfOperation

class HealthLocationDayOfOperation {
  final String? name;
  final String? openTime;
  final String? closeTime;

  final int? weekDay;
  final int? openMinutes;
  final int? closeMinutes;

  HealthLocationDayOfOperation({this.name, this.openTime, this.closeTime}) :
    weekDay = (name != null) ? DateTimeUtils.getWeekDayFromString(name.toLowerCase()) : null,
    openMinutes = _timeMinutes(openTime),
    closeMinutes = _timeMinutes(closeTime);

  static HealthLocationDayOfOperation? fromJson(Map<String,dynamic>? json){
    return (json != null) ? HealthLocationDayOfOperation(
      name: json["name"],
      openTime: json["open_time"],
      closeTime: json["close_time"],
    ) : null;
  }

  String get displayString{
    return "$name $openTime to $closeTime";
  }

  bool get isOpen {
    if ((openMinutes != null) && (closeMinutes != null)) {
      int nowWeekDay = DateTime.now().weekday;
      int? nowMinutes = _timeOfDayMinutes(TimeOfDay.now());
      return nowWeekDay == weekDay && openMinutes! < nowMinutes! && nowMinutes < closeMinutes!;
    }
    return false;
  }

  bool get willOpen {
    if (openMinutes != null) {
      int nowWeekDay = DateTime.now().weekday;
      int? nowMinutes = _timeOfDayMinutes(TimeOfDay.now());
      return nowWeekDay == weekDay && nowMinutes! < openMinutes!;
    }

    return false;
  }

  static List<HealthLocationDayOfOperation>? listFromJson(List<dynamic>? json) {
    List<HealthLocationDayOfOperation>? values;
    if (json != null) {
      values = <HealthLocationDayOfOperation>[];
      for (dynamic entry in json) {
        ListUtils.add(values, HealthLocationDayOfOperation.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  // Helper function for conversion work time string to number of minutes

  static int? _timeMinutes(String? time, {String format = 'hh:mma'}) {
    DateTime? dateTime = (time != null) ? DateTimeUtils.parseDateTime(time.toUpperCase(), format: format) : null;
    TimeOfDay? timeOfDay = (dateTime != null) ? TimeOfDay.fromDateTime(dateTime) : null;
    return _timeOfDayMinutes(timeOfDay);
  }

  static int? _timeOfDayMinutes(TimeOfDay? timeOfDay) {
    return (timeOfDay != null) ? (timeOfDay.hour * 60 + timeOfDay.minute) : null;
  }
}

///////////////////////////////
// HealthLocationWaitTimeColor

enum HealthLocationWaitTimeColor { red, yellow, green, grey }
