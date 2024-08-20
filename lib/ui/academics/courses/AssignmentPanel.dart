import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:neom/model/CustomCourses.dart';
import 'package:neom/service/AppDateTime.dart';
import 'package:neom/service/CustomCourses.dart';
import 'package:neom/service/SpeechToText.dart';
import 'package:neom/ui/academics/courses/EssentialSkillsCoachWidgets.dart';
import 'package:neom/ui/academics/courses/ResourcesPanel.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class AssignmentPanel extends StatefulWidget {
  final Content content;
  final UserContentReference contentReference;
  final Color? color;
  final Color? colorAccent;
  final List<Content>? helpContent;
  final bool preview;
  final bool current;
  final DateTime? courseDayStart;
  final DateTime? courseDayFinalNotification;

  final Widget? moduleIcon;
  final String moduleName;
  final int unitNumber;
  final String unitName;
  final int activityNumber;

  AssignmentPanel({required this.content, required this.contentReference, required this.color, required this.colorAccent,
    this.helpContent, required this.preview, required this.current, this.courseDayStart, this.courseDayFinalNotification,
    this.moduleIcon, required this.moduleName, required this.unitNumber, required this.unitName, required this.activityNumber});

  @override
  State<AssignmentPanel> createState() => _AssignmentPanelState();
}

class _AssignmentPanelState extends State<AssignmentPanel> implements NotificationsListener {

  late Content _content;
  List<Content>? _helpContent;
  Color? _color;
  Color? _colorAccent;
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _initialResponse;
  List<UserContent>? _userResponseHistory;
  int _viewingHistoryIndex = 0;

