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
import 'package:flutter/semantics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart' as rokwire;

class HeaderBar extends rokwire.HeaderBar {

  static const String defaultLeadingAsset = 'images/chevron-left-white.png';

  HeaderBar({Key? key,
    SemanticsSortKey? sortKey,

    Widget? leadingWidget,
    String? leadingLabel,
    String? leadingHint,
    String? leadingAsset = defaultLeadingAsset,
    void Function(BuildContext context)? onLeading,
    
    Widget? titleWidget,
    String? title,
    TextStyle? textStyle,
    Color? textColor,
    String? fontFamily,
    double? fontSize = 16.0,
    double? letterSpacing = 1.0,
    int? maxLines,
    TextAlign? textAlign,
    bool? centerTitle = true,

    List<Widget>? actions,
  }) : super(key: key,
    sortKey: sortKey,
    
    leadingWidget: leadingWidget,
    leadingLabel: leadingLabel ?? Localization().getStringEx('headerbar.back.title', 'Back'),
    leadingHint: leadingHint ?? Localization().getStringEx('headerbar.back.hint', ''),
    leadingAsset: leadingAsset,
    onLeading: onLeading,

    titleWidget: titleWidget,
    title: title,
    textStyle: textStyle,
    textColor: textColor ?? Styles().colors?.white,
    fontFamily: fontFamily ?? Styles().fontFamilies?.extraBold,
    fontSize: fontSize,
    letterSpacing: letterSpacing,
    maxLines: maxLines,
    textAlign: textAlign,
    centerTitle: centerTitle,

    actions: actions,
  );

  @override
  void leadingHandler(BuildContext context) {
    Navigator.of(context).pop();
  }
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
                StringUtils.isNotEmpty(imageUrl) ?  Positioned.fill(child:Image.network(imageUrl!, fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true)) : Container(),
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
                Analytics().logSelect(target: "Back");
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
                    Analytics().logSelect(target: "Back");
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