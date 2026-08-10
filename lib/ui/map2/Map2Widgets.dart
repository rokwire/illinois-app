
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
          ExcludeSemantics(child:
            Text(title ?? '', style: Styles().textStyles.getTextStyle('widget.button.title.small.medium'),),
          )
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

class Map2NavDirectionsButton extends StatelessWidget {
  final String imageKey;
  final double imageSize;
  final EdgeInsetsGeometry contentPadding;
  final void Function()? onTap;

  // ignore: unused_element_parameter
  Map2NavDirectionsButton(this.imageKey, { super.key,
    this.imageSize = _imageSize,
    this.contentPadding = _contentPadding,
    this.onTap
  });

  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child:
    Container(decoration: _buttonDecoration, child:
      Padding(padding: contentPadding, child:
        SizedBox(width: imageSize, height: imageSize, child:
          Center(child:
            Styles().images.getImage(imageKey, size: imageSize, color: Styles().colors.fillColorPrimary),
          ),
        )
      )
    )
  );

  static const EdgeInsetsGeometry _contentPadding = EdgeInsets.all(12);
  static const double _imageSize = 18;

  static Decoration get _buttonDecoration => BoxDecoration(
    color: Styles().colors.surface,
    borderRadius: _buttonBorderRadius,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
  );

  static const BorderRadiusGeometry _buttonBorderRadius = BorderRadius.all(_buttonRadius);
  static const Radius _buttonRadius = Radius.circular(8);
}
