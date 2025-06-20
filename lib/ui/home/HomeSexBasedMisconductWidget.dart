import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';

class HomeSexBasedMisconductWidget extends StatelessWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeSexBasedMisconductWidget({super.key, this.favoriteId, this.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
      HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
        title: title,
      );

  static String get title => Localization().getStringEx('widget.home.sex_based_misconduct.title', 'Sex-Based Misconduct');

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: favoriteId,
      title: title,
      titleIconKey: 'resources',
      child: _contentWidget(context),
    );
  }

  Widget _contentWidget(BuildContext context) =>
      Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information about reporting, resources, and support for those affected by sex-based misconduct.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 12),
          Text(
            'Think you or a friend may have experienced sex-based misconduct? Help is available.',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            '(Reminder: your app activity is not shared with others.)',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: () {
              Analytics().logSelect(target: 'Sex-Based Misconduct Resources');
              // TODO: Panel(s) for A Path Forward Pages
              // Navigator.push(context, CupertinoPageRoute(...));
              // TODO: Make the survey call(s) and display subsets of the JSON that comes back
              // Call: Surveys().loadSurvey(‘cabb1338-48df-4299-8c2a-563e021f82ca’)
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('View resources', style: TextStyle(color: Theme.of(context).primaryColor)),
                Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).primaryColor),
              ],
            ),
          ),
        ],
      )
      );
}
