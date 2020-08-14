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

import 'dart:async';

import 'package:flutter/services.dart';

class PollsPlugin{

  static const String _bleStartScan = "start_scan";
  static const String _bleStopScan = "stop_scan";
  static const String _bleOpenPoll = "create_poll";
  static const String _blePollOpened = "on_poll_created";

  static const String _bleEnable = "enable";
  static const String _bleDisable = "disable";

  static const MethodChannel _bleChannel = const MethodChannel('edu.illinois.rokwire/polls');

  final StreamController<String> pollStarted = StreamController<String>();

  static final PollsPlugin _instance = PollsPlugin._internal();
  PollsPlugin._internal(){
    _bleChannel.setMethodCallHandler(this._handleBleChannel);
  }

  factory PollsPlugin() {
    return _instance;
  }

  void startScan(){
    _bleChannel.invokeMethod(_bleStartScan);
  }

  void stopScan(){
    _bleChannel.invokeMethod(_bleStopScan);
  }

  void openPoll(String pollId){
    _bleChannel.invokeMethod(_bleOpenPoll, pollId);
  }

  void enable() {
    _bleChannel.invokeMethod(_bleEnable);
  }

  void disable() {
    _bleChannel.invokeMethod(_bleDisable);
  }

  Future<dynamic> _handleBleChannel(MethodCall call) async {
    switch (call.method) {
      case _blePollOpened:
        pollStarted.add(call.arguments as String);
        break;
      default:
        break;
    }
    return null;
  }
}