import 'package:flutter/cupertino.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

import '../../service/Storage.dart';
import '../widgets/RibbonButton.dart';

class SettingsAccessibilityPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => SettingsAccessibilityPageState();

}

class SettingsAccessibilityPageState extends State<SettingsAccessibilityPage> with NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [Storage.notifySettingChanged]);

    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
      Container(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 16),
            Row(children: [
              Expanded(
                  child: Text(Localization().getStringEx('panel.settings.home.accessibility.description.label', 'Accessibility Settings'),
                      style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")))
            ]),
            Container(height: 4),
            ToggleRibbonButton(
                label: Localization().getStringEx('panel.settings.home.accessibility.reduce_motion.label', 'Reduce Motion'),
                toggled: Storage().accessibilityReduceMotion ?? false,
                border: Border.all(color: Styles().colors.blackTransparent018, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(4)),
                onTap: _onTapMotionSetting)
          ]));

  void _onTapMotionSetting(){
      Storage().accessibilityReduceMotion = !(Storage().accessibilityReduceMotion ?? false);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Storage.notifySettingChanged && param == Storage.accessibilityReduceMotionKey) {
      setStateIfMounted();
    }
  }
}