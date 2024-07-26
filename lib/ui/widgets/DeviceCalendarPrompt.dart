
import 'package:flutter/material.dart';
import 'package:neom/service/Storage.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class DeviceCalendarAddEventPrompt extends DeviceCalendarPrompt {
  static String get message => Localization().getStringEx('model.device_calendar.prompt.add.event', 'Would you like to add this event to your device\'s calendar?');

  DeviceCalendarAddEventPrompt({Key? key}) :
    super(message, key: key);

  static Future<bool?> show(BuildContext context) =>
    DeviceCalendarPrompt.show(context, message);
}

class DeviceCalendarPrompt extends StatefulWidget {
  final String prompt;

  const DeviceCalendarPrompt(this.prompt, { super.key });

  static Future<bool?> show(BuildContext context, String prompt) =>
    showDialog<bool?>(context: context, builder: (_) =>
      Material(type: MaterialType.transparency, child: DeviceCalendarPrompt(prompt,))
    );

  @override
  State<StatefulWidget> createState() => _DeviceCalendarPromptState();
}

class _DeviceCalendarPromptState extends State<DeviceCalendarPrompt>{

  @override
  Widget build(BuildContext context) =>
     Dialog(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
                Padding( padding: EdgeInsets.all(8),
                  child: Text(widget.prompt,
                    style: Styles().textStyles.getTextStyle("widget.message.medium.thin"),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(height: 8,),
                Row(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.all(8),
                        child: RoundedButton(
                          label: Localization().getStringEx("dialog.no.title","No"),
                          textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
                          borderColor: Styles().colors.fillColorPrimary,
                          backgroundColor: Styles().colors.surface,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: _onDecline
                          ))),
                    Expanded(child:
                      Padding(padding: EdgeInsets.all(8),
                        child: RoundedButton(
                          label: Localization().getStringEx("dialog.yes.title","Yes"),
                          textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
                          borderColor: Styles().colors.fillColorSecondary,
                          backgroundColor: Styles().colors.surface,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: _onConfirm
                        ))),
                ]),
                Container(height: 16,),
                ToggleRibbonButton(
                    label: Localization().getStringEx('panel.settings.home.calendar.settings.prompt.label', 'Prompt when saving events or appointments to calendar'),
                    border: Border.all(color: Styles().colors.blackTransparent018, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium"),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    toggled: Storage().calendarShouldPrompt,
                    onTap: _onPromptChange
                ),
                Container(height: 8,),
            ]),
        ));

  void _onConfirm() =>
    Navigator.of(context).pop(true);

  void _onDecline() =>
    Navigator.of(context).pop(false);

  void _onPromptChange() =>
    setStateIfMounted(() {
      Storage().calendarShouldPrompt = !Storage().calendarShouldPrompt;
    });
}

class DeviceCalendarMessage extends StatelessWidget {
  final String message;

  const DeviceCalendarMessage(this.message, { super.key });

  static Future<bool?> show(BuildContext context, String message) =>
    showDialog<bool?>(context: context, builder: (_) =>
      Material(type: MaterialType.transparency, child: DeviceCalendarMessage(message,))
    );

  @override
  Widget build(BuildContext context) => Dialog(child:
    Padding(padding: EdgeInsets.all(16), child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        Padding( padding: EdgeInsets.all(8), child:
          Text(message, style: Styles().textStyles.getTextStyle("widget.message.medium.thin"), textAlign: TextAlign.center,),
        ),
        Container(height: 8,),
        Row(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: Container()),
            Expanded(flex: 2, child:
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                RoundedButton(
                  label: Localization().getStringEx("dialog.ok.title", "OK"),
                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
                  borderColor: Styles().colors.fillColorPrimary,
                  backgroundColor: Styles().colors.surface,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () => Navigator.of(context).pop()
                  )
              ),
            ),
            Expanded(flex: 1, child: Container()),
        ]),

      ]),
    )
  );
}
