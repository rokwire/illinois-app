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
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class ImageHolderListItem extends StatelessWidget {
  final Color placeHolderDividerResource;
  final String placeHolderSlantResource;

  final String imageUrl;
  final Widget child;
  final double imageHeight;
  final bool applyHorizontalPadding;

  const ImageHolderListItem(
      {Key key, this.placeHolderSlantResource = 'images/slant-down-right.png', this.placeHolderDividerResource, this.imageUrl, this.child, this.imageHeight = 240, this.applyHorizontalPadding = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double horizontalPadding = applyHorizontalPadding ? 16 : 0;
    String _imageUrl = imageUrl;
    return Stack(
      alignment: (_imageUrl != null && _imageUrl.isNotEmpty) ? Alignment
          .bottomCenter : Alignment.topCenter,
      children: <Widget>[
        Container(
          child: !_showImage()?
          Padding(
              padding: EdgeInsets.only(right: horizontalPadding, left: horizontalPadding, top: 16),
              child:child):
          Column(
            children: <Widget>[
              Stack(
                alignment: Alignment.topCenter,
                  children: <Widget>[
                    _showImage() ?
                    Image.network(
                      _imageUrl,
                      height: imageHeight,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                      headers: AppImage.getAuthImageHeaders(),
                    ) : Container(height: 0),
                    Padding(
                        padding: EdgeInsets.only(top: 168),
                        child:
                    Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          useDivider() ?
                          Container(
                            height: 72,
                            color: placeHolderDividerResource ?? Styles().colors.fillColorSecondary,
                          ) : Container(height: 0),
                          useSlantImage() ?
                          Container(
                            height: 112,
                            width: double.infinity,
                            child: Image.asset(
                                placeHolderSlantResource,
                                fit: BoxFit.fill,
                                color: placeHolderDividerResource ?? Styles().colors.fillColorSecondary,
                            ),
                          ) : Container(height: 0),
                        ],
                      ),
                      Padding(
                          padding: EdgeInsets.only(right: horizontalPadding, left: horizontalPadding, top: 16),
                          child: child)
                        ])
                    )

              ]),
            ],
          )
        ),

      ],
    );
  }
  bool _showImage(){
    return imageUrl!=null && imageUrl.isNotEmpty;
  }

  bool useDivider() {
    return placeHolderDividerResource != null;
  }

  bool useSlantImage() {
    return placeHolderSlantResource != null &&
        placeHolderSlantResource.isNotEmpty;
  }
}