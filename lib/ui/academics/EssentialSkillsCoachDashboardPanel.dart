
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';



class EssentialSkillsCoachDashboardPanel extends StatefulWidget {
  EssentialSkillsCoachDashboardPanel();

  @override
  State<EssentialSkillsCoachDashboardPanel> createState() => _EssentialSkillsCoachDashboardPanelState();
}

class _EssentialSkillsCoachDashboardPanelState extends State<EssentialSkillsCoachDashboardPanel> implements NotificationsListener {

  final PageController controller = PageController();
  Course _course = Course();
  List<String> moduleIconNames = ["skills-social-button", "skills-management-button", "skills-cooperation-button", "skills-emotional-button", "skills-innovation-button"];


  @override
  void initState() {
    super.initState();
    //TODO delete all hardcoded data once integration starts
    List<Content> content1 = <Content>[];
    content1.add(Content());
    content1.add(Content());
    content1.add(Content());
    content1.add(Content());
    content1.add(Content());
    List<Content> content2 = <Content>[];
    content2.add(Content());
    content2.add(Content());
    content2.add(Content());
    List<Unit> units = <Unit>[];
    Unit unit1 = new Unit("The first unit of this module", content1);
    Unit unit2 = new Unit("The second unit of this module", content2);
    Unit unit3 = new Unit("The third unit of this module", content1);
    units.add(unit1);
    units.add(unit2);
    units.add(unit3);
    List<Module> modules = <Module>[];
    Module module = Module("Social Engagement Skills", units);
    Module module2 = Module("Self Management Skills", units);
    Module module3 = Module("Cooperation Skills", units);
    Module module4 = Module("Emotional Resilience Skills", units);
    Module module5 = Module("Innovation Skills", units);
    modules.add(module);
    modules.add(module2);
    modules.add(module3);
    modules.add(module4);
    modules.add(module5);
    _course.moduleList = modules;


  }

