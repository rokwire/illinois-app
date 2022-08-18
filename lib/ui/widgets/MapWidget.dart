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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';

typedef void MapWidgetCreatedCallback(MapController controller);

class MapWidget extends StatefulWidget {
  final MapWidgetCreatedCallback? onMapCreated;
  final dynamic creationParams;

  const MapWidget({Key? key, this.onMapCreated, this.creationParams}) : super(key: key);

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'mapview',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
        creationParams: widget.creationParams,
      );
    } else if(defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'mapview',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
        creationParams: widget.creationParams,
      );
    }
    return Text('$defaultTargetPlatform is not yet supported by this plugin');
  }

  Future<void> onPlatformViewCreated(id) async {
    if (widget.onMapCreated == null) {
      return;
    }
    widget.onMapCreated!(MapController.init(id));
  }
}

class MapController {
  late MethodChannel _channel;
  int? _mapId;


  MapController.init(int id) {
    _mapId = id;
    _channel = MethodChannel('mapview_$id');
  }

  int? get mapId { return _mapId; }

  Future<void> placePOIs(List<dynamic>? explores) async {
    var options = {
      "LocationThresoldDistance": Storage().debugMapThresholdDistance
    };
    List<dynamic> jsonData = [];
    if (CollectionUtils.isNotEmpty(explores)) {
      for (dynamic explore in explores!) {
        jsonData.add(explore.toJson());
      }
    }
    return _channel.invokeMethod('placePOIs', { "explores": jsonData, "options": options});
  }

  Future<void>enable(bool enable) async {
    return _channel.invokeMethod('enable', enable);
  }

  Future<void>enableMyLocation(bool enable) async {
    return _channel.invokeMethod('enableMyLocation', enable);
  }

  Future<void> viewPoi(Map<String, dynamic>? target) async {
    return _channel.invokeMethod('viewPoi', {'target': target});
  }
}
