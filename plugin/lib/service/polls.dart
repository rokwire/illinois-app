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
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class Polls with Service implements NotificationsListener {

  static const String notifyCreated          = "edu.illinois.rokwire.poll.created"; // new poll created, bubble should appear
  static const String notifyPresentVote      = "edu.illinois.rokwire.poll.present.vote"; // poll opened for voting, bubble should appear
  static const String notifyPresentResult    = "edu.illinois.rokwire.poll.present.result"; // poll opened for voting, bubble should appear
  static const String notifyResultsChanged   = "edu.illinois.rokwire.poll.resultschanged"; // poll updated
  static const String notifyVoteChanged      = "edu.illinois.rokwire.poll.votechanged"; // poll updated
  static const String notifyStatusChanged    = "edu.illinois.rokwire.poll.statuschnaged"; // poll closed, results could be presented

  static const String notifyLifecycleCreate  = "edu.illinois.rokwire.poll.lifecycle.create";
  static const String notifyLifecycleOpen    = "edu.illinois.rokwire.poll.lifecycle.open";
  static const String notifyLifecycleClose   = "edu.illinois.rokwire.poll.lifecycle.close";
  static const String notifyLifecycleVote    = "edu.illinois.rokwire.poll.lifecycle.vote";

  final Map<String, PollChunk> _pollChunks = <String, PollChunk>{};
  
  @protected
  Map<String, PollChunk> get pollChunks => _pollChunks;

  // Singletone Factory

  static Polls? _instance;

  static Polls? get instance => _instance;
  
  @protected
  static set instance(Polls? value) => _instance = value;

  factory Polls() => _instance ?? (_instance = Polls.internal());

  @protected
  Polls.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, GeoFence.notifyCurrentRegionsUpdated);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this, GeoFence.notifyCurrentRegionsUpdated);
  }

  @override
  Future<void> initService() async {
    if (enabled) {
      await loadPollChunks();
      await super.initService();
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Storage(), Config(), Auth2() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (enabled) {
      if (name == GeoFence.notifyCurrentRegionsUpdated) {
        presentWaiting();
      }
    }
  }

  // Accessories

  Future<PollsChunk?>? getMyPolls({String? cursor, List<String>? groupIds}) async {
    return enabled ? getPolls('mypolls', cursor, groupIds: groupIds) : null;
  }

  Future<PollsChunk?>? getGroupPolls(List<String>? groupIds, {String? cursor}) async {
    return enabled ? getPolls('grouppolls', cursor, groupIds: groupIds) : null;
  }

  Future<PollsChunk?>? getRecentPolls({String? cursor}) async {
    return enabled ?  getPolls('recentpolls', cursor) : null;
  }

  @protected
  Future<PollsChunk?> getPolls(String pollsType, String? cursor, {bool includeAccountId = true, List<String>? groupIds}) async {
    if (enabled) {
      String? body;
      if (CollectionUtils.isNotEmpty(groupIds)) {
        body = json.encode({'group_ids': groupIds});
      }

      String url = '${Config().quickPollsUrl}/$pollsType';
      if (includeAccountId) {
        url += '/${Auth2().accountId}';
      }

      if (cursor != null) {
        url += '?cursor=$cursor';
      }

      Response? response = await Network().get(url, body: body, auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      String? responseBody = response?.body;
      if ((response != null) && (responseCode == 200)) {
        Map<String, dynamic>? responseJson = JsonUtils.decode(responseBody);
        String? pollsCursor = (responseJson != null) ? responseJson['cursor'] : null;
        List<dynamic>? pollsJson = (responseJson != null) ? responseJson['data'] : null;
        if (pollsJson != null) {
          return PollsChunk(polls: Poll.fromJsonList(pollsJson), cursor: pollsCursor);
        }
        else {
          throw PollsException(PollsError.serverResponseContent);
        }
      }
      else {
        throw PollsException(PollsError.serverResponse, '${response?.statusCode} ${response?.body}');
      }
    }
    return null;
  }

  Poll? getPoll({String? pollId}) {
    return enabled ? _pollChunks[pollId]?.poll : null;
  }

  // API

  Future<void> create(Poll poll) async {
    if (enabled) {
      String url = '${Config().quickPollsUrl}/pollcreate';
      Response? response = await Network().post(url, body: json.encode(poll.toJson()), auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      String? responseString = response?.body;
      if ((response != null) && (responseCode == 200)) {
        Map<String, dynamic>? responseJson = JsonUtils.decode(responseString);
        String? pollId = (responseJson != null) ? responseJson['id'] : null;
        if (pollId != null) {
          poll.pollId = pollId;

          NotificationService().notify(notifyLifecycleCreate, poll);

          addPollToChunks(poll);

          if (poll.status == PollStatus.opened) {
            NotificationService().notify(notifyLifecycleOpen, poll);
            /*if (poll.isFirebase) {
              FirebaseMessaging().send(topic:'polls', message:{'type':'poll_open', 'poll_id': pollId});
            }
            else {
              PollsPlugin().openPoll(poll.pollId);
            }*/
          }

          Timer(const Duration(milliseconds: 500), () {
            NotificationService().notify(notifyCreated, poll.pollId);
            if (!poll.hasGroup) {
              presentWaiting();
            }
          });
        }
        else {
          throw PollsException(PollsError.serverResponseContent);
        }
      }
      else {
        throw PollsException(PollsError.serverResponse, '${response?.statusCode} ${response?.body}');
      }
    }
    else {
      throw PollsException(PollsError.internal);
    }
  }

  Future<void> open(String? pollId) async {
    if (enabled) {
      if (pollId != null) {
        String url = '${Config().quickPollsUrl}/pollstart/$pollId';
        Response? response = await Network().put(url, auth: Auth2());
        if ((response != null) && (response.statusCode == 200)) {
          onPollStarted(pollId).then((Poll? poll) {
            if (poll != null) {
              NotificationService().notify(notifyLifecycleOpen, poll);
              /*if (poll.isFirebase) {
                FirebaseMessaging().send(topic:'polls', message:{'type':'poll_open', 'poll_id': pollId});
              }
              else {
                PollsPlugin().openPoll(pollId);
              }*/
            }
          });
        }
        else {
          throw PollsException(PollsError.serverResponse, '${response?.statusCode} ${response?.body}');
        }
      }
      else {
        throw PollsException(PollsError.internal);
      }
    }
  }

  Future<void> vote(String? pollId, PollVote? vote) async {
    if (enabled) {
      if ((pollId != null) && (vote != null)) {
        String url = '${Config().quickPollsUrl}/pollvote/$pollId';
        Map<String, dynamic> voteJson = {
          'userid': Auth2().accountId,
          'answer': vote.toVotesJson(),
        };
        String voteString = json.encode(voteJson);
        Response? response = await Network().post(url, body: voteString, auth: Auth2());
        if ((response != null) && (response.statusCode == 200)) {
          NotificationService().notify(notifyLifecycleVote, getPoll(pollId: pollId));
          updatePollVote(pollId, vote);
        }
        else {
          throw PollsException(PollsError.serverResponse, '${response?.statusCode} ${response?.body}');
        }
      }
      else {
        throw PollsException(PollsError.internal);
      }
    }
  }

  Future<void> close(String? pollId) async {
    if (enabled) {
      if (pollId != null) {
        String url = '${Config().quickPollsUrl}/pollend/$pollId';
        Response? response = await Network().put(url, auth: Auth2());
        if ((response != null) && (response.statusCode == 200)) {
          NotificationService().notify(notifyLifecycleClose, getPoll(pollId: pollId));
          updatePollStatus(pollId, PollStatus.closed);
          NotificationService().notify(notifyStatusChanged, pollId);
        }
        else {
          throw PollsException(PollsError.serverResponse, '${response?.statusCode} ${response?.body}');
        }
      }
      else {
        throw PollsException(PollsError.internal);
      }
    }
  }

  Future<Poll?> load({int? pollPin}) async {
    if (enabled) {
      if (pollPin != null) {
        String url = '${Config().quickPollsUrl}/pinpolls/$pollPin';
        Response? response = await Network().get(url, auth: Auth2());
        if (response?.statusCode == 200) {
          Map<String, dynamic>? responseJson = JsonUtils.decode(response?.body);
          List<dynamic>? responseList = (responseJson != null) ? responseJson['data'] : null;
          List<Poll>? polls = (responseList != null) ? Poll.fromJsonList(responseList) : null;
          if (polls != null) {
            List<Poll> results = [];
            for (Poll poll in polls) {
              if (!poll.isGeoFenced || GeoFence().currentRegionIds.contains(poll.regionId)) {
                results.add(poll);
              }
            }

            Poll? poll = polls.isNotEmpty ? polls.first : null;
            if ((poll != null) && (_pollChunks[poll.pollId] == null)) {
              addPollToChunks(poll);
              NotificationService().notify(notifyCreated, poll.pollId);
              //presentWaiting();
            }
            return poll;
          }
          else {
            throw PollsException(PollsError.serverResponseContent);
          }
        }
        else {
          throw PollsException(PollsError.serverResponse, '${response?.statusCode} ${response?.body}');
        }
      }
      else {
        throw PollsException(PollsError.internal);
      }
    }
    return null;
  }

  bool presentPollId(String? pollId) {
    if (enabled && presentPoll == null) {
      PollChunk? pollChunk = _pollChunks[pollId];
      if (pollChunk != null) {
        if ((pollChunk.status == PollUIStatus.waitingClose) && (pollChunk.poll!.status == PollStatus.opened)) {
          pollChunk.status = PollUIStatus.waitingVote;
        }
        if (pollChunk.canPresent) {
          presentPoll = pollChunk;
          return true;
        }
      }
    }
    return false;
  }

  void closePresenting() {
    if (enabled) {
      closePresent();
      presentWaiting();
    }
  }

  void presentPollVote(Poll? poll) {
    if (enabled) {
      PollChunk? pollChunk = _pollChunks[poll!.pollId];
      if ((pollChunk == null) && (poll.status == PollStatus.opened)) {
        pollChunk = addPollToChunks(poll);
      }
      if ((pollChunk != null) && (pollChunk.poll!.status == PollStatus.opened)) {
        if (pollChunk.status == PollUIStatus.waitingClose) {
          pollChunk.status = PollUIStatus.waitingVote;
        }
        presentWaiting();
      }
    }
  }

  Poll? get presentingPoll {
    return enabled ? presentPoll?.poll : null;
  }

  List<Poll>? localRecentPolls() {
    if (enabled) {
      List<PollChunk> pollChunks = [];
      _pollChunks.forEach((String? pollId, PollChunk pollChunk) {
        if ((pollChunk.poll!.status != PollStatus.closed) && ((pollChunk.poll!.userVote?.totalVotes ?? 0) == 0)) {
          pollChunks.add(pollChunk);
        }
      });

      pollChunks.sort((PollChunk pollChunk1, PollChunk pollChunk2) {
        return pollChunk2.poll!.pollId!.compareTo(pollChunk1.poll!.pollId!);
      });

      List<Poll> polls = [];
      for (PollChunk pollChunk in pollChunks) {
        if (pollChunk.poll != null) {
          polls.add(pollChunk.poll!);
        }
      }
      return polls;
    }
    return null;
  }

  @protected
  void updatePollStatus(String? pollId, PollStatus pollStatus) {
    if (pollId != null) {
      PollChunk? pollChunk = _pollChunks[pollId];
      if (pollChunk != null) {
        if (pollChunk.poll!.status != pollStatus) {
          pollChunk.poll!.status = pollStatus;
          NotificationService().notify(notifyStatusChanged, pollId);

          if (pollStatus == PollStatus.closed) {
            onPollClosed(pollId);
          }
        }
      }
    }
  }

  @protected
  void updatePollResults(String? pollId, PollVote? pollResults) {
    if (pollId != null) {
      PollChunk? pollChunk = _pollChunks[pollId];
      if (pollChunk != null) {
        if ((pollChunk.poll!.results == null) || !pollChunk.poll!.results!.isEqual(pollResults)) {
          pollChunk.poll!.results = pollResults;
          NotificationService().notify(notifyResultsChanged, pollId);
        }
      }
    }
  }

  @protected
  void updatePollVote(String? pollId, PollVote pollVote) {
    if (pollId != null) {
      PollChunk? pollChunk = _pollChunks[pollId];
      if (pollChunk != null) {
        pollChunk.poll!.apply(pollVote);
        NotificationService().notify(notifyVoteChanged, pollId);
      }
    }
  }

  @protected
  Future<Poll?> onPollStarted(String? pollId) async {
    Log.d('Polls: starting poll #$pollId');
    if (pollId != null) {
      PollChunk? pollChunk = _pollChunks[pollId];
      if (pollChunk == null) {
        try {
          String url = '${Config().quickPollsUrl}/poll/$pollId';
          Response? response = await Network().get(url, auth: Auth2());
          String? responseString = ((response != null) && (response.statusCode == 200)) ? response.body : null;
          Map<String, dynamic>? responseJson = JsonUtils.decode(responseString);
          Poll? poll = (responseJson != null) ? Poll.fromJson(responseJson) : null;
          if ((poll != null) && (!poll.isGeoFenced || GeoFence().currentRegionIds.contains(poll.regionId))) {
            addPollToChunks(poll);
            NotificationService().notify(notifyCreated, pollId);
            if (!poll.hasGroup) {
              presentWaiting();
              if (AppLivecycle().state == AppLifecycleState.paused) {
                launchPollNotification(poll);
              }
            }
            return poll;
          }
        } on Exception catch(e) {
          debugPrint(e.toString());
        }
      }
      else if ((pollChunk.poll?.status != PollStatus.opened)) {
        pollChunk.poll!.status = PollStatus.opened;
        NotificationService().notify(notifyStatusChanged, pollId);
        presentWaiting();
        return pollChunk.poll;
      }
    }
    return null;
  }

  @protected
  void onPollClosed(String pollId) {
    Log.d('Polls: closing poll #$pollId');
    PollChunk? pollChunk = _pollChunks[pollId];
    if (pollChunk != null) {
      if (pollChunk.status == PollUIStatus.waitingVote) {
        removePollChunk(pollChunk);
      }
      else if (pollChunk.status == PollUIStatus.presentVote) {
        // Wait for closePresenting to remove or change status
      }
      else if (pollChunk.status == PollUIStatus.waitingClose) {
        if (pollChunk.poll!.settings!.hideResultsUntilClosed!) {
          presentWaiting();
        }
        else {
          removePollChunk(pollChunk);
        }
      }
      else if (pollChunk.status == PollUIStatus.presentResult) {
        // Wait for closePresenting to remove
      }
    }
  }

  @protected
  void onPollEvent(String? pollId, String eventName, String eventData) {
    Log.d('Polls: received event \'$eventName\' from EventStream for poll #$pollId');
    try {
      if (eventName == 'status') {
        List<dynamic>? jsonList = JsonUtils.decode(eventData);
        String? statusString = ((jsonList != null) && jsonList.isNotEmpty) ? jsonList.first : null;
        PollStatus? pollStatus = Poll.pollStatusFromString(statusString);
        if (pollStatus != null) {
          updatePollStatus(pollId, pollStatus);
        }
      }
      else if (eventName == 'results') {
        List<dynamic>? jsonList = JsonUtils.decode(eventData);
        List<int>? results = (jsonList != null) ? jsonList.cast<int>() : null;
        PollVote? pollResults = (results != null) ? PollVote.fromJson(results: results) : null;
        if (pollResults != null) {
          updatePollResults(pollId, pollResults);
        }
      }
    }
    on Exception catch(e) {
      debugPrint(e.toString());
    }
  }

  @protected
  PollChunk? addPollToChunks(Poll poll, { PollUIStatus? status, bool save = true}) {
    PollChunk? pollChunk;
    if (poll.pollId != null) {
      if (_pollChunks[poll.pollId] == null) {
        status ??= (poll.status != PollStatus.closed) ? PollUIStatus.waitingVote : PollUIStatus.waitingClose;
        _pollChunks[poll.pollId!] = pollChunk = PollChunk(poll: poll, status: status);
        openEventStream(poll.pollId);
        if (save == true) {
          savePollChunks();
        }
      }
    }
    return pollChunk;
  }

  @protected
  void openEventStream(String? pollId) async {
    PollChunk? pollChunk = _pollChunks[pollId];
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

        var request = Request("GET", Uri.parse(url));
        request.headers["Cache-Control"] = "no-cache";
        request.headers["Accept"] = "text/event-stream";
        
        String? accessToken = Auth2().token?.accessToken;
        String tokenType = Auth2().token?.tokenType ?? 'Bearer';
        request.headers[HttpHeaders.authorizationHeader] = "$tokenType $accessToken";
        //request.headers[Network.RokwireApiKey] = Config().rokwireApiKey;

        Future<StreamedResponse> response = pollChunk.eventClient!.send(request);
        debugPrint("Subscribed!");

        pollChunk.eventListener = response.asStream().listen((streamedResponse) {
          debugPrint("Received streamedResponse.statusCode:${streamedResponse.statusCode}");
          streamedResponse.stream.listen((data) {
            // Data example: "event:results\ndata:[5,4]\n\n"
            String dataString = utf8.decode(data).trim();
            setEventListenerTimer(pollId);
            
            if(dataString.isNotEmpty){
              String eventName = dataString.substring(dataString.indexOf(":")+1, dataString.indexOf("\n"));
              String eventData = dataString.substring(dataString.lastIndexOf(":")+1);
              onPollEvent(pollId, eventName, eventData);
            }

          }, onError: (e){
            Log.e(e.toString());
            resetEventStream(pollId, timeout: const Duration(seconds: 3));
          }, onDone: (){
            resetEventStream(pollId, timeout: const Duration(seconds: 3));
          });
        });
      }
      on Exception catch(e) {
        Log.d('Polls: failed to opened EventStream for poll #$pollId');
        debugPrint(e.toString());
      }

      // retry after 3 secs.
      Log.d('Polls: scheduled opening EventStream for poll #$pollId after 3 seconds...');
      Timer(const Duration(seconds: 3), (){
        openEventStream(pollId);
      });
    }
  }

  @protected
  void resetEventStream(String? pollId, { Duration? timeout }) {

    PollChunk? pollChunk = _pollChunks[pollId];
    if (pollChunk != null) {
      Log.d('Polls: closed EventStream for poll #$pollId');
      pollChunk.closeEventStream(permanent: false);
    }
    
    if (timeout == null) {
      openEventStream(pollId);
    }
    else {
      Timer(timeout, () {
        openEventStream(pollId);
      });
    }
  }

  @protected
  void setEventListenerTimer(String? pollId) {
    PollChunk? pollChunk = _pollChunks[pollId];
    if (pollChunk != null) {
      if (pollChunk.eventListenerTimer != null) {
        pollChunk.eventListenerTimer!.cancel();
      }
      pollChunk.eventListenerTimer = Timer(const Duration(seconds: 60), () {
        Log.d('Polls: reopenning EventStream for poll #$pollId');
        resetEventStream(pollId);
      }  );
    }
  }

  @protected
  void removePollChunk(PollChunk pollChunk) {
    pollChunk.closeEventStream(permanent: true);
    _pollChunks.remove(pollChunk.poll?.pollId);
    savePollChunks();
  }

  @protected
  PollChunk? get waitingPoll {
    for (String? pollId in _pollChunks.keys) {
      PollChunk pollChunk = _pollChunks[pollId]!;
      if (pollChunk.canPresent) {
        return pollChunk;
      }
    }
    return null;
  }

  @protected
  PollChunk? get presentPoll {
    for (PollChunk pollChunk in _pollChunks.values) {
      if ((pollChunk.status == PollUIStatus.presentVote) || (pollChunk.status == PollUIStatus.presentResult)) {
        return pollChunk;
      }
    }
    return null;
  }

  @protected
  set presentPoll(PollChunk? pollChunk) {
    if (pollChunk != null) {
      if ((pollChunk.status == PollUIStatus.waitingVote) && (pollChunk.poll!.status == PollStatus.opened)) {
        pollChunk.status = PollUIStatus.presentVote;
        savePollChunks();
        NotificationService().notify(notifyPresentVote, pollChunk.poll!.pollId);
      }
      else if ((pollChunk.status == PollUIStatus.waitingClose) && (pollChunk.poll!.status == PollStatus.closed) && pollChunk.poll!.settings!.hideResultsUntilClosed!) {
        pollChunk.status = PollUIStatus.presentResult;
        savePollChunks();
        NotificationService().notify(notifyPresentResult, pollChunk.poll!.pollId);
      }
    }
  }

  void presentWaiting() {
    presentPoll ??= waitingPoll;
  }

  @protected
  void closePresent() {

    PollChunk? presentingPoll = presentPoll;
    if (presentingPoll != null) {
      if (presentingPoll.status == PollUIStatus.presentVote) {
        presentingPoll.status = PollUIStatus.waitingClose;
        savePollChunks();
      }
      else if (presentingPoll.status == PollUIStatus.presentResult) {
        removePollChunk(presentingPoll);
      }
    }
  }

  @protected
  void launchPollNotification(Poll poll) {
    RokwirePlugin.showNotification(body: poll.title, subtitle: getPollNotificationMessage(poll));
  }

  @protected
  String getPollNotificationMessage(Poll poll) {
    String creator = poll.creatorUserName ?? 'Someone';
    return sprintf('%s wants to know', [creator]);
  }

  @protected
  void savePollChunks() {
    Map<String, dynamic> chunksJson = {};
    _pollChunks.forEach((String pollId, PollChunk pollChunk) {
      chunksJson[pollId] = pollUIStatusToString(pollChunk.status);
    });
    try { Storage().activePolls = chunksJson.isNotEmpty ? json.encode(chunksJson) : null; }
    on Exception catch(e) { debugPrint(e.toString()); }
  }

  @protected
  Future<void> loadPollChunks() async {
    String? pollsJsonString = Storage().activePolls;
    Map<String, dynamic>? chunksJson = JsonUtils.decode(pollsJsonString);
    
    if ((chunksJson != null) && (chunksJson.isNotEmpty)) {
      String url = '${Config().quickPollsUrl}/polls/${Auth2().accountId}';

      String? body;
      try { body = json.encode({'ids': List.from(chunksJson.keys)}); }
      on Exception catch(e) { debugPrint(e.toString()); }

      Response? response = await Network().post(url, body: body, auth: Auth2());
      if ((response != null) && (response.statusCode == 200)) {
        List<dynamic>? pollsJson = JsonUtils.decode(response.body);
        if (pollsJson != null) {
          for (dynamic pollJson in pollsJson) {
            Poll poll = Poll.fromJson(pollJson)!;
              PollUIStatus? status = pollUIStatusFromString(chunksJson[poll.pollId]);
              if (poll.status != PollStatus.closed) {
                addPollToChunks(poll, status: status, save: false);
              } else if ((status != PollUIStatus.waitingVote) && poll.settings!.hideResultsUntilClosed!) {
                addPollToChunks(poll, status: PollUIStatus.waitingClose, save: false);
              }
          }
        }
        savePollChunks();
        presentWaiting();
      }
    }
  }

  /////////////////////////
  // Enabled

  bool get enabled => StringUtils.isNotEmpty(Config().quickPollsUrl);
}

