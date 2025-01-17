/*
 * Copyright 2025 Board of Trustees of the University of Illinois.
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

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class NotificationsFilterPanel extends StatefulWidget {
  final bool? unread;
  final bool? muted;

  NotificationsFilterPanel._({this.unread, this.muted});

  static void present(BuildContext context, {bool? unread, bool? muted}) {
    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        useRootNavigator: true,
        clipBehavior: Clip.antiAlias,
        backgroundColor: Styles().colors.background,
        constraints: BoxConstraints(maxHeight: height, minHeight: height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return NotificationsFilterPanel._(unread: unread, muted: muted);
        });
  }

  @override
  _NotificationsFilterPanelState createState() => _NotificationsFilterPanelState();
}

class _NotificationsFilterPanelState extends State<NotificationsFilterPanel> {
  bool? _unread;
  bool? _muted;

  @override
  void initState() {
    super.initState();
    _unread = widget.unread;
    _muted = widget.muted;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [_buildHeader(), Container(color: Styles().colors.surfaceAccent, height: 1), Expanded(child: _buildContent())]);
  }

  Widget _buildHeader() {
    return Container(
        color: Styles().colors.white,
        child: Row(children: [
          Expanded(
              child: Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Semantics(
                      container: true,
                      header: true,
                      child: Text(Localization().getStringEx('panel.settings.notifications.header.inbox.label', 'Notifications'),
                          style: Styles().textStyles.getTextStyle("widget.sheet.title.regular"))))),
          Semantics(
              label: Localization().getStringEx('dialog.close.title', 'Close'),
              hint: Localization().getStringEx('dialog.close.hint', ''),
              container: true,
              button: true,
              child: InkWell(
                  onTap: _onTapClose,
                  child: Container(
                      padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                      child: Styles().images.getImage('close-circle', excludeFromSemantics: true))))
        ]));
  }

  Widget _buildContent() {
    return Semantics(
        container: true,
        child: SingleChildScrollView(
            child: Container(
                color: Styles().colors.background,
                padding: EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildViewFilters(), _buildDateFilters()]))));
  }

  Widget _buildViewFilters() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Localization().getStringEx('panel.inbox.filter.view.label', 'VIEW'),
          style: Styles().textStyles.getTextStyle('widget.title.regular.fat')),
      Padding(
          padding: EdgeInsets.only(top: 10),
          child: _buildToggleWidget(
              label: Localization().getStringEx('panel.inbox.filter.notifications.toggle.unread.label', 'Unread Notifications'),
              value: _unread,
              onTapValue: _onTapUnread)),
      Padding(
          padding: EdgeInsets.only(top: 10),
          child: _buildToggleWidget(
              label: Localization().getStringEx('panel.inbox.filter.notifications.toggle.muted.label', 'Muted Notifications'),
              value: _muted,
              onTapValue: _onTapMuted)),
      Padding(
          padding: EdgeInsets.only(left: 12, top: 6),
          child: Text(
              Localization()
                  .getStringEx('panel.inbox.filter.notifications.toggle.muted.description', 'View notifications you have turned off.'),
              style: Styles().textStyles.getTextStyle('panel.inbox.notifications.filter.muted.description')))
    ]);
  }

  Widget _buildToggleWidget({required String label, bool? value, required void Function()? onTapValue}) {
    return Container(
        decoration: BoxDecoration(
            color: Styles().colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 4.0, offset: Offset(2, 2))]),
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Padding(padding: EdgeInsets.only(left: 10), child: Text(label, style: Styles().textStyles.getTextStyle('widget.info.small'))),
          InkWell(
              onTap: onTapValue,
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Styles().images.getImage((value == true) ? 'toggle-on' : 'toggle-off') ?? Container()))
        ]));
  }

  void _onTapMuted() {
    setStateIfMounted(() {
      _muted = (_muted != null) ? !_muted! : true;
    });
  }

  void _onTapUnread() {
    setStateIfMounted(() {
      _unread = (_unread != null) ? !_unread! : true;
    });
  }

  Widget _buildDateFilters() {
    return Padding(
        padding: EdgeInsets.only(top: 16),
        child: Column(children: [
          Text(Localization().getStringEx('panel.inbox.filter.date.label', 'DATE RANGE'),
              style: Styles().textStyles.getTextStyle('widget.title.regular.fat'))
        ]));
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }
}
