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
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';

class ExpandableText extends StatefulWidget {
  const ExpandableText(
      this.text, {
        Key key,
        this.trimLines = 3,
        this.style,
        this.iconColor,
      })  : assert(text != null),
        super(key: key);

  final String text;
  final int trimLines;
  final TextStyle style;
  final Color iconColor;

  @override
  ExpandableTextState createState() => ExpandableTextState();
}

class ExpandableTextState extends State<ExpandableText> {

  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        TextPainter textPainter = TextPainter(
          textScaleFactor: MediaQuery.of(context).textScaleFactor,
          text: TextSpan(
            text: "...",
            style: widget.style,
          ),
          textDirection: TextDirection.rtl,
          maxLines: widget.trimLines,
        );
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
        final elipsisSize = textPainter.size;
        textPainter.text = TextSpan(
            text: widget.text,
            style: widget.style
        );
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
        final textSize = textPainter.size;
        int endIndex;
        final pos = textPainter.getPositionForOffset(Offset(
          textSize.width - elipsisSize.width,
          textSize.height,
        ));
        endIndex = textPainter.getOffsetBefore(pos.offset);
        if (textPainter.didExceedMaxLines) {
          return Column(
            children: <Widget>[
              RichText(
                textScaleFactor: MediaQuery.of(context).textScaleFactor,
                softWrap: true,
                overflow: TextOverflow.clip,
                text: TextSpan(
                  text: _collapsed
                      ? widget.text.substring(0, endIndex) + "..."
                      : widget.text,
                  style: widget.style,
                ),
              ),
              _collapsed ? Container(color: Styles().colors.fillColorSecondary,height: 1,margin: EdgeInsets.only(top:5, bottom: 5),) : Container(),
              _collapsed ? Semantics(
                button: true,
                label: Localization().getStringEx( "app.common.label.read_more", "Read more"),
                child: GestureDetector(
                  onTap: _onTapLink,
                  child: Center(child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(Localization().getStringEx( "app.common.label.read_more", "Read more"), style: TextStyle(fontSize: 16,
                          fontFamily: Styles().fontFamilies.bold,
                          color: Styles().colors.fillColorPrimary),),
                      Padding(
                        padding: EdgeInsets.only(left: 7), child: Image.asset('images/icon-down-orange.png', color: widget.iconColor,),),
                    ],),
                  ),
                ),
              ) : Container(),
            ],
          );
        } else {
          return Text(
            widget.text,
            style: widget.style,
          );
        }
      },
    );
  }

  void _onTapLink() {
    setState(() => _collapsed = !_collapsed);
  }
}