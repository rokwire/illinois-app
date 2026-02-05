// Copyright 2024 Board of Trustees of the University of Illinois.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AssistantFaqsContentWidget extends StatefulWidget {
  final Map<String, dynamic>? pageContext;

  AssistantFaqsContentWidget({super.key, this.pageContext});

  @override
  State<AssistantFaqsContentWidget> createState() => _AssistantFaqsContentWidgetState();
}

class _AssistantFaqsContentWidgetState extends State<AssistantFaqsContentWidget> {
  
  static const String _faqsContextKey = 'faqs';
  Map<String, dynamic>? _faqs;
  bool _loadingFaqs = false;

  @override
  void initState() {
    super.initState();
    
    _faqs = JsonUtils.mapValue(widget.pageContext?[_faqsContextKey]);
    if (_faqs == null) {
      _loadingFaqs = true;
      Content().loadContentItem('assistant_faqs').then((dynamic contentItem){
        setStateIfMounted((){
          _loadingFaqs = false;
          widget.pageContext?[_faqsContextKey] = (_faqs = JsonUtils.mapValue(contentItem));
        });
      });
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    Positioned.fill(child:
      Padding(padding: EdgeInsets.all(20), child:
        SafeArea(child:
          _pageCongent
        )
      )
    );
  
  Widget get _pageCongent {
    if (_loadingFaqs) {
      return _loadingContent;
    }
    else if (_faqsText?.isNotEmpty != true) {
      return _emptyContent;
    }
    else {
      return _faqsContent;
    }
  }
  
  Widget get _loadingContent =>
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
      )
    );
  
  Widget get _emptyContent =>
    Center(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 48, vertical: 64), child:
        Row(children: [
          Expanded(child:
            Text(Localization().getStringEx('panel.assistant.faqs.missing.msg', 'No FAQs available.'), style: Styles().textStyles.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)
          )
        ],),
      )
    );

  Widget get _faqsContent =>
    SingleChildScrollView(child:
      HtmlWidget(_faqsText ?? '',
        onTapUrl: (url) {
          _launchUrl(url);
          return true;
        },
        textStyle: Styles().textStyles.getTextStyle('widget.detail.regular'),
        customStylesBuilder: (element) {
          if (element.localName == "h3") {
            String fontFamilyName = Styles().textStyles.getTextStyle('widget.detail.regular.fat')?.fontFamily.toString() ?? '';
            String fontSize = Styles().textStyles.getTextStyle('widget.detail.regular.fat')?.fontSize.toString() ?? '0';
            return {'font-size': '${fontSize}px', 'font-family': fontFamilyName};
          } else {
            return null;
          }
        }
      )
    );
      
  String? get _faqsText => _faqsTextFromSource(_faqs);

  static String? _faqsTextFromSource(Map<String, dynamic>? faqsSource) => (faqsSource != null) ? (
    JsonUtils.stringValue(faqsSource[Localization().currentLocale?.languageCode]) ??
    JsonUtils.stringValue(faqsSource[Localization().defaultLocale?.languageCode ?? 'en'])
  )  : null;

  void _launchUrl(String? url) async {
    Analytics().logSelect(target: 'Assistant FAQs: Open Link');
    if (StringUtils.isNotEmpty(url)) {
      if (StringUtils.isNotEmpty(url)) {
        Uri? uri = Uri.tryParse(url!);
        if ((uri != null) && (await canLaunchUrl(uri))) {
          launchUrl(uri, mode: LaunchMode.externalApplication).catchError((e) { debugPrint(e.toString()); return false; });
        }
      }
    }
  }

}
