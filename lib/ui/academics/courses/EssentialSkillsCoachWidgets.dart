import 'package:flutter/material.dart';
import 'package:neom/model/CustomCourses.dart';
import 'package:neom/ui/academics/courses/PDFPanel.dart';
import 'package:neom/ui/academics/courses/UnitInfoPanel.dart';
import 'package:neom/ui/academics/courses/VideoPanel.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:neom/ui/surveys/SurveyPanel.dart';
import 'package:url_launcher/url_launcher.dart';

class EssentialSkillsCoachWidgets {
  static void openPdfContent(BuildContext context, String? resourceName, String? resourceKey, {Function(dynamic)? callback}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => PDFPanel(resourceName: resourceName, resourceKey: resourceKey,),
    ),).then((result) => callback?.call(result));
  }

  static void openVideoContent(BuildContext context, String? resourceName, String? resourceKey, {Function(dynamic)? callback}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => VideoPanel(resourceName: resourceName, resourceKey: resourceKey,),
    ),).then((result) => callback?.call(result));
  }

  static Future<void> openUrlContent(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  static void openSurveyContent(BuildContext context, String? resourceKey, {Function(dynamic)? callback}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => SurveyPanel(survey: resourceKey, onComplete: callback, tabBar: uiuc.TabBar(),),
    ),);
  }

  static void openTextContent(BuildContext context, {required Content content, required UserContentReference contentReference,
    Color? color, Color? colorAccent, required bool preview, Widget? moduleIcon, required String moduleName, Function(dynamic)? callback}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => UnitInfoPanel(
        content: content,
        contentReference: contentReference,
        color: color,
        colorAccent: colorAccent,
        preview: preview,
        moduleIcon: moduleIcon,
        moduleName: moduleName,
      ),
    ),).then((result) => callback?.call(result));
  }
}

class EssentialSkillsCoachModuleHeader extends StatelessWidget {
  final Widget? icon;
  final String moduleName;
  final Color? backgroundColor;

  EssentialSkillsCoachModuleHeader({this.icon, required this.moduleName, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Flexible(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: icon,
              ),
            ),
            Flexible(
              flex: 4,
              child: Center(
                child: Padding(padding: EdgeInsets.only(right: 16),
                  child: Text(moduleName, style: Styles().textStyles.getTextStyle("widget.title.light.medium_large.extra_fat"))
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EssentialSkillsCoachDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?)? onChanged;

  EssentialSkillsCoachDropdown({required this.value, required this.items, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
      decoration: BoxDecoration(
        color: Styles().colors.surface,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton(
              alignment: AlignmentDirectional.centerStart,
              value: value,
              iconDisabledColor: Styles().colors.fillColorSecondary,
              iconEnabledColor: Styles().colors.fillColorSecondary,
              focusColor: Styles().colors.surface,
              dropdownColor: Styles().colors.surface,
              underline: Divider(color: Styles().colors.fillColorSecondary, height: 1.0, indent: 16.0, endIndent: 16.0),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              isExpanded: true,
              items: items,
              onChanged: onChanged,
          )
      ),
    );
  }
}