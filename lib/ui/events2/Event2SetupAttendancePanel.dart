
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Event2SetupAttendancePanel extends StatefulWidget {
  final Event2? event;
  final Event2AttendanceDetails? attendanceDetails;
  
  Event2SetupAttendancePanel({Key? key, this.event, this.attendanceDetails}) : super(key: key);
  
  Event2AttendanceDetails? get details => (event?.id != null) ? event?.attendanceDetails : attendanceDetails;

  @override
  State<StatefulWidget> createState() => _Event2SetupAttendancePanelState();
}

class _Event2SetupAttendancePanelState extends State<Event2SetupAttendancePanel>  {

  late bool _scanningEnabled;
  late bool _manualCheckEnabled;
  
  final TextEditingController _attendanceTakersController = TextEditingController();

  bool _updatingAttendance = false;

  @override
  void initState() {
    _scanningEnabled = widget.details?.scanningEnabled ?? false;
    _manualCheckEnabled = widget.details?.manualCheckEnabled ?? false;
    _attendanceTakersController.text = widget.details?.attendanceTakers?.join(' ') ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _attendanceTakersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx("panel.event2.setup.attendance.header.title", "Event Attendance"), leadingWidget: _headerBarLeading,),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.white,
    );
  }

  Widget _buildPanelContent() {
    return SingleChildScrollView(child:
      Column(children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildScanSection(),
            _buildManualSection(),
            _buildAttendanceTakersSection(),
          ]),
        )

      ],)

    );
  }

  //EdgeInsetsGeometry get _togglePadding => const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  //EdgeInsetsGeometry get _toggleDescriptionPadding => const EdgeInsets.symmetric(horizontal: 12, vertical: 5);
  //BoxBorder get _toggleBorder => Border.all(color: Styles().colors!.surfaceAccent!, width: 1);
  //BorderRadius get _toggleBorderRadius => BorderRadius.all(Radius.circular(4));

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
      padding: EdgeInsets.zero,
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
      padding: EdgeInsets.zero,
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

  // Attendance Takers

  Widget _buildAttendanceTakersSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.attendance.takers.label.title', 'Netids for additional attendance takers:')),
    body: Event2CreatePanel.buildTextEditWidget(_attendanceTakersController, keyboardType: TextInputType.text, maxLines: null),
    trailing: Column(children: [
      _buildAttendanceTakersHint(),
      _buildAttendanceTakersInfo(),
    ]),
  );

  Widget _buildAttendanceTakersHint() => Padding(padding: EdgeInsets.only(top: 2), child:
    Row(children: [
      Expanded(child:
        Text(Localization().getStringEx('panel.event2.setup.attendance.takers.label.hint', 'A space or comma separated list of Net IDs.'), style: _infoTextStype,),
      )
    ],),
  );

  Widget _buildAttendanceTakersInfo() => Padding(padding: EdgeInsets.only(top: 12), child:
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Styles().images?.getImage('info') ?? Container(),
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 6), child:
          Text(Localization().getStringEx('panel.event2.setup.attendance.takers.label.info', 'To check in a specific attendee, the individual must be accounted for in your total number of registrants within the Illinois app. No personal attendee information may be entered as part of taking attendance in the Illinois app.'), style: _infoTextStype,)
        ),
      ),
    ],),
  );

  TextStyle? get _infoTextStype => Styles().textStyles?.getTextStyle('widget.item.small.thin.italic');

  // HeaderBar

  Widget get _headerBarLeading => _updatingAttendance ?
    _headerBarBackProgress : _headerBarBackButton;

  Widget get _headerBarBackButton {
    String leadingLabel = Localization().getStringEx('headerbar.back.title', 'Back');
    String leadingHint = Localization().getStringEx('headerbar.back.hint', '');
    return Semantics(label: leadingLabel, hint: leadingHint, button: true, excludeSemantics: true, child:
      IconButton(icon: Styles().images?.getImage(HeaderBar.defaultLeadingIconKey, excludeFromSemantics: true) ?? Container(), onPressed: () => _onHeaderBack())
    );
  }

  Widget get _headerBarBackProgress =>
    Padding(padding: EdgeInsets.all(20), child:
        SizedBox(width: 16, height: 16, child:
          CircularProgressIndicator(color: Styles().colors?.white, strokeWidth: 3,)
        )
    );

  // For new registration details we must return non-zero instance, for update we 
  Event2AttendanceDetails _buildAttendanceDetails() => Event2AttendanceDetails(
      scanningEnabled: _scanningEnabled,
      manualCheckEnabled: _manualCheckEnabled,
      attendanceTakers: ListUtils.notEmpty(ListUtils.stripEmptyStrings(_attendanceTakersController.text.split(RegExp(r'[\s,;]+')))),
  );

  void _updateEventAttendanceDetails(Event2AttendanceDetails? attendanceDetails) {
    if (_updatingAttendance != true) {
      setState(() {
        _updatingAttendance = true;
      });
      Events2().updateEventAttendanceDetails(widget.event?.id ?? '', attendanceDetails).then((result) {
        if (mounted) {
          setState(() {
            _updatingAttendance = false;
          });
        }
        String? title, message;
        if (result is Event2) {
          //title = Localization().getStringEx('panel.event2.create.message.succeeded.title', 'Succeeded');
          //message = Localization().getStringEx('panel.event2.update.attendance.message.succeeded.message', 'Successfully updated \"{{event_name}}\" attendance.').replaceAll('{{event_name}}', result.name ?? '');
        }
        else if (result is String) {
          title = Localization().getStringEx('panel.event2.create.message.failed.title', 'Failed');
          message = result;
        }

        if (title != null) {
          Event2Popup.showMessage(context, title, message).then((_) {
            if (result is Event2) {
              Navigator.of(context).pop(result);
            }
          });
        }
        else if (result is Event2) {
          Navigator.of(context).pop(result);
        }
      });
    }
  }

  void _onHeaderBack() {
    Event2AttendanceDetails attendanceDetails = _buildAttendanceDetails();
    if (widget.event?.id != null) {
      Event2AttendanceDetails? eventAttendanceDetails = attendanceDetails.isNotEmpty ? attendanceDetails : null;
      if (widget.event?.attendanceDetails != eventAttendanceDetails) {
        _updateEventAttendanceDetails(attendanceDetails);
      }
      else {
        Navigator.of(context).pop(null);
      }
    }
    else {
      Navigator.of(context).pop(attendanceDetails);
    }
  }
}
