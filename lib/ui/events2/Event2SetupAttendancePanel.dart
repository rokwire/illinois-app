
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/events2/Event2AttendanceTakerPanel.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class Event2SetupAttendancePanel extends StatefulWidget with AnalyticsInfo {
  final Event2? event;
  final Event2AttendanceDetails? _attendanceDetails;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  Event2SetupAttendancePanel({ super.key, this.event, Event2AttendanceDetails? attendanceDetails, Event2RegistrationDetails? registrationDetails, this.analyticsFeature }) :
    _attendanceDetails = attendanceDetails;

  String? get eventId => event?.id;
  Event2AttendanceDetails? get attendanceDetails => (eventId != null) ? event?.attendanceDetails : _attendanceDetails;

  @override
  State<StatefulWidget> createState() => _Event2SetupAttendancePanelState();
}

class _Event2SetupAttendancePanelState extends State<Event2SetupAttendancePanel>  {

  late bool _scanningEnabled;
  late bool _manualCheckEnabled;
  late bool _selfCheckEnabled;
  late bool _selfCheckLimitedToRegisteredOnly;

  bool _scanningProgress = false;
  bool _manualCheckProgress = false;
  bool _selfCheckProgress = false;
  bool _selfCheckLimitedToRegisteredOnlyProgress = false;
  bool _selfCheckPdfProgress = false;
  bool _applyProgress = false;
  
  final TextEditingController _attendanceTakersController = TextEditingController();

  late bool _initialScanningEnabled;
  late bool _initialManualCheckEnabled;
  late bool _initialSelfCheckEnabled;
  late bool _initialSelfCheckLimitedToRegisteredOnly;
  List<String>? _initialAttendanceTakers;
  late String _initialAttendanceTakersDisplayString;

  Event2? _event;
  final StreamController<String> _updateController = StreamController.broadcast();

  bool _modified = false;
  bool _updatingAttendance = false;

  static const double _sectionPaddingHeight = 12;
  static const EdgeInsetsGeometry _sectionPadding = const EdgeInsets.symmetric(vertical: _sectionPaddingHeight);

