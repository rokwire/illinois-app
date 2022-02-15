/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/canvas/CanvasModuleDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseModulesPanel extends StatefulWidget {
  final int courseId;
  CanvasCourseModulesPanel({required this.courseId});

  @override
  _CanvasCourseModulesPanelState createState() => _CanvasCourseModulesPanelState();
}

class _CanvasCourseModulesPanelState extends State<CanvasCourseModulesPanel> {
  List<CanvasModule>? _modules;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.canvas_modules.header.title', 'Modules'),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingContent();
    }
    if (_modules != null) {
      if (_modules!.isNotEmpty) {
        return _buildModulesContent();
      } else {
        return _buildEmptyContent();
      }
    } else {
      return _buildErrorContent();
    }
  }

  Widget _buildLoadingContent() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(
                Localization()
                    .getStringEx('panel.canvas_modules.load.failed.error.msg', 'Failed to load modules. Please, try again later.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(Localization().getStringEx('panel.canvas_modules.empty.msg', 'There are no modules for this course.'),
                textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildModulesContent() {
    if (CollectionUtils.isEmpty(_modules)) {
      return Container();
    }

    List<Widget> moduleWidgetList = [];
    for (CanvasModule module in _modules!) {
      moduleWidgetList.add(_buildModuleItem(module));
    }

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: moduleWidgetList)));
  }

  Widget _buildModuleItem(CanvasModule module) {
    return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: GestureDetector(
            onTap: () => _onTapModule(module),
            child: Container(
                decoration: BoxDecoration(
                    color: Styles().colors!.backgroundVariant!, border: Border.all(color: Styles().colors!.blackTransparent06!, width: 1)),
                padding: EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        child: Text(StringUtils.ensureNotEmpty(module.name),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 18, color: Styles().colors!.fillColorPrimaryVariant)))
                  ])
                ]))));
  }

  void _onTapModule(CanvasModule module) {
    Analytics().logSelect(target: 'Canvas Module');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasModuleDetailPanel(courseId: widget.courseId, module: module)));
  }

  void _loadModules() {
    _increaseProgress();
    Canvas().loadModules(widget.courseId).then((modules) {
      _modules = modules;
      _decreaseProgress();
    });
  }

  void _increaseProgress() {
    _loadingProgress++;
    if (mounted) {
      setState(() {});
    }
  }

  void _decreaseProgress() {
    _loadingProgress--;
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isLoading {
    return (_loadingProgress > 0);
  }
}
