/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentCard.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeAppointmentsWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeAppointmentsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) => 
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position, title: title);

  static String get title => Localization().getStringEx('widget.home.appointments.my.label.header.title', 'MyMcKinley Appointments');

  @override
  State<StatefulWidget> createState() => _HomeAppointmentsWidgetState();
}

class _HomeAppointmentsWidgetState extends State<HomeAppointmentsWidget> implements NotificationsListener {
  List<Appointment>? _appointments;

  DateTime? _pausedDateTime;
  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  final double _pageSpacing = 16;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [Auth2.notifyLoginChanged, AppLivecycle.notifyStateChanged]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _updateAppointments();
        }
      });
    }
    _loadAppointments();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController?.dispose();
    NotificationService().unsubscribe(this);
  }

  void _loadAppointments() {
    Appointments().loadAppointments(onlyUpcoming: true).then((appointments) {
      setStateIfMounted(() {
        _appointments = appointments;
      });
    });
  }

  void _updateAppointments() {
    Appointments().loadAppointments(onlyUpcoming: true).then((appointments) {
      if (mounted && !DeepCollectionEquality().equals(_appointments, appointments)) {
        setState(() {
          _appointments = appointments;
          _pageViewKey = UniqueKey();
          _pageController = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(
        favoriteId: widget.favoriteId,
        title: HomeAppointmentsWidget.title,
        titleIconKey: 'campus-tools', // TODO: Change icon
        child: _haveAppointments ? _buildContent() : _buildEmpty());
  }

  Widget _buildContent() {
    List<Widget> pages = <Widget>[];
    if (CollectionUtils.isNotEmpty(_appointments)) {
      for (Appointment? appointment in _appointments!) {
        if (appointment != null) {
          pages.add(
              Padding(padding: EdgeInsets.only(right: _pageSpacing), child: Semantics(child: AppointmentCard(appointment: appointment))));
        }
      }
    }

    double pageHeight = 90 * 2 * MediaQuery.of(context).textScaleFactor;

    if (_pageController == null) {
      double screenWidth = MediaQuery.of(context).size.width;
      double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
      _pageController = PageController(viewportFraction: pageViewport);
    }

    return Column(children: [
      Container(
          height: pageHeight,
          child: PageView(key: _pageViewKey, controller: _pageController, children: pages, allowImplicitScrolling: true)),
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: pages.length),
      LinkButton(
          title: Localization().getStringEx('widget.home.appointments.my.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.appointments.my.button.all', 'Tap to view all appointments'),
          onTap: _onSeeAll)
    ]);
  }

  Widget _buildEmpty() {
    return HomeMessageCard(
        message: Localization().getStringEx('widget.home.appointments.my.text.empty.description',
            'You currently have no upcoming appointments linked within the {{app_title}} app.').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')));
  }

  @override
  void onNotification(String name, param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    } else if (name == Auth2.notifyLoginChanged) {
      _loadAppointments();
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateAppointments();
        }
      }
    }
  }

  bool get _haveAppointments {
    return _appointments?.isNotEmpty ?? false;
  }

  void _onSeeAll() {
    Analytics().logSelect(target: "View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.appointments)));
  }
}
