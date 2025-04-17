import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_io/io.dart';

class Event2ManageDataPanel extends StatefulWidget{
  final Event2? event;
  final String? surveyId;

  const Event2ManageDataPanel({super.key, this.event, this.surveyId});

  @override
  State<StatefulWidget> createState() => _Event2ManageDataState();

  static bool get canManage => canUploadCsv;
  static bool get canUploadCsv => PlatformUtils.isWeb;
  bool get _canUploadCsv => canUploadCsv;
}

class _Event2ManageDataState extends State<Event2ManageDataPanel>{
  static final _csvFileDateFormat = 'yyyy-MM-dd-HH-mm';
  static final _csvFileDefaultEmptyValue = '---';

  bool _downloadingSurveyResponses = false;
  bool _downloadingRegistrants = false;
  bool _uploadingRegistrants = false;
  bool _downloadingAttendees = false;
  bool _uploadingAttendees = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.event2.manage.data.header.title', 'Manage Event Data')),
      body: _buildContent(),
      backgroundColor: Styles().colors.white,
    );
  }

  Widget _buildContent() =>
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Visibility(visible: widget._canUploadCsv,
                child: Event2SettingsButton(
                  title: 'DOWNLOAD REGISTRANTS .csv',
                  progress: _downloadingRegistrants,
                  onTap: _onDownloadRegistrants)
              ),
              Visibility(visible: widget._canUploadCsv,
                child: Event2SettingsButton(
                    title: 'UPLOAD REGISTRANTS .csv',
                    progress: _uploadingRegistrants,
                    onTap: _onUploadRegistrants),
              ),
              Visibility(visible: widget._canUploadCsv,
                child: Event2SettingsButton(
                      title: 'DOWNLOAD ATTENDANCE .csv',
                      progress: _downloadingAttendees,
                      onTap: _onDownloadAttendance),
              ),
              Visibility(visible: widget._canUploadCsv,
                child: Event2SettingsButton(
                    title: 'UPLOAD ATTENDANCE .csv',
                    progress: _uploadingAttendees,
                    onTap: _onUploadAttendance),
              ),
              Visibility(visible: widget._canUploadCsv && _hasSurvey,
                child: Event2SettingsButton(
                    title: 'DOWNLOAD SURVEY RESULTS .csv',
                    progress: _downloadingSurveyResponses,
                    onTap: _onDownloadSurveyResults),
              ),
              _buildDownloadResultsDescription(),
          ]),
        )
    );

  Widget _buildDownloadResultsDescription() {
    TextStyle? mainStyle = Styles().textStyles.getTextStyle('widget.item.small.thin.italic');
    final Color defaultStyleColor = Colors.red;
    final String? eventAttendanceUrl = Config().eventAttendanceUrl;
    final String? displayAttendanceUrl = (eventAttendanceUrl != null) ? (UrlUtils.stripUrlScheme(eventAttendanceUrl) ?? eventAttendanceUrl) : null;
    final String eventAttendanceUrlMacro = '{{event_attendance_url}}';
    String contentHtml = Localization().getStringEx('panel.event2.detail.survey.download.results.description',
      "Download survey results at {{event_attendance_url}}.");
    contentHtml = contentHtml.replaceAll(eventAttendanceUrlMacro, displayAttendanceUrl ?? '');
    return Visibility(visible: PlatformUtils.isMobile && StringUtils.isNotEmpty(displayAttendanceUrl), child:
      Padding(padding: EdgeInsets.zero, child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Styles().images.getImage('info') ?? Container(),
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 6), child:
              HtmlWidget(contentHtml, onTapUrl: _onTapHtmlLink, textStyle: mainStyle,
                customStylesBuilder: (element) => (element.localName == "a") ? { "color": ColorUtils.toHex(mainStyle?.color ?? defaultStyleColor), "text-decoration-color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null,
              )
            ),
          ),
        ])
      ),
    );
  }

  bool _onTapHtmlLink(String? url) {
    Analytics().logSelect(target: '($url)');
    UrlUtils.launchExternal(url, mode: LaunchMode.externalApplication);
    return true;
  }

  void _onDownloadRegistrants() async {
    Analytics().logSelect(target: 'Download Registrants');
    if (_downloadingRegistrants) {
      return;
    }
    if (_event?.registrationDetails?.type != Event2RegistrationType.internal) {
      AppAlert.showDialogResult(
          context,
          Localization()
              .getStringEx('panel.event2.detail.admin_settings.download.registrants.type.not.internal.msg', 'This operation is available only for events with internal registration.'));
      return;
    }
    setStateIfMounted(() {
      _downloadingRegistrants = true;
    });
    Event2PersonsResult? personsResult = await Events2().loadEventPeople(_event!.id!);
    List<Event2Person>? registrants = personsResult?.registrants;
    Set<String>? eventRegistrantNetIds = Event2Person.netIdsInList(registrants, role: Event2UserRole.participant);
    if (CollectionUtils.isEmpty(eventRegistrantNetIds)) {
      setStateIfMounted((){
        _downloadingRegistrants = true;
      });
      AppAlert.showDialogResult(
          context,
          Localization()
              .getStringEx('panel.event2.detail.admin_settings.download.registrants.persons.missing.msg', 'There are no registrants for this event.'));
      return;
    }
    List<Event2Account>? accounts = await Events2().loadEventAccounts(eventId: _event!.id!, netIds: eventRegistrantNetIds!.toList());
    bool hasAccounts = CollectionUtils.isNotEmpty(accounts);
    if (hasAccounts) {
      debugPrint('Download registrants - failed to load event accounts.');
    }
    List<List<dynamic>> rows = <List<dynamic>>[];
    for (String netId in eventRegistrantNetIds) {
      Event2Account? account = hasAccounts ? accounts!.firstWhereOrNull((account) => (account.netId == netId)) : null;
      rows.add([_csvFormattedEventName, _csvFormattedEventStartDate, _csvFormattedEventStartTime,
        _buildCsvAccountUin(account), netId, _buildCsvAccountFirstName(account), _buildCsvAccountLastName(account)]);
    }

    String fileName = 'event_registrants_$_csvFormattedDateExported.csv';
    AppFile.exportCsv(rows: rows, fileName: fileName).then((_) {
      setStateIfMounted(() {
        _downloadingRegistrants = false;
      });
    });
  }

  void _onUploadRegistrants() {
    Analytics().logSelect(target: 'Upload Registrants');
    if (_uploadingRegistrants) {
      return;
    }
    Event2RegistrationDetails? registrationDetails = _event?.registrationDetails;
    Event2RegistrationType? registrationType = registrationDetails?.type;
    if ((registrationType == null) || (registrationType == Event2RegistrationType.none)) {
      AppAlert.showDialogResult(
          context,
          Localization()
              .getStringEx('panel.event2.detail.admin_settings.upload.registrants.type.not.allowed.msg', 'This operation is available only for events with registration.'));
      return;
    }
    setStateIfMounted(() {
      _uploadingRegistrants = true;
    });
    _buildNetIdsFromCsvFile().then((result) {
      if (result is String) {
        setStateIfMounted(() {
          _uploadingRegistrants = false;
        });
        AppAlert.showDialogResult(context, result);
      } else if (result is List<String>) {
        _uploadRegistrants(registrationDetails: registrationDetails!, newRegistrantNetIds: result);
      } else {
        setStateIfMounted(() {
          _uploadingRegistrants = false;
        });
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.event2.detail.admin_settings.upload.common.failed.unknown.msg', 'Unknown error occurred.'));
      }
    });
  }

  void _uploadRegistrants({required Event2RegistrationDetails registrationDetails, required List<String> newRegistrantNetIds}) {
    List<String>? oldRegistrantNetIds = registrationDetails.registrants;
    if (CollectionUtils.isNotEmpty(oldRegistrantNetIds)) {
      newRegistrantNetIds.addAll(oldRegistrantNetIds!);
    }
    Event2RegistrationDetails updatedDetails = Event2RegistrationDetails.fromOther(registrationDetails, registrants: newRegistrantNetIds)!;
    Events2().updateEventRegistrationDetails(_event!.id!, updatedDetails).then((result) {
      setStateIfMounted(() {
        _uploadingRegistrants = false;
      });
      late String message;
      if (result is String) {
        message = sprintf(Localization().getStringEx('panel.event2.detail.admin_settings.upload.registrants.failed.msg', "Failed to upload registrants' NetIDs. Reason: %s"), result);
      } else if (result is Event2) {
        message = Localization().getStringEx('panel.event2.detail.admin_settings.upload.registrants.succeeded.msg', "Successfully uploaded registrants' NetIDs.");
      } else {
        message = Localization().getStringEx('panel.event2.detail.admin_settings.upload.common.failed.unknown.msg', 'Unknown error occurred.');
      }
      AppAlert.showDialogResult(context, message);
    });
  }

  void _onDownloadAttendance() async {
    Analytics().logSelect(target: 'Download Attendance');
    if (_downloadingAttendees) {
      return;
    }
    setStateIfMounted(() {
      _downloadingAttendees = true;
    });
    Event2PersonsResult? personsResult = await Events2().loadEventPeople(_event!.id!);
    Set<String>? attendeesNetIds = Event2Person.netIdsFromList(personsResult?.attendees);
    if (CollectionUtils.isEmpty(attendeesNetIds)) {
      setStateIfMounted(() {
        _downloadingAttendees = true;
      });
      AppAlert.showDialogResult(
          context,
          Localization()
              .getStringEx('panel.event2.detail.admin_settings.download.attendees.persons.missing.msg', 'There are no attendees for this event.'));
      return;
    }
    List<Event2Account>? accounts = await Events2().loadEventAccounts(eventId: _event!.id!, netIds: attendeesNetIds!.toList());
    bool hasAccounts = CollectionUtils.isNotEmpty(accounts);
    if (hasAccounts) {
      debugPrint('Download attendees - failed to load event accounts.');
    }
    List<List<dynamic>> rows = <List<dynamic>>[];
    for (String netId in attendeesNetIds) {
      Event2Account? account = hasAccounts ? accounts!.firstWhereOrNull((account) => (account.netId == netId)) : null;
      rows.add([_csvFormattedEventName, _csvFormattedEventStartDate, _csvFormattedEventStartTime,
        _buildCsvAccountUin(account), netId, _buildCsvAccountFirstName(account), _buildCsvAccountLastName(account)]);
    }

    String fileName = 'event_attendees_$_csvFormattedDateExported.csv';
    AppFile.exportCsv(rows: rows, fileName: fileName).then((_) {
      setStateIfMounted(() {
        _downloadingAttendees = false;
      });
    });
  }

  void _onUploadAttendance() {
    Analytics().logSelect(target: 'Upload Attendance');
    if (_uploadingAttendees) {
      return;
    }
    setStateIfMounted(() {
      _uploadingAttendees = true;
    });
    _buildNetIdsFromCsvFile().then((result) {
      if (result is String) {
        setStateIfMounted(() {
          _uploadingAttendees = false;
        });
        AppAlert.showDialogResult(context, result);
      } else if (result is List<String>) {
        _uploadAttendees(result);
      } else {
        setStateIfMounted(() {
          _uploadingAttendees = false;
        });
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.event2.detail.admin_settings.upload.common.failed.unknown.msg', 'Unknown error occurred.'));
      }
    });
  }

  void _uploadAttendees(List<String> attendeeNetIds) {
    Events2().attendAllNetIds(eventId: widget.event!.id!, netIds: attendeeNetIds).then((result) {
      setStateIfMounted(() {
        _uploadingAttendees = false;
      });
      late String message;
      if (result is String) {
        message = sprintf(Localization().getStringEx('panel.event2.detail.admin_settings.upload.attendees.failed.msg', "Failed to upload attendees' NetIDs. Reason: %s"), result);
      } else if (result is List<Event2AttendeeResult>) {
        if (Event2AttendeeResult.allSucceeded(result)) {
          message = Localization().getStringEx('panel.event2.detail.admin_settings.upload.attendees.succeeded.msg', "Successfully uploaded attendees' NetIDs.");
        } else {
          List<String> succeededResults = result.where((element) => (element.succeeded == true)).map((element) => element.netId).toList();
          List<String> failedResults = result.where((element) => (element.succeeded == false)).map((element) => element.netId).toList();
          String succeededString = succeededResults.join(',');
          String failedString = failedResults.join(',');
          message = sprintf(Localization().getStringEx('panel.event2.detail.admin_settings.upload.attendees.mixed.msg', 'Succeeded NetIDs: %s \n\nFailed NetIds: %s'), [succeededString, failedString]);
        }
      } else {
        message = Localization().getStringEx('panel.event2.detail.admin_settings.upload.common.failed.unknown.msg', 'Unknown error occurred.');
      }
      AppAlert.showDialogResult(context, message);
    });
  }

  ///
  /// returns List<String> with NetIDs if successful and error message String - otherwise
  ///
  Future<dynamic> _buildNetIdsFromCsvFile() async {
    FilePickerResult? pickResult = await FilePicker.platform.pickFiles(allowedExtensions: ['csv'], type: FileType.custom);
    if (pickResult != null) {
      String? fileContent;
      if (PlatformUtils.isWeb) {
        Uint8List? fileBytes = pickResult.files.single.bytes;
        if (fileBytes != null) {
          fileContent = Utf8Decoder().convert(fileBytes);
        }
      } else {
        String? filePath = pickResult.files.single.path;
        File? selectedFile = StringUtils.isNotEmpty(filePath) ? File(filePath!) : null;
        fileContent = (selectedFile != null) ? selectedFile.readAsStringSync() : null;
      }
      if (StringUtils.isEmpty(fileContent)) {
        return Localization().getStringEx('panel.event2.detail.admin_settings.upload.common.file.invalid.msg', 'Invalid file selected.');
      }
      List<String> attendeesNetIds = fileContent!.split(ListUtils.commonDelimiterRegExp);
      if (CollectionUtils.isNotEmpty(attendeesNetIds)) {
        return attendeesNetIds;
      } else {
        return Localization().getStringEx('panel.event2.detail.admin_settings.upload.common.netds.missing.msg', 'There are no NetIDs in this file.');
      }
    } else {
      return Localization().getStringEx('panel.event2.detail.admin_settings.upload.common.operation.cancelled.msg', 'Upload was canceled by the user.');
    }
  }

  void _onDownloadSurveyResults() async {
    Analytics().logSelect(target: "Download Survey Results");
    if (_downloadingSurveyResponses) {
      return;
    }
    String? surveyId = widget.surveyId;
    if (StringUtils.isEmpty(surveyId)) {
      AppAlert.showDialogResult(context,
          Localization().getStringEx('panel.event2.detail.admin_settings.survey.missing.msg', 'There is no survey for this event.'));
      return;
    }
    setStateIfMounted(() {
      _downloadingSurveyResponses = true;
    });
    List<SurveyResponse>? responses = await Surveys().loadAllSurveyResponses(surveyId!);
    if (CollectionUtils.isEmpty(responses)) {
      setStateIfMounted(() {
        _downloadingSurveyResponses = false;
      });
      AppAlert.showDialogResult(
          context,
          Localization()
              .getStringEx('panel.event2.detail.admin_settings.survey.responses.missing.msg', 'There are no survey responses available.'));
      return;
    }
    List<String>? accountIds = responses!.map((response) => StringUtils.ensureNotEmpty(response.userId)).toList();
    List<Event2Account>? accounts = await Events2().loadEventAccounts(eventId: _event!.id!, accountIds: accountIds);
    if (CollectionUtils.isEmpty(accounts)) {
      debugPrint('Download survey responses - failed to load event accounts.');
    }
    bool hasAccounts = CollectionUtils.isNotEmpty(accounts);
    List<List<dynamic>> rows = <List<dynamic>>[];
    for (SurveyResponse response in responses) {
      String? accountId = response.userId;
      Event2Account? account =
      ((accountId != null) && hasAccounts) ? accounts!.firstWhereOrNull((account) => (account.accountId == accountId)) : null;
      Map<String, SurveyData> data = response.survey.data;
      for (String key in data.keys) {
        SurveyData? value = data[key];
        if (value != null) {
          String question = value.text;
          String answer = value.response;
          rows.add([_csvFormattedEventName, _csvFormattedEventStartDate, _csvFormattedEventStartTime,
            _buildCsvAccountUin(account), _buildCsvAccountNetId(account), _buildCsvAccountFirstName(account), _buildCsvAccountLastName(account),
            question,
            answer
          ]);
        }
      }
    }
    String fileName = 'event_survey_results_$_csvFormattedDateExported.csv';
    AppFile.exportCsv(rows: rows, fileName: fileName).then((_) {
      setStateIfMounted(() {
        _downloadingSurveyResponses = false;
      });
    });
  }

  String _buildCsvAccountUin(Event2Account? account) => StringUtils.ensureNotEmpty(account?.uin, defaultValue: _csvFileDefaultEmptyValue);
  String _buildCsvAccountNetId(Event2Account? account) => StringUtils.ensureNotEmpty(account?.netId, defaultValue: _csvFileDefaultEmptyValue);
  String _buildCsvAccountFirstName(Event2Account? account) => StringUtils.ensureNotEmpty(account?.firstName, defaultValue: _csvFileDefaultEmptyValue);
  String _buildCsvAccountLastName(Event2Account? account) => StringUtils.ensureNotEmpty(account?.lastName, defaultValue: _csvFileDefaultEmptyValue);

  Event2? get _event => widget.event;

  bool get _hasSurvey => StringUtils.isNotEmpty(widget.surveyId);

  String get _csvFormattedEventName => StringUtils.ensureNotEmpty(widget.event?.name, defaultValue: _csvFileDefaultEmptyValue);
  String get _csvFormattedEventStartDate => StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(_event?.startTimeUtc?.toLocalTZ(), format: 'yyyy-MM-dd'), defaultValue: _csvFileDefaultEmptyValue);
  String get _csvFormattedEventStartTime => StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(_event?.startTimeUtc?.toLocalTZ(), format: 'HH:mm'), defaultValue: _csvFileDefaultEmptyValue);
  String? get _csvFormattedDateExported => AppDateTime().formatDateTime(DateTime.now(), format: _csvFileDateFormat);
}
