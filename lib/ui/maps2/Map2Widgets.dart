
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Map2ContentTypeButton extends StatelessWidget {
  final String? title;
  final void Function()? onTap;

  Map2ContentTypeButton({super.key, this.title, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child:
    Container(decoration: _decoration, padding: _padding, child:
      Text(title ?? '', style: Styles().textStyles.getTextStyle('widget.button.title.small.medium'),),
    )
  );

  BoxDecoration get _decoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.circular(16),
  );

  EdgeInsetsGeometry get _padding => EdgeInsets.symmetric(horizontal: 12, vertical: 6);
}
