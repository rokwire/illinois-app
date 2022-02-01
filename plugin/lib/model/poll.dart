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

import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class Poll {
  String? pollId;            // unique poll id (uuid)
  String? title;             // the question / "What’s the best breakfast spot in the dining halls?"
  List<String>? options;     // possible options (answers)

  PollSettings? settings;    // poll settings
  
  String? creatorUserUuid;   // creator uuid
  String? creatorUserName;   // creator name / "A student wants to know.."
  String? regionId;          // region id for geo fenced polls
  int? pinCode;              // poll pin
  
  PollStatus? status;        // active / inactive
  PollVote? results;         // results for this poll
  PollVote? userVote;        // vote for particual user (as comes from mypolls / recentpolls).

  String? groupId;           // The Id of the Group that the Poll belongs to.
  int? uniqueVotersCount;    // The number of unique users that voted

  Poll({
    this.pollId, this.title, this.options, this.settings,
    this.creatorUserUuid, this.creatorUserName, this.regionId, this.pinCode,
    this.status, this.results, this.userVote, this.groupId, this.uniqueVotersCount
  });

  static Poll? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Poll(
      pollId: json['id'],
      title: json['question'],
      options: List<String>.from(json['options']),
      
      //settings: PollSettings.fromJson(json['settings']),
      settings: PollSettings(
        allowMultipleOptions: json['multi_choice'],
        allowRepeatOptions: json['repeat'],
        hideResultsUntilClosed: !json['show_results'],
        geoFence: json['geo_fence'],
      ),
      
      creatorUserUuid: json['userid'],
      creatorUserName: json['username'],
      regionId: json['stadium'],
      pinCode: json['pin'],
      
      status: pollStatusFromString(json['status']),
      results: PollVote.fromJson(results:json['results'], total:json['total']),
      userVote: PollVote.fromJson(votes:json['voted']),

      groupId: json['group_id'],
      uniqueVotersCount: json['unique_voters_count'],
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': pollId,
      'question': title,
      'options': options,
      
      //'settings': settings?.toJson(),
      'multi_choice': (settings?.allowMultipleOptions ?? false),
      'repeat': (settings?.allowRepeatOptions ?? false),
      'show_results': !(settings?.hideResultsUntilClosed ?? false),
      'geo_fence': settings?.geoFence,
      
      'userid': creatorUserUuid,
      'username': creatorUserName,
      'stadium': regionId,
      'pin': pinCode,
      
      'status': pollStatusToString(status),
      'results': results?.toResultsJson(length: options?.length),
      'total': results?.total,
      'voted': userVote?.toVotesJson(),

      'group_id': groupId,
      'unique_voters_count': uniqueVotersCount
    };
  }

  bool get isMine {
    return (creatorUserUuid != null) && (creatorUserUuid == Auth2().accountId);
  }

  /*bool get isFirebase {
    return (regionId != null) && regionId!.isNotEmpty;
  }*/

  bool get isGeoFenced {
    return (regionId != null) && regionId!.isNotEmpty && (settings?.geoFence ?? false);
  }

  bool get hasGroup {
    return StringUtils.isNotEmpty(groupId);
  }

  static int get randomPin {
    return Random().nextInt(9998) + 1;
  }

  void apply(PollVote pollVote) {
    results ??= PollVote();
    results!.apply(pollVote);

    _increaseUniqueVotersCount();

    userVote ??= PollVote();
    userVote!.apply(pollVote);
  }

  void _increaseUniqueVotersCount() {
    uniqueVotersCount ??= 0;
    uniqueVotersCount = uniqueVotersCount! + 1;
  }

  static List<Poll> fromJsonList(List<dynamic>? jsonList) {
    List<Poll> polls = [];
    if (jsonList != null) {
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(polls, Poll.fromJson(jsonEntry));
      }
    }
    return polls;
  }

  static List<dynamic> toJsonList(List<Poll>? polls) {
    List<dynamic> jsonList = [];
    if (polls != null) {
      for (Poll poll in polls) {
        jsonList.add(poll.toJson());
      }
    }
    return jsonList;
  }

  static PollStatus? pollStatusFromString(String? value) {
    if (value == 'created') {
      return PollStatus.created;
    }
    else if (value == 'started') {
      return PollStatus.opened;
    }
    else if (value == 'terminated') {
      return PollStatus.closed;
    }
    else {
      return null;
    }
  }

  static String? pollStatusToString(PollStatus? status) {
    if (status == PollStatus.created) {
      return 'created';
    }
    else if (status == PollStatus.opened) {
      return 'started';
    }
    else if (status == PollStatus.closed) {
      return 'terminated';
    }
    else {
      return null;
    }
  }
}

