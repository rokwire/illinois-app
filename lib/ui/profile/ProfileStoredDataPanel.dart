
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/CustomCourses.dart';
import 'package:illinois/service/Identity.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileStoredDataPanel extends StatefulWidget {
  static const String notifyRefresh  = "edu.illinois.rokwire.home.refresh";

  @override
  State<StatefulWidget> createState() => _ProfileStoredDataPanelState();
}

typedef _StoredDataProvider = Future<String?> Function();

enum _StoredDataType {
  // rokwire.illinois.edu/core
  coreAccount,

  // rokwire.illinois.edu/notifications
  notificationsAccount,

  // rokwire.illinois.edu/lms
  canvasAccount,
  customCourses,
  customCoursesHistory,

  // rokwire.illinois.edu/calendar
  myEvents,
  participatedEvents, // TBD: registered or attended events

  // rokwire.illinois.edu/gr
  myGroups,
  myGroupsPosts, // TBD: all my posts and messages in all groups
  myGroupsStats,

  // rokwire.illinois.edu/polls
  myPools,
  participatedPolls,

  // rokwire.illinois.edu/surveys
  mySurveys,
  participatedSurveys,

  // rokwire.illinois.edu/identity
  myStudentId,
  myStudentClassification,
  myMobileCredentials,

  // rokwire.illinois.edu/appointments
  myAppointments,

  // icard.uillinois.edu
  iCard,

  // housing.illinois.edu
  studentSummary,
  illiniCashBalance,
  illiniCashTransactions,
  mealPlanTransactions,
  cafeCreditTransactions,
}

class _ProfileStoredDataPanelState extends State<ProfileStoredDataPanel> {

  final StreamController<String> _updateController = StreamController.broadcast();
  final Map<_StoredDataType, GlobalKey> _storedDataKeys = <_StoredDataType, GlobalKey>{};

