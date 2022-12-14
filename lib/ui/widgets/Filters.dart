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
import 'package:rokwire_plugin/ui/widgets/filters.dart' as rokwire;

class FilterListItem extends rokwire.FilterListItem {

  FilterListItem({ Key? key,
    String? title,
    TextStyle? titleTextStyle,
    TextStyle? selectedTitleTextStyle,

    String? description,
    TextStyle? descriptionTextStyle,
    TextStyle? selectedDescriptionTextStyle,

    bool selected = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    GestureTapCallback? onTap,
  
    Widget? icon,
    String? iconAsset = 'images/icon-unselected.png',
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(left: 10),

    Widget? selectedIcon,
    String? selectedIconAsset = 'images/icon-selected.png',
    EdgeInsetsGeometry selectedIconPadding = const EdgeInsets.only(left: 10),
  }) : super(key: key,
    title: title,
    titleTextStyle: titleTextStyle,
    selectedTitleTextStyle: selectedTitleTextStyle,

    description: description,
    descriptionTextStyle: descriptionTextStyle,
    selectedDescriptionTextStyle: selectedDescriptionTextStyle,

    selected: selected,
    padding: padding,
    onTap: onTap,
  
    icon: icon,
    iconAsset: iconAsset,
    iconPadding: iconPadding,

    selectedIcon: selectedIcon,
    selectedIconAsset: selectedIconAsset,
    selectedIconPadding: selectedIconPadding,
  );
}

class FilterSelector extends rokwire.FilterSelector {

  FilterSelector({ Key? key,
    String? title,
    TextStyle? titleTextStyle,
    TextStyle? activeTitleTextStyle,

    String? hint,
    EdgeInsetsGeometry padding = const EdgeInsets.only(left: 4, right: 4, top: 12),
    bool active = false,
    bool expanded = false,
    GestureTapCallback? onTap,

    Widget? icon,
    String? iconKey = 'chevron-down',
    EdgeInsetsGeometry iconPadding = const EdgeInsets.symmetric(horizontal: 4),

    Widget? activeIcon,
    String? activeIconKey = 'chevron-up',
    EdgeInsetsGeometry activeIconPadding = const EdgeInsets.symmetric(horizontal: 4),
  }) : super(key: key,
    title: title,
    titleTextStyle: titleTextStyle,
    activeTitleTextStyle: activeTitleTextStyle,

    hint: hint,
    padding: padding,
    active: active,
    expanded: expanded,
    onTap: onTap,

    icon: icon,
    iconKey: iconKey,
    iconPadding: iconPadding,

    activeIcon: activeIcon,
    activeIconKey: activeIconKey,
    activeIconPadding: activeIconPadding,
  );
}