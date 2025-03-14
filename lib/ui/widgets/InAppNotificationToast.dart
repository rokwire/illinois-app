import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/popup_toast.dart';

class InAppNotificationToast extends StatelessWidget {

  final Widget message;
  final Widget? action;

  final EdgeInsetsGeometry padding;
  final Decoration? decoration;
  final double widthRatio;

  InAppNotificationToast({ super.key,
    required this.message,
    this.action,
    this.padding = PopupToast.defaultPadding,
    this.widthRatio = PopupToast.defaultWidthRatio,
    this.decoration,
  });

  InAppNotificationToast.message(String message, {
    String? actionText, void Function()? onAction, void Function()? onMessage,
    EdgeInsetsGeometry padding = PopupToast.defaultPadding,
    double widthRatio = PopupToast.defaultWidthRatio,
    Decoration? decoration,
  }) : this(
    
      message: (onMessage != null) ?
        InkWell(onTap: onMessage, child:
          Text(message, style: Styles().textStyles.getTextStyle('widget.message.regular.semi_fat'),)
        ) :
        Text(message, style: Styles().textStyles.getTextStyle('widget.message.regular.semi_fat'),),

      action: ((actionText != null) && (onAction != null)) ?
        TextButton(onPressed: onAction, child:
          Text(actionText, style: Styles().textStyles.getTextStyle('widget.button.title.medium.fat.dark.underline'),
        ),
      ) : null,

      padding: padding, widthRatio: widthRatio, decoration: decoration
  );

  @override
  Widget build(BuildContext context) =>
    PopupToast(padding: padding, widthRatio: widthRatio, decoration: decoration, child:
      Row(children: [
        Expanded(child:
          message
        ),
        if (action != null)
          Padding(padding: const EdgeInsets.only(left: 4), child:
            action
          )
      ])
    );
}
