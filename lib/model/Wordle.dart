
import 'package:collection/collection.dart';
import 'package:illinois/service/Storage.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';
import 'package:uuid/uuid.dart';

enum WordleLetterStatus { inPlace, inUse, outOfUse }

class WordleGame {

  final String uuid;
  final String word;
  final List<String> moves;

  WordleGame(this.word, { String? uuid, this.moves = const <String>[] }) :
    this.uuid = uuid ?? Uuid().v1();

  factory WordleGame.fromOther(WordleGame other, {
    String? word,
    String? uuid,
    List<String>? moves,
  }) => WordleGame(word ?? other.word,
    uuid: uuid ?? other.uuid,
    moves: moves ?? other.moves,
  );

  // Accessories

  int get wordLength => word.wordLength;
  int get numberOfWords => word.numberOfWords;
  double get asectRatio => word.asectRatio;

  bool get isSucceeded => moves.isNotEmpty && (moves.last == word);
  bool get isFailed => (moves.length == numberOfWords) && (moves.last != word);
  bool get isFinished => isSucceeded || isFailed;

  List<WordleLetterStatus> wordStatus(String guess) {

    Map<String, int> wordLettersBag = _LettersBag.fromWord(word);
    List<WordleLetterStatus> guessStatus = List<WordleLetterStatus>.filled(guess.length, WordleLetterStatus.outOfUse);

    // Pass 1: determine inPlace
    for (int index = 0; index < guess.length; index++) {
      if (index < word.length) {
        String guessLetter = guess.substring(index, index + 1);
        String wordLetter = word.substring(index, index + 1);
        if (guessLetter == wordLetter) {
          guessStatus[index] = WordleLetterStatus.inPlace;
          wordLettersBag.removeLetter(wordLetter);
        }
      }
    }

    // Pass 2: determine inUse
    for (int guessIndex = 0; guessIndex < guess.length; guessIndex++) {
      if (guessStatus[guessIndex] == WordleLetterStatus.outOfUse) {
        String guessLetter = guess.substring(guessIndex, guessIndex + 1);
        if (wordLettersBag.containsLetter(guessLetter)) {
          guessStatus[guessIndex] = WordleLetterStatus.inUse;
          wordLettersBag.removeLetter(guessLetter);
        }
      }
    }

    return guessStatus;
  }


  // Equality

  @override
  bool operator==(Object other) =>
    (other is WordleGame) &&
    (word == other.word) &&
    (uuid == other.uuid) &&
    DeepCollectionEquality().equals(moves, other.moves);

  @override
  int get hashCode =>
    word.hashCode ^
    uuid.hashCode ^
    DeepCollectionEquality().hash(moves);

  // Json Serialization

  static WordleGame? fromJson(Map<String, dynamic>? json) {
    String? word = JsonUtils.stringValue(json?['word']);
    String? uuid = JsonUtils.stringValue(json?['uuid']);
    List<String>? moves = JsonUtils.listStringsValue(json?['moves']);
    return ((word != null) && (uuid != null) && (moves != null)) ? WordleGame(word, uuid: uuid, moves: moves) : null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'word': word,
    'uuid': uuid,
    'moves': moves,
  };

  // Storage Serialization

  static WordleGame? fromStorage() =>
    WordleGame.fromJson(JsonUtils.decodeMap(Storage().wordleGame) );

  void saveToStorage() =>
    Storage().wordleGame = JsonUtils.encode(toJson());

}

class WordleDailyWord {
  final String word;
  final DateTime? dateUni;
  final String? author;
  final String? storyTitle;
  final String? storyUrl;

  const WordleDailyWord({
    required this.word,
    this.dateUni, this.author,
    this.storyTitle, this.storyUrl,
  });

  // Json Serialization
  static WordleDailyWord? fromJson(Map<String, dynamic>? json) =>
    _fromJsonWord(JsonUtils.stringValue(json?['word']), json: json);

  static WordleDailyWord? _fromJsonWord(String? word, { Map<String, dynamic>? json }) => ((word != null) && word.isNotEmpty) ?
    WordleDailyWord(
      word: word.toUpperCase(),
      dateUni: dateUniFromString(JsonUtils.stringValue(json?['date'],)),
      author: JsonUtils.stringValue(json?['author']),
      storyTitle: JsonUtils.stringValue(json?['story_title']),
      storyUrl: JsonUtils.stringValue(json?['story_url']),
    ) : null;


  Map<String, dynamic> toJson() => <String, dynamic>{
    'word': word,
    'date': dateUniAsString,
    'author': author,
    'story_title': storyTitle,
    'story_url': storyUrl,
  };

  static DateTime? dateUniFromString(String? value) {
    DateTime? dateTimeUtc = (value != null) ? DateFormat(_dateFormat).tryParse(value, true) : null;
    return (dateTimeUtc != null) ? TZDateTime(DateTimeUni.timezoneUniOrLocal, dateTimeUtc.year, dateTimeUtc.month, dateTimeUtc.day) : null;
  }

  String? get dateUniAsString => (dateUni != null) ?
    (DateFormat(_dateFormat).format(DateTime.utc(dateUni!.year, dateUni!.month, dateUni!.day)) + ' GMT') : null;

  static const String _dateFormat = 'EEE, d MMM yyyy HH:mm:ss Z';

  // Accessories
  int get wordLength => word.wordLength;
  int get numberOfWords => word.numberOfWords;
  double get asectRatio => word.asectRatio;

  // Equality

  @override
  bool operator==(Object other) =>
    (other is WordleDailyWord) &&
    (word == other.word) &&
    (dateUni == other.dateUni) &&
    (author == other.author) &&
    (storyTitle == other.storyTitle);

  @override
  int get hashCode =>
    (word.hashCode) ^
    (dateUni?.hashCode ?? 0) ^
    (author?.hashCode ?? 0) ^
    (storyTitle?.hashCode ?? 0);

}

extension WordleWordRules on String {
  int get wordLength => length;
  int get numberOfWords => wordLength + 1;
  double get asectRatio => wordLength.toDouble() / numberOfWords.toDouble();
}

extension _LettersBag on Map<String, int> {

  static Map<String, int> fromWord(String word) {
    Map<String, int> bag = <String, int>{};
    for (int index = 0; index < word.length; index++) {
      String letter = word.substring(index, index + 1);
      bag[letter] = (bag[letter] ?? 0) + 1;
    }
    return bag;
  }

  bool removeLetter(String letter) {
    int letterCount = this[letter] ?? 0;
    if (0 < letterCount) {
      letterCount = letterCount - 1;
      if (0 < letterCount) {
        this[letter] = letterCount;
      }
      else {
        this.remove(letter);
      }
      return true; // removed
    }
    else {
      return false; // not in the bag
    }
  }

  int _letterCount(String letter) => this[letter] ?? 0;
  bool containsLetter(String letter) => (0 < _letterCount(letter));
}
