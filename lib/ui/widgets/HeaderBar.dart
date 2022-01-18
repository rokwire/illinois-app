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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Network.dart';
//import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/ui/SearchPanel.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class HeaderBar extends AppBar {
  final BuildContext context;
  final Widget? titleWidget;
  final bool searchVisible;
  final bool rightButtonVisible;
  final String rightButtonText;
  final GestureTapCallback? onRightButtonTap;

  HeaderBar(
      {required this.context, this.titleWidget, this.searchVisible = false,
        this.rightButtonVisible = false, required this.rightButtonText, this.onRightButtonTap})
      : super(
            backgroundColor: Styles().colors!.fillColorPrimaryVariant,
            leading: Semantics(
              label: Localization().getStringEx('headerbar.home.title', 'Home'),
              hint: Localization().getStringEx('headerbar.home.hint', ''),
              button: true,
              excludeSemantics: true,
              child: IconButton(
                icon: Image.asset('images/block-i-orange.png', excludeFromSemantics: true),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                })),
            title: titleWidget,
            actions: <Widget>[
              Visibility(
                  visible: searchVisible,
                  child: Semantics(
                    label: Localization().getStringEx('headerbar.search.title', 'Search'),
                    hint: Localization().getStringEx('headerbar.search.hint', ''),
                    button: true,
                    child: IconButton(
                      icon: Image.asset('images/icon-search.png', excludeFromSemantics: true),
                      onPressed: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => SearchPanel()));
                      }))),
              Visibility(
                  visible: rightButtonVisible,
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      label: rightButtonText,
                      button: true,
                      excludeSemantics: true,
                      child:InkWell(
                      onTap: onRightButtonTap,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        child: Text(rightButtonText,
                            style: TextStyle(color: Colors.white,
                                fontSize: 16,
                                fontFamily: Styles().fontFamilies!.semiBold,
                                decoration: TextDecoration.underline,
                                decorationColor: Styles().colors!.fillColorSecondary,
                                decorationThickness: 1,
                                decorationStyle: TextDecorationStyle.solid)),),)),
                  )
              )
            ],
            centerTitle: true);
}

// SimpleAppBar

class SimpleHeaderBarWithBack extends StatelessWidget implements PreferredSizeWidget {
  final BuildContext context;
  final Widget? titleWidget;
  final bool? backVisible;
  final String backIconRes;
  final Function? onBackPressed;
  final bool searchVisible;
  final List<Widget>? actions;

  final semanticsSortKey;

  SimpleHeaderBarWithBack({required this.context, this.titleWidget, this.backVisible = true, this.onBackPressed, this.searchVisible = false, this.backIconRes = 'images/chevron-left-white.png', this.semanticsSortKey = const OrdinalSortKey(1), this.actions });

  @override
  Widget build(BuildContext context) {
    List<Widget> actionsList = <Widget>[];
    if (CollectionUtils.isNotEmpty(actions)) {
      actionsList.addAll(actions!);
    }
    if (searchVisible) {
      actionsList.add(_buildSearchButton());
    }

    return Semantics(sortKey:semanticsSortKey,child:AppBar(
      leading: backVisible! ? _buildBackButton() : null,
      title: titleWidget,
      centerTitle: true,
      backgroundColor: Styles().colors!.fillColorPrimaryVariant,
      actions: actionsList,
    ));
  }

  Widget _buildBackButton() {
    return Semantics(
      label: Localization().getStringEx('headerbar.back.title', 'Back'),
      hint: Localization().getStringEx('headerbar.back.hint', ''),
      button: true,
      excludeSemantics: true,
      child: IconButton(
        icon: Image.asset(backIconRes, excludeFromSemantics: true),
        onPressed: _onTapBack));
  }

