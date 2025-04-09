import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ui/events2/Even2SetupSuperEvent.dart';
import 'package:illinois/ui/events2/Event2SetupNotificationsPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import '../../service/Analytics.dart';
import '../widgets/HeaderBar.dart';
import '../widgets/RibbonButton.dart';
import 'Event2CreatePanel.dart';

class Event2AdminSettingsPanel extends StatefulWidget{
  final Event2? event;
  final String? surveyId;

  const Event2AdminSettingsPanel({super.key, this.event, this.surveyId});

  @override
  State<StatefulWidget> createState() => Event2AdminSettingsState();
}

class Event2AdminSettingsState extends State<Event2AdminSettingsPanel>{
  bool _duplicating = false;
  //TBD: DD - change member name and check when it's true
  bool _loadingSurveyResponses = false;
  bool _downloadingRegistrants = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.event2.detail.admin_settings.header.title', 'Admin Settings')),
      body: _buildContent(),
      backgroundColor: Styles().colors.white,
    );
  }

  Widget _buildContent() =>
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ButtonWidget(
                title: Localization().getStringEx('panel.event2.create.button.duplicate.title', 'DUPLICATE'), //TBD localize
                subTitle: Localization().getStringEx('panel.event2.create.button.duplicate.description', 'Create duplicate of this event'), //TBD localize
                progress: _duplicating,
                onTap: _onSettingDuplicateEvent,),
              _ButtonWidget(
                title: Localization().getStringEx('panel.event2.create.button.custom_notifications.title', 'CUSTOM NOTIFICATIONS'), //TBD localize
                subTitle: Localization().getStringEx('panel.event2.create.button.custom_notifications.description', 'Create and schedule up to two custom Illinois app event notifications.'), //TBD localize
                onTap: _onCustomNotifications),
              Visibility(visible: _showSuperEvent,
                child:_ButtonWidget(
                  title: 'SUPER EVENT',
                  subTitle: 'Manage this event as a multi-part “super event” by linking one or more of your other events as sub-events (e.g., sessions in a conference, performances in a festival, etc.). The super event will display all related events as one group of events in the Illinois app.',
                  onTap: _onSuperEvent)),
              Visibility(visible: _isCsvAvailable,
                child: _ButtonWidget(
                  title: 'DOWNLOAD REGISTRANTS .csv',
                  onTap: _onDownloadRegistrants)
              ),
              Visibility(visible: _isCsvAvailable,
                child: _ButtonWidget(
                    title: 'UPLOAD REGISTRANTS .csv',
                    onTap: _onUploadRegistrants),
              ),
              Visibility(visible: _isCsvAvailable,
                child: _ButtonWidget(
                      title: 'DOWNLOAD ATTENDANCE .csv',
                      onTap: _onDownloadAttendance),
              ),
              Visibility(visible: _isCsvAvailable,
                child: _ButtonWidget(
                    title: 'UPLOAD ATTENDANCE .csv',
                    onTap: _onUploadAttendance),
              ),
              Visibility(visible: (_isCsvAvailable && _hasSurvey),
                child: _ButtonWidget(
                    title: 'DOWNLOAD SURVEY RESULTS .csv',
                    onTap: _onDownloadSurveyResults,
                    progress: _loadingSurveyResponses),
              )
          ]),
        )
    );

  void _onCustomNotifications() {
    Analytics().logSelect(target: "Custom Notifications");

    Navigator.push<List<Event2NotificationSetting>?>(context, CupertinoPageRoute(builder: (context) => Event2SetupNotificationsPanel(
      event: _event,
      eventName: _event?.name,
      eventHasInternalRegistration: (_event?.registrationDetails?.type == Event2RegistrationType.internal),
      eventStartDateTimeUtc: _event?.startTimeUtc,
      isGroupEvent: widget.event?.isGroupEvent,
    )));
  }

  void _onSuperEvent() async {
    Analytics().logSelect(target: "Super Event");
    //We can skip passing supEvents, they will be loaded in the panel. This is designed to pass during create/edit.
    List<Event2>? subEvents; /*= (await Events2().loadEvents(
        Events2Query(grouping:  _event?.linkedEventsGroupingQuery)))?.events;*/
    Navigator.push(context,  CupertinoPageRoute(builder: (context) => Event2SetupSuperEventPanel(event: _event, subEvents: subEvents)));
  }

  //TBD: DD - localize
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
    final String defaultEmptyValue = '---';
    String eventName = StringUtils.ensureNotEmpty(widget.event?.name, defaultValue: defaultEmptyValue);
    String eventStartDate = StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(widget.event?.startTimeUtc?.toLocalTZ(), format: 'yyyy-MM-dd'), defaultValue: defaultEmptyValue);
    String eventStartTime = StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(widget.event?.startTimeUtc?.toLocalTZ(), format: 'HH:mm'), defaultValue: defaultEmptyValue);
    List<List<dynamic>> rows = <List<dynamic>>[];

    for (String netId in eventRegistrantNetIds) {
      Event2Account? account = hasAccounts ? accounts!.firstWhereOrNull((account) => (account.netId == netId)) : null;
      rows.add([eventName, eventStartDate, eventStartTime, StringUtils.ensureNotEmpty(account?.uin, defaultValue: defaultEmptyValue), netId, StringUtils.ensureNotEmpty(account?.firstName, defaultValue: defaultEmptyValue), StringUtils.ensureNotEmpty(account?.lastName, defaultValue: defaultEmptyValue)]);
    }

    String? dateExported = AppDateTime().formatDateTime(DateTime.now(), format: 'yyyy-MM-dd-HH-mm');
    String fileName = 'event_registrants_$dateExported.csv';
    AppFile.exportCsv(rows: rows, fileName: fileName).then((_) {
      setStateIfMounted(() {
        _downloadingRegistrants = false;
      });
    });
  }

  void _onUploadRegistrants() {
    Analytics().logSelect(target: "Upload Registrants");
   AppToast.showMessage("TBD");
  }

  void _onDownloadAttendance() {
    Analytics().logSelect(target: "Download Attendance");
    AppToast.showMessage("TBD");
  }

  void _onUploadAttendance() {
    Analytics().logSelect(target: "Upload Attendance");
    AppToast.showMessage("TBD");
  }

  void _onDownloadSurveyResults() async {
    Analytics().logSelect(target: "Download Survey Results");
    String? surveyId = widget.surveyId;
    if (StringUtils.isEmpty(surveyId)) {
      AppAlert.showDialogResult(context,
          Localization().getStringEx('panel.event2.detail.admin_settings.survey.missing.msg', 'There is no survey for this event.'));
      return;
    }
    setStateIfMounted(() {
      _loadingSurveyResponses = true;
    });
    List<SurveyResponse>? responses = await Surveys().loadAllSurveyResponses(surveyId!);
    if (CollectionUtils.isEmpty(responses)) {
      setStateIfMounted(() {
        _loadingSurveyResponses = false;
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
    final String defaultEmptyValue = '---';
    String eventName = StringUtils.ensureNotEmpty(widget.event?.name, defaultValue: defaultEmptyValue);
    String eventStartDate = StringUtils.ensureNotEmpty(
        AppDateTime().formatDateTime(widget.event?.startTimeUtc?.toLocalTZ(), format: 'yyyy-MM-dd'),
        defaultValue: defaultEmptyValue);
    String eventStartTime = StringUtils.ensureNotEmpty(
        AppDateTime().formatDateTime(widget.event?.startTimeUtc?.toLocalTZ(), format: 'HH:mm'),
        defaultValue: defaultEmptyValue);
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
          rows.add([
            eventName,
            eventStartDate,
            eventStartTime,
            StringUtils.ensureNotEmpty(account?.uin, defaultValue: defaultEmptyValue),
            StringUtils.ensureNotEmpty(account?.netId, defaultValue: defaultEmptyValue),
            StringUtils.ensureNotEmpty(account?.firstName, defaultValue: defaultEmptyValue),
            StringUtils.ensureNotEmpty(account?.lastName, defaultValue: defaultEmptyValue),
            question,
            answer
          ]);
        }
      }
      String? dateExported = AppDateTime().formatDateTime(DateTime.now(), format: 'yyyy-MM-dd-HH-mm');
      String fileName = 'event_survey_results_$dateExported.csv';
      AppFile.exportCsv(rows: rows, fileName: fileName).then((_) {
        setStateIfMounted(() {
          _loadingSurveyResponses = false;
        });
      });
    }
  }

  void _onSettingDuplicateEvent() {
    Analytics().logSelect(target: "Duplicate event");

    if (_event != null) {
      Event2Popup.showPrompt(context,
        title: Localization().getStringEx('', 'Duplicate'),
        message: Localization().getStringEx('', 'Are you sure you want to duplicate event ${_event?.name}?'),
      ).then((bool? result) async {
        if (result == true) {
          setStateIfMounted(() {_duplicating = true;});
          Events2().duplicateEvent(_event).then((result) {
            if(result.successful){
              Event2Popup.showMessage(context, message: "Successfully duplicated Event");
            } else {
              Event2Popup.showErrorResult(context, result.error ?? "Error occurred");
            }
          }).whenComplete(() =>
              setStateIfMounted((){_duplicating = false;}));
          // Events2ListResult? subEventsLoad = await Events2().loadEvents(Events2Query(groupings: _event?.linkedEventsGroupingQuery));
          //
          // // TBD  // 1. Acknowledge Event Admins
          // Events2().createEvent(_event!.duplicate).then((createdEvent) async {
          //   if (createdEvent is Event2) {
          //     if(CollectionUtils.isEmpty(subEventsLoad?.events)){
          //       Navigator.pop(context);
          //       Event2Popup.showMessage(context, message: "Successfully duplicated Event");
          //       setStateIfMounted((){_duplicating = false;});
          //       // return;
          //     }
          //
          //     //Duplicate sub events
          //    Event2SuperEventResult<int> updateResult = await  Event2SuperEventsController.multiUpload(
          //         events: Event2SuperEventsController.applyCollectionChange(
          //             collection: subEventsLoad?.events,
          //             change: (subEvent) {
          //               Event2Grouping subGrouping = subEvent.grouping?.copyWith(superEventId:  createdEvent.id) ?? Event2Grouping.superEvent(createdEvent.id);
          //               return subEvent.duplicateWith(grouping: subGrouping);}),
          //         uploadAPI: Events2().createEvent);
          //
          //     if(updateResult.successful){
          //       Event2Popup.showMessage(context, message: "Successfully duplicated Super event and ${updateResult.data} sub events");
          //     } else {
          //       Event2Popup.showErrorResult(context, updateResult.error);
          //     }
          //     setStateIfMounted((){_duplicating = false;});
          //   } else {
          //     Event2Popup.showErrorResult(context, createdEvent);
          //     setStateIfMounted((){_duplicating = false;});
          //   }
          // });
        }
      });
    }
  }

  Event2? get _event => widget.event;

  bool get _showSuperEvent => widget.event?.isRecurring != true;

  bool get _isCsvAvailable => PlatformUtils.isWeb;

  bool get _hasSurvey => StringUtils.isNotEmpty(widget.surveyId);
}

class _ButtonWidget extends StatelessWidget{
  final String? title;
  final String? subTitle;
  final bool progress;
  final Function? onTap;

  const _ButtonWidget({this.title, this.subTitle, this.onTap, this.progress = false});

  @override
  Widget build(BuildContext context) {
    return _buildWidget();
  }

  // Widget _buildWidget() => Event2CreatePanel.buildButtonSectionWidget(
  //   heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
  //       title: title?? "",
  //       subTitle: subTitle,
  //       onTap: () => onTap?.call()
  //   ),
  // );

Widget _buildWidget() => Event2CreatePanel.buildButtonSectionWidget(
  heading: RibbonButton(
        label: title?? "",
        description: subTitle,
        progress: progress,
        onTap: () => onTap?.call(),
        borderRadius: BorderRadius.all(Radius.circular(15)),
        progressSize: 18,
      ));
}