  @override
  Widget build(BuildContext context) {

    return PageView(
      controller: controller,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: Container(
            color: Styles().colors!.essentialSkillsCoachPurple,
            child: _buildSocialView(),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Container(
            color: Styles().colors!.essentialSkillsCoachBlue,
            child: _buildSelfManagementView(),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Container(
            color: Styles().colors!.essentialSkillsCoachRed,
            child: _buildCooperationView(),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Container(
            color: Styles().colors!.essentialSkillsCoachOrange,
            child: _buildEmotionalResilienceView(),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Container(
            color: Styles().colors!.essentialSkillsCoachGreen,
            child: _buildInnovationView(),
          ),
        ),
      ],
    );

  }

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }

  //TODO refactor views to be more dynamic
  Widget _buildSocialView(){
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            _buildStreakWidget(),
            Container(
              height: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: Styles().images?.getImage('skills-social') ?? Container(),
                  ),
                  Container(height: 16,),
                  Text('Social Engagement Skills',style: Styles().textStyles?.getTextStyle("widget.title.light.regular.fat")),
                ],
              ),
            ),
            Column(
                children:_buildModuleUnitWidgets(Styles().colors!.essentialSkillsCoachPurple, Styles().colors!.essentialSkillsCoachPurpleAccent, 0)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfManagementView(){
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            _buildStreakWidget(),
            Container(
              height: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: Styles().images?.getImage('skills-management') ?? Container(),
                  ),
                  Container(height: 16,),
                  Text('Self Management Skills', style: Styles().textStyles?.getTextStyle("widget.title.light.regular.fat")),
                ],
              ),
            ),
            Column(
                children:_buildModuleUnitWidgets(Styles().colors!.essentialSkillsCoachBlue, Styles().colors!.essentialSkillsCoachBlueAccent, 1)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCooperationView(){
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            _buildStreakWidget(),
            Container(
              height: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: Styles().images?.getImage('skills-cooperation') ?? Container(),
                  ),
                  Container(height: 16,),
                  Text('Cooperation Skills', style: Styles().textStyles?.getTextStyle("widget.title.light.regular.fat")),
                ],
              ),
            ),
            Column(
                children:_buildModuleUnitWidgets(Styles().colors!.essentialSkillsCoachRed, Styles().colors!.essentialSkillsCoachRedAccent, 2)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionalResilienceView(){
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            _buildStreakWidget(),
            Container(
              height: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: Styles().images?.getImage('skills-emotional') ?? Container(),
                  ),
                  Container(height: 16,),
                  Text('Emotional Resilience Skills', style: Styles().textStyles?.getTextStyle("widget.title.light.regular.fat")),
                ],
              ),
            ),
            Column(
                children:_buildModuleUnitWidgets(Styles().colors!.essentialSkillsCoachOrange, Styles().colors!.essentialSkillsCoachOrangeAccent, 3)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInnovationView(){
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            _buildStreakWidget(),
            Container(
              height: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width:150,
                    child: Styles().images?.getImage('skills-innovation') ?? Container(),
                  ),
                  Container(height: 16,),
                  Text('Innovation Skills', style: Styles().textStyles?.getTextStyle("widget.title.light.regular.fat")),
                ],
              ),
            ),
            Column(
                children:_buildModuleUnitWidgets(Styles().colors!.essentialSkillsCoachGreen, Styles().colors!.essentialSkillsCoachGreenAccent, 4)
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildModuleUnitWidgets(Color? color, Color? colorAccent, int moduleNumber){
    List<Widget> moduleUnitWidgets = <Widget>[];
    for(int i =0; i<_course.moduleList[moduleNumber].unitList.length; i++ ){
      moduleUnitWidgets.add(_buildUnitInfoWidget(color, colorAccent, i, moduleNumber));
      moduleUnitWidgets.add(Container(height: 16,));
      //TODO check based on data
      moduleUnitWidgets.add(_buildUnitHelpButtons());
      moduleUnitWidgets.add(Container(height: 16,));
      //TODO delete below checkmark widget only after integration
      moduleUnitWidgets.add(
        Center(
          // elevated button
          child: ElevatedButton(
            onPressed: () {},
            // icon of the button
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 60.0,
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
      );
      moduleUnitWidgets.add(Container(height: 16,));
      moduleUnitWidgets.addAll(_buildUnitWidgets(color, colorAccent, _course.moduleList[moduleNumber].unitList[i].contentList, moduleNumber));
    }
    return moduleUnitWidgets;

  }

  List<Widget> _buildUnitWidgets(Color? color, Color? colorAccent, List<Content> contentList, int moduleNumber){
    List<Widget> unitWidgets = <Widget>[];
    // Widget bigCircle = new Container(
    //   width: 100.0,
    //   height: 90.0,
    //   decoration: new BoxDecoration(
    //     color: Colors.white,
    //     shape: BoxShape.circle,
    //   ),
    // );
    for(int i =0; i< contentList.length; i++ ){
      // unitWidgets.add(Center(
      //   // elevated button
      //   child: Stack(
      //     children: [
      //       bigCircle,
      //       Padding(
      //           padding: EdgeInsets.only(top: 10, left: 8),
      //           child: ElevatedButton(
      //             onPressed: () {},
      //             // icon of the button
      //             child: Styles().images?.getImage(moduleIconNames[moduleNumber]) ?? Container(),
      //             // styling the button
      //             style: ElevatedButton.styleFrom(
      //               shape: CircleBorder(),
      //               padding: EdgeInsets.all(10),
      //               // Button color
      //               backgroundColor: colorAccent,
      //             ),
      //           ),
      //       ),
      //     ],
      //   ),
      // ),);
      unitWidgets.add(
        Center(
          child: ElevatedButton(
            onPressed: () {},
            // icon of the button
            child: Styles().images?.getImage(moduleIconNames[moduleNumber]) ?? Container(),
            // styling the button
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(12),
              // Button color
              backgroundColor: colorAccent,
            ),
          ),
        )
      );
      unitWidgets.add(Container(height: 16,));
    }

    return unitWidgets;
  }

  Widget _buildUnitInfoWidget(Color? color, Color? colorAccent, int unitNumber, int moduleNumber){
    return Container(
      color: colorAccent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Unit ' + (unitNumber + 1).toString(), style: Styles().textStyles?.getTextStyle("widget.title.light.huge.fat")),
              Container(
                width: 150,
                child: Text(_course.moduleList[moduleNumber].unitList[unitNumber].name, style: Styles().textStyles?.getTextStyle("widget.title.light.small.fat")),
              )
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},
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
              Text('Resources', style: Styles().textStyles?.getTextStyle("widget.title.light.small.fat")),
            ],
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

  Widget _buildUnitHelpButtons(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          // elevated button
          child: ElevatedButton(
            onPressed: () {},
            // icon of the button
            child: Icon(
              Icons.question_mark_rounded,
              color: Colors.white,
              size: 60.0,
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
        Container(width: 24,),
        Center(
          // elevated button
          child: ElevatedButton(
            onPressed: () {},
            // icon of the button
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 60.0,
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

//TODO delete everything below once integration starts
class Course {
  String name = "Essential Skills";
  String key = "Essential Skills";
  late List<Module> moduleList;

}

class Module {
  late String name;
  late List<Unit> unitList;

  Module(String name, List<Unit> unitList) {
    this.name = name;
    this.unitList = unitList;
  }
}

class Unit{
  late String name;
  late List<Content> contentList;

  Unit(String name, List<Content> contentList) {
    this.name = name;
    this.contentList = contentList;
  }
}

class Content{
  late String key;
  String content = "test";
}

class Schedule{

}