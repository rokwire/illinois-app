
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/courses/Content.dart';
import 'package:illinois/model/courses/Module.dart';
import 'package:illinois/model/courses/Reference.dart';
import 'package:illinois/ui/academics/courses/AssignmentPanel.dart';
import 'package:illinois/ui/academics/courses/ResourcesPanel.dart';
import 'package:illinois/ui/academics/courses/UnitInfoPanel.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

import '../../model/courses/Course.dart';
import '../../model/courses/Unit.dart';
import 'courses/StreakPanel.dart';



class EssentialSkillsCoachDashboardPanel extends StatefulWidget {
  EssentialSkillsCoachDashboardPanel();

  @override
  State<EssentialSkillsCoachDashboardPanel> createState() => _EssentialSkillsCoachDashboardPanelState();
}

class _EssentialSkillsCoachDashboardPanelState extends State<EssentialSkillsCoachDashboardPanel> implements NotificationsListener {

  final PageController controller = PageController();
  List<String> moduleIconNames = ["skills-social-button", "skills-management-button", "skills-cooperation-button", "skills-emotional-button", "skills-innovation-button"];
  int moduleNumber = 0;
  late Course _course;

  String? _selectedTimeframe = "Social Engagement Skills";
  final List<String> _timeframes = ["Social Engagement Skills", "Self Management Skills",
    "Cooperation Skills", "Emotional Resilience Skills", "Innovation Skills"];