  List<UserCourse>? _userCourses;
  Set<Completer<Response?>>? _userCoursesListeners;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(
      title: Localization().getStringEx("panel.profile.stored_data.header.title", "My Stored Data"),
      actions: [HeaderBarActionTextButton(
        title: Localization().getStringEx("panel.profile.stored_data.button.copy_all.title", "Copy All"),
        onTap: _onCopyAll,
      )],
    ),
    body: _scaffoldContent,
    backgroundColor: Styles().colors.background,
  );

  Widget get _scaffoldContent => SafeArea(child:
    RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
        _panelContent,
      )
    ),
  );

  Widget get _panelContent => Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // rokwire.illinois.edu/core
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.coreAccount] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.core_account.title', "Core Account"),
        dataProvider: _provideCoreAccountJson,
        updateController: _updateController,
      ),

      // rokwire.illinois.edu/notifications
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.notificationsAccount] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.notifications_user.title', "Notifications Account"),
        dataProvider: _provideNotificationsAccountJson,
        updateController: _updateController,
      ),

      // rokwire.illinois.edu/lms
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.canvasAccount] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.canvas_user.title', "Canvas Account"),
        dataProvider: _provideCanvasAccountJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.customCourses] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.custom_courses.title', "My Canvas Courses"),
        dataProvider: _provideCustomCoursesJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.customCoursesHistory] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.custom_courses_history.title', "My Canvas Courses Content"),
        dataProvider: _provideCustomCoursesHistoryJson,
        updateController: _updateController,
      ),

      // rokwire.illinois.edu/calendar
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.myEvents] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.my_events.title', "My Events"),
        dataProvider: _provideMyEventsJson,
        updateController: _updateController,
      ),

      // rokwire.illinois.edu/gr
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.myGroups] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.my_groups.title', "My Groups"),
        dataProvider: _provideMyGroupsJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.myGroupsStats] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.my_groups_stats.title', "My Groups Stats"),
        dataProvider: _provideMyGroupsStatsJson,
        updateController: _updateController,
      ),

      // rokwire.illinois.edu/polls
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.myPools] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.my_polls.title', "My Polls"),
        dataProvider: _provideMyPollsJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.participatedPolls] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.participated_polls.title', "Participated Polls"),
        dataProvider: _provideParticipatedPollsJson,
        updateController: _updateController,
      ),

      // rokwire.illinois.edu/surveys
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.mySurveys] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.my_surveys.title', "My Surveys"),
        dataProvider: _provideMySurveysJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.participatedSurveys] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.participated_surveys.title', "Participated Surveys"),
        dataProvider: _provideParticipatedSurveysJson,
        updateController: _updateController,
      ),

      // rokwire.illinois.edu/identity
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.myStudentId] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.my_student_id.title', "My Student ID"),
        dataProvider: _provideMyStudentIdJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.myStudentClassification] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.my_student_classification.title', "My Student Classification"),
        dataProvider: _provideMyStudentClassificationJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.myMobileCredentials] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.my_mobile_credentials.title', "My Mobile Credentials"),
        dataProvider: _provideMyMobileCredentialsJson,
        updateController: _updateController,
      ),

      // rokwire.illinois.edu/appointments
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.myAppointments] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.my_appointments.title', "My Appointments"),
        dataProvider: _provideMyAppointmentsJson,
        updateController: _updateController,
      ),

      // icard.uillinois.edu
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.iCard] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.i_card.title', "iCard"),
        dataProvider: _provideICardJson,
        updateController: _updateController,
      ),

      // housing.illinois.edu
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.studentSummary] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.student_summary.title', "Student Summary"),
        dataProvider: _provideStudentSummaryJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.illiniCashBalance] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.illini_cash_balance.title', "Illini Cash Balance"),
        dataProvider: _provideIlliniCashBalanceJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.illiniCashTransactions] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.illini_cash_transactions.title', "Illini Cash Transactions"),
        hint: Localization().getStringEx('panel.profile.stored_data.label.this_year', " (this year)"),
        dataProvider: _provideIlliniCashTransactionsJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.mealPlanTransactions] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.meal_plan_transactions.title', "Meal Plan Transactions"),
        hint: Localization().getStringEx('panel.profile.stored_data.label.this_year', " (this year)"),
        dataProvider: _provideMealPlanTransactionsJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.cafeCreditTransactions] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.cafe_credit_transactions.title', "Cafe Credit Transactions"),
        hint: Localization().getStringEx('panel.profile.stored_data.label.this_year', " (this year)"),
        dataProvider: _provideCafeCreditTransactionsJson,
        updateController: _updateController,
      ),
    ]),
  );

  // rokwire.illinois.edu/core
  Future<String?> _provideCoreAccountJson() async          => _provideResponseData(await Auth2().loadAccountResponse());

  // rokwire.illinois.edu/notifications
  Future<String?> _provideNotificationsAccountJson() async => _provideResponseData(await Inbox().loadUserInfoResponse());

  // rokwire.illinois.edu/lms
  Future<String?> _provideCanvasAccountJson() async        => _provideResponseData(await Canvas().loadSelfUserResponse());

  //Future<String?> _provideCustomCoursesJson() async        => _provideResponseData(await CustomCourses().loadUserCoursesResponse());
  Future<String?> _provideCustomCoursesJson() async {
    Response? response;
    if (_userCoursesListeners != null) {
      Completer<Response?> completer = Completer<Response?>();
      _userCoursesListeners?.add(completer);
      response = await completer.future;
    }
    else {
      Set<Completer<Response?>> completers = <Completer<Response?>>{};
      _userCoursesListeners = completers;
      response = await CustomCourses().loadUserCoursesResponse();
      _userCourses = _buildUserCourses(response);
      _userCoursesListeners = null;
      for (Completer<Response?> completer in completers) {
        completer.complete();
      }
    }
    return _provideResponseData(response);
  }

  //Future<String?> _provideCustomCoursesHistoryJson() async => _provideResponseData(await CustomCourses().loadUserContentHistoryResponse());
  Future<String?> _provideCustomCoursesHistoryJson() async {
    if (_userCoursesListeners != null) {
      Completer<Response?> completer = Completer<Response?>();
      _userCoursesListeners?.add(completer);
      await completer.future;
    }
    Response? response = await CustomCourses().loadUserContentHistoryResponse(ids: _userCoursesIds);
    return _provideResponseData(response);
  }

  List<String> get _userCoursesIds => List<String>.from(_userCourses?.map((UserCourse course) => course.id) ?? []);

  List<UserCourse>? _buildUserCourses(Response? response) {
    List<dynamic>? userCoursesJson = (response?.statusCode == 200) ? JsonUtils.decodeList(response?.body) : null;
    return (userCoursesJson != null) ? UserCourse.listFromJson(userCoursesJson) : null;
  }

  // rokwire.illinois.edu/calendar
  Future<String?> _provideMyEventsJson() async             => _provideResponseData(await Events2().loadEventsResponse(Events2Query(
    types: { Event2TypeFilter.admin },
    timeFilter: null,
  )));

  // rokwire.illinois.edu/gr
  Future<String?> _provideMyGroupsJson() async             => _provideResponseData(await Groups().loadUserGroupsResponse());
  Future<String?> _provideMyGroupsStatsJson() async        => _provideResponseData(await Groups().loadUserStatsResponse());

  // rokwire.illinois.edu/polls
  Future<String?> _provideMyPollsJson() async              => _provideResponseData(await Polls().getPollsResponse(PollFilter(
    myPolls: true
  )));
  Future<String?> _provideParticipatedPollsJson() async    => _provideResponseData(await Polls().getPollsResponse(PollFilter(
      respondedPolls: true
  )));

  // rokwire.illinois.edu/surveys
  Future<String?> _provideMySurveysJson() async            => _provideResponseData(await Surveys().loadCreatorSurveysResponse());
  Future<String?> _provideParticipatedSurveysJson() async  => _provideResponseData(await Surveys().loadUserSurveyResponsesResponse());

  // rokwire.illinois.edu/identity
  Future<String?> _provideMyStudentIdJson() async          => _provideResponseData(await Identity().loadStudentIdResponse());
  Future<String?> _provideMyStudentClassificationJson() async => _provideResponseData(await Identity().loadStudentClassificationResponse());
  Future<String?> _provideMyMobileCredentialsJson() async  => _provideResponseData(await Identity().loadMobileCredentialResponse());

  // rokwire.illinois.edu/appointments
  Future<String?> _provideMyAppointmentsJson() async       => _provideResponseData(await Appointments().loadAppointmentseResponse());

  // icard.uillinois.edu
  Future<String?> _provideICardJson() async                => _provideResponseData(await Auth2().loadAuthCardResponse());

  // housing.illinois.edu
  Future<String?> _provideStudentSummaryJson() async       => _provideResponseData(await _provideStudentSummaryResponse());
  Future<String?> _provideIlliniCashBalanceJson() async    => _provideResponseData(await IlliniCash().loadBalanceRequest());
  Future<String?> _provideIlliniCashTransactionsJson() async => _provideResponseData(await IlliniCash().loadTransactionHistoryResponse(DateTime(DateTime.now().year), DateTime.now()));
  Future<String?> _provideMealPlanTransactionsJson() async => _provideResponseData(await IlliniCash().loadMealPlanTransactionHistoryResponse(DateTime(DateTime.now().year), DateTime.now()));
  Future<String?> _provideCafeCreditTransactionsJson() async => _provideResponseData(await IlliniCash().loadCafeCreditTransactionHistoryResponse(DateTime(DateTime.now().year), DateTime.now()));

  Future<Response?> _provideStudentSummaryResponse() async {
    dynamic result = await IlliniCash().loadStudentSummaryResponse();
    return (result is Response) ? result : null;
  }
  
  // Implementation

  String? _provideResponseData(Response? response) => ((response != null) && (response.statusCode >= 200) && (response.statusCode <= 301)) ?
    (JsonUtils.encode(JsonUtils.decode(response.body), prettify: true) ?? response.body) : null;

  Future<void> _onRefresh() async {
    _updateController.add(ProfileStoredDataPanel.notifyRefresh);
  }

  void _onCopyAll() {
    Analytics().logSelect(target: 'Copy All');

    String combinedJson = "";
    for (_StoredDataType dataType in _StoredDataType.values) {
      GlobalKey? dataTypeKey = _storedDataKeys[dataType];
      State<StatefulWidget>? state = dataTypeKey?.currentState;
      _ProfileStoredDataWidgetState? dataTypeState = (state is _ProfileStoredDataWidgetState) ? state : null;
      if (dataTypeState != null) {
        if (dataTypeState.widget.title != null) {
          combinedJson += '\n// ${dataTypeState.widget.title}\n';
        }
        combinedJson += dataTypeState._providedData ?? 'NA\n';
      }
    }
    Clipboard.setData(ClipboardData(text: combinedJson)).then((_) {
      AppToast.showMessage(Localization().getStringEx('panel.profile.stored_data.copied_all.succeeded.message', 'Copied everything to your clipboard!'));
    });
  }
}


