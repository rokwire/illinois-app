
import 'package:collection/collection.dart';
import 'package:illinois/model/GBV.dart';

extension GBVResourceUI on GBVResource {

  String? get chevronIconKey {
    if (type != GBVResourceType.external_link) {
      return 'chevron-right';
    }
    else if (externalLinkDetail != null) {
      return 'external-link';
    }
    else {
      return null;
    }
  }

  Iterable<GBVResourceDetail> get directoryNotLinkContent => directoryContent.where((detail) => detail.type.isNotLink);

  GBVResourceDetail? get externalLinkDetail => directoryContent.firstWhereOrNull((detail) => detail.type == GBVResourceDetailType.external_link);
  GBVResourceDetail? get internalLinkDetail => directoryContent.firstWhereOrNull((detail) => detail.type == GBVResourceDetailType.internal_link);

  GBVResourceDetail? get externalOrInternalLinkDetail => externalLinkDetail ?? internalLinkDetail;
  GBVResourceDetail? get internalOrExternalLinkDetail => internalLinkDetail ?? externalLinkDetail;
}

