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
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CanvasSyllabusHtmlPanel extends StatefulWidget {
  final int? courseId;
  CanvasSyllabusHtmlPanel({this.courseId});

  @override
  _CanvasSyllabusHtmlPanelState createState() => _CanvasSyllabusHtmlPanelState();
}

class _CanvasSyllabusHtmlPanelState extends State<CanvasSyllabusHtmlPanel> {
  String? _syllabusBody;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadSyllabusBody();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
          context: context,
          titleWidget: Text(Localization().getStringEx('panel.syllabus_html.header.title', 'Syllabus'),
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
    if (_syllabusBody != null) {
      return _buildHtmlContent();
    } else {
      return _buildErrorContent();
    }
  }

  Widget _buildLoadingContent() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorContent() {
    return Center(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.syllabus_html.load.failed.error.msg', 'Failed to load syllabus content. Please, try again later.'),
            textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildHtmlContent() {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.all(16),
            child: Html(data: _syllabusBody, onLinkTap: (url, context, attributes, element) => _onTapLink(url), style: {
              "body": Style(
                  color: Styles().colors!.fillColorPrimary,
                  fontFamily: Styles().fontFamilies!.bold,
                  fontSize: FontSize(18),
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero)
            })));
  }

  void _onTapLink(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url!);
      }
    }
  }

  void _loadSyllabusBody() {
    _increaseProgress();
    Canvas().loadCourse(widget.courseId, includeInfo: CanvasIncludeInfo.syllabus).then((course) {
      _syllabusBody = course?.syllabusBody;
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
