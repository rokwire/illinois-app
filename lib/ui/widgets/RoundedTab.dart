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
import 'package:rokwire_plugin/service/styles.dart';

class RoundedTab extends StatelessWidget {
  final String? title;

  final String? hint;
  final int tabIndex;
  final void Function(RoundedTab tab)? onTap;
  final bool selected;

  static const Color _borderColor = Color(0xffdadde1);
  
  RoundedTab({ Key? key,
    this.title,

    this.hint,
    this.tabIndex = 0,
    this.onTap,
    this.selected = false
  }): super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () => _onPressed(), child:
      Semantics(label: title, hint: hint, button: true, selected: selected, excludeSemantics: true, child:
        Container(decoration: ShapeDecoration(color: _borderColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34),),), child:
          Padding(padding: EdgeInsets.all(1), child:
            Container(decoration: ShapeDecoration(color: getBackColor(), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35),),), child:
              Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), child:
                Text(title ?? '', style: TextStyle(fontFamily: Styles().fontFamilies!.bold, color: getTextColor(), fontSize: 16,),),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color? getBackColor() {
    return selected
        ? Styles().colors!.fillColorPrimary
        : Styles().colors!.surfaceAccent;
  }

  Color? getTextColor(){
    return selected
        ? Colors.white
        : Styles().colors!.fillColorPrimary;
  }

  void _onPressed() {
    if (onTap != null) {
      onTap!(this);
    }
  }
}
