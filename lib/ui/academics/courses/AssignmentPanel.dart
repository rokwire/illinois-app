
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/SpeechToText.dart';
import 'package:illinois/ui/academics/courses/ModuleHeaderWidget.dart';
import 'package:illinois/ui/academics/courses/ResourcesPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:sprintf/sprintf.dart';

class AssignmentPanel extends StatefulWidget {
  final Content content;
  final Map<String, dynamic>? data;
  final Color? color;
  final Color? colorAccent;
  final bool isCurrent;
  final List<Content>? helpContent;
  final bool preview;

  final Widget? moduleIcon;
  final String moduleName;
  final int unitNumber;
  final String unitName;
  final int activityNumber;

  AssignmentPanel({required this.content, required this.data, required this.color, required this.colorAccent, required this.isCurrent,
    this.helpContent, required this.preview, this.moduleIcon, required this.moduleName, required this.unitNumber, required this.unitName, required this.activityNumber,});

  @override
  State<AssignmentPanel> createState() => _AssignmentPanelState();
}

class _AssignmentPanelState extends State<AssignmentPanel> implements NotificationsListener {

  late Content _content;
  Map<String, dynamic>? _data;
  List<Content>? _helpContent;
  Color? _color;
  Color? _colorAccent;
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController();

  bool _helpContentOpen = false;
  bool _listening = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      SpeechToText.notifyError,
    ]);

    //TODO: load history

    _content = widget.content;
    _data = widget.data != null ? Map.of(widget.data!) : null;
    _controller.text = userNotes ?? '';
    _color = widget.color;
    _colorAccent = widget.colorAccent;
    _helpContent = widget.helpContent;
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get isComplete => _data?[UserContent.completeKey] == true;
  bool get isNotComplete => _data?[UserContent.completeKey] == false;
  set complete(bool? value) {
    _data ??= {};
    _data![UserContent.completeKey] = value;
  }

  bool get isGoodExperience => _data?[UserContent.experienceKey] == UserContent.goodExperience;
  bool get isBadExperience => _data?[UserContent.experienceKey] == UserContent.badExperience;
  set experience(String? value) {
    _data ??= {};
    _data![UserContent.experienceKey] = value;
  }

  String? get userNotes => _data?[UserContent.notesKey].toString();
  set userNotes(String? value) {
    _data ??= {};
    _data![UserContent.notesKey] = value;
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
      onPopInvoked: _saveProgress,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: HeaderBar(
          title: sprintf(Localization().getStringEx("panel.essential_skills_coach.assignment.header.title", "Unit %d Activity %d"), [widget.unitNumber, widget.activityNumber]),
          textStyle: Styles().textStyles.getTextStyle('header_bar'), onLeading: () => _saveProgress(false),
        ),
        body: Column(
          children: [
            ModuleHeaderWidget(icon: widget.moduleIcon, moduleName: widget.moduleName, backgroundColor: _color,),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: _buildAssignmentActivityWidgets(),
                  ),
                ),
              ),
            ),
            if (!widget.preview)
              Padding(
                padding: EdgeInsets.all(16),
                child: RoundedButton(
                    label: Localization().getStringEx('panel.essential_skills_coach.assignment.button.save.label', 'Save'),
                    textStyle: Styles().textStyles.getTextStyle("widget.title.light.regular.fat"),
                    backgroundColor: _color,
                    borderColor: _color,
                    onTap: () => _saveProgress(false)),
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
        child: Align(alignment: AlignmentDirectional.centerStart, child: Text(_content.name ?? "", style: Styles().textStyles.getTextStyle("widget.title.light.medium_large.extra_fat")?.apply(color: _color),)),
      ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Align(alignment: AlignmentDirectional.centerStart, child: Text(_content.details ?? "", style: Styles().textStyles.getTextStyle("widget.title.light.large")?.apply(color: _color))),
      ),
    ];

    if (!widget.preview) {
      List<Widget> noteWidgets = [];
      if(isComplete){
        noteWidgets.addAll([
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(_content.styles?.strings?['experience_prompt'] ?? Localization().getStringEx('panel.essential_skills_coach.assignment.experience.selection.header', "How did it go?"),
              style: Styles().textStyles.getTextStyle("widget.title.light.regular")?.apply(color: _color),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 150,
                  child:RoundedButton(
                    label: "",
                    textWidget: Icon(
                      Icons.thumb_up_alt_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                    backgroundColor: isGoodExperience ? _color : _colorAccent,
                    borderColor: _color,
                    onTap: widget.isCurrent ? (){
                      setState(() {
                        experience = isGoodExperience ? null : UserContent.goodExperience;
                      });
                    } : null,
                  ),
                ),
                SizedBox(width: 8,),
                Container(
                    width: 150,
                    child:RoundedButton(
                      label: "",
                      textWidget: Icon(
                        Icons.thumb_down_alt_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                      backgroundColor:  isBadExperience ? _color : _colorAccent,
                      borderColor: _color,
                      onTap: widget.isCurrent ? (){
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(notesHeaderText, style: Styles().textStyles.getTextStyle("widget.title.light.small.fat")?.apply(color: _color),),
                Visibility(
                  visible: widget.isCurrent && SpeechToText().isEnabled,
                  child: _buildSpeechToTextButton(),
                )
              ],
            ),
          )
      );

      assignmentWidgets.addAll([
        Divider(color: _color, thickness: 2, indent: 8.0, endIndent: 8.0,),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(_content.styles?.strings?['complete_prompt'] ?? Localization().getStringEx('panel.essential_skills_coach.assignment.completion.selection.header', "Did you complete this task?"),
            style: Styles().textStyles.getTextStyle("widget.title.light.regular")?.apply(color: _color),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 150,
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
                    onTap: widget.isCurrent && widget.data?[UserContent.completeKey] != true ? () {
                      setState(() {
                        complete = isComplete ? null : true;
                      });
                    } : null
                ),
              ),
              SizedBox(width: 8,),
              Container(
                  width: 150,
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
                    onTap: widget.isCurrent && widget.data?[UserContent.completeKey] != true ? (){
                      setState(() {
                        complete = isNotComplete ? null : false;
                      });
                    } : null,
                  )),
            ],
          ),
        ),
        ...noteWidgets,
        Padding(
          padding: EdgeInsets.only(bottom: 32),
          child:TextField(
            controller: _controller,
            maxLines: 10,
            readOnly: !widget.isCurrent,
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
        //TODO: add history here
      ]);
    }

    return assignmentWidgets;
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

  void _saveProgress(bool didPop) async {
    if (userNotes != null || _controller.text.isNotEmpty) {
      userNotes = _controller.text;
    }
    if (!didPop) {
      Navigator.pop(context, !widget.isCurrent || DeepCollectionEquality().equals(_data, widget.data) ? null : _data);
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
      if (widget.isCurrent) {
        _controller.text = result;
      }
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