import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ModuleHeaderWidget extends StatelessWidget {
  final Widget? icon;
  final String moduleName;
  final Color? backgroundColor;

  ModuleHeaderWidget({this.icon, required this.moduleName, this.backgroundColor});

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