class PollSettings {
  bool? allowMultipleOptions;   // "Allow selecting more than one choice"
  bool? allowRepeatOptions;     // "Allow repeat votes"
  bool? hideResultsUntilClosed; // "Shows results before poll ends"
  bool? geoFence;               // Poll is geo fenced

  PollSettings({this.allowMultipleOptions, this.allowRepeatOptions, this.hideResultsUntilClosed, this.geoFence});
}

enum PollStatus { created, opened, closed }

class PollVote {
  Map<int, int>? _votes;
  int? _total;

  PollVote({Map<int, int>? votes, int? total}) {
    _votes = votes;
    _total = total;
  }

  static PollVote? fromJson({List<dynamic>? results, List<dynamic>? votes, int? total}) {
    Map<int, int>? votesMap;
    if (results != null) {
      votesMap = {};
      for (int optionIndex = 0; optionIndex < results.length; optionIndex++) {
        votesMap[optionIndex] = results[optionIndex];
      }
    }
    else if (votes != null) {
      votesMap = {};
      for (int optionIndex in votes) {
        votesMap[optionIndex] = (votesMap[optionIndex] ?? 0) + 1;
      }
    }

    return (votesMap != null) ? PollVote(votes:votesMap, total: total) : null;
  }

  List<dynamic>?toResultsJson({int? length}) {
    List<dynamic>? results;
    if (_votes != null) {
      results = [];
      _votes!.forEach((int optionIndex, int optionVotes) {
        if ((length == null) || (optionIndex < length)) {
          while (results!.length < optionIndex) {
            results.add(0);
          }
          if (results.length == optionIndex) {
            results.add(optionVotes);
          }
          else {
            results[optionIndex] = optionVotes;
          }
        }
      });
    }
    return results;
  }

  List<dynamic>?toVotesJson() {
    List<dynamic>? votes;
    if (_votes != null) {
      votes = [];
      _votes!.forEach((int optionIndex, int optionVotes) {
        for (int optionVote = 0; optionVote < optionVotes; optionVote++) {
          votes!.add(optionIndex);
        }
      });
    }
    return votes;
  }

  Map<int, int>? get votes {
    return _votes;
  }

  int? get total {
    return _total;
  }

  int get totalVotes {
    int totalVotes = 0;
    if (_votes != null) {
      _votes!.forEach((int optionIndex, int optionVotes) {
        totalVotes += optionVotes;
      });
    }
    return totalVotes;
  }

  int? operator [](int? optionIndex) {
    return (_votes != null) ? _votes![optionIndex] : null;
  }

  void operator []=(int? optionIndex, int? optionValue) {
    if (optionIndex != null) {
      if (optionValue != null) {
        if (_votes != null) {
          _updateTotal(optionValue - (_votes![optionIndex] ?? 0));
          _votes![optionIndex] = optionValue;
        }
        else {
          _updateTotal(optionValue);
          _votes = { optionIndex : optionValue };
        }
      }
      else if (_votes != null) {
        _updateTotal(0 - (_votes![optionIndex] ?? 0));
        _votes!.remove(optionIndex);
      }
    }
  }

  bool isEqual(PollVote? pollVote) {
    Map<int, int>? votes = pollVote?._votes;
    if ((_votes == null) && (votes == null)) {
      return true;
    }
    if ((_votes != null) && (votes != null)) {
      if (votes.length == _votes!.length) {
        for (int optionIndex in votes.keys) {
          if (votes[optionIndex] != _votes![optionIndex]) {
            return false;
          }
        }
        return true;
      }
    }
    return false;
  }

  void _updateTotal(int? delta) {
    if (delta != null) {
      if (_total != null) {
        _total = _total! + delta;
      }
      else {
        _total = delta;
      }
    }
  }

  void apply(PollVote? vote) {
    if ((vote?._votes != null) && vote!._votes!.isNotEmpty) {
      _votes ??= {};
      int deltaTotal = 0;
      vote._votes!.forEach((int optionIndex, int optionVotes) {
        _votes![optionIndex] = optionVotes + (_votes![optionIndex] ?? 0);
        deltaTotal += optionVotes;
      });
      _updateTotal(deltaTotal);
    }
  }
}
