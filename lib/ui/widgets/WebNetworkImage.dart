/*
 * Copyright 2025 Board of Trustees of the University of Illinois.
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

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:illinois/service/Config.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';

class WebNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final bool excludeFromSemantics;
  final String? semanticLabel;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double? width;
  final double? height;

  WebNetworkImage({required this.imageUrl, this.fit, this.alignment = Alignment.center, this.excludeFromSemantics = false,
    this.semanticLabel, this.loadingBuilder, this.errorBuilder, this.width, this.height});

  @override
  State<WebNetworkImage> createState() => _WebNetworkImageState();
}

class _WebNetworkImageState extends State<WebNetworkImage> {
  bool _loading = false;
  Uint8List? _imageBytes;

  @override
  Widget build(BuildContext context) {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        errorBuilder: widget.errorBuilder,
        alignment: widget.alignment,
        fit: widget.fit,
        excludeFromSemantics: widget.excludeFromSemantics,
        semanticLabel: widget.semanticLabel,
        width: widget.width,
        height: widget.height,
      );
    } else if (_loading) {
      if (widget.loadingBuilder != null) {
        return Image.network(
          '',
          loadingBuilder: widget.loadingBuilder,
          errorBuilder: widget.errorBuilder,
          alignment: widget.alignment,
          fit: widget.fit,
          excludeFromSemantics: widget.excludeFromSemantics,
          semanticLabel: widget.semanticLabel,
          width: widget.width,
          height: widget.height,
        ); //mimic loading builder
      } else {
        return Container();
      }
    } else {
      return Container();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadImage() {
    final box = Hive.box(AppWebUtils.webNetworkImageCacheKey);

    if (box.containsKey(widget.imageUrl)) {
      setStateIfMounted(() {
        _imageBytes = box.get(widget.imageUrl);
      });
    } else {
      String proxyUrl = Config().wrapWebProxyUrl(sourceUrl: widget.imageUrl) ?? '';
      setStateIfMounted(() {
        _loading = true;
      });
      http.get(Uri.parse(proxyUrl), headers: Auth2Csrf().networkAuthHeaders).then((response) {
        Uint8List? responseBytes;
        if ((response.statusCode >= 200) && (response.statusCode <= 304)) {
          responseBytes = response.bodyBytes;
          box.put(widget.imageUrl, responseBytes);
        } else {
          debugPrint('WebNetworkImage: Failed to load image. Reason: ${response.statusCode}, ${response.body}');
        }
        setStateIfMounted(() {
          _loading = false;
          _imageBytes = responseBytes;
        });
      });
    }
  }
}
