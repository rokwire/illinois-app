
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2AttendanceTakerPanel.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/GestureDetector.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class Event2SetupAttendancePanel extends StatefulWidget {
  final Event2? event;
  final Event2AttendanceDetails? attendanceDetails;
  
  Event2SetupAttendancePanel({Key? key, this.event, this.attendanceDetails}) : super(key: key);
  
  String? get eventId => event?.id;
  Event2AttendanceDetails? get details => (eventId != null) ? event?.attendanceDetails : attendanceDetails;

  @override
  State<StatefulWidget> createState() => _Event2SetupAttendancePanelState();
}

class _Event2SetupAttendancePanelState extends State<Event2SetupAttendancePanel>  {

  late bool _scanningEnabled;
  late bool _manualCheckEnabled;

  bool _scanningProgress = false;
  bool _manualCheckProgress = false;
  bool _applyProgress = false;
  
  final TextEditingController _attendanceTakersController = TextEditingController();

  late bool _initialScanningEnabled;
  late bool _initialManualCheckEnabled;
  List<String>? _initialAttendanceTakers;
  late String _initialAttendanceTakersDisplayString;

  Event2? _event;
  final StreamController<String> _updateController = StreamController.broadcast();

  bool _modified = false;
  bool _updatingAttendance = false;

  @override
  void initState() {
    _event = widget.event;
    _initDetails(widget.details);
    if (_isEditing) {
      _attendanceTakersController.addListener(_checkModified);
    }
    super.initState();
  }

