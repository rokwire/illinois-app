
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/CustomCourses.dart';
import 'package:illinois/ui/academics/courses/AssignmentPanel.dart';
import 'package:illinois/ui/academics/courses/UnitInfoPanel.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class EssentialSkillsCoachDashboardPanel extends StatefulWidget {
  EssentialSkillsCoachDashboardPanel();

  @override
  State<EssentialSkillsCoachDashboardPanel> createState() => _EssentialSkillsCoachDashboardPanelState();
}

class _EssentialSkillsCoachDashboardPanelState extends State<EssentialSkillsCoachDashboardPanel> implements NotificationsListener {
  static const String essentialSkillsCoachKey  = "essential_skills_coach"; //TODO: move to config?

  final PageController controller = PageController();
  List<String> moduleIconNames = ["skills-social-button", "skills-management-button", "skills-cooperation-button", "skills-emotional-button", "skills-innovation-button"];
  int moduleNumber = 0;
  Course? _course;

  String? _selectedTimeframe = "Social Engagement Skills";
  final List<String> _timeframes = ["Social Engagement Skills", "Self Management Skills",
    "Cooperation Skills", "Emotional Resilience Skills", "Innovation Skills"];

  @override
  void initState() {
    if (CollectionUtils.isNotEmpty(CustomCourses().courses)) {
      _course = CustomCourses().courses!.firstWhere((course) => course.key == essentialSkillsCoachKey);
    } else {
      CustomCourses().loadCourses().then((courses) {
        setState(() {
          _course = courses?.firstWhere((course) => course.key == essentialSkillsCoachKey);
        });
      });
    }
    super.initState();
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
          color: Styles().colors.getColor("essentialSkillsCoachPurple"),
          child: _buildModuleInfoView("skills-social", Styles().colors.getColor("essentialSkillsCoachPurple"), Styles().colors.getColor("essentialSkillsCoachPurpleAccent")),
        );
      case "Self Management Skills":
        return Container(
          color: Styles().colors.getColor("essentialSkillsCoachBlue"),
          child: _buildModuleInfoView("skills-management", Styles().colors.getColor("essentialSkillsCoachBlue"), Styles().colors.getColor("essentialSkillsCoachBlueAccent")),

        );
      case "Cooperation Skills":
        return Container(
          color: Styles().colors.getColor("essentialSkillsCoachRed"),
          child: _buildModuleInfoView("skills-cooperation", Styles().colors.getColor("essentialSkillsCoachRed"), Styles().colors.getColor("essentialSkillsCoachRedAccent")),

        );
      case "Emotional Resilience Skills":
        return Container(
          color: Styles().colors.getColor("essentialSkillsCoachOrange"),
          child: _buildModuleInfoView("skills-emotional", Styles().colors.getColor("essentialSkillsCoachOrange"), Styles().colors.getColor("essentialSkillsCoachOrangeAccent")),

        );
      case "Innovation Skills":
        return Container(
          color: Styles().colors.getColor("essentialSkillsCoachGreen"),
          child: _buildModuleInfoView("skills-innovation", Styles().colors.getColor("essentialSkillsCoachGreen"), Styles().colors.getColor("essentialSkillsCoachGreenAccent")),
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
    for(int i =0; i<(_course?.modules?[moduleNumber].units?.length ?? 0); i++ ){
      moduleUnitWidgets.add(_buildUnitInfoWidget(color, colorAccent, i, moduleNumber));
      moduleUnitWidgets.add(Container(height: 16,));
      moduleUnitWidgets.add(_buildUnitHelpButtons(_course?.modules?[moduleNumber].units?[i].contentItems ?? <Content>[], color, colorAccent));
      //TODO delete below checkmark widget only after integration
      moduleUnitWidgets.add(Container(height: 16,));
      moduleUnitWidgets.addAll(_buildUnitWidgets(color, colorAccent, _course?.modules?[moduleNumber].units?[i].contentItems ?? <Content>[], moduleNumber));
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
        // if(contentList[i].isComplete){
        //   unitWidgets.add(
        //     Center(
        //       // elevated button
        //       child: ElevatedButton(
        //         onPressed: () {
        //
        //           Navigator.push(context, CupertinoPageRoute(builder: (context) => AssignmentPanel(content: contentList[i], color: color, colorAccent:colorAccent, isActivityComplete: true, helpContent: helpContent,)));
        //         },
        //         // icon of the button
        //         child: Styles().images?.getImage("skills-check") ?? Container(),
        //         // styling the button
        //         style: ElevatedButton.styleFrom(
        //           shape: CircleBorder(),
        //           padding: EdgeInsets.all(10),
        //           // Button color
        //           backgroundColor: Colors.green,
        //         ),
        //       ),
        //     ),
        //   );
        //   unitWidgets.add(Container(height: 16,));
        // }else{
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
                          // contentList[i].isComplete = true;

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
        // }

      }else{
        if(contentList[i].type != "info"){
          helpContent = contentList[i];
        }
      }
    }

    return unitWidgets;
  }

  Widget _buildUnitInfoWidget(Color? color, Color? colorAccent, int unitNumber, int moduleNumber){
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
                  child: Text(_course?.modules?[moduleNumber].units?[unitNumber].name ?? "No name", style: Styles().textStyles?.getTextStyle("widget.title.light.regular.fat")),
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
          Text('2 Day Streak!',style: Styles().textStyles!.getTextStyle("widget.title.light.small.fat"),),
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
