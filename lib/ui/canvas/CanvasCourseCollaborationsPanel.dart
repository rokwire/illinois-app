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

import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseCollaborationsPanel extends StatefulWidget {
  final int courseId;
  CanvasCourseCollaborationsPanel({required this.courseId});

  @override
  _CanvasCourseCollaborationsPanelState createState() => _CanvasCourseCollaborationsPanelState();
}

class _CanvasCourseCollaborationsPanelState extends State<CanvasCourseCollaborationsPanel> {
  List<CanvasCollaboration>? _collaborations;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadCollaborations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx('panel.canvas_collaborations.header.title', 'Collaborations')!,
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0)
        )
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
    if (_collaborations != null) {
      if (_collaborations!.isNotEmpty) {
        return _buildCollaborationsContent();
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
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.canvas_collaborations.load.failed.error.msg', 'Failed to load collaborations. Please, try again later.')!,
            textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.canvas_collaborations.empty.msg', 'There are no collaborations for this course.')!,
            textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildCollaborationsContent() {
    if (CollectionUtils.isEmpty(_collaborations)) {
      return Container();
    }

    List<Widget> collaborationWidgetList = [];
    for (CanvasCollaboration collaboration in _collaborations!) {
      collaborationWidgetList.add(_buildCollaborationWidget(collaboration));
    }

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: collaborationWidgetList)));
  }

  Widget _buildCollaborationWidget(CanvasCollaboration collaboration) {
    return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: GestureDetector(
            onTap: () => _onTapCollaboration(collaboration),
            child: Container(
                decoration: BoxDecoration(
                    color: Styles().colors!.white!,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Styles().colors!.lightGray!, width: 1),
                    boxShadow: [
                      BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))
                    ]),
                padding: EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(StringUtils.ensureNotEmpty(collaboration.title),
                        style: TextStyle(fontSize: 18, color: Styles().colors!.fillColorPrimaryVariant)),
                    Text(StringUtils.ensureNotEmpty(collaboration.createdAtDisplayDate),
                        style: TextStyle(fontSize: 14, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface))
                  ]),
                  Visibility(
                      visible: StringUtils.isNotEmpty(collaboration.userName),
                      child: Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(StringUtils.ensureNotEmpty(collaboration.userName),
                              style: TextStyle(
                                  fontSize: 14, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface))))
                ]))));
  }

  void _onTapCollaboration(CanvasCollaboration collaboration) {
    //TBD: implement when we know how to do it.
  }

  void _loadCollaborations() {
    _increaseProgress();
    Canvas().loadCollaborations(widget.courseId).then((collaborations) {
      _collaborations = collaborations;
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