  @override
  void dispose() {
    _attendanceTakersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: () => AppPopScope.back(_onHeaderBarBack), child: Platform.isIOS ?
      BackGestureDetector(onBack: _onHeaderBarBack, child:
        _buildScaffoldContent(),
      ) :
      _buildScaffoldContent()
    );
  }

  Widget _buildScaffoldContent() => Scaffold(
    appBar: _headerBar,
    body: _buildPanelContent(),
    backgroundColor: Styles().colors!.white,
  );

  Widget _buildPanelContent() {
    return RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
        Column(children: [
          Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _buildScanSection()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _buildManualSection()),
              _isEditing ? _buildAttendanceTakerSection() : Container(),
              _isEditing ? Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _buildAttendanceTakersSection()) : Container(),
            ]),
          )

        ],),
      )
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
      toggled: _scanningEnabled,
      onTap: _onTapScan,
      padding: EdgeInsets.zero,
      progress: _scanningProgress,
      //border: _toggleBorder,
      //borderRadius: _toggleBorderRadius,
    ));

  void _onTapScan() {
    Analytics().logSelect(target: "Toggle Scan Illini ID");
    Event2CreatePanel.hideKeyboard(context);
    if (_isCreating) {
      setStateIfMounted(() {
        _scanningEnabled = !_scanningEnabled;
      });
    }
    else {
      _updateEventAttendanceDetails(
        attendanceDetails: Event2AttendanceDetails(
          scanningEnabled: !_scanningEnabled,
          manualCheckEnabled: _manualCheckEnabled,
          attendanceTakers: _initialAttendanceTakers
        ),
        progress: (bool value) => (_scanningProgress = value),
        success: (Event2 event) => _applyEventDetails(event)
      );
    }
  }

  // Manual

  Widget _buildManualSection() =>
    Padding(padding: Event2CreatePanel.sectionPadding, child:
      _buildManualToggle(),
    );

  Widget _buildManualToggle() => Semantics(toggled: _manualCheckEnabled, excludeSemantics: true, 
    label: Localization().getStringEx("panel.event2.setup.attendance.manual.toggle.title", "Allow manual attendance taking"),
    hint: Localization().getStringEx("panel.event2.setup.attendance.manual.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.setup.attendance.manual.toggle.title", "Allow manual attendance taking"),
      toggled: _manualCheckEnabled,
      onTap: _onTapManual,
      padding: EdgeInsets.zero,
      progress: _manualCheckProgress,
      //border: _toggleBorder,
      //borderRadius: _toggleBorderRadius,
    ));

  void _onTapManual() {
    Analytics().logSelect(target: "Toggle Manual Check");
    Event2CreatePanel.hideKeyboard(context);

    if (_isCreating) {
      setStateIfMounted(() {
        _manualCheckEnabled = !_manualCheckEnabled;
      });
    }
    else {
      _updateEventAttendanceDetails(
        attendanceDetails: Event2AttendanceDetails(
          scanningEnabled: _scanningEnabled,
          manualCheckEnabled: !_manualCheckEnabled,
          attendanceTakers: _initialAttendanceTakers
        ),
        progress: (bool value) => (_manualCheckProgress = value),
        success: (Event2 event) => _applyEventDetails(event)
      );
    }
  }

  // Attendance Taker

  Widget _buildAttendanceTakerSection() {
    return Padding(padding: Event2CreatePanel.sectionPadding, child:
      Column(children: [
        Divider(color: Styles().colors?.dividerLineAccent, thickness: 1),
        Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child:
          Event2AttendanceTakerWidget(_event, updateController: _updateController,),
        ),
        Divider(color: Styles().colors?.dividerLineAccent, thickness: 1),
      ],),
    );
  }

  // Attendance Takers

  Widget _buildAttendanceTakersSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.attendance.takers.label.title', 'Netids for additional attendance takers:')),
    body: Event2CreatePanel.buildTextEditWidget(_attendanceTakersController, keyboardType: TextInputType.text, maxLines: null),
    trailing: Column(children: [
      _buildAttendanceTakersHint(),
    ]),
  );

  Widget _buildAttendanceTakersHint() => Padding(padding: EdgeInsets.only(top: 2), child:
    Row(children: [
      Expanded(child:
        Text(Localization().getStringEx('panel.event2.setup.attendance.takers.label.hint', 'A space- or comma-separated list of NetIDs.'), style: _infoTextStype,),
      )
    ],),
  );

  TextStyle? get _infoTextStype => Styles().textStyles?.getTextStyle('widget.item.small.thin.italic');

  Future<void> _onRefresh() async {
    _updateController.add(Event2AttendanceTakerWidget.notifyRefresh);
  }

  // HeaderBar

  bool get _isEditing => StringUtils.isNotEmpty(widget.eventId);
  bool get _isCreating => StringUtils.isEmpty(widget.eventId);

  PreferredSizeWidget get _headerBar => HeaderBar(
    title: Localization().getStringEx("panel.event2.setup.attendance.header.title", "Event Attendance"),
    onLeading: _onHeaderBarBack,
    actions: _headerBarActions,
  );

  List<Widget>? get _headerBarActions {
    if (_applyProgress) {
      return [Event2CreatePanel.buildHeaderBarActionProgress()];  
    }
    else if (_isEditing && _modified) {
      return [Event2CreatePanel.buildHeaderBarActionButton(
        title: Localization().getStringEx('dialog.apply.title', 'Apply'),
        onTap: _onTapApply,
      )];
    }
    else {
      return null;
    }
  }

  void _initDetails(Event2AttendanceDetails? details) {
    _scanningEnabled = _initialScanningEnabled = details?.scanningEnabled ?? false;
    _manualCheckEnabled = _initialManualCheckEnabled = details?.manualCheckEnabled ?? false;
    _initialAttendanceTakers = details?.attendanceTakers;
    _attendanceTakersController.text = _initialAttendanceTakersDisplayString = details?.attendanceTakers?.join(' ') ?? '';
    _modified = false;
  }

  void _applyEventDetails(Event2 event) =>
    setStateIfMounted(() {
      _event = event;
      _initDetails(event.attendanceDetails);
    });
  
  void _checkModified() {
    if (_isEditing && mounted) {
      
      bool modified = (_scanningEnabled != _initialScanningEnabled) ||
        (_manualCheckEnabled != _initialManualCheckEnabled) ||
        (_attendanceTakersController.text != _initialAttendanceTakersDisplayString);

      if (_modified != modified) {
        setState(() {
          _modified = modified;
        });
      }
    }
  }

  // For new registration details we must return non-zero instance, for update we 
  Event2AttendanceDetails _buildAttendanceDetails() => Event2AttendanceDetails(
      scanningEnabled: _scanningEnabled,
      manualCheckEnabled: _manualCheckEnabled,
      attendanceTakers: _buildAttendanceTakers(),
  );

  List<String>? _buildAttendanceTakers() =>
    ListUtils.notEmpty(ListUtils.stripEmptyStrings(_attendanceTakersController.text.split(RegExp(r'[\s,;]+'))));

  void _updateEventAttendanceDetails({required Event2AttendanceDetails attendanceDetails, void Function(bool)? progress, void Function(Event2)? success }) {
    if ((_updatingAttendance != true) && mounted) {
      setState(() {
        _updatingAttendance = true;
        if (progress != null) {
          progress(true);
        }
      });
      // https://github.com/rokwire/calendar-building-block/issues/235
      // Temporarily pass empty non-null attendance details until this gets fixed on the backend:
      // attendanceDetails.isNotEmpty ? attendanceDetails : null
      Events2().updateEventAttendanceDetails(widget.eventId ?? '', attendanceDetails).then((result) {
        if (mounted) {
          setState(() {
            _updatingAttendance = false;
            if (progress != null) {
              progress(false);
            }
          });
        }
        if (result is Event2) {
          if (success != null) {
            success(result);
          }
        }
        else {
          Event2Popup.showErrorResult(context, result);
        }
      });
    }
  }

  Future<List<String>?> _checkForInvalidAttendanceTakers({void Function(bool)? progress}) async {
    String? eventId = widget.eventId;
    List<String>? attendanceTakers = _buildAttendanceTakers();
    if ((eventId != null) && (attendanceTakers != null) && attendanceTakers.isNotEmpty) {
      setStateIfMounted(() {
        if (progress != null) {
          progress(true);
        }
      });

      Event2PersonsResult? persons = await Events2().loadEventPeople(eventId);
      
      setStateIfMounted(() {
        if (progress != null) {
          progress(false);
        }
      });

      Set<String>? registrants = Event2Person.netIdsFromList(persons?.registrants);
      if ((registrants != null) && registrants.isNotEmpty) {
        List<String> invalidAttendanceTakers = <String>[];
        for (String attendanceTaker in attendanceTakers) {
          if (registrants.contains(attendanceTaker)) {
            invalidAttendanceTakers.add(attendanceTaker);
          }
        }
        return invalidAttendanceTakers;
      }
    }
    return null;
  }

  void _onTapApply() async {
    Analytics().logSelect(target: 'HeaderBar: Apply');
    List<String>? invalidAttendanceTakers = await _checkForInvalidAttendanceTakers(
      progress: (bool value) => (_applyProgress = value),
    );
    if (mounted) {
      if ((invalidAttendanceTakers != null) && invalidAttendanceTakers.isNotEmpty) {
        String msg = sprintf(Localization().getStringEx('panel.event2.setup.attendance.takers.duplicated_netids.error.msg', 'Registrants with the following NetIDs cannot be added as attendance takers until they unregister for the event:\n\n %s'), [ invalidAttendanceTakers.join(', ') ]);
        Event2Popup.showMessage(context, title: Localization().getStringEx("panel.event2.setup.attendance.header.title", "Event Attendance"), message: msg);
      }
      else {
        _updateEventAttendanceDetails(
            attendanceDetails: _buildAttendanceDetails(),
            progress: (bool value) => (_applyProgress = value),
            success: (Event2 event) => _applyEventDetails(event)
        );
      }
    }
  }

  void _onHeaderBarBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    Navigator.of(context).pop(_isCreating ? _buildAttendanceDetails() : null);
  }
}
