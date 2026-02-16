/*
 * Copyright 2026 Board of Trustees of the University of Illinois.
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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';

extension CanvasCourseExt on CanvasCourse {
  String? get crn => sections?.firstWhereOrNull((item) => (item.crn != null))?.crn;
}

extension CanvasSectionExt on CanvasSection {
  ///
  /// #5584:
  /// "The CRN is definitely part of the Section Name for registrar-enabled courses, and is pre-pended with "CRN" (with no spaces) before the 5 digit integer"
  ///
  String? get crn {
    String? crn;
    if ((name != null) && name!.isNotEmpty) {
      final String crnLabel = 'CRN';
      int crnIndex = name!.lastIndexOf(crnLabel);
      if (crnIndex >= 0) {
        int crnStartIndex = crnIndex + crnLabel.length;
        int crnEndIndex = crnStartIndex + 5; // crn number is 5 digit number
        try {
          crn = name!.substring(crnStartIndex, crnEndIndex);
        } catch (e) {
          debugPrint('Canvas: Failed to extract CRN number from section name. Ex: $e');
        }
      }
    }
    return crn;
  }
}