
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
  int moduleNumber = 0;
  bool _isFirstModule = true;
  bool _isLastModule = false;

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

    if(moduleNumber != 0){
      _isFirstModule = false;
    }else{
      _isFirstModule = true;
    }

    if(moduleNumber !=4){
      _isLastModule = false;
    }else{
      _isLastModule = true;
    }


    return SingleChildScrollView(
      child: _buildModuleView(),
    );
  }

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }

  Widget _buildModuleView(){
    switch (moduleNumber){
      case 0:
        return Container(
          color: Styles().colors!.essentialSkillsCoachPurple,
          child: _buildModuleInfoView("skills-social", Styles().colors!.essentialSkillsCoachPurple, Styles().colors!.essentialSkillsCoachPurpleAccent),
        );
      case 1:
        return Container(
          color: Styles().colors!.essentialSkillsCoachBlue,
          child: _buildModuleInfoView("skills-management", Styles().colors!.essentialSkillsCoachBlue, Styles().colors!.essentialSkillsCoachBlueAccent),

        );
      case 2:
        return Container(
          color: Styles().colors!.essentialSkillsCoachRed,
          child: _buildModuleInfoView("skills-cooperation", Styles().colors!.essentialSkillsCoachRed, Styles().colors!.essentialSkillsCoachRedAccent),

        );
      case 3:
        return Container(
          color: Styles().colors!.essentialSkillsCoachOrange,
          child: _buildModuleInfoView("skills-emotional", Styles().colors!.essentialSkillsCoachOrange, Styles().colors!.essentialSkillsCoachOrangeAccent),

        );
      case 4:
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
                height: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child:  Container(
                        child: Styles().images?.getImage(moduleType) ?? Container(),
                      ),

                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        (
                          _isFirstModule ? Container(width: 30) : IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            color: Colors.white,
                            onPressed: () {
                              if (moduleNumber != 0){
                                setState(() {
                                  moduleNumber= moduleNumber-1;
                                });
                              }
                            },
                          )
                        ),
                        Text(_course.moduleList[moduleNumber].name,style: Styles().textStyles?.getTextStyle("widget.title.light.large.fat")),
                        (
                          _isLastModule ? Container(width: 30): IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            color: Colors.white,
                            onPressed: () {
                              if (moduleNumber != 4){
                                setState(() {
                                  moduleNumber= moduleNumber+1;
                                });
                              }
                            },
                          )
                        ),
                      ],
                    )
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
      moduleUnitWidgets.add(Container(height: 16,));
      moduleUnitWidgets.addAll(_buildUnitWidgets(color, colorAccent, _course.moduleList[moduleNumber].unitList[i].contentList, moduleNumber));
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
    for(int i =0; i< contentList.length; i++ ){
      unitWidgets.add(Center(
        // elevated button
        child: Stack(
          children: [
            bigCircle,
            Padding(
              padding: EdgeInsets.only(top: 4, left: 4),
              child: ElevatedButton(
                onPressed: () {},
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
                  backgroundColor: colorAccent,
                ),
              ),
            ),
          ],
        ),
      ),);
      // unitWidgets.add(
      //   Center(
      //     child: ElevatedButton(
      //       onPressed: () {},
      //       // icon of the button
      //       child: Styles().images?.getImage(moduleIconNames[moduleNumber]) ?? Container(),
      //       // styling the button
      //       style: ElevatedButton.styleFrom(
      //         shape: CircleBorder(),
      //         padding: EdgeInsets.all(12),
      //         // Button color
      //         backgroundColor: colorAccent,
      //       ),
      //     ),
      //   )
      // );
      unitWidgets.add(Container(height: 16,));
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
                  child: Text(_course.moduleList[moduleNumber].unitList[unitNumber].name, style: Styles().textStyles?.getTextStyle("widget.title.light.regular.fat")),
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

  Widget _buildUnitHelpButtons(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          // elevated button
          child: ElevatedButton(
            onPressed: () {},
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