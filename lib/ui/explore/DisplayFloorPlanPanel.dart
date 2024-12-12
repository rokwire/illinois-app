import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'dart:convert';

import '../../model/StudentCourse.dart';

String kExamplePage = '''
  <!DOCTYPE html>
  <html lang="en">
  <head>
  <title>Load file or HTML string example</title>
  </head>
  <body>
  ''';

class WebViewApp extends StatefulWidget {
  final Building? building;
  const WebViewApp({super.key, this.building});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  final Color bottom_nav_bg_color = Colors.white;
  final Color bottom_nav_text_color = Color(0xFF13294B);
  late final WebViewController controller;
  Building? _building;
  int floorIndex = 0;
  String htmlWithFloorPlan = '';
  String urlBase = 'https://api-dev.rokwire.illinois.edu/gateway/api/wayfinding/floorplan?';
  String currentFloorCode = '';

  List<String>? buildingFloorList = [];

  @override
  void initState() {
    super.initState();
    controller = WebViewController();
    _building = widget.building!;
    buildingFloorList = _building?.floors;
    currentFloorCode = buildingFloorList![0];
    loadFloorPlan(currentFloorCode);
  }

  Future<String> fetchFloorPlanData(String url) async {
    http.Response? response = await Network().get(url, auth: Auth2());
    if (response?.statusCode == 200) {
      try {
        var jsonResponseBody = jsonDecode(response!.body);
        if (jsonResponseBody['svg'] is String && jsonResponseBody['svg'].isEmpty) {
          return 'Empty SVG data';
        }
        return jsonResponseBody['svg'];
      } catch (_) {
        return '${response?.statusCode}';
      }
    } else {
      return '${response?.statusCode} error, could not get plan for this floor';
    }
  }

  Future<void> loadFloorPlan(String floorCode) async {
    String url = '${urlBase}bldgid=${_building?.number}&floor=$floorCode';
    String floorPlanSvg = await fetchFloorPlanData(url);
    setState(() {
      if (floorPlanSvg == 'Empty SVG data') {
        htmlWithFloorPlan = '<html><body>No floor plan available</body></html>';
      } else {
        htmlWithFloorPlan = '$kExamplePage$floorPlanSvg</body></html>';
      }
      controller.loadHtmlString(htmlWithFloorPlan);
    });
  }

  void changeActiveFloor(String? floorCode) {
    if (floorCode != null) {
      loadFloorPlan(floorCode);
      setState(() {
        currentFloorCode = floorCode;
      });
    }
  }

  void viewNextFloor(int direction) {
    int currentIndex = buildingFloorList!.indexOf(currentFloorCode);
    int newIndex = (currentIndex + direction).clamp(0, buildingFloorList!.length - 1);

    if (newIndex != currentIndex) {
      changeActiveFloor(buildingFloorList![newIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: ' ${_building?.name}'),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          buildHeader(),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Semantics(
        child: Container(
          color: bottom_nav_bg_color,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () => viewNextFloor(-1),
                  child: buildingFloorList != null
                      ? Styles().images.getImage('chevron-left-bold') ?? Container()
                      : Container(
                    foregroundDecoration: BoxDecoration(
                      color: Colors.grey,
                      backgroundBlendMode: BlendMode.saturation,
                    ),
                    child: Styles().images.getImage('chevron-left-bold') ?? Container(),
                  ),
                ),
              ),
              Flexible(
                child: FractionallySizedBox(
                  widthFactor: 0.5, // Adjust this factor to control the space
                ),
              ),
              if (buildingFloorList != null)
                Semantics(
                  container: true,
                  button: true,
                  child: buildAccountDropDown('Floor $currentFloorCode'),
                ),
              Flexible(
                child: FractionallySizedBox(
                  widthFactor: 0.5, // Use the same factor for symmetry
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () => viewNextFloor(1),
                  child: buildingFloorList != null
                      ? Styles().images.getImage('chevron-right-bold') ?? Container()
                      : Container(
                    foregroundDecoration: BoxDecoration(
                      color: Colors.grey,
                      backgroundBlendMode: BlendMode.saturation,
                    ),
                    child: Styles().images.getImage('chevron-right-bold') ?? Container(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> buildDropDownItems() {
    return buildingFloorList!.map((floorLetters) {
      return DropdownMenuItem<String>(
        value: floorLetters,
        child: Semantics(
          label: 'Floor $floorLetters',
          hint: "Double tap to select floor",
          button: false,
          excludeSemantics: true,
          child: Center( // Center the text
            child: Text(
              'Floor $floorLetters',
              style: Styles().textStyles.getTextStyle("widget.button.title.medium"),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget buildAccountDropDown(String currentFloor) {
    return Semantics(
      label: currentFloor,
      hint: "Double tap to select floor",
      button: true,
      container: true,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          icon: Padding(
            padding: EdgeInsets.only(left: 4),
            child: Styles().images.getImage('chevron-down', excludeFromSemantics: true),
          ),
          isExpanded: false,
          style: TextStyle(
            color: bottom_nav_text_color,
            fontWeight: FontWeight.bold,
          ),
          hint: Text(
            currentFloor,
            style: TextStyle(
              color: bottom_nav_text_color,
              fontWeight: FontWeight.bold,
            ),
          ),
          dropdownColor: Colors.white, // Set the dropdown menu's background color to white
          items: buildDropDownItems(),
          onChanged: changeActiveFloor,
        ),
      ),
    );
  }

}
