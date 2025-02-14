// Copyright 2023 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:html';

import 'package:flutter/foundation.dart';

import 'package:neom/platform_impl/base.dart';

import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class FileHelper extends BaseFileHelper {
  @override
  void initializePicker() {
    FilePickerWeb.registerWith(webPluginRegistrar);
  }

  @override
  Future<bool> saveDownload(String name, Uint8List data) async {
    // setup
    final blob = Blob([data]);
    final url = Url.createObjectUrlFromBlob(blob);
    final anchor = document.createElement('a') as AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = name;
    document.body?.children.add(anchor);

    // download file
    anchor.click();

    // cleanup
    document.body?.children.remove(anchor);
    Url.revokeObjectUrl(url);
    return true;
  }
}