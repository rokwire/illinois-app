/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/parking/ParkingEventsPanel.dart';
import 'package:illinois/ui/polls/CreateStadiumPollPanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeStateFarmCenterWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeStateFarmCenterWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widgets.home.state_farm_center.header.title',  'State Farm Center');

  @override
  State<StatefulWidget> createState() => _HomeStateFarmCenterWidgetState();
}

class _HomeStateFarmCenterWidgetState extends State<HomeStateFarmCenterWidget> implements NotificationsListener{

  List<String>? _displayCodes;
  Set<String>? _availableCodes;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
        }
      });
    }

    _availableCodes = _buildAvailableCodes();
    _displayCodes = _buildDisplayCodes();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateAvailableCodes();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updateDisplayCodes();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> commandsList = _buildCommandsList();
    return commandsList.isNotEmpty ? HomeSlantWidget(favoriteId: widget.favoriteId,
      title: Localization().getStringEx('widgets.home.state_farm_center.header.title', 'State Farm Center'),
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      child: Column(children: commandsList,),
      //flatHeight: 0, slantHeight: 0, childPadding: EdgeInsets.all(16),
    ) : Container();
  }

  List<Widget> _buildCommandsList() {
    List<Widget> contentList = <Widget>[];
    if (_displayCodes != null) {
      for (String code in _displayCodes!.reversed) {
        if ((_availableCodes == null) || _availableCodes!.contains(code)) {
          Widget? contentEntry;
          if (code == 'parking') {
            contentEntry = HomeCommandButton(
              title: Localization().getStringEx('widgets.home.state_farm_center.parking.button.title', 'Parking'),
              description: Localization().getStringEx('widgets.home.state_farm_center.parking.button.description', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
              favorite: HomeFavorite(code, category: widget.favoriteId),
              onTap: _onParking,
            );
          }
          else if (code == 'wayfinding') {
            contentEntry = HomeCommandButton(
              title: Localization().getStringEx('widgets.home.state_farm_center.wayfinding.button.title', 'Wayfinding'),
              description: Localization().getStringEx('widgets.home.state_farm_center.wayfinding.button.description', 'Aenean commodo faucibus sem, id finibus tortor rutrum consectetur.'),
              favorite: HomeFavorite(code, category: widget.favoriteId),
              onTap: _onWayfinding,
            );
          }
          else if (code == 'create_stadium_poll') {
            contentEntry = HomeCommandButton(
              title: Localization().getStringEx('widgets.home.state_farm_center.create_stadium_poll.button.title', 'Create Stadium Poll'),
              description: Localization().getStringEx('widgets.home.state_farm_center.create_stadium_poll.button.description', 'Vivamus aliquam hendrerit risus eget accumsan.'),
              favorite: HomeFavorite(code, category: widget.favoriteId),
              onTap: _onCreateStadiumPoll,
            );
          }

          if (contentEntry != null) {
            if (contentList.isNotEmpty) {
              contentList.add(Container(height: 6,));
            }
            contentList.add(contentEntry);
          }
        }
      }

    }
   return contentList;
  }

  Set<String>? _buildAvailableCodes() => JsonUtils.setStringsValue(FlexUI()['home.state_farm_center']);

  void _updateAvailableCodes() {
    Set<String>? availableCodes = JsonUtils.setStringsValue(FlexUI()['home.state_farm_center']);
    if ((availableCodes != null) && !DeepCollectionEquality().equals(_availableCodes, availableCodes) && mounted) {
      setState(() {
        _availableCodes = availableCodes;
      });
    }
  }

  List<String>? _buildDisplayCodes() {
    LinkedHashSet<String>? favorites = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName(category: widget.favoriteId));
    if (favorites == null) {
      // Build a default set of favorites
      List<String>? fullContent = JsonUtils.listStringsValue(FlexUI().contentSourceEntry('home.state_farm_center'));
      if (fullContent != null) {
        favorites = LinkedHashSet<String>.from(fullContent.reversed);
        Future.delayed(Duration(), () {
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: widget.favoriteId), favorites);
        });
      }
    }
    
    return (favorites != null) ? List.from(favorites) : null;
  }

  void _updateDisplayCodes() {
    List<String>? displayCodes = _buildDisplayCodes();
    if ((displayCodes != null) && !DeepCollectionEquality().equals(_displayCodes, displayCodes) && mounted) {
      setState(() {
        _displayCodes = displayCodes;
      });
    }
  }

  void _onParking() {
    Analytics().logSelect(target: "HomeStateFarmCenterWidget: Parking");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ParkingEventsPanel()));
  }

  void _onWayfinding() {
    Analytics().logSelect(target: "HomeStateFarmCenterWidget: Wayfinding");
    NativeCommunicator().launchMap(target: {
      'latitude': Config().stateFarmWayfinding['latitude'],
      'longitude': Config().stateFarmWayfinding['longitude'],
      'zoom': Config().stateFarmWayfinding['zoom'],
    });
  }

  void _onCreateStadiumPoll() {
    Analytics().logSelect(target: "HomeStateFarmCenterWidget: Create Stadium Poll");
    CreateStadiumPollPanel.present(context);
  }

}
