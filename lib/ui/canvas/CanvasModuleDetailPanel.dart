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
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CanvasModuleDetailPanel extends StatefulWidget {
  final int courseId;
  final CanvasModule module;
  CanvasModuleDetailPanel({required this.courseId, required this.module});

  @override
  _CanvasModuleDetailPanelState createState() => _CanvasModuleDetailPanelState();
}

class _CanvasModuleDetailPanelState extends State<CanvasModuleDetailPanel> {
  List<CanvasModuleItem>? _items;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadModuleItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: StringUtils.ensureNotEmpty(widget.module.name), maxLines: 3,),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingContent();
    }
    if (_items != null) {
      if (_items!.isNotEmpty) {
        return _buildItemsContent();
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
                Localization().getStringEx(
                    'panel.canvas_module_detail.load.failed.error.msg', 'Failed to load module items. Please, try again later.'),
                textAlign: TextAlign.center,
                style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(Localization().getStringEx('panel.canvas_module_detail.empty.msg', 'There are no module items.'),
                textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildItemsContent() {
    if (CollectionUtils.isEmpty(_items)) {
      return Container();
    }

    List<Widget> itemWidgetList = [];
    for (int i = 0; i < _items!.length; i++) {
      CanvasModuleItem item = _items![i];
      itemWidgetList.add(_buildItem(item, isFirst: (i == 0)));
    }

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: itemWidgetList)));
  }

  Widget _buildItem(CanvasModuleItem item, {bool isFirst = false}) {
    double innerPadding = 10;
    BorderSide borderSide = BorderSide(color: Styles().colors!.blackTransparent06!, width: 1);
    return GestureDetector(
        onTap: () => _onTapItem(item),
        child: Container(
            decoration: BoxDecoration(
                color: Styles().colors!.white!,
                border: Border(left: borderSide, top: (isFirst ? borderSide : BorderSide.none), right: borderSide, bottom: borderSide)),
            padding: EdgeInsets.only(
                left: ((item.indent ?? 0) * 20 + innerPadding), top: innerPadding, right: innerPadding, bottom: innerPadding),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                _buildItemImageWidget(item),
                Expanded(
                    child: Text(StringUtils.ensureNotEmpty(item.title),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Styles().textStyles?.getTextStyle("panel.canvas.text.medium.fat")))
              ])
            ])));
  }

  Widget _buildItemImageWidget(CanvasModuleItem item) {
    String? imagePath;
    switch (item.type) {
      case CanvasModuleItemType.page:
        imagePath = 'icon-news.png';
        break;
      case CanvasModuleItemType.external_url:
        imagePath = 'external-link.png';
        break;
      case CanvasModuleItemType.quiz:
        imagePath = 'icon-faqs.png';
        break;
      case CanvasModuleItemType.assignment:
        imagePath = 'icon-schedule.png';
        break;
      default:
        break;
    }

    if (StringUtils.isNotEmpty(imagePath)) {
      return Padding(padding: EdgeInsets.only(right: 20), child: Image.asset('images/$imagePath'));
    } else {
      return Container();
    }
  }

  void _onTapItem(CanvasModuleItem item) {
    Analytics().logSelect(target: 'Canvas Module Item');
    String? url = item.htmlUrl;
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }

  void _loadModuleItems() {
    setStateIfMounted(() {
      _loading = true;
    });
    Canvas().loadModuleItems(courseId: widget.courseId, moduleId: widget.module.id!).then((items) {
      setStateIfMounted(() {
        _items = items;
        _loading = false;
      });
    });
  }
}