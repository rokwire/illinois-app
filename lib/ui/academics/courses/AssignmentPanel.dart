
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/academics/courses/AssignmentCompletePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class AssignmentPanel extends StatefulWidget {
  final Content? content;
  final Color? color;
  final Color? colorAccent;
  final bool isActivityComplete;
  final bool isCurrent;
  final Content? helpContent;
  const AssignmentPanel({required this.content, required this.color, required this.colorAccent, required this.isActivityComplete, required this.isCurrent, this.helpContent});

  @override
  State<AssignmentPanel> createState() => _AssignmentPanelState();
}

class _AssignmentPanelState extends State<AssignmentPanel> implements NotificationsListener {

  late Content _content;
  late Content _helpContent;
  late Color? _color;
  late Color? _colorAccent;
  late TextEditingController _controller;
  List<bool> _isOpen = [false];
  late bool _isActivityComplete;
  bool _isActivityNotCompleted = false;
  bool _isGood = false;
  bool _isBad = false;

  @override
  void initState() {
    _content = widget.content!;
    _color = widget.color!;
    _isActivityComplete = widget.isActivityComplete;
    _colorAccent = widget.colorAccent!;
    _helpContent = widget.helpContent!;
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: HeaderBar(title: Localization().getStringEx('', 'Daily Activities'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: Column(
        children: _buildAssignmentActivity(),
      ),
      backgroundColor: _color,
    );
  }

  List<Widget> _buildAssignmentActivity(){
    List<Widget> widgets = <Widget>[];

    widgets.add(Padding(
      padding: EdgeInsets.all(24),
      child: Text(_content.details ?? "Name", style: Styles().textStyles.getTextStyle("widget.title.light.large")),
    ));

    widgets.add(
      Container(
        width: 350,
        height: 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: _colorAccent,
        ),
      )
    );

    widgets.add(
        Padding(
          padding: EdgeInsets.all(16),
          child: Text("Did you complete this task?",
            style: Styles().textStyles.getTextStyle("widget.title.light.regular"),
          ),
        )
    );

    widgets.add(
      Container(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                  width: 150,
                  child:RoundedButton(
                      label: Localization().getStringEx('', 'Yes'),
                      leftIconPadding: EdgeInsets.only(left: 15),
                      textStyle: Styles().textStyles.getTextStyle("widget.title.light.large.fat"),
                      backgroundColor: _isActivityComplete ? _colorAccent : _color,
                      borderColor: _colorAccent,
                      leftIcon: Icon(
                        Icons.check_rounded,
                        color: _isActivityComplete ? _color : _colorAccent,
                        size: 20,
                      ),
                      //TODO: use widget.isCurrent to enable/disable tap
                      onTap: (){
                        if(_isActivityComplete){
                          setState(() {
                            _isActivityComplete = false;
                          });
                        }else{
                          setState(() {
                            _isActivityComplete = true;
                            Navigator.push(context, CupertinoPageRoute(builder: (context) => AssignmentCompletePanel( color: _color, colorAccent: _colorAccent,)));
                          });
                        }
                      }

                  ),
              ),
              Container(width: 8,),
              Container(
                width: 150,
                child:RoundedButton(
                    label: Localization().getStringEx('', 'No'),
                    leftIconPadding: EdgeInsets.only(left: 15),
                    textStyle: Styles().textStyles.getTextStyle("widget.title.light.large.fat"),
                    backgroundColor:  _isActivityNotCompleted ? _colorAccent : _color,
                    borderColor: _colorAccent,
                    leftIcon: Icon(
                      Icons.close_rounded,
                      color: _isActivityNotCompleted ? _color : _colorAccent,
                      size: 20,
                    ),
                    onTap: (){
                      setState(() {
                        _isActivityNotCompleted = !_isActivityNotCompleted;
                      });
                    }
              )),
            ],
          ),
        )
      )
    );


    if(_isActivityComplete){
      widgets.add(
          Padding(
            padding: EdgeInsets.all(16),
            child: Text("How did it go?",
              style: Styles().textStyles.getTextStyle("widget.title.light.regular"),
            ),
          )
      );

      widgets.add(
          Container(
              width: double.infinity,
              child: Padding(
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
                          backgroundColor: _isGood ? _colorAccent : _color,
                          borderColor: _colorAccent,
                          onTap: (){
                            setState(() {
                              _isGood = !_isGood;
                            });
                          }

                      ),
                    ),
                    Container(width: 8,),
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
                            backgroundColor:  _isBad ? _colorAccent : _color,
                            borderColor: _colorAccent,
                            onTap: (){
                              setState(() {
                                _isBad = !_isBad;
                              });
                            }
                        )),
                  ],
                ),
              )
          )
      );


      widgets.add(
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
            child: Row(
              children: [
                Text("Describe your experience.",
                  style: Styles().textStyles.getTextStyle("widget.title.light.small.fat"),
                ),
                Expanded(child: Container(),),
                IconButton(
                  icon: Styles().images.getImage("skills-mic") ?? Container(),
                  onPressed: () {
                    //TODO voice to text
                  },
                )
              ],
            ),
          )
      );
    }else if(_isActivityNotCompleted){
      widgets.add(
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
            child: Row(
              children: [
                Text("Why not? What got in your way?",
                  style: Styles().textStyles.getTextStyle("widget.title.light.small.fat"),
                ),
                Expanded(child: Container(),),
                IconButton(
                  icon: Styles().images.getImage("skills-mic") ?? Container(),
                  onPressed: () {
                    //TODO voice to text
                  },
                )
              ],
            ),
          )
      );
    }else{
      widgets.add(
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
            child: Row(
              children: [
                Text("Notes",
                  style: Styles().textStyles.getTextStyle("widget.title.light.small.fat"),
                ),
                Expanded(child: Container(),),
                IconButton(
                  icon: Styles().images.getImage("skills-mic") ?? Container(),
                  onPressed: () {
                    //TODO voice to text

                  },
                )
              ],
            ),
          )
      );
    }

    widgets.add(
      Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child:Center(
            child: TextField(
            controller: _controller,
            maxLines: 10,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              hintStyle: TextStyle(color: Colors.grey[800]),
              fillColor: Colors.white,
            ),
          ),
        )
      )
    );

    widgets.add(Expanded(child: Container()));

    widgets.add(
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
                  child:Text("Helpful Information", style:Styles().textStyles.getTextStyle("widget.title.light.large.fat")),
                )
              );
            },
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: EdgeInsets.all(8),
                    child: Text("- " + (_helpContent.name ?? "Name") + ": " + (_helpContent.details ?? " "), style:Styles().textStyles.getTextStyle("widget.title.light.small")),
                ),
                Padding(padding: EdgeInsets.all(8),
                  child: Text("- " + "Link to other resources or more text", style:Styles().textStyles.getTextStyle("widget.title.light.small")),
                ),
              ],
            ),
          )
        ],
      )
    );

    return widgets;
  }

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }

}