
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Map2ContentTypeButton extends StatelessWidget {
  final String? title;
  final String? label;
  final String? hint;
  final void Function()? onTap;
  final EdgeInsetsGeometry padding;

  Map2ContentTypeButton(this.title, {super.key, this.label, this.hint, this.onTap, this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6) });

  @override
  Widget build(BuildContext context) =>
    Semantics(label: label ?? title, hint: hint, button: true, child:
      InkWell(onTap: onTap, child:
        Container(decoration: _decoration, padding: padding, child:
          Text(title ?? '', style: Styles().textStyles.getTextStyle('widget.button.title.small.medium'),),
        )
      )
    );

  BoxDecoration get _decoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.circular(16),
  );
}

class Map2FilterImageButton extends StatelessWidget {
  final Widget? image;
  final String? imageKey;
  final String? label;
  final String? hint;
  final void Function()? onTap;
  final EdgeInsetsGeometry padding;

  static const EdgeInsetsGeometry defaultPadding = const EdgeInsets.all(9);
  static const double defaultHeight = 18 + 2 * 9;

  Map2FilterImageButton({super.key, this.image, this.imageKey, this.hint, this.label, this.onTap,
    this.padding = defaultPadding
  });

  @override
  Widget build(BuildContext context) =>
    Semantics(label: label, hint: hint, button: true, child:
      InkWell(onTap: onTap, child:
        Container(decoration: _decoration, padding: padding, child:
          image ?? Styles().images.getImage(imageKey, excludeFromSemantics: true),
        )
      ),
    );

  BoxDecoration get _decoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.circular(12),
  );
}

class Map2FilterTextButton extends StatelessWidget {
  final String? title;
  final String? label;
  final String? hint;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final bool toggled;
  final void Function()? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry leftIconPadding;
  final EdgeInsetsGeometry rightIconPadding;

  Map2FilterTextButton({super.key, this.title, this.label, this.hint, this.leftIcon, this.rightIcon, this.onTap,
    this.toggled = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    this.leftIconPadding = const EdgeInsets.only(right: 6),
    this.rightIconPadding = const EdgeInsets.only(left: 6),
  });

  @override
  Widget build(BuildContext context) =>
    Semantics(label: label ?? title, hint: hint, button: true, child:
      InkWell(onTap: onTap, child:
        Container(decoration: _decoration, padding: padding, child:
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (leftIcon != null)
              Padding(padding: leftIconPadding, child: leftIcon,),
            Text(title ?? '', style: _titleTextStyle,),
            if (rightIcon != null)
              Padding(padding: rightIconPadding, child: rightIcon,),
          ],)
        )
      )
    );

  BoxDecoration get _decoration => BoxDecoration(
    color: _backColor,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.circular(18),
  );

  Color? get _backColor => toggled ? Styles().colors.fillColorPrimary : Styles().colors.surface;
  TextStyle? get _titleTextStyle => toggled ? Styles().textStyles.getTextStyle('widget.title.light.small') : Styles().textStyles.getTextStyle('widget.button.title.small.medium');
}

class Map2PlainImageButton extends StatelessWidget {
  final Widget? image;
  final String? imageKey;
  final String? label;
  final String? hint;
  final void Function()? onTap;
  final EdgeInsetsGeometry padding;

  Map2PlainImageButton({super.key, this.image, this.imageKey, this.hint, this.label, this.onTap, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) =>
    Semantics(label: label, hint: hint, button: true, excludeSemantics: true, child:
      InkWell(onTap: onTap, child:
        Padding(padding: padding, child:
          image ?? Styles().images.getImage(imageKey, excludeFromSemantics: true),
        ),
      ),
    );
}
