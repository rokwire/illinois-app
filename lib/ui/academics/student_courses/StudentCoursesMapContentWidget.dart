/*
 * Copyright 2026 Board of Trustees of the University of Illinois.
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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/map2/Map2BasePanel.dart';
import 'package:illinois/ui/map2/Map2TraySheet.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

// Map view content for StudentCoursesHomePanel: shows the buildings of the courses passed in
// (already loaded by the host, so this widget does not fetch its own data) as map markers, with a
// bottom tray listing all courses by default (narrowing to a tapped marker/group's courses, like the
// main Map tab's Map2HomePanel behaves), reusing Map2TraySheet (which already renders
// StudentCourseCard for StudentCourse explores). Modeled on Map2HomePanel/Map2LocationPanel's
// `StudentCourses` case, but trimmed down: no building-search button, no pin-drop/"select location"
// workflow, and no own HeaderBar/Scaffold (the host panel already provides those).
class StudentCoursesMapContentWidget extends StatefulWidget {
  final List<StudentCourse>? courses;
  final AnalyticsFeature? analyticsFeature;

  StudentCoursesMapContentWidget({super.key, this.courses, this.analyticsFeature});

  @override
  State<StudentCoursesMapContentWidget> createState() => _StudentCoursesMapContentWidgetState();
}

class _StudentCoursesMapContentWidgetState extends Map2BasePanelState<StudentCoursesMapContentWidget> {

  final GlobalKey _contentKey = GlobalKey();
  final DraggableScrollableController _traySheetController = DraggableScrollableController();

  Set<Explore>? _selectedExploreGroup;
  List<Explore>? _trayExplores;

  @override
  void initState() {
    super.initState();
    _trayExplores = _buildTrayExplores();
    WidgetsBinding.instance.addPostFrameCallback((_) => buildMapContentData(_explores, updateCamera: true));
  }

  @override
  void didUpdateWidget(StudentCoursesMapContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DeepCollectionEquality().equals(widget.courses, oldWidget.courses)) {
      _selectedExploreGroup = null;
      buildMapContentData(_explores, updateCamera: true, showProgress: true);
      _updateTrayExplores();
    }
  }

  @override
  void dispose() {
    _traySheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(key: _contentKey, children: <Widget>[
    Positioned.fill(child: mapView),
    Positioned.fill(child: Visibility(visible: (_trayExplores?.isNotEmpty == true), child: _traySheet)),
    if (markersProgress)
      Positioned.fill(child: Center(child: _mapProgressIndicator)),
  ]);

  Widget get _mapProgressIndicator => Semantics(
    label: Localization().getStringEx('panel.explore.state.loading.title', 'Loading'),
    hint: Localization().getStringEx('panel.explore.state.loading.hint', 'Please wait'),
    excludeSemantics: true, child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3),
      ),
  );

  // Tray Sheet (shows all courses by default; narrows to a marker/group's courses once tapped)

  static const List<double> _traySnapSizes = <double>[0.03, 0.35, 0.97];
  static const Duration _trayAnimationDuration = Duration(milliseconds: 200);
  static const Curve _trayAnimationCurve = Curves.easeInOut;

  Widget get _traySheet => DraggableScrollableSheet(
    controller: _traySheetController,
    snap: true, snapSizes: _traySnapSizes,
    initialChildSize: _traySnapSizes[1],
    minChildSize: _traySnapSizes.first,
    maxChildSize: _traySnapSizes.last,
    builder: (BuildContext context, ScrollController scrollController) => Map2TraySheet(
      explores: _trayExplores,
      scrollController: scrollController,
      totalCount: _trayTotalCount,
      analyticsFeature: widget.analyticsFeature,
    ),
  );

  // Defaults to showing all explores (like Map2HomePanel does for content types that are always
  // implicitly "filtered" by term selection); narrows down to just the tapped marker/group once one
  // is selected.
  List<Explore>? _sortExplores(Iterable<Explore>? explores) => (explores != null) ?
    (List<Explore>.from(explores)..sort((Explore e1, Explore e2) => (e1.exploreTitle ?? '').compareTo(e2.exploreTitle ?? ''))) :
    null;

  List<Explore>? _buildTrayExplores() => _sortExplores(_selectedExploreGroup ?? _explores);

  int? get _trayTotalCount => (_selectedExploreGroup != null) ? _explores?.length : null;

  void _updateTrayExplores() {
    List<Explore>? trayExplores = _buildTrayExplores();
    if (mounted && !DeepCollectionEquality().equals(_trayExplores, trayExplores)) {
      bool hadTray = _trayExplores?.isNotEmpty == true;
      bool haveTray = trayExplores?.isNotEmpty == true;
      if (haveTray == hadTray) {
        setState(() {
          _trayExplores = trayExplores;
        });
      }
      else if (haveTray) {
        setState(() {
          _trayExplores = trayExplores;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_traySheetController.isAttached) {
            _traySheetController.animateTo(_traySnapSizes[1], duration: _trayAnimationDuration, curve: _trayAnimationCurve);
          }
        });
      }
      else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_traySheetController.isAttached) {
            _traySheetController.animateTo(_traySnapSizes.first, duration: _trayAnimationDuration, curve: _trayAnimationCurve).then((_) {
              setStateIfMounted(() {
                _trayExplores = trayExplores;
              });
            });
          }
        });
      }
    }
  }

  // Map Overrides

  // Courses without a valid building/location (e.g. online sections) are naturally excluded here.
  List<Explore>? get _explores => widget.courses?.validList;

  @override
  List<Explore>? get mapExplores => _explores;

  @override
  Size? get mapSize => _contentKey.renderBoxSize;

  @override
  bool isExploreGroupMarkerDisabled(Set<Explore> exploreGroup) =>
    (_selectedExploreGroup != null) && (_selectedExploreGroup?.intersection(exploreGroup).isNotEmpty != true);

  @override
  bool isExploreMarkerDisabled(Explore explore) =>
    (_selectedExploreGroup != null) && (_selectedExploreGroup?.contains(explore) != true);

  // Map Events

  @override
  void onTapMap(LatLng coordinate) {
    Analytics().logSelect(target: "Map Location: { ${coordinate.latitude.toStringAsFixed(6)}, ${coordinate.longitude.toStringAsFixed(6)} }");
    _clearSelection();
  }

  @override
  void onTapMapPoi(PointOfInterest poi) {
    Analytics().logSelect(target: "Map POI: ${poi.name}");
    _clearSelection();
  }

  @override
  void onTapMarker(dynamic origin) {
    if (origin is Explore) {
      // A single (non-grouped) marker: like Map2HomePanel, this opens the course detail directly
      // instead of "selecting" it, and clears any active group selection so the tray falls back to
      // showing all courses again.
      Analytics().logSelect(target: "Map Marker: ${origin.exploreTitle}");
      if (_selectedExploreGroup != null) {
        setState(() {
          _selectedExploreGroup = null;
        });
        updateMapMarkers();
        _updateTrayExplores();
      }
      origin.exploreLaunchDetail(context, analyticsFeature: widget.analyticsFeature);
    }
    else if (origin is Set<Explore>) {
      Analytics().logSelect(target: "Map Marker: { ${origin.length} items }");
      setState(() {
        _selectedExploreGroup = DeepCollectionEquality().equals(_selectedExploreGroup, origin) ? null : origin;
      });
      updateMapMarkers();
      _updateTrayExplores();
    }
  }

  void _clearSelection() {
    if (_selectedExploreGroup != null) {
      setState(() {
        _selectedExploreGroup = null;
      });
      updateMapMarkers();
      _updateTrayExplores();
    }
  }
}
