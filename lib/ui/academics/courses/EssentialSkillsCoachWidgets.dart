import 'package:flutter/material.dart';
import 'package:rokwire_plugin/gen/styles.dart';
import 'package:rokwire_plugin/service/styles.dart';

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
        color: AppColors.surface,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton(
              alignment: AlignmentDirectional.centerStart,
              value: value,
              iconDisabledColor: AppColors.fillColorSecondary,
              iconEnabledColor: AppColors.fillColorSecondary,
              focusColor: AppColors.surface,
              dropdownColor: AppColors.surface,
              underline: Divider(color: AppColors.fillColorSecondary, height: 1.0, indent: 16.0, endIndent: 16.0),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              isExpanded: true,
              items: items,
              onChanged: onChanged,
          )
      ),
    );
  }
}