  @override
  void initState() {
    _event = widget.event;
    _initDetails(widget.attendanceDetails);
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
  Widget build(BuildContext context) =>
    PopScopeFix(onBack: _onHeaderBarBack, child: _buildScaffoldContent());

  Widget _buildScaffoldContent() => Scaffold(
    appBar: _headerBar,
    body: _buildPanelContent(),
    backgroundColor: Styles().colors.white,
  );

  Widget _buildPanelContent() =>
    RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
        Column(children: [
          Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _buildHeadingDescription()),
              _sectionDivider,
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _buildScanSection()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _dividerLine),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _buildManualSection()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _dividerLine),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _buildSelfCheckSection()),
              if (_isEditing)
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _buildAttendanceTakerSection()),
              _sectionDivider,
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _buildAttendanceTakersSection()),
            ]),
          )

        ],),
      )
    );

  //EdgeInsetsGeometry get _togglePadding => const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  //EdgeInsetsGeometry get _toggleDescriptionPadding => const EdgeInsets.symmetric(horizontal: 12, vertical: 5);
  //BoxBorder get _toggleBorder => Border.all(color: Styles().colors.surfaceAccent, width: 1);
  //BorderRadius get _toggleBorderRadius => BorderRadius.all(Radius.circular(4));

  // Heading Description
  
  Widget _buildHeadingDescription() =>
    Padding(padding: _sectionPadding, child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(Localization().getStringEx('panel.event2.setup.attendance.header.description1', 'Attendance taking in the Illinois app is limited to event attendees with NetIDs.'), style: _headingDescriptionTextStyle,),
        Padding(padding: EdgeInsets.only(top: _sectionPaddingHeight)),
        Text(Localization().getStringEx('panel.event2.setup.attendance.header.description2', 'If you are taking registration in the Illinois app or uploading a registration list to the Illinois app, scanning Illini IDs and using manual attendance will alert attendance takers if the individual has NOT registered for that event. The attendance taker can choose to mark the individual as attended or not.'), style: _headingDescriptionTextStyle,),
      ],),
    );

  TextStyle? get _headingDescriptionTextStyle =>
      Styles().textStyles.getTextStyle('widget.item.small.thin'); // widget.info.small

  // Section Divider

  Widget get _sectionDivider => Padding(padding: EdgeInsets.symmetric(vertical: _sectionPaddingHeight), child:
    _dividerLine,
  );

  Widget get _dividerLine =>
    Divider(color: Styles().colors.dividerLineAccent, height: 1, thickness: 1);

  // Scan

  Widget _buildScanSection() =>
    Padding(padding: _sectionPadding, child:
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
          selfCheckEnabled: _selfCheckEnabled,
          selfCheckLimitedToRegisteredOnly: _selfCheckLimitedToRegisteredOnly,
          attendanceTakers: _initialAttendanceTakers
        ),
        progress: (bool value) => (_scanningProgress = value),
        success: (Event2 event) => _applyEventDetails(event)
      );
    }
  }

  // Manual

  Widget _buildManualSection() =>
    Padding(padding: _sectionPadding, child:
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
          selfCheckEnabled: _selfCheckEnabled,
          selfCheckLimitedToRegisteredOnly: _selfCheckLimitedToRegisteredOnly,
          attendanceTakers: _initialAttendanceTakers
        ),
        progress: (bool value) => (_manualCheckProgress = value),
        success: (Event2 event) => _applyEventDetails(event)
      );
    }
  }

  // Self Check

  Widget _buildSelfCheckSection() =>
    Padding(padding: _sectionPadding, child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          _buildSelfCheckToggle(),
          _buildSelfCheckLimitedToRegisteredOnlyToggle(),
          if (_isEditing)
            _buildSelfCheckPdf(),
        ],)
    );

  Widget _buildSelfCheckToggle() => Semantics(toggled: _selfCheckEnabled, excludeSemantics: true,
    label: Localization().getStringEx("panel.event2.setup.attendance.self_check.toggle.title", "Enable self check-in by scanning a printed event QR code"),
    hint: Localization().getStringEx("panel.event2.setup.attendance.self_check.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.setup.attendance.self_check.toggle.title", "Enable self check-in by scanning a printed event QR code"),
      toggled: _selfCheckEnabled,
      onTap: _onTapSelfCheck,
      padding: EdgeInsets.zero,
      progress: _selfCheckProgress,
      //border: _toggleBorder,
      //borderRadius: _toggleBorderRadius,
    ));

  void _onTapSelfCheck() {
    Analytics().logSelect(target: "Toggle Self Check");
    Event2CreatePanel.hideKeyboard(context);

    if (_isCreating) {
      setStateIfMounted(() {
        _selfCheckEnabled = !_selfCheckEnabled;
      });
    }
    else {
      _updateEventAttendanceDetails(
        attendanceDetails: Event2AttendanceDetails(
          scanningEnabled: _scanningEnabled,
          manualCheckEnabled: _manualCheckEnabled,
          selfCheckEnabled: !_selfCheckEnabled,
          selfCheckLimitedToRegisteredOnly: _selfCheckLimitedToRegisteredOnly,
          attendanceTakers: _initialAttendanceTakers
        ),
        progress: (bool value) => (_selfCheckProgress = value),
        success: (Event2 event) => _applyEventDetails(event)
      );
    }
  }

  Widget _buildSelfCheckLimitedToRegisteredOnlyToggle() => Semantics(enabled: _selfCheckEnabled, toggled: _selfCheckLimitedToRegisteredOnly, excludeSemantics: true,
    label: Localization().getStringEx("panel.event2.setup.attendance.self_check_limited_to_registered_only.toggle.title", "Limit self check-in to those who have registered for the event"),
    hint: Localization().getStringEx("panel.event2.setup.attendance.self_check_limited_to_registered_only.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.setup.attendance.self_check_limited_to_registered_only.toggle.title", "Limit self check-in to those who have registered for the event"),
      toggled: _selfCheckLimitedToRegisteredOnly,
      textStyle: _selfCheckEnabled ? Styles().textStyles.getTextStyle('widget.button.title.medium.thin') : Styles().textStyles.getTextStyle('widget.button.title.medium.thin.variant3'),
      rightIconKeys: _selfCheckEnabled ? ToggleRibbonButton.defaultRightIconKeys : ToggleRibbonButton.disabledRightIconKeys,
      onTap: _selfCheckEnabled ? _onTapSelfCheckLimitedToRegisteredOnly : null,
      padding: EdgeInsets.only(left: 24),
      progress: _selfCheckLimitedToRegisteredOnlyProgress,
      //border: _toggleBorder,
      //borderRadius: _toggleBorderRadius,
    ));

  void _onTapSelfCheckLimitedToRegisteredOnly() {
    Analytics().logSelect(target: "Toggle Self Check Limited To Registered Only");
    Event2CreatePanel.hideKeyboard(context);

    if (_isCreating) {
      setStateIfMounted(() {
        _selfCheckLimitedToRegisteredOnly = _selfCheckEnabled && !_selfCheckLimitedToRegisteredOnly;
      });
    }
    else {
      _updateEventAttendanceDetails(
        attendanceDetails: Event2AttendanceDetails(
          scanningEnabled: _scanningEnabled,
          manualCheckEnabled: _manualCheckEnabled,
          selfCheckEnabled: _selfCheckEnabled,
          selfCheckLimitedToRegisteredOnly: _selfCheckEnabled && !_selfCheckLimitedToRegisteredOnly,
          attendanceTakers: _initialAttendanceTakers
        ),
        progress: (bool value) => (_selfCheckLimitedToRegisteredOnlyProgress = value),
        success: (Event2 event) => _applyEventDetails(event)
      );
    }
  }

  Widget _buildSelfCheckPdf() =>
    Padding(padding: EdgeInsets.only(top: _sectionPaddingHeight), child:
      RoundedButton(
        label: Localization().getStringEx('panel.event2.setup.attendance.self_check.generate_pdf.title', 'Download Self Check-In PDF'),
        hint: Localization().getStringEx('panel.event2.setup.attendance.self_check.generate_pdf.hint', ''),
        textStyle: _selfCheckEnabled ? Styles().textStyles.getTextStyle('widget.button.title.medium') : Styles().textStyles.getTextStyle('widget.button.title.medium.variant3'),
        borderColor: _selfCheckEnabled ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
        backgroundColor: Styles().colors.white,
        onTap: _selfCheckEnabled ? _onTapSelfCheckPdf : null,
        contentWeight: 0.75,
        progress: _selfCheckPdfProgress,
      ),
    );

  void _onTapSelfCheckPdf() async {
    final int _imageSize = 1024;
    Analytics().logSelect(target: "Download Self Check-In PDF");
    Event2CreatePanel.hideKeyboard(context);
    String? eventId = widget.eventId;
    if (eventId != null) {
      setState(() {
        _selfCheckPdfProgress = true;
      });
      String? secret = await Events2().getEventSelfCheckSecret(eventId);
      if (mounted) {
        if (secret != null) {
          String selfCheckurl = Events2.eventSelfCheckUrl(eventId, secret: secret);
          Uint8List? qrCodeImageData = await NativeCommunicator().getBarcodeImageData({
                'content': selfCheckurl,
                'format': 'qrCode',
                'width': _imageSize,
                'height': _imageSize,
              });
          if (mounted) {
            if (qrCodeImageData != null) {
              Uint8List pdfData = await _generateSelfCheckPdf(qrCodeImageData);
              String pdfFileNale = await _saveSelfCheckPdfToFile(pdfData);
              if (mounted) {
                Share.shareXFiles([XFile(pdfFileNale, mimeType: 'application/pdf',)],
                  text: Localization().getStringEx('panel.event2.setup.self_check.title', 'Event Check In'),
                );
              }
            }
            else {
              setState(() {
                _selfCheckPdfProgress = false;
              });
              Event2Popup.showMessage(context,
                title: Localization().getStringEx("panel.event2.setup.attendance.header.title", "Event Attendance"),
                message: Localization().getStringEx('panel.event2.setup.attendance.self_check.generate_pdf.error.qr_code.msg', 'Failed to generate Self Check-In QR code image.'),
              );
            }
          }
        }
        else {
          setState(() {
            _selfCheckPdfProgress = false;
          });
          Event2Popup.showMessage(context,
            title: Localization().getStringEx("panel.event2.setup.attendance.header.title", "Event Attendance"),
            message: Localization().getStringEx('panel.event2.setup.attendance.self_check.generate_pdf.error.secret.msg', 'Failed to retrieve Self Check-In token.'),
          );
        }
      }
    }
  }

  Future<Uint8List> _generateSelfCheckPdf(Uint8List qrCodeImageData, { PdfPageFormat format = PdfPageFormat.letter }) async {
    pw.Document doc = pw.Document(
        title: Localization().getStringEx('panel.event2.setup.self_check.title', 'Event Check In'),
        author: Auth2().profile?.fullName
    );

    pw.PageTheme pageTheme = pw.PageTheme(
      pageFormat: format.applyMargin(
        left: 1.0 * PdfPageFormat.inch,
        right: 1.0 * PdfPageFormat.inch,
        top: 2.0 * PdfPageFormat.inch,
        bottom: 1.0 * PdfPageFormat.inch
      ),
      theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.openSansRegular(),
          bold: await PdfGoogleFonts.openSansBold(),
          icons: await PdfGoogleFonts.materialIcons(),
        ),
        buildBackground: (pw.Context context) =>
          pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              margin: const pw.EdgeInsets.all(PdfPageFormat.inch / 5.0),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromInt(Styles().colors.surfaceAccent.toARGB32()),
                  width: 1
                ),
            ),
          ),
        ),
      );

    pw.MemoryImage logoImage = pw.MemoryImage((await rootBundle.load('images/block-i-orange-blue.png')).buffer.asUint8List(),);
    pw.MemoryImage qrCodeImage = pw.MemoryImage(qrCodeImageData);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (pw.Context context) => [],
      ),
    );

    return doc.save();
  }

  Future<String> _saveSelfCheckPdfToFile(Uint8List pdfData) async {
    final String dir = (await getApplicationDocumentsDirectory()).path;
    final String saveFileName = '${widget.event?.name} SelfCheck-In ${DateTimeUtils.localDateTimeFileStampToString(DateTime.now())}';
    final String fullPath = '$dir/$saveFileName.pdf';
    File capturedFile = File(fullPath);
    await capturedFile.writeAsBytes(pdfData);
    return capturedFile.path;
  }

  // Attendance Taker

  Widget _buildAttendanceTakerSection() =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      _sectionDivider,
      Padding(padding: _sectionPadding, child:
        Event2AttendanceTakerWidget(_event, updateController: _updateController,),
      ),
    ],);

  // Attendance Takers

  Widget _buildAttendanceTakersSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.attendance.takers.label.title', 'Netids for additional attendance takers:')),
    body: Event2CreatePanel.buildTextEditWidget(_attendanceTakersController, keyboardType: TextInputType.text, maxLines: null),
    padding: _sectionPadding,
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

  TextStyle? get _infoTextStype => Styles().textStyles.getTextStyle('widget.item.small.thin.italic');

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
    _selfCheckEnabled = _initialSelfCheckEnabled = details?.selfCheckEnabled ?? false;
    _selfCheckLimitedToRegisteredOnly = _initialSelfCheckLimitedToRegisteredOnly = details?.selfCheckLimitedToRegisteredOnly ?? false;
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
        (_selfCheckEnabled != _initialSelfCheckEnabled) ||
        (_selfCheckEnabled && _initialSelfCheckEnabled && (_selfCheckLimitedToRegisteredOnly != _initialSelfCheckLimitedToRegisteredOnly)) ||
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
      selfCheckEnabled: _selfCheckEnabled,
      selfCheckLimitedToRegisteredOnly: _selfCheckLimitedToRegisteredOnly,
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
    //Future.delayed(Duration(seconds: 1), () {});
  }
}
