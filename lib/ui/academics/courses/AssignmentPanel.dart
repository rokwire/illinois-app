
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/SpeechToText.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/academics/courses/AssignmentCompletePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class AssignmentPanel extends StatefulWidget {
  final Content content;
  final Map<String, dynamic>? data;
  final Color? color;
  final Color? colorAccent;
  final bool isCurrent;
  final List<Content>? helpContent;
  AssignmentPanel({required this.content, required this.data, required this.color, required this.colorAccent, required this.isCurrent, this.helpContent});

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
  List<bool> _isOpen = [false];

  bool _listening = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      SpeechToText.notifyError,
    ]);

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

  bool get isComplete => _data?['complete'] == true;
  bool get isNotComplete => _data?['complete'] == false;
  set complete(bool? value) {
    _data ??= {};
    _data!['complete'] = value;
  }

  bool get isGoodExperience => _data?['experience'] == 'good';
  bool get isBadExperience => _data?['experience'] == 'bad';
  set experience(String? value) {
    _data ??= {};
    _data!['experience'] = value;
  }

  String? get userNotes => _data?['notes'].toString();

  @override
  Widget build(BuildContext context) {
    List<Widget> helpContentWidgets = [];
    for (Content help in _helpContent ?? []) {
      helpContentWidgets.add(
        //TODO: make this tappable to link to ResourcesPanel
        Padding(padding: EdgeInsets.all(8),
          child: Text("- " + (help.name ?? "") + ": " + (help.details ?? ""), style:Styles().textStyles.getTextStyle("widget.title.light.small")),
        )
      );
    }
    return PopScope(
      canPop: false,
      onPopInvoked: _saveProgress,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: HeaderBar(title: _content.name, textStyle: Styles().textStyles.getTextStyle('header_bar'), onLeading: () => _saveProgress(false),),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: _buildAssignmentActivityWidgets(),
                ),
              ),
            ),
            if (helpContentWidgets.isNotEmpty)
              ExpansionPanelList(
                expandIconColor: Colors.white,
                expansionCallback: (i, isOpen) =>
                    setState(() => _isOpen[i] = !isOpen),
                children: [
                  ExpansionPanel(
                    backgroundColor: _colorAccent,
                    isExpanded: _isOpen[0],
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                          iconColor: Colors.white,
                          title: Center(
                            child:Text(Localization().getStringEx('panel.essential_skills_coach.assignment.help.header.title', "Helpful Information"), style:Styles().textStyles.getTextStyle("widget.title.light.large.fat")),
                          )
                      );
                    },
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: helpContentWidgets,
                    ),
                  )
                ],
              ),
          ],
        ),
        backgroundColor: _color,
      ),
    );
  }

  List<Widget> _buildAssignmentActivityWidgets(){
    List<Widget> noteWidgets = [];
    if(isComplete){
      noteWidgets.addAll([
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(Localization().getStringEx('panel.essential_skills_coach.assignment.experience.selection.header.', "How did it go?"),
            style: Styles().textStyles.getTextStyle("widget.title.light.regular"),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
                    textStyle: Styles().textStyles.getTextStyle("widget.title.light.large.fat"),
                    backgroundColor: isGoodExperience ? _colorAccent : _color,
                    borderColor: _colorAccent,
                    onTap: widget.isCurrent ? (){
                      setState(() {
                        experience = isGoodExperience ? null : 'good';
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
                      textStyle: Styles().textStyles.getTextStyle("widget.title.light.large.fat"),
                      backgroundColor:  isBadExperience ? _colorAccent : _color,
                      borderColor: _colorAccent,
                      onTap: widget.isCurrent ? (){
                        setState(() {
                          experience = isBadExperience ? null : 'bad';
                        });
                      } : null,
                  )),
            ],
          ),
        ),
      ]);
    }

    String notesHeaderText = isComplete ? Localization().getStringEx('panel.essential_skills_coach.assignment.experience.good.notes.header.', "Describe your experience.") :
      (isNotComplete ? Localization().getStringEx('panel.essential_skills_coach.assignment.experience.bad.notes.header.', "Why not? What got in your way?") :
        Localization().getStringEx('panel.essential_skills_coach.assignment.experience.notes.header.', "Notes"));
    noteWidgets.add(
        Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(notesHeaderText, style: Styles().textStyles.getTextStyle("widget.title.light.small.fat"),),
              Visibility(
                visible: widget.isCurrent && SpeechToText().isEnabled,
                child: _buildSpeechToTextButton(),
              )
            ],
          ),
        )
    );

    return [
      Padding(
        padding: EdgeInsets.all(24),
        child: Text(_content.details ?? "", style: Styles().textStyles.getTextStyle("widget.title.light.large")),
      ),
      Divider(color: _colorAccent, thickness: 2, indent: 24.0, endIndent: 24.0,),
      Padding(
        padding: EdgeInsets.all(16),
        child: Text(Localization().getStringEx('panel.essential_skills_coach.assignment.completion.selection.header', "Did you complete this task?"),
          style: Styles().textStyles.getTextStyle("widget.title.light.regular"),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 150,
              child:RoundedButton(
                  label: Localization().getStringEx('panel.essential_skills_coach.assignment.completion.button.yes.label', 'Yes'),
                  leftIconPadding: EdgeInsets.only(left: 15),
                  textStyle: Styles().textStyles.getTextStyle("widget.title.light.large.fat"),
                  backgroundColor: isComplete ? _colorAccent : _color,
                  borderColor: _colorAccent,
                  leftIcon: Icon(
                    Icons.check_rounded,
                    color: isComplete ? _color : _colorAccent,
                    size: 20,
                  ),
                  onTap: widget.isCurrent ? () {
                    setState(() {
                      complete = isComplete ? null : true;
                    });
                    if (isComplete) {
                      Navigator.push(context, CupertinoPageRoute(builder: (context) => AssignmentCompletePanel(contentName: _content.name ?? '', color: _color, colorAccent: _colorAccent,)));
                    }
                  } : null
              ),
            ),
            SizedBox(width: 8,),
            Container(
                width: 150,
                child:RoundedButton(
                    label: Localization().getStringEx('panel.essential_skills_coach.assignment.completion.button.no.label', 'No'),
                    leftIconPadding: EdgeInsets.only(left: 15),
                    textStyle: Styles().textStyles.getTextStyle("widget.title.light.large.fat"),
                    backgroundColor:  isNotComplete ?  _colorAccent : _color,
                    borderColor: _colorAccent,
                    leftIcon: Icon(
                      Icons.close_rounded,
                      color: isNotComplete ? _color : _colorAccent,
                      size: 20,
                    ),
                    onTap: widget.isCurrent ? (){
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
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 32),
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
              fillColor: Colors.white,
            ),
          )
      ),
    ];
  }

  Widget _buildSpeechToTextButton() => Material(
    color: _color,
    child: IconButton(
      icon: Styles().images.getImage(_listening ? "skills-speech-pause" :"skills-speech-mic") ?? Container(),
      color: _colorAccent,
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
    _data?['notes'] = _controller.text;
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