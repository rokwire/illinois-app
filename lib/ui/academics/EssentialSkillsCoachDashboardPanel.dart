
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/CustomCourses.dart';
import 'package:illinois/ui/academics/courses/AssignmentPanel.dart';
import 'package:illinois/ui/academics/courses/ResourcesPanel.dart';
import 'package:illinois/ui/academics/courses/StreakPanel.dart';
import 'package:illinois/ui/academics/courses/UnitInfoPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
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
  // List<String> moduleIconNames = ["skills-social-button", "skills-management-button", "skills-cooperation-button", "skills-emotional-button", "skills-innovation-button"];
  Course? _course;
  UserCourse? _userCourse;
  List<UserUnit>? _userCourseUnits;

  String? _selectedModuleKey;

  @override
  void initState() {
    _loadCourseAndUnits();

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Module? selectedModule = _course?.searchByKey(moduleKey: _selectedModuleKey);
    if (selectedModule != null) {
      Color? primaryColor = selectedModule.display?.primaryColor != null ? Styles().colors.getColor(selectedModule.display!.primaryColor!) : Styles().colors.fillColorPrimary;
      Color? accentColor = selectedModule.display?.accentColor != null ? Styles().colors.getColor(selectedModule.display!.accentColor!) : Styles().colors.fillColorPrimary;
      return SingleChildScrollView(
        child: Container(
          color: primaryColor,
          child: _buildModuleInfoView(selectedModule.display?.icon ?? 'skills-question', primaryColor, accentColor),
        ),
      );
    }
    return Container();
  }

  bool get _hasStartedSkillsCoach => _userCourse != null;

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }

  Widget _buildModuleInfoView(String moduleType, Color? color, Color? colorAccent,){
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            _buildStreakWidget(),
            Container(
              height: 170,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child:  Container(
                      child: Styles().images.getImage(moduleType) ?? Container(),
                    ),

                  ),
                  Padding(padding: EdgeInsets.only(left: 16, right: 16,bottom: 16),
                    child:  Center(
                      child: DropdownButton(
                          value: _selectedModuleKey,
                          iconDisabledColor: Colors.white,
                          iconEnabledColor: Colors.white,
                          focusColor: Colors.white,
                          dropdownColor: colorAccent,
                          isExpanded: true,
                          items: _moduleDropdownItems(style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")),
                          onChanged: (String? selected) {
                            setState(() {
                              _selectedModuleKey = selected;
                            });
                          }
                      ),
                    )
                  ),
                  // Text(_course.modules?[moduleNumber].name ?? "No name",style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")),
                ],
              ),
            ),
            Column(
                children:_buildModuleUnitWidgets(color, colorAccent, 0)
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildModuleUnitWidgets(Color? color, Color? colorAccent, int moduleNumber){
    List<Widget> moduleUnitWidgets = <Widget>[];
    for(int i =0; i<(_course?.modules?[moduleNumber].units?.length ?? 0); i++ ){
      moduleUnitWidgets.add(_buildUnitInfoWidget(color, colorAccent, i, moduleNumber, _course?.modules?[moduleNumber].units?[i]));
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
        //           Navigator.push(context, CupertinoPageRoute(builder: (context) => AssignmentPanel(content: contentList[i], color: color, colorAccent:colorAccent, isActivityComplete: true, helpContent: helpContent,)));
        //         },
        //         // icon of the button
        //         child: Styles().images.getImage("skills-check") ?? Container(),
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
                        child: Styles().images.getImage(contentList[i].display?.icon) ?? Container(),
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
                        child: Styles().images.getImage(contentList[i].display?.icon) ?? Container(),
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
                Text('Unit ' + (unitNumber + 1).toString(), style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat")),
                Container(
                  width: 200,
                  child: Text(_course?.modules?[moduleNumber].units?[unitNumber].name ?? "No name", style: Styles().textStyles.getTextStyle("widget.title.light.regular.fat")),
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
                  child: Text('Resources', style: Styles().textStyles.getTextStyle("widget.title.light.small.fat")),
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
      color: Styles().colors.fillColorPrimary,
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
            child: Text('2 Day Streak!',style: Styles().textStyles.getTextStyle("widget.title.light.small.fat"),),
          ),

        ],
      ),
    );
  }

  Widget _buildUnitHelpButtons(List<Content> contentItems, Color? color, Color? colorAccent){

    bool isHelpContentPresent = false;
    bool isHelpVideoContentPresent = false;
    Content? helpContent;
    //Unused: Content? helpVideoContent;
    for(final content in contentItems){
      if(content.type == "info"){
        isHelpContentPresent = true;
        helpContent = content;
      }

      if(content.type == "infoVideo"){
        isHelpVideoContentPresent = true;
        //Unused: helpVideoContent = content;
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
              child: Styles().images.getImage("skills-question") ?? Container(),
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
                child: Styles().images.getImage("skills-play") ?? Container(),
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
          child: Styles().images.getImage("skills-question") ?? Container(),
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
            child: Styles().images.getImage("skills-play") ?? Container(),
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

  List<DropdownMenuItem<String>> _moduleDropdownItems({String? nullOption, TextStyle? style}) {
    List<DropdownMenuItem<String>> dropDownItems = <DropdownMenuItem<String>>[];
    if (nullOption != null) {
      dropDownItems.add(DropdownMenuItem(value: null, child: Text(nullOption, style: style ?? Styles().textStyles.getTextStyle("widget.detail.regular"))));
    }
    for (Module module in _course?.modules ?? []) {
      if (module.key != null && module.name != null && CollectionUtils.isNotEmpty(module.units)) {
        dropDownItems.add(DropdownMenuItem(value: module.key, child: Text(module.name!, style: style ?? Styles().textStyles.getTextStyle("widget.detail.regular"))));
      }
    }
    return dropDownItems;
  }

  Future<void> _loadCourseAndUnits() async {
    _userCourse ??= CustomCourses().userCourses?[essentialSkillsCoachKey];
    if (_userCourse == null) {
      UserCourse? userCourse = await CustomCourses().loadUserCourse(essentialSkillsCoachKey);
      if (userCourse != null) {
        await _loadUserCourseUnits();
        setStateIfMounted(() {
          _userCourse = userCourse;
          _selectedModuleKey ??= CollectionUtils.isNotEmpty(userCourse.course?.modules) ? userCourse.course!.modules![0].key : null;
        });
      } else {
        await _loadCourse();
      }
    } else {
      await _loadUserCourseUnits();
    }
  }

  Future<void> _loadCourse() async {
    _course ??= CustomCourses().courses?[essentialSkillsCoachKey];
    if (_course == null) {
      Course? course = await CustomCourses().loadCourse(essentialSkillsCoachKey);
      if (course != null) {
        setStateIfMounted(() {
          _course = course;
          _selectedModuleKey ??= CollectionUtils.isNotEmpty(course.modules) ? course.modules![0].key : null;
        });
      }
    } else {
      setStateIfMounted(() {
        _selectedModuleKey ??= CollectionUtils.isNotEmpty(_course!.modules) ? _course!.modules![0].key : null;
      });
    }
  }

  Future<void> _loadUserCourseUnits() async {
    _userCourseUnits ??= CustomCourses().userCourseUnits?[essentialSkillsCoachKey];
    if (_userCourseUnits == null) {
      List<UserUnit>? userUnits = await CustomCourses().loadUserCourseUnits(essentialSkillsCoachKey);
      if (userUnits != null) {
        setStateIfMounted(() {
          _userCourseUnits = userUnits;
        });
      }
    } else {
      setStateIfMounted(() {});
    }
  }
}
