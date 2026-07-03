
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryContentPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';

class AcademicLinksPanel extends GBVResourceDirectoryContentPanel {
  AcademicLinksPanel() : super(
    headerBarTitle: Localization().getStringEx('panel.browse.entry.academics.academic_links.title', 'Academic Links'),
    contentWidgetBuilder: (context) => AcademicLinksWidget(),
    analyticsFeature: AnalyticsFeature.AcademicsLinks,
  );
}

class AcademicLinksWidget extends GBVResourceDirectoryContentWidget {
  AcademicLinksWidget() : super(
    contentCategory: 'academic_links',
    contentAssetKey: 'assets/extra/academicLinks.json',
    contentFailedMessage: Localization().getStringEx('', 'Failed to load academic links data'),
  );
}

