import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Config.dart';
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

class DisplayFloorPlanPanel extends StatefulWidget {
  final Building? building;
  const DisplayFloorPlanPanel({super.key, this.building});

  @override
  State<DisplayFloorPlanPanel> createState() => _DisplayFloorPlanPanelState();
}

class _DisplayFloorPlanPanelState extends State<DisplayFloorPlanPanel> {
  late final WebViewController _controller;
  String _htmlWithFloorPlan = '';
  String _urlBase = '${Config().gatewayUrl}/wayfinding/floorplan?';
  String _currentFloorCode = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();

    // Initialize only if building is provided
    if (widget.building != null) {
      List<String>? floors = widget.building?.floors;
      if (floors != null && floors.isNotEmpty) {
        _currentFloorCode = floors.first; // Set to the first floor code
        loadFloorPlan(_currentFloorCode);
      }
    }
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
    String url = '${_urlBase}bldgid=${widget.building?.number}&floor=$floorCode';
    String floorPlanSvg = await fetchFloorPlanData(url);
    if (!mounted) return; // Ensure widget is still mounted
    setState(() {
      if (floorPlanSvg == 'Empty SVG data') {
        _htmlWithFloorPlan = '<html lang=""><body>No floor plan available</body></html>';
      } else {
        _htmlWithFloorPlan = '$kExamplePage$floorPlanSvg</body></html>';
      }
      _controller.loadHtmlString(_htmlWithFloorPlan);
    });
  }


  void changeActiveFloor(String? floorCode) {
    if (floorCode != null) {
      loadFloorPlan(floorCode);
      setState(() {
        _currentFloorCode = floorCode;
      });
    }
  }

  void viewNextFloor(int direction) {
    List<String>? floors = widget.building?.floors;
    if (floors != null && floors.isNotEmpty) {
      int currentIndex = floors.indexOf(_currentFloorCode);
      int newIndex = (currentIndex + direction).clamp(0, floors.length - 1);

      if (newIndex != currentIndex) {
        changeActiveFloor(floors[newIndex]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: ' ${widget.building?.name ?? ''}'),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          buildFooter(),
        ],
      ),
    );
  }

  Widget buildFooter() {
    List<String>? floors = widget.building?.floors;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Semantics(
        child: Container(
          color: Styles().colors.textColorPrimary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () => viewNextFloor(-1),
                  child: floors != null
                      ? Styles().images.getImage('chevron-left-bold') ?? Container()
                      : Container(
                    foregroundDecoration: BoxDecoration(
                      color: Styles().colors.mediumGray,
                      backgroundBlendMode: BlendMode.saturation,
                    ),
                    child: Styles().images.getImage('chevron-left-bold') ?? Container(),
                  ),
                ),
              ),
              Flexible(child: FractionallySizedBox(widthFactor: 0.5)),
              if (floors != null)
                Semantics(
                  container: true,
                  button: true,
                  child: buildAccountDropDown(
                    '${Localization().getStringEx('panel.display_floor_plan_panel.footer.menu_item', 'Floor')} $_currentFloorCode',
                  ),
                ),
              Flexible(child: FractionallySizedBox(widthFactor: 0.5)),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () => viewNextFloor(1),
                  child: floors != null
                      ? Styles().images.getImage('chevron-right-bold') ?? Container()
                      : Container(
                    foregroundDecoration: BoxDecoration(
                      color: Styles().colors.mediumGray,
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
    List<String>? floors = widget.building?.floors;
    return floors?.map((floorLetters) {
      return DropdownMenuItem<String>(
        value: floorLetters,
        child: Semantics(
          label:
          '${Localization().getStringEx('panel.display_floor_plan_panel.footer.menu_item', 'Floor')} $floorLetters',
          hint:
          '${Localization().getStringEx('panel.display_floor_plan_panel.footer.hint', 'Double tap to select floor')}',
          button: false,
          excludeSemantics: true,
          child: Center(
            child: Text(
              '${Localization().getStringEx('panel.display_floor_plan_panel.footer.menu_item', 'Floor')} $floorLetters',
              style:
              Styles().textStyles.getTextStyle("widget.button.title.medium"),
            ),
          ),
        ),
      );
    }).toList() ??
        [];
  }

  Widget buildAccountDropDown(String currentFloor) {
    return Semantics(
      label: currentFloor,
      hint:
      '${Localization().getStringEx('panel.display_floor_plan_panel.footer.hint', 'Double tap to select floor')}',
      button: true,
      container: true,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          icon: Padding(
            padding: EdgeInsets.only(left: 4),
            child:
            Styles().images.getImage('chevron-down', excludeFromSemantics: true),
          ),
          isExpanded: false,
          style:
          Styles().textStyles.getTextStyle('widget.title.regular.fat'),
          hint: Text(
            currentFloor,
            style:
            Styles().textStyles.getTextStyle('widget.title.regular.fat'),
          ),
          dropdownColor:
          Styles().colors.white, // Dropdown menu background
          items: buildDropDownItems(),
          onChanged: changeActiveFloor,
        ),
      ),
    );
  }
}

