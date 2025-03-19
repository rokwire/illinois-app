import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import '../service/AppDateTime.dart';

extension PollExt on Poll {
  String? get displayUpdateTime {
    String? dateUpdatedString = dateUpdatedUtcString ?? dateCreatedUtcString;
    if(StringUtils.isNotEmpty(dateUpdatedString)) {
      DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(DateTime.tryParse(dateUpdatedString!));
      return (deviceDateTime != null) ? AppDateTimeUtils.timeAgoSinceDate(deviceDateTime) : null;
    }
    else {
      return null;
    }
  }
}