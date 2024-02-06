import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/ui/academics/courses/ModuleHeaderWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class UnitInfoPanel extends StatelessWidget {
  final Content content;
  final Map<String, dynamic>? data;
  final Color? color;
  final Color? colorAccent;
  final bool preview;

  final Widget? moduleIcon;
  final String moduleName;

  const UnitInfoPanel({required this.content, required this.data, required this.color, required this.colorAccent, required this.preview, this.moduleIcon, required this.moduleName});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => _saveProgress(context, didPop),
      child: Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx("panel.essential_skills_coach.unit_info.header.title", "Unit Information"), textStyle: Styles().textStyles.getTextStyle('header_bar'), onLeading: () => _saveProgress(context, false),),
        body: Column(
          //TODO add any extra content i.e. videos and files
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  ModuleHeaderWidget(icon: moduleIcon, moduleName: moduleName, backgroundColor: color,),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Styles().images.getImage(content.styles?.images?['icon']) ?? Container(),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                            side: BorderSide(color: color ?? Styles().colors.surface, width: 4.0, strokeAlign: BorderSide.strokeAlignOutside),
                            padding: EdgeInsets.all(8),
                            backgroundColor: colorAccent,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(content.name?.toUpperCase() ?? "", style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat")?.apply(color: color)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(content.details ?? "", style: Styles().textStyles.getTextStyle("widget.title.light.large")?.apply(color: color)),
                        ),
                        //TODO other content to be added here
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: Container(),),
            Padding(
              padding: EdgeInsets.all(16),
              child: RoundedButton(
                  label: Localization().getStringEx('panel.essential_skills_coach.unit_info.button.continue.label', 'Continue'),
                  textStyle: Styles().textStyles.getTextStyle("widget.title.light.regular.fat"),
                  backgroundColor: color,
                  borderColor: color,
                  onTap: () => _saveProgress(context, false)),
            ),
          ],
        ),
        backgroundColor: Styles().colors.background,
      )
    );
  }

  void _saveProgress(BuildContext context, bool didPop) async {
    Map<String, dynamic>? updatedData;
    bool returnData = preview ? false : (data?['complete'] != true);
    if (returnData) {
      updatedData = data != null ? Map.from(data!) : {};
      updatedData['complete'] = true;
    }
    if (!didPop) {
      Navigator.pop(context, returnData ? updatedData : null);
    }
  }
}