  void _onTapBack() {
    Analytics.instance.logSelect(target: "Back");
    if (onBackPressed != null) {
      onBackPressed!();
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildSearchButton() {
    return Semantics(
      label: Localization().getStringEx('headerbar.search.title', 'Search'),
      hint: Localization().getStringEx('headerbar.search.hint', ''),
      button: true,
      excludeSemantics: true,
      child: IconButton(
        icon: Image.asset('images/icon-search.png', width: 20, height: 20, excludeFromSemantics: true),
        onPressed: _onTapSearch,
      ));
  }

  void _onTapSearch() {
    Analytics.instance.logSelect(target: "Search");
    Navigator.push(context, CupertinoPageRoute( builder: (context) => SearchPanel()));
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class SliverToutHeaderBar extends SliverAppBar {
  final BuildContext context;
  final String? imageUrl;
  final GestureTapCallback? onBackTap;

  SliverToutHeaderBar(
      {
        required this.context,
        this.imageUrl,
        this.onBackTap,
        Color? backColor,
        Color? leftTriangleColor,
        Color? rightTriangleColor,
      })
      : super(
      pinned: true,
      floating: false,
      expandedHeight: 200,
      backgroundColor: Styles().colors!.fillColorPrimaryVariant,
      flexibleSpace: Semantics(container: true,excludeSemantics: true,child: FlexibleSpaceBar(
          background:
          Container(
            color: backColor ?? Styles().colors!.background,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                StringUtils.isNotEmpty(imageUrl) ?  Positioned.fill(child:Image.network(imageUrl!, fit: BoxFit.cover, headers: Network.authApiKeyHeader, excludeFromSemantics: true)) : Container(),
                CustomPaint(
                  painter: TrianglePainter(painterColor: rightTriangleColor ?? Styles().colors!.fillColorSecondaryTransparent05, left: false),
                  child: Container(
                    height: 53,
                  ),
                ),
                CustomPaint(
                  painter: TrianglePainter(painterColor: leftTriangleColor ?? Styles().colors!.background),
                  child: Container(
                    height: 30,
                  ),
                ),
              ],
            ),
          ))
      ),
      leading: Semantics(
          label: Localization().getStringEx('headerbar.back.title', 'Back'),
          hint: Localization().getStringEx('headerbar.back.hint', ''),
          button: true,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: onBackTap != null ? onBackTap : (){
                Analytics.instance.logSelect(target: "Back");
                Navigator.pop(context);
              },
              child: ClipOval(
                child: Container(
                    height: 32,
                    width: 32,
                    color: Styles().colors!.fillColorPrimary,
                    child: Image.asset('images/chevron-left-white.png', excludeFromSemantics: true)
                ),
              ),
            ),
          )
      )
  );
}

// SliverSheetHeaderBar

class SliverHeaderBar extends SliverAppBar {
  final BuildContext context;
  final Widget? titleWidget;
  final bool backVisible;
  final Color? backgroundColor;
  final String backIconRes;
  final Function? onBackPressed;
  final List<Widget>? actions;

  SliverHeaderBar({required this.context, this.titleWidget, this.backVisible = true, this.onBackPressed, this.backgroundColor, this.backIconRes = 'images/chevron-left-white.png', this.actions}):
        super(
        pinned: true,
        floating: false,
        backgroundColor: backgroundColor ?? Styles().colors!.fillColorPrimaryVariant,
        elevation: 0,
        leading: Visibility(visible: backVisible, child: Semantics(
            label: Localization().getStringEx('headerbar.back.title', 'Back'),
            hint: Localization().getStringEx('headerbar.back.hint', ''),
            button: true,
            excludeSemantics: true,
            child: IconButton(
                icon: Image.asset(backIconRes, excludeFromSemantics: true),
                onPressed: (){
                    Analytics.instance.logSelect(target: "Back");
                    if (onBackPressed != null) {
                      onBackPressed();
                    } else {
                      Navigator.pop(context);
                    }
                })),),
        title: titleWidget,
        centerTitle: true,
        actions: actions,
      );
}