class _ProfileStoredDataWidget extends StatefulWidget {
  final String? title;
  final String? hint;
  final _StoredDataProvider dataProvider;
  final StreamController<String>? updateController;
  final EdgeInsetsGeometry margin;

  _ProfileStoredDataWidget({
    // ignore: unused_element
    super.key,
    this.title, this.hint,
    required this.dataProvider,
    this.updateController,
    // ignore: unused_element
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
  });

  @override
  State<StatefulWidget> createState() => _ProfileStoredDataWidgetState();
}

class _ProfileStoredDataWidgetState extends State<_ProfileStoredDataWidget> {
  TextEditingController _textController = TextEditingController();
  bool _providingData = false;
  String? _providedData;

  @override
  void initState() {

    widget.updateController?.stream.listen((String command) {
      if (command == ProfileStoredDataPanel.notifyRefresh) {
        _refresh();
      }
    });

    _init();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? headingWidget = _buildHeadingWidget();
    return Padding(padding: widget.margin, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (headingWidget != null)
          Padding(padding: EdgeInsets.only(bottom: 4), child: headingWidget,),
        Stack(children: [
          TextField(
            maxLines: 5,
            readOnly: true,
            controller: _textController,
            decoration: InputDecoration(
              border: _textBorder,
              focusedBorder: _textBorder,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            ),
            style: (_providedData != null) ? Styles().textStyles.getTextStyle('widget.input_field.text.regular') : Styles().textStyles.getTextStyle('widget.item.small.thin.italic'),
          ),

          Visibility(visible: _providingData, child:
            Positioned.fill(child:
              Align(alignment: Alignment.center, child:
                SizedBox(height: 24, width: 24, child:
                  CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3),
                ),
              ),
            ),
          ),

          Visibility(visible: !_providingData && StringUtils.isNotEmpty(_providedData), child:
            Positioned.fill(child:
              Align(alignment: Alignment.topRight, child:
                InkWell(onTap: _onCopy, child:
                  Padding(padding: EdgeInsets.all(12), child:
                    Styles().images.getImage('copy', excludeFromSemantics: true),
                  ),
                ),
              ),
            ),
          ),

        ],),
      ]),
    );
  }

  Widget? _buildHeadingWidget() {
    List<InlineSpan> spans = <InlineSpan>[
      if (StringUtils.isNotEmpty(widget.title))
        TextSpan(text: widget.title, style: Styles().textStyles.getTextStyle('widget.title.small.fat')),
      if (StringUtils.isNotEmpty(widget.hint))
        TextSpan(text: widget.hint, style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat.light')),
    ];
    return spans.isNotEmpty ? RichText(
      text: TextSpan(style: Styles().textStyles.getTextStyle('widget.title.small.fat'), children: spans)
    ) : null;
  }

  InputBorder get _textBorder =>
    OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0));

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _providedData = null;
      });
      _textController.text = '';
      await _init();
    }
  }

  Future<void> _init() async {
    setState(() {
      _providingData = true;
    });
    widget.dataProvider().then((String? data) {
      if (mounted) {
        setState(() {
          _providedData = data;
          _providingData = false;
        });
        _textController.text = data ?? Localization().getStringEx('widget.profile.stored_data.retrieve.failed.message', 'Failed to retrieve data');
      }
    });
  }

  void _onCopy() {
    Analytics().logSelect(target: 'Copy All');
    if (_providedData != null) {
      Clipboard.setData(ClipboardData(text: _providedData ?? '')).then((_) {
        AppToast.showMessage(Localization().getStringEx('widget.profile.stored_data.copied.succeeded.message', 'Copied to your clipboard!'));
      });
    }
  }
}