  @override
  void initState() {
    super.initState();

    Content skillsHelpContent = Content(
        name: "Soften",
        type: "info",
        details: "(smile, open posture, forward lean, touch, eye contact, nod)",
    );

    Content skillsHelpInfoVideoContent = Content(
        name: "Soften",
        type: "infoVideo",
        details: "(smile, open posture, forward lean, touch, eye contact, nod)"
    );

    Content lesson1 = Content(
        name: "Arm Position in Conversations",
        type: "assignment",
        details: "Make a note of holding your arms in a relaxed position at your side when talking to a colleague",
        isComplete: true
    );

    Content lesson2 = Content(
        name: "Try to smile during three conversations",
        type: "assignment",
        details: "Try to smile during three conversations"
    );

    Content lesson3 = Content(
        name: "Make a note of looking your conversational partners in the eyes while talking to them",
        type: "assignment",
        details: "Make a note of looking your conversational partners in the eyes while talking to them"
    );

    Content lesson4 = Content(
        name: "Make a note of leaning forward while having a conversation (while sitting).",
        type: "assignment",
        details: "Make a note of leaning forward while having a conversation (while sitting)."
    );

    Content lesson5 = Content(
        name: "Try to touch conversational partners in a non-threatening fashion–on the back of the arm.",
        type: "assignment",
        details: "Try to touch conversational partners in a non-threatening fashion–on the back of the arm."
    );

    Content lesson6 = Content(
        name: "Try to nod affirmatively during 3 conversations",
        type: "assignment",
        details: "Try to nod affirmatively during 3 conversations"
    );

    Reference pdfRef = Reference(
        name: "PDF",
        type: "pdf"
    );

    Content pdfResource = Content(
        name: "PDF resource",
        type: "resource",
        details: "Try to nod affirmatively during 3 conversations",
        reference: pdfRef
    );

    Reference textRef = Reference(
        name: "text",
        type: "text"
    );

    Content textResource = Content(
        name: "Text resource",
        type: "resource",
        details: "text",
        reference: textRef
    );

    Reference linkRef = Reference(
        name: "External Link Reference",
        type: "link"
    );

    Content linkResource = Content(
        name: "External link resource",
        type: "resource",
        details: "text",
        reference: linkRef
    );

    Reference ppRef = Reference(
        name: "External Link Reference",
        type: "powerpoint"
    );

    Content ppResource = Content(
        name: "Power Point resource",
        type: "resource",
        details: "text",
        reference: ppRef
    );

    Reference vidRef = Reference(
        name: "External Link Reference",
        type: "video"
    );

    Content videoResource = Content(
        name: "Video resource",
        type: "resource",
        details: "text",
        reference: vidRef
    );

    List<Content>? contentList = <Content>[];
    contentList.add(skillsHelpContent);
    contentList.add(skillsHelpInfoVideoContent);
    contentList.add(lesson1);
    contentList.add(lesson2);
    contentList.add(lesson3);
    contentList.add(lesson4);
    contentList.add(lesson5);
    contentList.add(lesson6);
    contentList.add(pdfResource);
    contentList.add(textResource);
    contentList.add(linkResource);
    contentList.add(ppResource);
    contentList.add(videoResource);

    Unit unit1 = Unit(
      name: "The physical side of communication",
      contentItems: contentList,

    );

    Content skillsHelpContent2 = Content(
        name: "ART",
        type: "info",
        details: "Ask an open-ended question, Tell them that their answer is interesting/good/compelling, Respond with relevant story about yourself and Repeat"
    );

    Content lesson7 = Content(
        name: "Arm Position in Conversations",
        type: "assignment",
        details: "Make a note of holding your arms in a relaxed position at your side when talking to a colleague"
    );

    Content lesson8 = Content(
        name: "Try to smile during three conversations",
        type: "assignment",
        details: "Try to smile during three conversations"
    );

    Content lesson9 = Content(
        name: "Make a note of looking your conversational partners in the eyes while talking to them",
        type: "assignment",
        details: "Make a note of looking your conversational partners in the eyes while talking to them"
    );

    Content lesson10 = Content(
        name: "Make a note of leaning forward while having a conversation (while sitting).",
        type: "assignment",
        details: "Make a note of leaning forward while having a conversation (while sitting)."
    );

    List<Content>? contentList2 = <Content>[];
    contentList2.add(skillsHelpContent2);
    contentList2.add(lesson7);
    contentList2.add(lesson8);
    contentList2.add(lesson9);
    contentList2.add(lesson10);


    Unit unit2 = Unit(
      name: "Asking questions that promote conversations",
      contentItems: contentList2,

    );


    Content skillsHelpContent3 = Content(
      name: "Soften",
      type: "info",
      details: "How to begin: \n1. Ask a question \n2. Voice an opinion \n3. State a fact \n4. Follow up with how, why, and in what way questions",
    );

    Content lesson11 = Content(
        name: "Observe at least 2 strangers and note things about them or the situation that you could use to start a conversation.",
        type: "assignment",
        details: "Observe at least 2 strangers and note things about them or the situation that you could use to start a conversation."
    );

    Content lesson12 = Content(
        name: "Practice introducing yourself to a stranger",
        type: "assignment",
        details: "Practice introducing yourself to a stranger"
    );

    Content lesson13 = Content(
        name: "Talk to a stranger about the stranger",
        type: "assignment",
        details: "Talk to a stranger about the stranger"
    );

    Content lesson14 = Content(
        name: "Talk to a stranger about the situation",
        type: "assignment",
        details: "Talk to a stranger about the situation"
    );

    List<Content>? contentList3 = <Content>[];
    contentList3.add(skillsHelpContent3);
    contentList3.add(lesson11);
    contentList3.add(lesson12);
    contentList3.add(lesson13);
    contentList3.add(lesson14);

    Unit unit3 = Unit(
      name: "Starting and maintaining conversations",
      contentItems: contentList3,

    );

    List<Unit>? unitList = <Unit>[];
    unitList.add(unit1);
    unitList.add(unit2);
    unitList.add(unit3);

    Module socialModule = Module(
      name: "Social Engagement Skills",
      units: unitList
    );

    Module managementModule = Module(
        name: "Self Management Skills",
        units: unitList
    );

    Module coopModule = Module(
        name: "Cooperation Skills",
        units: unitList
    );

    Module emotionalModule = Module(
        name: "Emotional Resilience Skills",
        units: unitList
    );

    Module innovationModule = Module(
        name: "Innovation Skills",
        units: unitList
    );

    List<Module>? moduleList = <Module>[];
    moduleList.add(socialModule);
    moduleList.add(managementModule);
    moduleList.add(coopModule);
    moduleList.add(emotionalModule);
    moduleList.add(innovationModule);

    _course = Course(
      modules: moduleList
    );

  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      child: _buildModuleView(_selectedTimeframe!),
    );
  }

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }


  Widget _buildModuleView(String module){
    switch (module){
      case "Social Engagement Skills":
        return Container(
          color: Styles().colors!.essentialSkillsCoachPurple,
          child: _buildModuleInfoView("skills-social", Styles().colors!.essentialSkillsCoachPurple, Styles().colors!.essentialSkillsCoachPurpleAccent),
        );
      case "Self Management Skills":
        return Container(
          color: Styles().colors!.essentialSkillsCoachBlue,
          child: _buildModuleInfoView("skills-management", Styles().colors!.essentialSkillsCoachBlue, Styles().colors!.essentialSkillsCoachBlueAccent),

        );
      case "Cooperation Skills":
        return Container(
          color: Styles().colors!.essentialSkillsCoachRed,
          child: _buildModuleInfoView("skills-cooperation", Styles().colors!.essentialSkillsCoachRed, Styles().colors!.essentialSkillsCoachRedAccent),

        );
      case "Emotional Resilience Skills":
        return Container(
          color: Styles().colors!.essentialSkillsCoachOrange,
          child: _buildModuleInfoView("skills-emotional", Styles().colors!.essentialSkillsCoachOrange, Styles().colors!.essentialSkillsCoachOrangeAccent),

        );
      case "Innovation Skills":
        return Container(
          color: Styles().colors!.essentialSkillsCoachGreen,
          child: _buildModuleInfoView("skills-innovation", Styles().colors!.essentialSkillsCoachGreen, Styles().colors!.essentialSkillsCoachGreenAccent),
        );
      default:
        return Container();
    }
  }

  Widget _buildModuleInfoView(String moduleType, Color? color, Color? colorAccent,){
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            _buildStreakWidget(),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0 && moduleNumber != 0) {
                  setState(() {
                    moduleNumber= moduleNumber-1;
                  });
                }

                if (details.primaryVelocity! < 0 && moduleNumber != 4) {
                  setState(() {
                    moduleNumber= moduleNumber+1;
                  });
                }
              },
              child: Container(
                height: 170,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child:  Container(
                        child: Styles().images?.getImage(moduleType) ?? Container(),
                      ),

                    ),
                    Padding(padding: EdgeInsets.only(left: 16, right: 16,bottom: 16),
                      child:  Center(
                        child: DropdownButton(
                            value: _selectedTimeframe,
                            iconDisabledColor: Colors.white,
                            iconEnabledColor: Colors.white,
                            focusColor: Colors.white,
                            dropdownColor: colorAccent,
                            isExpanded: true,
                            items: DropdownBuilder.getItems(_timeframes, style: Styles().textStyles?.getTextStyle("widget.title.light.large.fat")),
                            onChanged: (String? selected) {
                              setState(() {
                                _selectedTimeframe = selected;
                              });
                            }
                        ),
                      )
                    ),
                    // Text(_course.modules?[moduleNumber].name ?? "No name",style: Styles().textStyles?.getTextStyle("widget.title.light.large.fat")),
                  ],
                ),
              ),
            ),
            Column(
                children:_buildModuleUnitWidgets(color, colorAccent, moduleNumber)
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildModuleUnitWidgets(Color? color, Color? colorAccent, int moduleNumber){
    List<Widget> moduleUnitWidgets = <Widget>[];
    for(int i =0; i<(_course.modules?[moduleNumber].units?.length ?? 0); i++ ){
      moduleUnitWidgets.add(_buildUnitInfoWidget(color, colorAccent, i, moduleNumber, _course.modules?[moduleNumber].units?[i]));
      moduleUnitWidgets.add(Container(height: 16,));
      moduleUnitWidgets.add(_buildUnitHelpButtons(_course.modules?[moduleNumber].units?[i].contentItems ?? <Content>[], color, colorAccent));
      //TODO delete below checkmark widget only after integration
      moduleUnitWidgets.add(Container(height: 16,));
      moduleUnitWidgets.addAll(_buildUnitWidgets(color, colorAccent, _course.modules?[moduleNumber].units?[i].contentItems ?? <Content>[], moduleNumber));
    }
    return moduleUnitWidgets;

  }

  List<Widget> _buildUnitWidgets(Color? color, Color? colorAccent, List<Content> contentList, int moduleNumber){
    List<Widget> unitWidgets = <Widget>[];
    Widget bigCircle = new Container(
      width: 82.0,
      height: 82.0,
      decoration: new BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
    bool isOpaqe = false;
    Content helpContent = Content();
    for(int i =0; i< contentList.length; i++ ){
      if(contentList[i].type != "info" && contentList[i].type != "infoVideo"){
        if(contentList[i].isComplete){
          unitWidgets.add(
            Center(
              // elevated button
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (context) => AssignmentPanel(content: contentList[i], color: color, colorAccent:colorAccent, isActivityComplete: true, helpContent: helpContent,)));
                },
                // icon of the button
                child: Styles().images?.getImage("skills-check") ?? Container(),
                // styling the button
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(10),
                  // Button color
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          );
          unitWidgets.add(Container(height: 16,));
        }else{
          if(!isOpaqe){
            unitWidgets.add(Center(
              // elevated button
              child: Stack(
                children: [
                  bigCircle,
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => AssignmentPanel(content: contentList[i], color: color, colorAccent:colorAccent, isActivityComplete: false, helpContent: helpContent,)));
                          contentList[i].isComplete = true;

                        });
                        // Navigator.push(context, CupertinoPageRoute(builder: (context) => AssignmentPanel(content: contentList[i], color: color, colorAccent:colorAccent, isActivityComplete: false, helpContent: helpContent,)));
                      },
                      // icon of the button
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Styles().images?.getImage(moduleIconNames[moduleNumber]) ?? Container(),
                      ),
                      // styling the button
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(8),
                        // Button color
                        backgroundColor: colorAccent
                      ),
                    ),
                  ),
                ],
              ),
            ),);
            isOpaqe = true;
          }else{
            unitWidgets.add(Center(
              // elevated button
              child: Stack(
                children: [
                  bigCircle,
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 4),
                    child: ElevatedButton(
                      onPressed: () {

                        Navigator.push(context, CupertinoPageRoute(builder: (context) => AssignmentPanel(content: contentList[i], color: color, colorAccent:colorAccent, isActivityComplete: false, helpContent: helpContent,)));
                      },
                      // icon of the button
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Styles().images?.getImage(moduleIconNames[moduleNumber]) ?? Container(),
                      ),
                      // styling the button
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(8),
                        // Button color
                        backgroundColor: colorAccent?.withOpacity(.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),);
          }
          unitWidgets.add(Container(height: 16,));
        }

      }else{
        if(contentList[i].type != "info"){
          helpContent = contentList[i];
        }
      }
    }

    return unitWidgets;
  }

  Widget _buildUnitInfoWidget(Color? color, Color? colorAccent, int unitNumber, int moduleNumber, Unit? unit){
    return Container(
      color: colorAccent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Unit ' + (unitNumber + 1).toString(), style: Styles().textStyles?.getTextStyle("widget.title.light.huge.fat")),
                Container(
                  width: 200,
                  child: Text(_course.modules?[moduleNumber].units?[unitNumber].name ?? "No name", style: Styles().textStyles?.getTextStyle("widget.title.light.regular.fat")),
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      List<Content>? resourceContentItems = <Content>[];
                      for(int i = 0; i < (unit?.contentItems?.length ?? 0); i++){
                        if(unit?.contentItems?[i].type == "resource"){
                          resourceContentItems.add(unit!.contentItems![i]);
                        }
                      }
                      Navigator.push(context, CupertinoPageRoute(builder: (context) => ResourcesPanel( color: color, colorAccent:colorAccent, unitNumber: unitNumber, contentItems: resourceContentItems, unitName: unit?.name ?? "no name")));
                    },
                    // icon of the button
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: color,
                      size: 30.0,
                    ),
                    // styling the button
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(16),
                      // Button color
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(4),
                  child: Text('Resources', style: Styles().textStyles?.getTextStyle("widget.title.light.small.fat")),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakWidget(){
    return Container(
      height: 48,
      color: Styles().colors!.fillColorPrimary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_circle,
            color: Colors.white,
            size: 30.0,
          ),
          Container(width: 8,),
          TextButton(
            onPressed: () {
              Navigator.push(context, CupertinoPageRoute(builder: (context) => StreakPanel()));
            },
            child: Text('2 Day Streak!',style: Styles().textStyles!.getTextStyle("widget.title.light.small.fat"),),
          ),

        ],
      ),
    );
  }

  Widget _buildUnitHelpButtons(List<Content> contentItems, Color? color, Color? colorAccent){

    bool isHelpContentPresent = false;
    bool isHelpVideoContentPresent = false;
    Content? helpContent;
    Content? helpVideoContent;
    for(final content in contentItems){
      if(content.type == "info"){
        isHelpContentPresent = true;
        helpContent = content;
      }

      if(content.type == "infoVideo"){
        isHelpVideoContentPresent = true;
        helpVideoContent = content;
      }
    }

    if(isHelpContentPresent == true && isHelpVideoContentPresent == true){
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            // elevated button
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, CupertinoPageRoute(builder: (context) => UnitInfoPanel(content: helpContent, color: color, colorAccent:colorAccent,)));
              },
              // icon of the button
              child: Styles().images?.getImage("skills-question") ?? Container(),
              // styling the button
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(10),
                // Button color
                backgroundColor: Colors.green,
              ),
            ),
          ),
          Container(width: 24,),
          Center(
            // elevated button
            child: ElevatedButton(
              onPressed: () {},
              // icon of the button
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Styles().images?.getImage("skills-play") ?? Container(),
              ),
              // styling the button
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(10),
                // Button color
                backgroundColor: Colors.green,
              ),
            ),
          ),
        ],
      );
    }else if(isHelpContentPresent == false && isHelpVideoContentPresent == false){
      return Container();
    }else if(isHelpContentPresent == true && isHelpVideoContentPresent == false){
      return Center(
        // elevated button
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => UnitInfoPanel(content: helpContent, color: color, colorAccent:colorAccent,)));
          },
          // icon of the button
          child: Styles().images?.getImage("skills-question") ?? Container(),
          // styling the button
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(10),
            // Button color
            backgroundColor: Colors.green,
          ),
        ),
      );
    }else{
      return Center(
        // elevated button
        child: ElevatedButton(
          onPressed: () {},
          // icon of the button
          child: Padding(
            padding: EdgeInsets.only(left: 4),
            child: Styles().images?.getImage("skills-play") ?? Container(),
          ),
          // styling the button
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(10),
            // Button color
            backgroundColor: Colors.green,
          ),
        ),
      );
    }

  }

}



class DropdownBuilder {
  static List<DropdownMenuItem<T>> getItems<T>(List<T> options, {String? nullOption, TextStyle? style}) {
    List<DropdownMenuItem<T>> dropDownItems = <DropdownMenuItem<T>>[];
    if (nullOption != null) {
      dropDownItems.add(DropdownMenuItem(value: null, child: Text(nullOption, style: style ?? Styles().textStyles?.getTextStyle("widget.detail.regular"))));
    }
    for (T option in options) {
      dropDownItems.add(DropdownMenuItem(value: option, child: Text(option.toString(), style: style ?? Styles().textStyles?.getTextStyle("widget.detail.regular"))));
    }
    return dropDownItems;
  }
}