class PollChunk {
  Poll? poll;
  
  PollUIStatus? status;
  
  Client? eventClient;
  StreamSubscription? eventListener;
  Timer? eventListenerTimer;
  String? lastEventId;

  PollChunk({this.poll, this.status });

  bool get canPresent {
    if ((status == PollUIStatus.waitingVote) &&
        (poll!.status == PollStatus.opened) &&
        (!poll!.isGeoFenced || GeoFence().currentRegionIds.contains(poll!.regionId)))
      {
          return true;
      }
      if ((status == PollUIStatus.waitingClose) &&
          (poll!.status == PollStatus.closed) &&
          poll!.settings!.hideResultsUntilClosed!)
      {
          return true;
      }
      return false;
  }

  // This method is unused but keep it to suppress the must close subscription warning
  void closeEventStream({bool permanent = true}) {
    eventListener?.cancel();
    eventListener = null;

    eventListenerTimer?.cancel();
    eventListenerTimer = null;

    eventClient?.close();
    eventClient = null;

    if (permanent) {
      lastEventId = null;
    }
  }
}

enum PollUIStatus { waitingVote, presentVote, waitingClose, presentResult }

class PollsChunk {
  List<Poll>? polls;
  String? cursor;
  PollsChunk({this.polls, this.cursor});
}

