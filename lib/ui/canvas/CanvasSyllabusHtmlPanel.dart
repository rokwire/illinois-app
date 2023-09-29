/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
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
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSyllabusBody();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.syllabus_html.header.title', 'Syllabus'),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
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
            textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildHtmlContent() {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.all(16),
            child: Html(data: _syllabusBody, onLinkTap: (url, context, element) => _onTapLink(url), style: {
              "body": Style(
                  color: Styles().colors!.fillColorPrimary,
                  fontFamily: Styles().fontFamilies!.bold,
                  fontSize: FontSize(18),
                  padding: EdgeInsets.zero,
                  margin: Margins.zero)
            })));
  }

  void _onTapLink(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri);
        }
      }
    }
  }

  void _loadSyllabusBody() {
    setStateIfMounted(() {
      _loading = true;
    });
    Canvas().loadCourse(widget.courseId, includeInfo: CanvasIncludeInfo.syllabus).then((course) {
      _syllabusBody = course?.syllabusBody;
      setStateIfMounted(() {
      _loading = false;
    });
    });
  }
}
