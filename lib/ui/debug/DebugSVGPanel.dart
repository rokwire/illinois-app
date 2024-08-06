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
import 'package:flutter/services.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jovial_svg/jovial_svg.dart';

class DebugSVGPanel extends StatefulWidget{
  _DebugSVGPanelState createState() => _DebugSVGPanelState();
}

class _DebugSVGPanelState extends State<DebugSVGPanel>{

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.surface,
      appBar: HeaderBar(title: "SVG Test",),
      body: PinchZoom(maxScale: 12, child:
        _scalableImageWidget
      ),
    );
  }

  // ignore: unused_element
  Widget get _svgPictureWidget =>
    SvgPicture.asset(_svgAssetName, semanticsLabel: 'Building Example');

  // ignore: unused_element
  Widget get _scalableImageWidget => ScalableImageWidget.fromSISource(
    fit: BoxFit.contain,
    si: ScalableImageSource.fromSvg(rootBundle, _svgAssetName),
  );

  // ignore: unused_element
  static const String _svgAssetName = 'images/building-example.svg';

  // ignore: unused_element
  static const String _svgOptimizedAssetName = 'images/building-example-optimized.svg';

  // ignore: unused_element
  static const String _svgFixedAssetName = 'images/building-example-fixed.svg';

  // ignore: unused_element
  static const String _svgFixedOptimizedAssetName = 'images/building-example-fixed-optimized.svg';

}


