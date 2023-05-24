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
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CanvasFileSystemEntitiesListPanel extends StatefulWidget {
  final int? courseId;
  final int? folderId;
  CanvasFileSystemEntitiesListPanel({this.courseId, this.folderId});

  @override
  _CanvasFileSystemEntitiesListPanelState createState() => _CanvasFileSystemEntitiesListPanelState();
}

class _CanvasFileSystemEntitiesListPanelState extends State<CanvasFileSystemEntitiesListPanel> {
  List<CanvasFileSystemEntity>? _fsEntities;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadEntities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.canvas_files.header.title', 'Files'),
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
    if (_fsEntities != null) {
      if (_fsEntities!.isNotEmpty) {
        return _buildFileSystemEntitiesContent();
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
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.canvas_files.load.failed.error.msg', 'Failed to load files and folders. Please, try again later.'),
            textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.canvas_files.empty.msg', 'There are no files and folders.'),
            textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildFileSystemEntitiesContent() {
    if (CollectionUtils.isEmpty(_fsEntities)) {
      return Container();
    }

    List<Widget> entityWidgetList = [];
    for (CanvasFileSystemEntity fileSystemEntity in _fsEntities!) {
      entityWidgetList.add(_buildFileSystemEntityWidget(fileSystemEntity));
    }

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: entityWidgetList)));
  }

  Widget _buildFileSystemEntityWidget(CanvasFileSystemEntity entity) {
    return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: GestureDetector(
            onTap: () => _onTapFsEntity(entity),
            child: Container(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Image.asset('images/${entity.isFile ? 'icon-news.png' : 'campus-tools.png'}')),
              Expanded(
                  child: Text(StringUtils.ensureNotEmpty(entity.entityName),
                      maxLines: 3,
                      style: Styles().textStyles?.getTextStyle("widget.title.medium.semi_fat"))),
            ]))));
  }

  void _onTapFsEntity(CanvasFileSystemEntity entity) {
    bool isFile = entity.isFile;
    Analytics().logSelect(target: "Canvas Files -> ${isFile ? 'File' : 'Folder'}");
    if (isFile) {
      String? url = (entity as CanvasFile).url;
      if (StringUtils.isNotEmpty(url)) {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasFileSystemEntitiesListPanel(folderId: entity.entityId)));
    }
  }

  void _loadEntities() {
    setStateIfMounted(() {
      _loading = true;
    });
    Canvas().loadFileSystemEntities(courseId: widget.courseId, folderId: widget.folderId).then((fsEntities) {
      setStateIfMounted(() {
        _fsEntities = fsEntities;
        _loading = false;
      });
    });
  }
}