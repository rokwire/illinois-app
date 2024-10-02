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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class TextTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget> tabs;
  final TextStyle? labelStyle;
  final EdgeInsets? labelPadding;
  final TabController? controller;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final bool isScrollable;
  final void Function(int)? onTap;

  TextTabBar({required this.tabs, this.labelStyle, this.labelPadding, this.controller, this.backgroundColor,
    this.padding = const EdgeInsets.only(bottom: 4.0, left: 16.0, right: 16.0), this.isScrollable = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: TabBar(
        tabAlignment: isScrollable ? TabAlignment.center : TabAlignment.fill,
        isScrollable: isScrollable,
        tabs: tabs,
        controller: controller,
        padding: padding,
        dividerHeight: 1,
        dividerColor: Styles().colors.textDisabled,
        labelPadding: labelPadding ?? const EdgeInsets.symmetric(horizontal: 12.0),
        indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 2, color: Styles().colors.fillColorSecondary)),
        indicatorSize: isScrollable ? TabBarIndicatorSize.label : TabBarIndicatorSize.tab,
        // indicatorColor: AppColors.textPrimary,
        // indicatorPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        unselectedLabelStyle: labelStyle ?? Styles().textStyles.getTextStyle('widget.heading.regular.fat'),
        unselectedLabelColor: Styles().colors.textPrimary,
        labelStyle: labelStyle ?? Styles().textStyles.getTextStyle('widget.heading.regular.fat'),
        labelColor: Styles().colors.textPrimary,
        onTap: onTap,
      ),
    );
  }

  @override
  Size get preferredSize {
    double maxHeight = kToolbarHeight;
    for (final Widget item in tabs) {
      if (item is PreferredSizeWidget) {
        final double itemHeight = item.preferredSize.height;
        maxHeight = max(itemHeight, maxHeight);
      }
    }
    return Size.fromHeight(maxHeight);
  }
}

class TextTabButton extends StatelessWidget {
  final String title;

  TextTabButton({required this.title});

  @override
  Widget build(BuildContext context) {
    return Tab(height: 48.0, child: Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
      child: Text(title, overflow: TextOverflow.ellipsis,),
    ));
  }
}
