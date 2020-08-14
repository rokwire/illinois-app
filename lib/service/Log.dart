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

import 'package:logger/logger.dart';

abstract class Log {
  static final _logger = Logger();

  static v(String message) {
    _logger.v(message);
  }

  static d(String message) {
    _logger.d(message);
  }

  static i(String message) {
    _logger.i(message);
  }

  static w(String message) {
    _logger.w(message);
  }

  static e(String message) {
    _logger.e(message);
  }
}
