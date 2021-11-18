import 'package:flutter/material.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/guide/GuideCategoriesPanel.dart';

class CampusGuidePanel extends GuideCategoriesPanel {
  CampusGuidePanel({Key key}) : super(key: key, guide: Guide.campusGuide);
}