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

import 'dart:math';

import 'package:logger/logger.dart';

abstract class Log {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // number of method calls to be displayed
      errorMethodCount: 128, // number of method calls if stacktrace is provided
      lineLength: 120, // width of the output
      colors: true, // Colorful log messages
      printEmojis: false, // Print an emoji for each log message
      printTime: false // Should each log print contain a timestamp
    ),
  );

  static v(String message, {int? lineLength}) {
    _logger.v(message);
  }

  static d(String message, {int? lineLength}) {
    _logger.d(_processMessage(message, lineLength: lineLength));
  }

  static i(String message, {int? lineLength}) {
    _logger.i(_processMessage(message, lineLength: lineLength));
  }

  static w(String message, {int? lineLength}) {
    _logger.w(_processMessage(message, lineLength: lineLength));
  }

  static e(String? message, {int? lineLength}) {
    _logger.e(_processMessage(message, lineLength: lineLength));
  }

  static String? _processMessage(String? message, {int? lineLength}) {
    if ((message != null) && (lineLength != null)) {
      List<String> result = <String>[];
      List<String> lines = message.split("\n");
      for (String line in lines) {
        if (lineLength < line.length) {
          for (int linePos = 0; linePos < line.length; linePos += lineLength) {
            result.add(line.substring(linePos, min(linePos + lineLength, line.length)));
          }
        }
        else {
          result.add(line);
        }
      }
      if (lines.length < result.length) {
        return result.join("\n");
      }
    }
    return message;
  }
}
