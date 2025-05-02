import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/localization.dart';

import '../../model/StudentCourse.dart';

class DisplayFloorPlanPanel extends StatefulWidget {
  final Building? building;
  final String? startingFloor;
  const DisplayFloorPlanPanel({super.key, this.building, this.startingFloor = null});

  @override
  State<DisplayFloorPlanPanel> createState() => _DisplayFloorPlanPanelState();
}

class _DisplayFloorPlanPanelState extends State<DisplayFloorPlanPanel> {
  late final WebViewController _controller;
  String _htmlWithFloorPlan = '';
  String _currentFloorCode = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();

    // Initialize only if building is provided
    if (widget.building != null) {
      List<String>? floors = widget.building?.floors;
      if (floors != null && floors.isNotEmpty) {
        _currentFloorCode = (widget.startingFloor != null) ? widget.startingFloor! : floors.first; // Set to the first floor code
        loadFloorPlan(_currentFloorCode);
      }
      else {
        _htmlWithFloorPlan = '${Localization().getStringEx('panel.display_floor_plan_panel.html_svg_header', 'Floor Plan')} ${Localization().getStringEx('panel.display_floor_plan_panel.html_error', 'No Floor Plan')} ${Localization().getStringEx('panel.display_floor_plan_panel.html_svg_footer', 'Floor Plan')}';
      }
    }
  }

  Future<void> loadFloorPlan(String floorCode) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic>? floorPlanData = await Gateway().fetchFloorPlanData(
      widget.building?.number ?? '',
      floorId: floorCode,
    );

    String? floorPlanSvg = floorPlanData?['svg'] ?? null;

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (floorPlanSvg == null) {
        _htmlWithFloorPlan = '${Localization().getStringEx('panel.display_floor_plan_panel.html_svg_header', 'Floor Plan')} ${Localization().getStringEx('panel.display_floor_plan_panel.html_error', 'No Floor Plan')} ${Localization().getStringEx('panel.display_floor_plan_panel.html_svg_footer', 'Floor Plan')}';
      } else {
        _htmlWithFloorPlan = '${Localization().getStringEx('panel.display_floor_plan_panel.html_svg_header', 'Floor Plan')} $floorPlanSvg ${Localization().getStringEx('panel.display_floor_plan_panel.html_svg_footer', 'Floor Plan')}';
      }
      _controller.loadHtmlString(_htmlWithFloorPlan);
    });
  }

  void changeActiveFloor(String? floorCode) {
    if (floorCode != null) {
      loadFloorPlan(floorCode);
      if (!mounted) return;
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
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
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
                  child: Padding(padding: EdgeInsets.only(bottom: 10), child: buildFloorDropDown(
                    '${Localization().getStringEx('panel.display_floor_plan_panel.footer.menu_item', 'Floor')} $_currentFloorCode',
                  )),
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

  Widget buildFloorDropDown(String currentFloor) {
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
            Styles().images.getImage('chevron-down-dark-blue', excludeFromSemantics: true),
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
          Styles().colors.surface, // Dropdown menu background
          items: buildDropDownItems(),
          onChanged: changeActiveFloor,
        ),
      ),
    );
  }
}
