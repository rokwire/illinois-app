import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/poll.dart';

extension PollExt on Poll {
  String? get displayUpdateTime => (dateUpdatedUtcString != null) ?
    AppRelativeTime.timeAgoSinceDate(DateTime.tryParse(dateUpdatedUtcString!)) :
    null;
}