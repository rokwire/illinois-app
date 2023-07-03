
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Event2SetupAttendancePanel extends StatefulWidget {
  final AttendanceDetails? attendanceDetails;
  
  Event2SetupAttendancePanel({Key? key, this.attendanceDetails}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() => _Event2SetupAttendancePanelState();
}

class _Event2SetupAttendancePanelState extends State<Event2SetupAttendancePanel>  {

  late bool _takeAttendanceViaAppEnabled;
  late bool _scanningEnabled;
  late bool _manualCheckEnabled;

  @override
  void initState() {
    _takeAttendanceViaAppEnabled = widget.attendanceDetails?.takeAttendanceViaAppEnabled ?? false;
    _scanningEnabled = widget.attendanceDetails?.scanningEnabled ?? false;
    _manualCheckEnabled = widget.attendanceDetails?.manualCheckEnabled ?? false;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx("panel.event2.setup.attendance.header.title", "Event Attendance"), onLeading: _onHeaderBack,),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.white,
    );
  }

  Widget _buildPanelContent() {
    return SingleChildScrollView(child:
      Column(children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildTakeViaAppSection(),
            _buildScanSection(),
            _buildManualSection(),
          ]),
        )

      ],)

    );
  }

  //EdgeInsetsGeometry get _togglePadding => const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  //EdgeInsetsGeometry get _toggleDescriptionPadding => const EdgeInsets.symmetric(horizontal: 12, vertical: 5);
  //BoxBorder get _toggleBorder => Border.all(color: Styles().colors!.surfaceAccent!, width: 1);
  //BorderRadius get _toggleBorderRadius => BorderRadius.all(Radius.circular(4));

  // Take Via App

  Widget _buildTakeViaAppSection() =>
    Padding(padding: Event2CreatePanel.sectionPadding, child:
      _buildTakeViaAppToggle(),
    );

  Widget _buildTakeViaAppToggle() => Semantics(toggled: _takeAttendanceViaAppEnabled, excludeSemantics: true, 
    label: Localization().getStringEx("panel.event2.setup.attendance.take_via_app.toggle.title", "TAKE ATTENDANCE VIA THE APP"),
    hint: Localization().getStringEx("panel.event2.setup.attendance.take_via_app.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.setup.attendance.take_via_app.toggle.title", "TAKE ATTENDANCE VIA THE APP"),
      toggled: _takeAttendanceViaAppEnabled,
      onTap: _onTapTakeViaApp,
      //padding: _togglePadding,
      //border: _toggleBorder,
      //borderRadius: _toggleBorderRadius,
    ));

  void _onTapTakeViaApp() {
    Analytics().logSelect(target: "Toggle Take Attendance Via The App");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _takeAttendanceViaAppEnabled = !_takeAttendanceViaAppEnabled;
    });
  }

  // Scan

  Widget _buildScanSection() =>
    Padding(padding: Event2CreatePanel.sectionPadding, child:
      _buildScanToggle(),
    );

  Widget _buildScanToggle() => Semantics(toggled: _scanningEnabled, excludeSemantics: true, 
    label: Localization().getStringEx("panel.event2.setup.attendance.scan.toggle.title", "Scan Illini ID"),
    hint: Localization().getStringEx("panel.event2.setup.attendance.scan.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.setup.attendance.scan.toggle.title", "Scan Illini ID"),
      description: Localization().getStringEx("panel.event2.setup.attendance.scan.toggle.description", "Does not require advance registration."),
      toggled: _scanningEnabled,
      onTap: _onTapScan,
      //padding: _toggleDescriptionPadding,
      //border: _toggleBorder,
      //borderRadius: _toggleBorderRadius,
    ));

  void _onTapScan() {
    Analytics().logSelect(target: "Toggle Scan Illini ID");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _scanningEnabled = !_scanningEnabled;
    });
  }

  // Manual

  Widget _buildManualSection() =>
    Padding(padding: Event2CreatePanel.sectionPadding, child:
      _buildManualToggle(),
    );

  Widget _buildManualToggle() => Semantics(toggled: _manualCheckEnabled, excludeSemantics: true, 
    label: Localization().getStringEx("panel.event2.setup.attendance.manual.toggle.title", "Allow manual attendance check"),
    hint: Localization().getStringEx("panel.event2.setup.attendance.manual.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.setup.attendance.manual.toggle.title", "Allow manual attendance check"),
      description: Localization().getStringEx("panel.event2.setup.attendance.manual.toggle.description", "Requires advance registration."),
      toggled: _manualCheckEnabled,
      onTap: _onTapManual,
      //padding: _toggleDescriptionPadding,
      //border: _toggleBorder,
      //borderRadius: _toggleBorderRadius,
    ));

  void _onTapManual() {
    Analytics().logSelect(target: "Toggle Manual Check");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _manualCheckEnabled = !_manualCheckEnabled;
    });
  }

  // Submit

  void _onHeaderBack() {
    Navigator.of(context).pop((_takeAttendanceViaAppEnabled || _scanningEnabled || _manualCheckEnabled) ? AttendanceDetails(
      attendanceRequired: widget.attendanceDetails?.attendanceRequired,
      takeAttendanceViaAppEnabled: _takeAttendanceViaAppEnabled,
      scanningEnabled: _scanningEnabled,
      manualCheckEnabled: _manualCheckEnabled,
    ) : null);
  }
}
