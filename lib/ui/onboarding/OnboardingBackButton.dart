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

class OnboardingBackButton extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final GestureTapCallback? onTap;
  final String imageKey;

  OnboardingBackButton({this.padding, this.onTap, this.imageKey = 'chevron-left-gray'});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Localization().getStringEx('headerbar.back.title', 'Back'),
      hint: Localization().getStringEx('headerbar.back.hint', ''),
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: padding!,
          child: Container(
              height: 32,
              width: 32,
              child: Styles().images?.getImage(imageKey, excludeFromSemantics: true)
          ),
        ),
      )
    );
  }
}