import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import '../service/AppDateTime.dart';

extension PollExt on Poll {
  String? get displayUpdateTime {
    if(StringUtils.isNotEmpty(dateUpdatedUtcString)) {
      DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(DateTime.tryParse(dateUpdatedUtcString!));
      return (deviceDateTime != null) ? AppDateTimeUtils.timeAgoSinceDate(deviceDateTime) : null;
    }
    else {
      return null;
    }
  }
}