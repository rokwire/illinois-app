import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/guide/GuideCategoriesPanel.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';

class CampusGuidePanel extends GuideCategoriesPanel {
  CampusGuidePanel({super.key}) : super(
    guide: Guide.campusGuide,
    title: Localization().getStringEx('panel.campus_guide.label.heading', 'Campus Guide'),
    emptyDescriptin: Localization().getStringEx('panel.campus_guide.label.content.empty', 'Empty resources content')
  );
}

class CampusHighlightsPanel extends GuideListPanel {
  CampusHighlightsPanel({List<Map<String, dynamic>>? contentList}) : super(
    contentList: contentList ?? Guide().promotedList,
    contentTitle: Localization().getStringEx('panel.guide_list.label.highlights.section', 'Featured Resources'),
    contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.highlights.empty", "There are currently no featured resources."),
    favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusHighlightContentType),
    analyticsFeature: AnalyticsFeature.Guide,
  );
}

class CampusSafetyResourcesPanel extends GuideListPanel {
  CampusSafetyResourcesPanel({ List<Map<String, dynamic>>? contentList, String? contentTitle, String? contentEmptyMessage }) : super(
    contentList: contentList ?? Guide().safetyResourcesList,
    contentTitle: contentTitle ?? Localization().getStringEx('panel.guide_list.label.safety_resources.section', 'Safety Resources'),
    contentEmptyMessage: contentEmptyMessage ?? Localization().getStringEx("panel.guide_list.label.safety_resources.empty", "There are no active Campus Safety Resources."),
    favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusSafetyResourceContentType),
    analyticsFeature: AnalyticsFeature.Guide,
  );
}

class CampusRemindersPanel extends GuideListPanel {
  CampusRemindersPanel({ List<Map<String, dynamic>>? contentList, String? contentTitle, String? contentEmptyMessage }) : super(
    contentList: contentList ?? Guide().remindersList,
    contentTitle: contentTitle ?? Localization().getStringEx('panel.guide_list.label.campus_reminders.section', 'Campus Reminders'),
    contentEmptyMessage: contentEmptyMessage ?? Localization().getStringEx("panel.guide_list.label.campus_reminders.empty", "There are no active Campus Reminders."),
    analyticsFeature: AnalyticsFeature.AcademicsCampusReminders,
  );
}
