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
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/Poll.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/BluetoothServices.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/GeoFence.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/PollsPlugin.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:sprintf/sprintf.dart';

class Polls with Service implements NotificationsListener {

  static const String notifyCreated  = "edu.illinois.rokwire.poll.created"; // new poll created, bubble should appear
  static const String notifyPresentVote  = "edu.illinois.rokwire.poll.present.vote"; // poll opened for voting, bubble should appear
  static const String notifyPresentResult  = "edu.illinois.rokwire.poll.present.result"; // poll opened for voting, bubble should appear
  static const String notifyResultsChanged  = "edu.illinois.rokwire.poll.resultschanged"; // poll updated
  static const String notifyVoteChanged  = "edu.illinois.rokwire.poll.votechanged"; // poll updated
  static const String notifyStatusChanged  = "edu.illinois.rokwire.poll.statuschnaged"; // poll closed, results could be presented

  Map<String, _PollChunk> _pollChunks = {};
  bool _pluginEnabled = false;
  bool _pluginStarted = false;

  static final Polls _service = Polls._internal();
  Polls._internal();

  factory Polls() {
    return _service;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      FirebaseMessaging.notifyPollOpen,
      GeoFence.notifyCurrentRegionsUpdated,
      AppLivecycle.notifyStateChanged,
      BluetoothServices.notifyStatusChanged,
    ]);
  }

  @override
  void destroyService() {
    PollsPlugin().stopScan(); // check this
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    if(_enabled) {
      PollsPlugin().pollStarted.stream.listen((pollId) {
        _onPollStarted(pollId);
      });
      enablePlugin();
      startPlugin();

      await _loadPollChunks();
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config(), BluetoothServices(), Auth2()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if(_enabled) {
      if (name == FirebaseMessaging.notifyPollOpen) {
        dynamic pollId = (param is Map) ? param['poll_id'] : null;
        if (pollId is String) {
          _onPollStarted(pollId);
        }
      }
      else if (name == GeoFence.notifyCurrentRegionsUpdated) {
        _presentWaiting();
      }
      else if (name == AppLivecycle.notifyStateChanged) {
        _processAppLifeCycle();
      }
      else if (name == BluetoothServices.notifyStatusChanged) {
        enablePlugin();
        startPlugin();
      }
    }
  }

  // Polls Plugin

  void enablePlugin() {
    if(_enabled) {
      if ((BluetoothServices().status == BluetoothStatus.PermissionAllowed) && !_pluginEnabled) {
        PollsPlugin().enable();
        _pluginEnabled = true;
      }
    }
  }

  void disablePlugin() {
    if(_enabled) {
      if (_pluginEnabled) {
        PollsPlugin().disable();
        _pluginEnabled = false;
      }
    }
  }

  void startPlugin() {
    if(_enabled) {
      if (_pluginEnabled && !_pluginStarted) {
        PollsPlugin().startScan();
        _pluginStarted = true;
      }
    }
  }

  void stopPlugin() {
    if(_enabled) {
      if (_pluginStarted) {
        PollsPlugin().stopScan();
        _pluginStarted = false;
      }
    }
  }

  // Accessories

  Future<PollsChunk> getMyPolls({String cursor}) async {
    return _enabled ? _getPolls('mypolls', cursor) : null;
  }

  Future<PollsChunk> getRecentPolls({String cursor}) async {
    return _enabled ?  _getPolls('recentpolls', cursor) : null;
  }

  Future<PollsChunk> _getPolls(String pollsType, String cursor) async {
    if(_enabled) {
      try {
        String urlParams = (cursor != null) ? '?cursor=$cursor' : '';
        String url = '${Config().quickPollsUrl}/$pollsType/${Auth2().accountId}$urlParams';
        Response response = await Network().get(url, auth: NetworkAuth.Auth2);
        int responseCode = response?.statusCode ?? -1;
        String responseBody = response?.body;
        if ((response != null) && (responseCode == 200)) {
          Map<String, dynamic> responseJson = AppJson.decode(responseBody);
          String pollsCursor = (responseJson != null) ? responseJson['cursor'] : null;
          List<dynamic> pollsJson = (responseJson != null) ? responseJson['data'] : null;
          if (pollsJson != null) {
            return PollsChunk(polls: Poll.fromJsonList(pollsJson), cursor: pollsCursor);
          }
          else {
            throw Localization().getStringEx('logic.general.invalid_response', 'Invalid server response');
          }
        }
        else {
          throw sprintf(Localization().getStringEx('logic.general.response_error', 'Response Error: %s %s'), ['$responseCode', '$responseBody']);
        }
      } on Exception catch (e) {
        print(e.toString());
        throw e;
      }
    }
    return null;
  }

  Poll getPoll({String pollId}) {
    return _enabled ? _pollChunks[pollId]?.poll : null;
  }

  // API

  Future<void> create(Poll poll) async {
    if(_enabled) {
      if (poll != null) {
        try {
          String url = '${Config().quickPollsUrl}/pollcreate';
          Response response = await Network().post(url, body: json.encode(poll.toJson()), auth: NetworkAuth.Auth2);
          int responseCode = response?.statusCode ?? -1;
          String responseString = response?.body;
          if ((response != null) && (response.statusCode == 200)) {
            Map<String, dynamic> responseJson = AppJson.decode(responseString);
            String pollId = (responseJson != null) ? responseJson['id'] : null;
            if (pollId != null) {
              poll.pollId = pollId;

              Analytics().logPoll(poll, Analytics.LogPollCreateActionName);

              _addPollToChunks(poll);

              if (poll.status == PollStatus.opened) {
                if (poll.isBluetooth) {
                  PollsPlugin().openPoll(poll.pollId);
                }
                else if (poll.isFirebase) {
                  // FirebaseMessaging().send(topic:'polls', message:{'type':'poll_open', 'poll_id': pollId});
                }
              }

              Timer(Duration(milliseconds: 500), () {
                NotificationService().notify(notifyCreated, poll.pollId);
                _presentWaiting();
              });
            }
            else {
              throw Localization().getStringEx('logic.general.invalid_response', 'Invalid server response');
            }
          }
          else {
            throw sprintf(Localization().getStringEx('logic.general.response_error', 'Response Error: %s %s'), ['$responseCode', '$responseString']);
          }
        } on Exception catch (e) {
          print(e.toString());
          throw e;
        }
      }
      else {
        throw Localization().getStringEx('logic.general.internal_error', 'Internal Error Occured');
      }
    }
    return null;
  }

  Future<void> open(String pollId) async {
    if(_enabled) {
      if (pollId != null) {
        try {
          String url = '${Config().quickPollsUrl}/pollstart/$pollId';
          Response response = await Network().put(url, auth: NetworkAuth.Auth2);
          if ((response != null) && (response.statusCode == 200)) {
            _onPollStarted(pollId).then((Poll poll) {
              if (poll != null) {
                Analytics().logPoll(poll, Analytics.LogPollOpenActionName);
                if (poll.isBluetooth) {
                  PollsPlugin().openPoll(pollId);
                }
                else if (poll.isFirebase) {
                  // FirebaseMessaging().send(topic:'polls', message:{'type':'poll_open', 'poll_id': pollId});
                }
              }
            });
          }
          else {
            throw sprintf(Localization().getStringEx('logic.general.response_error', 'Response Error: %s %s'), ['${response?.statusCode}', '${response?.body}']);
          }
        } on Exception catch (e) {
          print(e.toString());
          throw e;
        }
      }
      else {
        throw Localization().getStringEx('logic.general.internal_error', 'Internal Error Occured');
      }
    }
    return null;
  }

  Future<void> vote(String pollId, PollVote vote) async {
    if(_enabled) {
      if ((pollId != null) && (vote != null)) {
        try {
          String url = '${Config().quickPollsUrl}/pollvote/$pollId';
          Map<String, dynamic> voteJson = {
            'userid': Auth2().accountId,
            'answer': vote?.toVotesJson(),
          };
          String voteString = json.encode(voteJson);
          Response response = await Network().post(url, body: voteString, auth: NetworkAuth.Auth2);
          if ((response != null) && (response.statusCode == 200)) {
            Analytics().logPoll(getPoll(pollId: pollId), Analytics.LogPollVoteActionName);
            _updatePollVote(pollId, vote);
          }
          else {
            throw sprintf(Localization().getStringEx('logic.general.response_error', 'Response Error: %s %s'), ['${response?.statusCode}', '${response?.body}']);
          }
        } on Exception catch (e) {
          print(e.toString());
          throw e.toString();
        }
      }
      else {
        throw Localization().getStringEx('logic.general.internal_error', 'Internal Error Occured');
      }
    }
  }

  Future<void> close(String pollId) async {
    if(_enabled) {
      if (pollId != null) {
        try {
          String url = '${Config().quickPollsUrl}/pollend/$pollId';
          Response response = await Network().put(url, auth: NetworkAuth.Auth2);
          if ((response != null) && (response.statusCode == 200)) {
            Analytics().logPoll(getPoll(pollId: pollId), Analytics.LogPollCloseActionName);
            _updatePollStatus(pollId, PollStatus.closed);
            NotificationService().notify(notifyStatusChanged, pollId);
          }
          else {
            throw sprintf(Localization().getStringEx('logic.general.response_error', 'Response Error: %s %s'), ['${response?.statusCode}', '${response?.body}']);
          }
        } on Exception catch (e) {
          print(e.toString());
          throw e;
        }
      }
      else {
        throw Localization().getStringEx('logic.general.internal_error', 'Internal Error Occured');
      }
    }
  }

  Future<Poll> load({int pollPin}) async {
    if(_enabled) {
      if (pollPin != null) {
        try {
          if (!Connectivity().isNotOffline) {
            throw Localization().getStringEx('app.offline.message.title', 'You appear to be offline');
          }
          String url = '${Config().quickPollsUrl}/pinpolls/$pollPin';
          Response response = await Network().get(url, auth: NetworkAuth.Auth2);
          String responseString = response?.body;
          Map<String, dynamic> responseJson = AppJson.decode(responseString);
          List<dynamic> responseList = (responseJson != null) ? responseJson['data'] : null;
          List<Poll> polls = (responseList != null) ? Poll.fromJsonList(responseList) : null;
          if (polls == null) {
            throw responseString ?? Localization().getStringEx('logic.polls.unable_to_load_poll', 'Unable to load poll');
          }

          List<Poll> results = [];
          for (Poll poll in polls) {
            if (!poll.isGeoFenced || GeoFence().currentRegionIds.contains(poll.regionId)) {
              results.add(poll);
            }
          }
          if (results.length == 0) {
            throw Localization().getStringEx('logic.polls.no_polls_with_pin', 'There are no polls with this pin');
          }
          else if (1 < results.length) {
            throw Localization().getStringEx('logic.polls.multiple_polls_with_pin', 'There are multiple opened polls with this pin');
          }

          Poll poll = polls.first;
          if (_pollChunks[poll.pollId] == null) {
            _addPollToChunks(poll);
            NotificationService().notify(notifyCreated, poll.pollId);
            //_presentWaiting();
          }
          return poll;
        } on Exception catch (e) {
          print(e.toString());
          throw e;
        }
      }
      else {
        throw Localization().getStringEx('logic.general.internal_error', 'Internal Error Occured');
      }
    }
    return null;
  }

  bool presentPollId(String pollId) {
    if (_enabled && _presentPoll == null) {
      _PollChunk pollChunk = _pollChunks[pollId];
      if (pollChunk != null) {
        if ((pollChunk.status == _PollUIStatus.waitingClose) && (pollChunk.poll.status == PollStatus.opened)) {
          pollChunk.status = _PollUIStatus.waitingVote;
        }
        if (pollChunk.canPresent) {
          _presentPoll = pollChunk;
          return true;
        }
      }
    }
    return false;
  }

  void closePresent() {
    if(_enabled) {
      _closePresent();
      _presentWaiting();
    }
  }

  void presentPollVote(Poll poll) {
    if(_enabled) {
      _PollChunk pollChunk = _pollChunks[poll.pollId];
      if ((pollChunk == null) && (poll.status == PollStatus.opened)) {
        pollChunk = _addPollToChunks(poll);
      }
      if ((pollChunk != null) && (pollChunk.poll.status == PollStatus.opened)) {
        if (pollChunk.status == _PollUIStatus.waitingClose) {
          pollChunk.status = _PollUIStatus.waitingVote;
        }
        _presentWaiting();
      }
    }
  }

  Poll get presentPoll {
    return _enabled ? _presentPoll?.poll : null;
  }

  List<Poll> localRecentPolls() {
    if(_enabled) {
      List<_PollChunk> pollChunks = [];
      _pollChunks.forEach((String pollId, _PollChunk pollChunk) {
        if ((pollChunk.poll.status != PollStatus.closed) && ((pollChunk.poll.userVote?.totalVotes ?? 0) == 0)) {
          pollChunks.add(pollChunk);
        }
      });

      pollChunks.sort((_PollChunk pollChunk1, _PollChunk pollChunk2) {
        return pollChunk2.poll.pollId.compareTo(pollChunk1.poll.pollId);
      });

      List<Poll> polls = [];
      for (_PollChunk pollChunk in pollChunks) {
        polls.add(pollChunk.poll);
      }
      return polls;
    }
    return null;
  }

  void _updatePollStatus(String pollId, PollStatus pollStatus) {
    if (pollId != null) {
      _PollChunk pollChunk = _pollChunks[pollId];
      if (pollChunk != null) {
        if (pollChunk.poll.status != pollStatus) {
          pollChunk.poll.status = pollStatus;
          NotificationService().notify(notifyStatusChanged, pollId);

          if (pollStatus == PollStatus.closed) {
            _onPollClosed(pollId);
          }
        }
      }
    }
  }

  void _updatePollResults(String pollId, PollVote pollResults) {
    if (pollId != null) {
      _PollChunk pollChunk = _pollChunks[pollId];
      if (pollChunk != null) {
        if ((pollChunk.poll.results == null) || !pollChunk.poll.results.isEqual(pollResults)) {
          pollChunk.poll.results = pollResults;
          NotificationService().notify(notifyResultsChanged, pollId);
        }
      }
    }
  }

  void _updatePollVote(String pollId, PollVote pollVote) {
    if (pollId != null) {
      _PollChunk pollChunk = _pollChunks[pollId];
      if (pollChunk != null) {
        pollChunk.poll.apply(pollVote);
        NotificationService().notify(notifyVoteChanged, pollId);
      }
    }
  }

  Future<Poll> _onPollStarted(String pollId) async {
    Log.d('Polls: starting poll #$pollId');
    if (pollId != null) {
      _PollChunk pollChunk = _pollChunks[pollId];
      if (pollChunk == null) {
        try {
          String url = '${Config().quickPollsUrl}/poll/$pollId';
          Response response = await Network().get(url, auth: NetworkAuth.Auth2);
          String responseString = ((response != null) && (response.statusCode == 200)) ? response.body : null;
          Map<String, dynamic> responseJson = AppJson.decode(responseString);
          Poll poll = (responseJson != null) ? Poll.fromJson(responseJson) : null;
          if ((poll != null) && (!poll.isGeoFenced || GeoFence().currentRegionIds.contains(poll.regionId))) {
            _addPollToChunks(poll);
            NotificationService().notify(notifyCreated, pollId);
            _presentWaiting();
            if (AppLivecycle().state == AppLifecycleState.paused) {
              _launchPollNotification(poll);
            }
            return poll;
          }
        } on Exception catch(e) {
          print(e.toString());
        }
      }
      else if ((pollChunk != null) && (pollChunk.poll.status != PollStatus.opened)) {
        pollChunk.poll.status = PollStatus.opened;
        NotificationService().notify(notifyStatusChanged, pollId);
        _presentWaiting();
        return pollChunk.poll;
      }
    }
    return null;
  }

  void _onPollClosed(String pollId) {
    Log.d('Polls: closing poll #$pollId');
    _PollChunk pollChunk = _pollChunks[pollId];
    if (pollChunk != null) {
      if (pollChunk.status == _PollUIStatus.waitingVote) {
        _removePollChunk(pollChunk);
      }
      else if (pollChunk.status == _PollUIStatus.presentVote) {
        // Wait for closePresent to remove or change status
      }
      else if (pollChunk.status == _PollUIStatus.waitingClose) {
        if (pollChunk.poll.settings.hideResultsUntilClosed) {
          _presentWaiting();
        }
        else {
          _removePollChunk(pollChunk);
        }
      }
      else if (pollChunk.status == _PollUIStatus.presentResult) {
        // Wait for closePresent to remove
      }
    }
  }

  void _onPollEvent(String pollId, String eventName, String eventData) {
    Log.d('Polls: received event \'$eventName\' from EventStream for poll #$pollId');
    try {
      if (eventName == 'status') {
        List<dynamic> jsonList = AppJson.decode(eventData);
        String statusString = ((jsonList != null) && jsonList.isNotEmpty) ? jsonList.first : null;
        PollStatus pollStatus = Poll.pollStatusFromString(statusString);
        if (pollStatus != null) {
          _updatePollStatus(pollId, pollStatus);
        }
      }
      else if (eventName == 'results') {
        List<dynamic> jsonList = AppJson.decode(eventData);
        List<int> results = (jsonList != null) ? jsonList.cast<int>() : null;
        PollVote pollResults = (results != null) ? PollVote.fromJson(results: results) : null;
        if (pollResults != null) {
          _updatePollResults(pollId, pollResults);
        }
      }
    }
    on Exception catch(e) {
      print(e.toString());
    }
  }

  _PollChunk _addPollToChunks(Poll poll, { _PollUIStatus status, bool save = true}) {
    _PollChunk pollChunk;
    if (_pollChunks[poll.pollId] == null) {
      if (status == null) {
        status = (poll.status != PollStatus.closed) ? _PollUIStatus.waitingVote : _PollUIStatus.waitingClose;
      }
      _pollChunks[poll.pollId] = pollChunk = _PollChunk(poll: poll, status: status);
      _openEventStream(poll.pollId);
      if (save == true) {
        _savePollChunks();
      }
    }
    return pollChunk;
  }

  void _openEventStream(String pollId) async {
    _PollChunk pollChunk = _pollChunks[pollId];
    if ((pollChunk != null) && (pollChunk.eventClient == null) && (pollChunk.eventListener == null)) {
      try {
        String url = '${Config().quickPollsUrl}/events/$pollId';
        pollChunk.eventClient = Client();
        /*pollChunk.eventSource = EventSource(Uri.parse(url),
            clientFactory: (){
          //Network.RokwireApiKey: Config().rokwireApiKey,
              HttpClient client = HttpClient();
              return client;
            },
        );*/

        var request = new Request("GET", Uri.parse(url));
        request.headers["Cache-Control"] = "no-cache";
        request.headers["Accept"] = "text/event-stream";
        
        String accessToken = Auth2().token?.accessToken;
        String tokenType = Auth2().token?.tokenType ?? 'Bearer';
        request.headers[HttpHeaders.authorizationHeader] = "$tokenType $accessToken";
        //request.headers[Network.RokwireApiKey] = Config().rokwireApiKey;

        Future<StreamedResponse> response = pollChunk.eventClient.send(request);
        print("Subscribed!");

        pollChunk.eventListener = response.asStream().listen((streamedResponse) {
          print("Received streamedResponse.statusCode:${streamedResponse.statusCode}");
          streamedResponse.stream.listen((data) {
            // Data example: "event:results\ndata:[5,4]\n\n"
            String dataString = utf8.decode(data).trim();
            _setEventListenerTimer(pollId);
            
            if(dataString?.isNotEmpty ?? false){
              String eventName = dataString.substring(dataString.indexOf(":")+1, dataString.indexOf("\n"));
              String eventData = dataString.substring(dataString.lastIndexOf(":")+1);
              _onPollEvent(pollId, eventName, eventData);
            }

          }, onError: (e){
            Log.e(e.toString());
            _resetEventStream(pollId, timeout: Duration(seconds: 3));
          }, onDone: (){
            _resetEventStream(pollId, timeout: Duration(seconds: 3));
          });
        });
      }
      on Exception catch(e) {
        Log.d('Polls: failed to opened EventStream for poll #$pollId');
        print(e.toString());
      }

      // retry after 3 secs.
      Log.d('Polls: scheduled opening EventStream for poll #$pollId after 3 seconds...');
      Timer(Duration(seconds: 3), (){
        _openEventStream(pollId);
      });
    }
  }

  void _resetEventStream(String pollId, { Duration timeout }) {

    _PollChunk pollChunk = _pollChunks[pollId];
    if (pollChunk != null) {
      Log.d('Polls: closed EventStream for poll #$pollId');
      pollChunk.closeEventStream(permanent: false);
    }
    
    if (timeout == null) {
      _openEventStream(pollId);
    }
    else {
      Timer(timeout, () {
        _openEventStream(pollId);
      });
    }
  }

  void _setEventListenerTimer(String pollId) {
    _PollChunk pollChunk = _pollChunks[pollId];
    if (pollChunk != null) {
      if (pollChunk.eventListenerTimer != null) {
        pollChunk.eventListenerTimer.cancel();
      }
      pollChunk.eventListenerTimer = Timer(Duration(seconds: 60), () {
        Log.d('Polls: reopenning EventStream for poll #$pollId');
        _resetEventStream(pollId);
      }  );
    }
  }

  void _removePollChunk(_PollChunk pollChunk) {
    pollChunk.closeEventStream(permanent: true);
    _pollChunks.remove(pollChunk?.poll?.pollId);
    _savePollChunks();
  }

  _PollChunk get _waitingPoll {
    for (String pollId in _pollChunks.keys) {
      _PollChunk pollChunk = _pollChunks[pollId];
      if (pollChunk.canPresent) {
        return pollChunk;
      }
    }
    return null;
  }

  _PollChunk get _presentPoll {
    for (_PollChunk pollChunk in _pollChunks.values) {
      if ((pollChunk.status == _PollUIStatus.presentVote) || (pollChunk.status == _PollUIStatus.presentResult)) {
        return pollChunk;
      }
    }
    return null;
  }

  set _presentPoll(_PollChunk pollChunk) {
    if (pollChunk != null) {
      if ((pollChunk.status == _PollUIStatus.waitingVote) && (pollChunk.poll.status == PollStatus.opened)) {
        pollChunk.status = _PollUIStatus.presentVote;
        _savePollChunks();
        NotificationService().notify(notifyPresentVote, pollChunk.poll.pollId);
      }
      else if ((pollChunk.status == _PollUIStatus.waitingClose) && (pollChunk.poll.status == PollStatus.closed) && pollChunk.poll.settings.hideResultsUntilClosed) {
        pollChunk.status = _PollUIStatus.presentResult;
        _savePollChunks();
        NotificationService().notify(notifyPresentResult, pollChunk.poll.pollId);
      }
    }
  }

  void _presentWaiting() {
    if (_presentPoll == null) {
      _presentPoll = _waitingPoll;
    }
  }

  void _processAppLifeCycle(){
    if(AppLivecycle().state == AppLifecycleState.paused){
      PollsPlugin().stopScan();
    }
    else if(AppLivecycle().state == AppLifecycleState.resumed){
      PollsPlugin().startScan();
    }
  }

  void _closePresent() {
    _PollChunk presentPoll = _presentPoll;
    if (presentPoll != null) {
      if (presentPoll.status == _PollUIStatus.presentVote) {
        presentPoll.status = _PollUIStatus.waitingClose;
        _savePollChunks();
      }
      else if (presentPoll.status == _PollUIStatus.presentResult) {
        _removePollChunk(presentPoll);
      }
    }
  }

  void _launchPollNotification(Poll poll) {
    String creator = poll?.creatorUserName ?? Localization().getStringEx('panel.poll_prompt.text.someone', 'Someone');
    String wantsToKnow = sprintf(Localization().getStringEx('panel.poll_prompt.text.wants_to_know', '%s wants to know'), [creator]);
    NativeCommunicator().launchNotification(body: poll.title, subtitle: wantsToKnow);
  }

  void _savePollChunks() {
    Map<String, dynamic> chunksJson = {};
    _pollChunks.forEach((String pollId, _PollChunk pollChunk) {
      chunksJson[pollId] = _pollUIStatusToString(pollChunk.status);
    });
    try { Storage().activePolls = chunksJson.isNotEmpty ? json.encode(chunksJson) : null; }
    on Exception catch(e) { print(e.toString()); }
  }

  Future<void> _loadPollChunks() async {
    String pollsJsonString = Storage().activePolls;
    Map<String, dynamic> chunksJson = AppJson.decode(pollsJsonString);
    
    if ((chunksJson != null) && (chunksJson.isNotEmpty)) {
      String url = '${Config().quickPollsUrl}/polls/${Auth2().accountId}';

      String body;
      try { body = json.encode({'ids': List.from(chunksJson.keys)}); }
      on Exception catch(e) { print(e.toString()); }

      Response response = await Network().post(url, body: body, auth: NetworkAuth.Auth2);
      if ((response != null) && (response.statusCode == 200)) {
        List<dynamic> pollsJson = AppJson.decode(response.body);
        if (pollsJson != null) {
          for (dynamic pollJson in pollsJson) {
            Poll poll = Poll.fromJson(pollJson);
            _PollUIStatus status = _pollUIStatusFromString(chunksJson[poll.pollId]);
            if (poll.status != PollStatus.closed) {
              _addPollToChunks(poll, status: status, save: false);
            }
            else if ((status != _PollUIStatus.waitingVote) && poll.settings.hideResultsUntilClosed) {
              _addPollToChunks(poll, status: _PollUIStatus.waitingClose, save: false);
            }
          }
        }
        _savePollChunks();
        _presentWaiting();
      }
    }
  }

  /////////////////////////
  // Enabled

  bool get _enabled => AppString.isStringNotEmpty(Config().quickPollsUrl);
}

