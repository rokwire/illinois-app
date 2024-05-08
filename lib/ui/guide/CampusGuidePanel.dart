import 'package:flutter/material.dart';
import 'package:neom/service/Guide.dart';
import 'package:neom/ui/guide/GuideCategoriesPanel.dart';

class CampusGuidePanel extends GuideCategoriesPanel {
  CampusGuidePanel({Key? key}) : super(key: key, guide: Guide.campusGuide);
}