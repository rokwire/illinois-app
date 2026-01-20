import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/web_semantics.dart';

import '../../service/Storage.dart';
import '../widgets/RibbonButton.dart';

class SettingsAccessibilityPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => SettingsAccessibilityPageState();

}

class SettingsAccessibilityPageState extends State<SettingsAccessibilityPage> with NotificationsListener {

  final FocusNode _entryFocusNode = FocusNode();

  @override
  void initState() {
    NotificationService().subscribe(this, [Storage.notifySettingChanged]);

    super.initState();
  }

  @override
  void dispose() {
    _entryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(padding: EdgeInsets.only(top: 16), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _favoritesSection,
      Container(height: 25),
      _adaSection,
    ])
  );

  Widget get _favoritesSection =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child:
          Text(Localization().getStringEx('panel.settings.home.favorites.description.label', 'Favorites'), style:
            Styles().textStyles.getTextStyle("widget.detail.regular.fat")
          )
        )
      ]),
      Container(height: 4),
      WebFocusableSemanticsWidget(focusNode: _entryFocusNode, onSelect: _onTapMotionSetting, child: ToggleRibbonButton(
        title: Localization().getStringEx('panel.settings.home.accessibility.reduce_motion.label', 'Reduce motion'),
        toggled: Storage().accessibilityReduceMotion == true,
        border: Border.all(color: Styles().colors.blackTransparent018, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(4)),
        onTap: _onTapMotionSetting
      ))
    ]);

  void _onTapMotionSetting(){
    bool accessibilityReduceMotion = Storage().accessibilityReduceMotion != true;
    Analytics().logSelect(target: 'Reduce Motion: ${accessibilityReduceMotion}');
    setStateIfMounted(() {
      Storage().accessibilityReduceMotion = accessibilityReduceMotion;
    });
  }

  Widget get _adaSection =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children:<Widget>[
      Row(children: [
        Expanded(child:
          Text(Localization().getStringEx('panel.settings.home.accessibility.map.label', 'Map'), style:
            Styles().textStyles.getTextStyle("widget.detail.regular.fat")
          ),
        ),
      ]),
      Container(height: 4),
       WebFocusableSemanticsWidget(onSelect: _onRequireAdaToggled, child: ToggleRibbonButton(
        title: Localization().getStringEx('panel.settings.home.accessibility.ada_navigation.label', 'Navigate to ADA-accessible building entrances for My Courses'),
        toggled: StudentCourses().requireAda == true,
        border: Border.all(color: Styles().colors.blackTransparent018, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(4)),
        onTap: _onRequireAdaToggled
      ))
    ]);

  void _onRequireAdaToggled() {
    bool requireAda = StudentCourses().requireAda != true;
    Analytics().logSelect(target: 'Require ADA entrances: ${requireAda}');
    setStateIfMounted(() {
      StudentCourses().requireAda = requireAda;
    });
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Storage.notifySettingChanged && param == Storage.accessibilityReduceMotionKey) {
      setStateIfMounted();
    }
  }
}