class _PollChunk {
  Poll poll;
  
  _PollUIStatus status;
  
  Client eventClient;
  StreamSubscription eventListener;
  Timer eventListenerTimer;
  String lastEventId;

  _PollChunk({this.poll, this.status });

  bool get canPresent {
    if ((status == _PollUIStatus.waitingVote) &&
        (poll.status == PollStatus.opened) &&
        (!poll.isGeoFenced || GeoFence().currentRegionIds.contains(poll.regionId)))
      {
          return true;
      }
      if ((status == _PollUIStatus.waitingClose) &&
          (poll.status == PollStatus.closed) &&
          poll.settings.hideResultsUntilClosed)
      {
          return true;
      }
      return false;
  }

  // This method is unused but keep it to suppress the must close subscription warning
  void closeEventStream({bool permanent = true}) {
    if (eventListener != null) {
      eventListener.cancel();
      eventListener = null;
    }
    if (eventListenerTimer != null) {
      eventListenerTimer.cancel();
      eventListenerTimer = null;
    }
    if (eventClient != null) {
      eventClient.close();
      eventClient = null;
    }
    if (permanent) {
      lastEventId = null;
    }
  }
}

enum _PollUIStatus { waitingVote, presentVote, waitingClose, presentResult }

class PollsChunk {
  List<Poll> polls;
  String cursor;
  PollsChunk({this.polls, this.cursor});
}

String _pollUIStatusToString(_PollUIStatus status) {
  switch(status) {
    case _PollUIStatus.waitingVote : return 'waitingVote';
    case _PollUIStatus.presentVote : return 'presentVote';
    case _PollUIStatus.waitingClose : return 'waitingClose';
    case _PollUIStatus.presentResult : return 'presentResult';
  }
  return null;
}

_PollUIStatus _pollUIStatusFromString(String value) {
  if (value == 'waitingVote') {
    return _PollUIStatus.waitingVote;
  }
  else if (value == 'presentVote') {
    return _PollUIStatus.presentVote;
  }
  else if (value == 'waitingClose') {
    return _PollUIStatus.waitingClose;
  }
  else if (value == 'presentResult') {
    return _PollUIStatus.presentResult;
  }
  else {
    return null;
  }
}
