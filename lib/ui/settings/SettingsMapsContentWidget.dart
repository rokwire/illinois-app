import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/OnCampus.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SettingsMapsContentWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _SettingsMapsContentWidgetState();

}

class _SettingsMapsContentWidgetState extends State<SettingsMapsContentWidget> with NotificationsListener{

  @override
  void initState() {
    NotificationService().subscribe(this, [
      OnCampus.notifyChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    if (name == OnCampus.notifyChanged) {
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOnCampusSettings(),
        _buildAdaSettings()
      ],
    );
  }

//OnCampus Settings
  Widget _buildOnCampusSettings() {
    bool onCampusRegionMonitorEnabled = OnCampus().enabled;
    bool onCampusRegionMonitorSelected = OnCampus().monitorEnabled;

    bool campusRegionManualInsideSelected = OnCampus().monitorManualInside;
    bool onCampusSelected = !onCampusRegionMonitorSelected &&
        campusRegionManualInsideSelected;
    bool offCampusSelected = !onCampusRegionMonitorSelected &&
        !campusRegionManualInsideSelected;

    String onCampusRegionMonitorInfo = onCampusRegionMonitorEnabled ?
    Localization().getStringEx(
        'panel.settings.home.calendar.on_campus.location_services.required.label',
        'requires location services') :
    Localization().getStringEx(
        'panel.settings.home.calendar.on_campus.location_services.not_available.label',
        'not available');
    String autoOnCampusInfo = Localization().getStringEx(
        'panel.settings.home.calendar.on_campus.radio_button.auto.title',
        'Automatically detect when I am on Campus') +
        '\n($onCampusRegionMonitorInfo)';

    return Padding(padding: EdgeInsets.only(top: 25), child:
    Column(children: <Widget>[
      Row(children: [
        Expanded(child:
        Text(Localization().getStringEx(
            '', 'My Location'), style:
        Styles().textStyles.getTextStyle("widget.title.large.fat")
        ),
        ),
      ]),
      _buildOnCampusRadioItem(
          label: autoOnCampusInfo,
          enabled: onCampusRegionMonitorEnabled,
          selected: onCampusRegionMonitorSelected,
          onTap: _onTapOnCampusAuto),
      _buildOnCampusRadioItem(
          label: Localization().getStringEx(
              'panel.settings.home.calendar.on_campus.radio_button.on.title',
              'Always make me on campus'),
          selected: onCampusSelected,
          onTap: _onTapOnCampusOn),
      _buildOnCampusRadioItem(
          label: Localization().getStringEx(
              'panel.settings.home.calendar.on_campus.radio_button.off.title',
              'Always make me off campus'),
          selected: offCampusSelected,
          onTap: _onTapOnCampusOff),
    ]),
    );
  }

  Widget _buildOnCampusRadioItem(
      {required String label, bool enabled = true, required bool selected, VoidCallback? onTap}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 4),
      Semantics(label: label, enabled: enabled, checked: selected, inMutuallyExclusiveGroup: true, child:
        InkWell(onTap: onTap, child:
          Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                  color: Styles().colors.white,
                  border: Border.all(
                      color: Styles().colors.blackTransparent018, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child:
                    ExcludeSemantics(child:
                      Text(label, style: enabled ? Styles().textStyles.getTextStyle(
                          "widget.button.title.enabled") : Styles().textStyles
                          .getTextStyle("widget.button.title.disabled")
                      )
                    )
                ),
                Padding(padding: EdgeInsets.only(left: 5), child:
                Styles().images.getImage(
                    selected ?  'radio-button-on' : 'radio-button-off',
                    excludeFromSemantics: true)
                )
              ])
          )
        )
      )
  ]);

  void _onTapOnCampusAuto() {
    if (OnCampus().enabled && !OnCampus().monitorEnabled) {
      Analytics().logSelect(target: 'Automatically detect when I am on Campus');
      setState(() {
        OnCampus().monitorEnabled = true;
      });
    }
  }

  void _onTapOnCampusOn() {
    if ((OnCampus().monitorEnabled || !OnCampus().monitorManualInside)) {
      Analytics().logSelect(target: 'Always make me on campus');
      setState(() {
        OnCampus().monitorEnabled = false;
        OnCampus().monitorManualInside = true;
      });
    }
  }

  void _onTapOnCampusOff() {
    if ((OnCampus().monitorEnabled || OnCampus().monitorManualInside)) {
      Analytics().logSelect(target: 'Always make me off campus');
      setState(() {
        OnCampus().monitorEnabled = false;
        OnCampus().monitorManualInside = false;
      });
    }
  }

  //ADA
  Widget _buildAdaSettings() =>
    Padding(padding: EdgeInsets.only(top: 25), child:
      Column(children:<Widget>[
        Row(children: [
          Expanded(child:
          Text(Localization().getStringEx('panel.settings.home.calendar.ada.title', 'Accessibility Needs'), style:
          Styles().textStyles.getTextStyle("widget.title.large.fat")
          ),
          ),
        ]),
        Container(height: 4),
        ToggleRibbonButton(
            label: Localization().getStringEx('panel.settings.home.calendar.ada.toggle.title', 'Display ADA accessible building entrances for My Courses'),
            border: Border.all(color: Styles().colors.surfaceAccent),
            borderRadius: BorderRadius.all(Radius.circular(4)),
            toggled: StudentCourses().requireAda,
            onTap: _onRequireAdaToggled)
      ]),
    );

  void _onRequireAdaToggled() {
    Analytics().logSelect(target: 'I require ADA entrances');
    setStateIfMounted(() {
      StudentCourses().requireAda = !StudentCourses().requireAda;
    });
  }
}