String? pollUIStatusToString(PollUIStatus? status) {
  switch(status) {
    case PollUIStatus.waitingVote : return 'waitingVote';
    case PollUIStatus.presentVote : return 'presentVote';
    case PollUIStatus.waitingClose : return 'waitingClose';
    case PollUIStatus.presentResult : return 'presentResult';
    default: break;
  }
  return null;
}

PollUIStatus? pollUIStatusFromString(String? value) {
  if (value == 'waitingVote') {
    return PollUIStatus.waitingVote;
  }
  else if (value == 'presentVote') {
    return PollUIStatus.presentVote;
  }
  else if (value == 'waitingClose') {
    return PollUIStatus.waitingClose;
  }
  else if (value == 'presentResult') {
    return PollUIStatus.presentResult;
  }
  else {
    return null;
  }
}

enum PollsError { serverResponse, serverResponseContent, internal }

class PollsException implements Exception {
  final PollsError error;
  final String? descrition;
 
  PollsException(this.error, [this.descrition]);

  @override
  String toString() {
    String errorText;
    switch(error) {
      case PollsError.serverResponse: errorText = 'Server Response Error'; break;
      case PollsError.serverResponseContent: errorText = 'Invalid Server Response'; break;
      case PollsError.internal: errorText = 'Internal Error Occured'; break;
    }
    return (descrition != null) ? '$errorText: $descrition' : errorText;
  }

  @override
  bool operator ==(other) =>
    (other is PollsException) &&
      (other.error == error) &&
      (other.descrition == descrition);

  @override
  int get hashCode =>
    error.hashCode ^
    (descrition?.hashCode ?? 0);
}