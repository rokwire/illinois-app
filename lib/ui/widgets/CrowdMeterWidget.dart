/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:illinois/model/CrowdMeter.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

Map<int, WeekDay> intToWeekDay = {
  1: WeekDay.monday,
  2: WeekDay.tuesday,
  3: WeekDay.wednesday,
  4: WeekDay.thursday,
  5: WeekDay.friday,
  6: WeekDay.saturday,
  7: WeekDay.sunday
};

List<String> busyStrings = [
  "Usually not busy at all",
  "Usually not too busy",
  "Usually a little busy",
  "Usually busy",
  "Usually as busy as it gets",
];

class CrowdMeterWidget extends StatefulWidget {
  final String locationId;
  final String locationType;

  const CrowdMeterWidget({
    Key? key,
    required this.locationId,
    required this.locationType,
  }) : super(key: key);

  @override
  State<CrowdMeterWidget> createState() => _CrowdMeterWidgetState();
}

class _CrowdMeterWidgetState extends State<CrowdMeterWidget> with TickerProviderStateMixin {
  bool _isCrowdMeterLoading = true;
  CrowdMeterWeek? _crowdMeterWeek;
  String? _busyString;
  final _accessTime = DateTime.now();
  late WeekDay _selectedDay = intToWeekDay[_accessTime.weekday] ?? WeekDay.monday;
  late AnimationController _barHeightAnimationController;

  @override
  void initState() {
    super.initState();
    _barHeightAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _loadCrowdMeter().then((CrowdMeterWeek? crowdMeterWeek) {
      if (mounted) {
        // Move midnight value to end of list to display in correct order (6am-12am)
        if (crowdMeterWeek != null) {
          for (CrowdMeterDay day in crowdMeterWeek.days ?? []) {
            if (day.busyLevels != null && day.busyLevels!.length == 24) {
              int midnightValue = day.busyLevels!.removeAt(0);
              day.busyLevels!.add(midnightValue);
            }
          }
        }
        setState(() {
          _crowdMeterWeek = crowdMeterWeek;
          if (crowdMeterWeek != null) {
            CrowdMeterDay? selectedDayData = crowdMeterWeek.days?.firstWhere((day) => day.day == _selectedDay);
            List<int>? dayBusyLevels = selectedDayData?.busyLevels;
            int busyLevelIndex = (_accessTime.hour - 1 + 24) % 24;
            int busyLevel = (dayBusyLevels != null && busyLevelIndex < dayBusyLevels.length)
                ? dayBusyLevels[busyLevelIndex] 
                : 0;
            _busyString = busyStrings[busyLevel];
          } else {
            _busyString = null;
          }
          _isCrowdMeterLoading = false;
        });
        _barHeightAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _barHeightAnimationController.dispose();
    super.dispose();
  }

  Future<CrowdMeterWeek?> _loadCrowdMeter() async {
    String? url = "${Config().gatewayUrl}/crowdmeter/location?lid=${widget.locationId}&type=${widget.locationType}";
    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      debugPrint(responseString);
      return CrowdMeterWeek.fromJson(JsonUtils.decode(responseString));
    } else {
      debugPrint('Failed to load crowd meter data, response code: $responseCode, response: $responseString');
      return null;
    }
  }

  void _onTapDay(WeekDay day) {
    setState(() {
      _selectedDay = day;
    });
    _barHeightAnimationController.reset();
    _barHeightAnimationController.forward();
  }

  Widget _buildLoadingContent() {
    return Column(children: <Widget>[
      Center(child:
        CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary)
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return (_isCrowdMeterLoading)
      ? _buildLoadingContent()
      : _buildCrowdMeterContent();
  }

  Widget _buildCrowdMeterContent() {
    double unitHeight = 25.0;
    int hoursDisplayed = 19;
    List<String> hourLabels = ["6a", "9a", "12p", "3p", "6p", "9p", "12a"];
    CrowdMeterDay? crowdMeterDay = _crowdMeterWeek?.days?.firstWhere((day) => day.day == _selectedDay);
    List<int> busyLevels = crowdMeterDay?.busyLevels ?? [];

    Map<WeekDay, String> dayLabels = {
      WeekDay.monday: "MON",
      WeekDay.tuesday: "TUE",
      WeekDay.wednesday: "WED",
      WeekDay.thursday: "THU",
      WeekDay.friday: "FRI",
      WeekDay.saturday: "SAT",
      WeekDay.sunday: "SUN"
    };
    return Container(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ...WeekDay.values.map((day) =>
                  GestureDetector(
                      onTap: () => _onTapDay(day),
                      child: Text(dayLabels[day] ?? '',
                          style: (day == _selectedDay)
                              ? Styles().textStyles.getTextStyle('widget.button.light.title.medium.underline')
                              : Styles().textStyles.getTextStyle('widget.button.light.title.medium'))))
            ],
          ),
          Container(height: 8),
          Stack(children: [
            Column(children: [
              Padding(padding: EdgeInsets.only(bottom: unitHeight - 1), child:
              Container(height: 1, color: Styles().colors.surfaceAccent),
              ),
              Padding(padding: EdgeInsets.only(bottom: unitHeight - 1), child:
              Container(height: 1, color: Styles().colors.surfaceAccent),
              ),
              Padding(padding: EdgeInsets.only(bottom: unitHeight - 1), child:
              Container(height: 1, color: Styles().colors.surfaceAccent),
              ),
              Padding(padding: EdgeInsets.only(bottom: unitHeight - 1), child:
              Container(height: 1, color: Styles().colors.surfaceAccent),
              ),
            ]),
            (_crowdMeterWeek != null && busyLevels.length == 24)
                ? Positioned.fill(child:
            AnimatedBuilder(
              animation: _barHeightAnimationController,
              builder: (context, child) {
                return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [...List.generate(hoursDisplayed, (index) => index).map((x) =>
                        Container(
                          decoration: BoxDecoration(
                              color: (_selectedDay == intToWeekDay[_accessTime.weekday] && _accessTime.hour == x+6)
                              ? Styles().colors.fillColorSecondary
                              : Styles().colors.blueAccent,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(10))),
                          width: 10, height: unitHeight * ((busyLevels[(x+5)] as num?) ?? 0) * _barHeightAnimationController.value,
                        ))]
                );
              },
            )
            )
                : Positioned.fill(child: Text("No data to display.", textAlign: TextAlign.center)),
          ]),
          Padding(padding: EdgeInsets.only(top: 3), child:
          Container(height: 1, color: Styles().colors.black),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [...List.generate(hoursDisplayed, (index) => index).map((x) =>
              (x % 3 == 0)
                  ? Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 4.5), child:
                Container(
                    decoration: BoxDecoration(
                        color: Styles().colors.black),
                    width: 1, height: 5)
                ),
                Padding(padding: EdgeInsets.only(top: 2), child:
                Text(hourLabels[(x ~/ 3)], style: Styles().textStyles.getTextStyle("widget.item.tiny"))
                )
              ])
                  : Padding(padding: EdgeInsets.symmetric(horizontal: 5))
              )]
          ),
          Container(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("NOW:", style: Styles().textStyles.getTextStyle('widget.label.regular.fat')),
            Container(width: 4),
            Text(_busyString ?? 'Unknown', style: Styles().textStyles.getTextStyle("widget.description.regular"))
          ])

        ],
      ),
    );

  }
}
