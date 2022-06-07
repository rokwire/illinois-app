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

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WellnessToDoHomeContentWidget extends StatefulWidget {
  WellnessToDoHomeContentWidget();

  @override
  State<WellnessToDoHomeContentWidget> createState() => _WellnessToDoHomeContentWidgetState();
}

class _WellnessToDoHomeContentWidgetState extends State<WellnessToDoHomeContentWidget> {
  late _ToDoTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = _ToDoTab.daily;
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [_buildTabButtonRow()]);
  }

  Widget _buildTabButtonRow() {
    return Row(children: [
      Expanded(
          child: _TabButton(
              position: _TabButtonPosition.first,
              selected: (_selectedTab == _ToDoTab.daily),
              label: Localization().getStringEx('panel.wellness.todo.tab.daily.label', 'Daily'),
              hint: Localization().getStringEx('panel.wellness.todo.tab.daily.hint', ''),
              onTap: () => _onTabChanged(tab: _ToDoTab.daily))),
      Expanded(
          child: _TabButton(
              position: _TabButtonPosition.middle,
              selected: (_selectedTab == _ToDoTab.category),
              label: Localization().getStringEx('panel.wellness.todo.tab.category.label', 'Category'),
              hint: Localization().getStringEx('panel.wellness.todo.tab.category.hint', ''),
              onTap: () => _onTabChanged(tab: _ToDoTab.category))),
      Expanded(
          child: _TabButton(
              position: _TabButtonPosition.last,
              selected: (_selectedTab == _ToDoTab.reminders),
              label: Localization().getStringEx('panel.wellness.todo.tab.reminders.label', 'Reminders'),
              hint: Localization().getStringEx('panel.wellness.todo.tab.reminders.hint', ''),
              onTap: () => _onTabChanged(tab: _ToDoTab.reminders)))
    ]);
  }

  void _onTabChanged({required _ToDoTab tab}) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      if (mounted) {
        setState(() {});
      }
    }
  }
}

class _TabButton extends StatelessWidget {
  final String? label;
  final String? hint;
  final _TabButtonPosition position;
  final bool? selected;
  final GestureTapCallback? onTap;

  _TabButton({this.label, this.hint, required this.position, this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Semantics(
            label: label,
            hint: hint,
            button: true,
            excludeSemantics: true,
            child: Container(
                height: 24 + 16 * MediaQuery.of(context).textScaleFactor,
                decoration: BoxDecoration(
                    color: selected! ? Colors.white : Styles().colors!.lightGray, border: _border, borderRadius: _borderRadius),
                child: Center(
                    child: Text(label!,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: selected! ? Styles().fontFamilies!.extraBold : Styles().fontFamilies!.medium,
                            fontSize: 16,
                            color: Styles().colors!.fillColorPrimary))))));
  }

  BorderRadiusGeometry? get _borderRadius {
    switch (position) {
      case _TabButtonPosition.first:
        return BorderRadius.horizontal(left: Radius.circular(100.0));
      case _TabButtonPosition.middle:
        return null;
      case _TabButtonPosition.last:
        return BorderRadius.horizontal(right: Radius.circular(100.0));
    }
  }

  BoxBorder? get _border {
    BorderSide borderSide = BorderSide(color: Styles().colors!.surfaceAccent!, width: 2, style: BorderStyle.solid);
    switch (position) {
      case _TabButtonPosition.first:
        return Border.fromBorderSide(borderSide);
      case _TabButtonPosition.middle:
        return Border(top: borderSide, bottom: borderSide);
      case _TabButtonPosition.last:
        return Border.fromBorderSide(borderSide);
    }
  }
}

enum _ToDoTab { daily, category, reminders }

enum _TabButtonPosition { first, middle, last }
