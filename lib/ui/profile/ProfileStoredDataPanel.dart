
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Canvas.dart';
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

  // icard.uillinois.edu
  iCard,

  // housing.illinois.edu
  studentSummary,
}

class _ProfileStoredDataPanelState extends State<ProfileStoredDataPanel> {

  final StreamController<String> _updateController = StreamController.broadcast();
  final Map<_StoredDataType, GlobalKey> _storedDataKeys = <_StoredDataType, GlobalKey>{};

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
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.coreAccount] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.core_account.title', "Core Account"),
        dataProvider: _provideCoreAccountJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.notificationsAccount] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.notifications_user.title', "Notifications Account"),
        dataProvider: _provideNotificationsAccountJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.canvasAccount] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.canvas_user.title', "Canvas Account"),
        dataProvider: _provideCanvasAccountJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.myEvents] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.my_events.title', "My Events"),
        dataProvider: _provideMyEventsJson,
        updateController: _updateController,
      ),
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
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.iCard] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.i_card.title', "iCard"),
        dataProvider: _provideICardJson,
        updateController: _updateController,
      ),
      _ProfileStoredDataWidget(
        key: _storedDataKeys[_StoredDataType.studentSummary] ??= GlobalKey(),
        title: Localization().getStringEx('panel.profile.stored_data.student_summary.title', "Student Summary"),
        dataProvider: _provideStudentSummaryJson,
        updateController: _updateController,
      ),
    ]),
  );

  Future<String?> _provideCoreAccountJson() async =>
    _provideResponseData(await Auth2().loadAccountResponse());

  Future<String?> _provideNotificationsAccountJson() async =>
    _provideResponseData(await Inbox().loadUserInfoResponse());

  Future<String?> _provideCanvasAccountJson() async =>
    _provideResponseData(await Canvas().loadSelfUserResponse());

  Future<String?> _provideMyEventsJson() async =>
    _provideResponseData(await _provideMyEventsResponse());

  Future<Response?> _provideMyEventsResponse() => Events2().loadEventsResponse(Events2Query(
    types: { Event2TypeFilter.admin },
    timeFilter: null,
  ));

  Future<String?> _provideMyGroupsJson() async =>
    _provideResponseData(await Groups().loadUserGroupsResponse());

  Future<String?> _provideMyGroupsStatsJson() async =>
    _provideResponseData(await Groups().loadUserStatsResponse());

  Future<String?> _provideMyPollsJson() async =>
    _provideResponseData(await _provideMyPollsResponse());

  Future<Response?> _provideMyPollsResponse() => Polls().getPollsResponse(PollFilter(
    myPolls: true
  ));

  Future<String?> _provideParticipatedPollsJson() async =>
    _provideResponseData(await _provideParticipatedPollsResponse());

  Future<Response?> _provideParticipatedPollsResponse() => Polls().getPollsResponse(PollFilter(
      respondedPolls: true
  ));

  Future<String?> _provideICardJson() async =>
    _provideResponseData(await Auth2().loadAuthCardResponse());

  Future<String?> _provideStudentSummaryJson() async =>
    _provideResponseData(await _provideStudentSummaryResponse());

  Future<Response?> _provideStudentSummaryResponse() async {
    dynamic result = await IlliniCash().loadStudentSummaryResponse();
    return (result is Response) ? result : null;
  }

  String? _provideResponseData(Response? response) => ((response != null) && (response.statusCode >= 200) && (response.statusCode <= 301)) ?
    JsonUtils.encode(JsonUtils.decode(response.body), prettify: true) : null;

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
  final _StoredDataProvider dataProvider;
  final StreamController<String>? updateController;
  final EdgeInsetsGeometry margin;

  _ProfileStoredDataWidget({
    // ignore: unused_element
    super.key,
    this.title,
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
  Widget build(BuildContext context) => Padding(padding: widget.margin, child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      if (StringUtils.isNotEmpty(widget.title))
        Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text(widget.title ?? '', style: Styles().textStyles.getTextStyle('widget.title.small.fat'),),
        ),
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