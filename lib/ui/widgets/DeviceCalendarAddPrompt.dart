
import 'package:flutter/material.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class DeviceCalendarAddPrompt extends StatefulWidget {

  const DeviceCalendarAddPrompt({super.key});

  static Future<bool?> show(BuildContext context) =>
    showDialog<bool?>(context: context, builder: (_) =>
      Material(type: MaterialType.transparency, child: DeviceCalendarAddPrompt())
    );

  @override
  State<StatefulWidget> createState() => _DeviceCalendarAddPromptState();
}

class _DeviceCalendarAddPromptState extends State<DeviceCalendarAddPrompt>{

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
                  child: Text(Localization().getStringEx('prompt.device_calendar.msg.add_event', 'Would you like to add this event to your device\'s calendar?'),
                    style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"),
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
                          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
                          borderColor: Styles().colors!.fillColorPrimary,
                          backgroundColor: Styles().colors!.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: _onDecline
                          ))),
                    Expanded(child:
                      Padding(padding: EdgeInsets.all(8),
                        child: RoundedButton(
                          label: Localization().getStringEx("dialog.yes.title","Yes"),
                          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
                          borderColor: Styles().colors!.fillColorSecondary,
                          backgroundColor: Styles().colors!.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: (){
                            Navigator.of(context).pop();
                            _onConfirm();
                          }))),
                ]),
                Container(height: 16,),
                ToggleRibbonButton(
                    label: Localization().getStringEx('panel.settings.home.calendar.settings.prompt.label', 'Prompt when saving events or appointments to calendar'),
                    border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium"),
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