  bool _historyExpanded = false;
  bool _helpContentOpen = false;
  bool _listening = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      SpeechToText.notifyError,
    ]);

    _content = widget.content;
    _controller.text = userNotes ?? '';
    _color = widget.color;
    _colorAccent = widget.colorAccent;
    _helpContent = widget.helpContent;

    _loadAssignmentHistory();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _showCompletionOptions {
    bool isAfterFinalNotification = widget.courseDayStart == null && widget.courseDayFinalNotification == null && widget.courseDayStart!.isBefore(widget.courseDayFinalNotification!);
    return !widget.current || isComplete || isNotComplete || isAfterFinalNotification;
  }

  Map<String, dynamic>? get displayResponse => _userResponseHistory?[_viewingHistoryIndex].response;
  set displayResponse(Map<String, dynamic>? value){
    _userResponseHistory?[0].response = value;
  }

  bool get isComplete => displayResponse?[UserContent.completeKey] == true;
  bool get isNotComplete => displayResponse?[UserContent.completeKey] == false;
  set complete(bool? value) {
    displayResponse ??= {};
    displayResponse![UserContent.completeKey] = value;
  }

  bool get isGoodExperience => displayResponse?[UserContent.experienceKey] == UserContent.goodExperience;
  bool get isBadExperience => displayResponse?[UserContent.experienceKey] == UserContent.badExperience;
  set experience(String? value) {
    displayResponse ??= {};
    displayResponse![UserContent.experienceKey] = value;
  }

  String? get userNotes => displayResponse?[UserContent.notesKey].toString();
  set userNotes(String? value) {
    displayResponse ??= {};
    displayResponse![UserContent.notesKey] = value;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> helpContentWidgets = [];
    for (Content help in _helpContent ?? []) {
      helpContentWidgets.add(
        Padding(padding: EdgeInsets.only(top: 16.0),
          child: TextButton(
            child: Text("\u2022 ${help.name}: ${help.details}", style:Styles().textStyles.getTextStyle("widget.title.light.regular")),
            onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => ResourcesPanel(
              color: _color,
              initialReferenceType: help.reference?.type,
              unitNumber: widget.unitNumber,
              contentItems: _helpContent!,  //TODO: pass all unit resources here or only linked content for this task?
              unitName: widget.unitName,
              moduleIcon: widget.moduleIcon,
              moduleName: widget.moduleName,
            ))),
          ),
        )
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) => _saveProgress(didPop),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: HeaderBar(
          title: sprintf(Localization().getStringEx("panel.essential_skills_coach.assignment.header.title", "Unit %d Activity %d"), [widget.unitNumber, widget.activityNumber]),
          textStyle: Styles().textStyles.getTextStyle('header_bar'), onLeading: () => _saveProgress(false),
        ),
        body: Column(
          children: [
            EssentialSkillsCoachModuleHeader(icon: widget.moduleIcon, moduleName: widget.moduleName, backgroundColor: _color,),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: _buildAssignmentActivityWidgets(),
                      ),
                    ),
                  ),
                  if (_viewingHistoryIndex == 0 && !widget.preview)
                    Column(
                      children: [
                        Expanded(child: Container()),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: RoundedButton(
                            label: Localization().getStringEx('panel.essential_skills_coach.assignment.button.save.label', 'Save'),
                            textStyle: Styles().textStyles.getTextStyle("widget.title.light.regular.fat"),
                            backgroundColor: _color,
                            borderColor: _color,
                            onTap: () => _saveProgress(false)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (!widget.preview && helpContentWidgets.isNotEmpty)
              ExpansionPanelList(
                expandedHeaderPadding: EdgeInsets.zero,
                expandIconColor: Styles().colors.surface,
                expansionCallback: (i, isOpen) => setState(() => _helpContentOpen = isOpen),
                children: [
                  ExpansionPanel(
                    backgroundColor: _colorAccent,
                    isExpanded: _helpContentOpen,
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        iconColor: Styles().colors.surface,
                        title: Text(Localization().getStringEx('panel.essential_skills_coach.assignment.help.header.title', "Helpful Information"), style: Styles().textStyles.getTextStyle("widget.title.light.large.extra_fat"))
                      );
                    },
                    body: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: _color, thickness: 2.0),
                          ...helpContentWidgets
                        ],
                      ),
                    ),
                  )
                ],
              ),
          ],
        ),
        backgroundColor: Styles().colors.background,
      ),
    );
  }

  List<Widget> _buildAssignmentActivityWidgets(){
    List<Widget> assignmentWidgets = [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: html.Html(
            data: _content.name ?? "",
            style: {
              'body': html.Style.fromTextStyle(Styles().textStyles.getTextStyle("widget.detail.large.extra_fat") ??
                  TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20.0, color: Styles().colors.fillColorPrimary)),
            }
          )
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: html.Html(
            data: _content.details ?? "",
            style: {
              'body': html.Style.fromTextStyle(Styles().textStyles.getTextStyle("widget.detail.large") ??
                TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 20.0, color: Styles().colors.fillColorPrimary)),
            }
          )
        ),
      ),
    ];

    if (!widget.preview) {
      List<Widget> noteWidgets = [];
      if (isComplete) {
        noteWidgets.addAll([
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: html.Html(data: _content.styles?.strings?['experience_prompt'] ?? Localization().getStringEx('panel.essential_skills_coach.assignment.experience.selection.header', "How did it go?"),
              style: {
                'body': html.Style.fromTextStyle(Styles().textStyles.getTextStyle("widget.detail.regular") ??
                  TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16.0, color: Styles().colors.fillColorPrimary)),
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child:RoundedButton(
                    label: "",
                    textWidget: Icon(
                      Icons.thumb_up_alt_rounded,
                      color: Styles().colors.surface,
                      size: 25,
                    ),
                    backgroundColor: isGoodExperience ? _color : _colorAccent,
                    borderColor: _color,
                    onTap: _viewingHistoryIndex == 0 ? (){
                      setState(() {
                        experience = isGoodExperience ? null : UserContent.goodExperience;
                      });
                    } : null,
                  ),
                ),
                SizedBox(width: 8,),
                Expanded(
                    child:RoundedButton(
                      label: "",
                      textWidget: Icon(
                        Icons.thumb_down_alt_rounded,
                        color: Styles().colors.surface,
                        size: 25,
                      ),
                      backgroundColor: isBadExperience ? _color : _colorAccent,
                      borderColor: _color,
                      onTap: _viewingHistoryIndex == 0 ? () {
                        setState(() {
                          experience = isBadExperience ? null : UserContent.badExperience;
                        });
                      } : null,
                    )),
              ],
            ),
          ),
        ]);
      }

      String notesHeaderText = isComplete ? (_content.styles?.strings?['notes_complete_prompt'] ?? Localization().getStringEx('panel.essential_skills_coach.assignment.experience.good.notes.header.', "Describe your experience.")) :
      (isNotComplete ? (_content.styles?.strings?['notes_incomplete_prompt'] ?? Localization().getStringEx('panel.essential_skills_coach.assignment.experience.bad.notes.header.', "Why not? What got in your way?")) :
      (_content.styles?.strings?['notes_prompt'] ?? Localization().getStringEx('panel.essential_skills_coach.assignment.experience.notes.header.', "Notes")));
      noteWidgets.add(
          Padding(padding: EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: html.Html(
                      data: notesHeaderText,
                      style: {
                        'body': html.Style.fromTextStyle(Styles().textStyles.getTextStyle("widget.detail.small.fat") ??
                            TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 14.0, color: Styles().colors.fillColorPrimary)),
                      }
                  ),
                ),
                Visibility(
                  visible: SpeechToText().isEnabled,
                  child: _buildSpeechToTextButton(),
                )
              ],
            ),
          )
      );

      String completionResponseDay = AppDateTime().getDisplayDay(dateTimeUtc: widget.courseDayFinalNotification, includeAtSuffix: true)?.toLowerCase() ?? '';
      String completionResponseTime = AppDateTime().getDisplayTime(dateTimeUtc: widget.courseDayFinalNotification) ?? '';
      String completionResponseDateTime = 'later';
      if (completionResponseDay.isNotEmpty) {
        completionResponseDateTime = completionResponseDay;
        if (completionResponseTime.isNotEmpty) {
          completionResponseDateTime += ' $completionResponseTime';
        }
      }
      assignmentWidgets.addAll([
        Divider(color: _color, thickness: 2, indent: 8.0, endIndent: 8.0,),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: html.Html(
            data: _showCompletionOptions ?
              (_content.styles?.strings?['complete_prompt'] ??
                  Localization().getStringEx('panel.essential_skills_coach.assignment.completion.selection.header', "Did you complete this task?")) :
              sprintf(_content.styles?.strings?['check_later_message'] ??
                  Localization().getStringEx('panel.essential_skills_coach.assignment.completion.later.message', "Check back %s to tell us how it went."), [completionResponseDateTime]),
            style: {
              'body': html.Style.fromTextStyle(Styles().textStyles.getTextStyle("widget.detail.regular") ??
                  TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16.0, color: Styles().colors.fillColorPrimary)),
            },
          ),
        ),
        if (_showCompletionOptions)
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child:RoundedButton(
                      label: Localization().getStringEx('panel.essential_skills_coach.assignment.completion.button.yes.label', 'Yes'),
                      leftIconPadding: EdgeInsets.only(left: 16),
                      textStyle: Styles().textStyles.getTextStyle("widget.title.light.large.fat"),
                      backgroundColor: isComplete ? _color : _colorAccent,
                      borderColor: _color,
                      leftIcon: Icon(
                        Icons.check_rounded,
                        color: isComplete ? _colorAccent : _color,
                        size: 20,
                      ),
                      onTap: _viewingHistoryIndex == 0 && _initialResponse?[UserContent.completeKey] != true ? () {
                        setState(() {
                          complete = isComplete ? null : true;
                        });
                      } : null
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                    child:RoundedButton(
                      label: Localization().getStringEx('panel.essential_skills_coach.assignment.completion.button.no.label', 'No'),
                      leftIconPadding: EdgeInsets.only(left: 16),
                      textStyle: Styles().textStyles.getTextStyle("widget.title.light.large.fat"),
                      backgroundColor:  isNotComplete ?  _color : _colorAccent,
                      borderColor: _color,
                      leftIcon: Icon(
                        Icons.close_rounded,
                        color: isNotComplete ? _colorAccent : _color,
                        size: 20,
                      ),
                      onTap: _viewingHistoryIndex == 0 && _initialResponse?[UserContent.completeKey] != true ? (){
                        setState(() {
                          complete = isNotComplete ? null : false;
                          experience = null;
                        });
                      } : null,
                    )),
              ],
            ),
          ),
        ...noteWidgets,
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child:TextField(
            controller: _controller,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              hintStyle: TextStyle(color: Colors.grey[800]),
              fillColor: Styles().colors.surface,
            ),
          )
        ),
        Padding(padding: const EdgeInsets.only(bottom: 80),
          child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(Localization().getStringEx("panel.essential_skills_coach.assignment.history.header", "History"), style: Styles().textStyles.getTextStyle("widget.detail.small.fat")),
            iconColor: Styles().colors.fillColorPrimary,
            collapsedIconColor: Styles().colors.fillColorPrimary,
            children: _buildTaskHistoryWidgets(),
            onExpansionChanged: (open) {
              _historyExpanded = open;
            },
            initiallyExpanded: _historyExpanded,
          ))
        )
      ]);
    }

    return assignmentWidgets;
  }

  List<Widget> _buildTaskHistoryWidgets(){
    List<Widget> taskWidgets = [];

    for(int i = 0; i < (_userResponseHistory?.length ?? 0); i++) {
      UserContent historyItem = _userResponseHistory![i];
      DateTime? displayTime = historyItem.dateUpdated ?? historyItem.dateCreated;
      bool isSelected = (i == _viewingHistoryIndex);
      String label = '';
      if (widget.current && !_showCompletionOptions) {
        label = Localization().getStringEx("panel.essential_skills_coach.assignment.history.pending.label", "Pending Response");
      } else if (displayTime == null) {
        label = Localization().getStringEx("panel.essential_skills_coach.assignment.history.unsaved.label", "Unsaved Response");
      } else if (historyItem.isComplete) {
        label = Localization().getStringEx("panel.essential_skills_coach.assignment.history.complete.label", "Task Completed");
      } else {
        label = Localization().getStringEx("panel.essential_skills_coach.assignment.history.incomplete.label", "Task Not Completed");
      }
      taskWidgets.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton(
              onPressed: () => _onTapViewHistoryResponse(i),
              child: Text(
                label,
                style: Styles().textStyles.getTextStyle(isSelected ? "widget.detail.regular.extra_fat" : "widget.detail.regular")?.apply(decoration: TextDecoration.underline),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              displayTime == null ? Localization().getStringEx("panel.essential_skills_coach.assignment.history.timestamp.now.label", "Now") : '${AppDateTime().getDisplayDay(dateTimeUtc: displayTime, includeAtSuffix: true)} ${AppDateTime().getDisplayTime(dateTimeUtc: displayTime)}',
              style: Styles().textStyles.getTextStyle(isSelected ? "widget.detail.regular.extra_fat" : "widget.detail.regular"),
            ),
          ),
        ],
      ));
    }
    return taskWidgets;
  }

  Widget _buildSpeechToTextButton() => Material(
    color: Styles().colors.background,
    child: IconButton(
      icon: Styles().images.getImage(_listening ? "skills-speech-pause" :"skills-speech-mic") ?? Container(),
      color: _color,
      onPressed: () {
        if (_listening) {
          _stopListening();
        } else {
          _startListening();
        }
      },
    ),
  );

  void _onTapViewHistoryResponse(int index) {
    if (_viewingHistoryIndex != index) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.linear);
      });
    }
    setState(() {
      _viewingHistoryIndex = index;
      _controller.text = userNotes ?? '';
    });
  }

  Future<void> _loadAssignmentHistory() async {
    List<UserContent>? history = CollectionUtils.isNotEmpty(widget.contentReference.ids) ? await CustomCourses().loadUserContentHistory(ids: widget.contentReference.ids) : [];
    if (history != null) {
      history.sort(((a, b) => b.dateCreated?.compareTo(a.dateCreated ?? DateTime.now()) ?? 0));
      for (int i = 0; i < history.length; i++) {
        UserContent historyItem = history[i];
        if (widget.courseDayStart != null && !(historyItem.dateCreated?.isBefore(widget.courseDayStart!.subtract(Duration(days: 1))) ?? true)) {
          _initialResponse = historyItem.response != null ? Map.from(historyItem.response!) : null; // copy the current response so we can check if the user changed it when saving
          break;
        }
      }

      if (_initialResponse == null) {
        history.insert(0, UserContent()); // insert new UserContent with an empty response at the "top" of the history to act as the new potential response
      }

      setStateIfMounted(() {
        _userResponseHistory = history;
        _controller.text = userNotes ?? '';
      });
    }
  }

  void _saveProgress(bool didPop) async {
    if (userNotes != null || _controller.text.isNotEmpty) {
      userNotes = _controller.text;
    }
    if (!didPop) {
      Navigator.pop(context, _viewingHistoryIndex != 0 || DeepCollectionEquality().equals(displayResponse, _initialResponse) ? null : displayResponse);
    }
  }

  void _startListening() {
    SpeechToText().listen(onResult: _onSpeechResult);
    setState(() {
      _listening = true;
    });
  }

  void _stopListening() async {
    await SpeechToText().stopListening();
    setState(() {
      _listening = false;
    });
  }

  void _onSpeechResult(String result, bool finalResult) {
    setState(() {
      _controller.text = result;
      if (finalResult) {
        _listening = false;
      }
    });
  }

  @override
  void onNotification(String name, param) {
    if (name == SpeechToText.notifyError) {
      setState(() {
        _listening = false;
      });
    }
  }
}