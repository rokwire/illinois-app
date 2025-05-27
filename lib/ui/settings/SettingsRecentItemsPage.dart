import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';


class SettingsRecentItemsPage extends StatefulWidget{
  final String? parentRouteName;

  const SettingsRecentItemsPage({super.key, this.parentRouteName});

  @override
  State<StatefulWidget> createState() => _SettingsRecentItemsPageState();

}

class _SettingsRecentItemsPageState extends State<SettingsRecentItemsPage> with NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      RecentItems.notifySettingChanged,
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
    if (name == RecentItems.notifySettingChanged) {
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
    Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(top: 25), child:
        Column(children:<Widget>[
          /* Row(children: [
            Expanded(child:
              Text(Localization().getStringEx('panel.settings.home.recent_items.title', 'Browsing History'), style:
                Styles().textStyles.getTextStyle("widget.title.large.fat")
              ),
            ),
          ]),
          Container(height: 4), */
          ToggleRibbonButton(
              label: Localization().getStringEx('panel.settings.home.recent_items.enable.toggle.title', 'Display recently viewed app content'),
              border: Border.all(color: Styles().colors.surfaceAccent),
              borderRadius: BorderRadius.all(Radius.circular(4)),
              toggled: RecentItems().recentItemsEnabled,
              onTap: _onRecentItemsEnabeldToggled
          ),
          Padding(padding: EdgeInsets.only(left: 16, top: 16, bottom: 16), child:
            Text(Localization().getStringEx("panel.settings.home.recent_items.enable.toggle.info", "When enabled, the Illinois app will display the items you recently viewed under Home > Sections > Visited Recently. For quick access, star the Visited Recently section to add it to your Favorites."),
              style: Styles().textStyles.getTextStyle('widget.item.regular.thin'),
            ),
          ),
        ]),
      ),
    ],);


  void _onRecentItemsEnabeldToggled() {
    Analytics().logSelect(target: 'Display recently viewed app content');
    if (RecentItems().recentItemsEnabled) {
      AppAlert.showConfirmationDialog(context,
        message: Localization().getStringEx('panel.settings.home.recent_items.disable.toggle.prompt', 'This will clear your browsing history. Proceed?'),
        positiveButtonLabel: Localization().getStringEx('dialog.ok.title', 'OK'),
        negativeButtonLabel: Localization().getStringEx('dialog.cancel.title', 'Cancel'),
      ).then((value) {
        if (value == true) {
          RecentItems().recentItemsEnabled = false;
        }
      });
    }
    else {
      setState(() {
        RecentItems().recentItemsEnabled = true;
      });
    }
  }
}