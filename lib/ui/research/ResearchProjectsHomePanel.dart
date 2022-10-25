import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';

class ResearchProjectsHomePanel extends StatefulWidget {

  final ResearchProjectsContentType? contentType;

  ResearchProjectsHomePanel({Key? key, this.contentType}) : super(key: key);
  
  State<ResearchProjectsHomePanel> createState() => _ResearchProjectsHomePanelState();
}

class _ResearchProjectsHomePanelState extends State<ResearchProjectsHomePanel> implements NotificationsListener {
  
  final Color _dimmedBackgroundColor = Color(0x99000000);

  ResearchProjectsContentType? _selectedContentType;
  bool _contentTypesDropdownExpanded = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
    ]);
    if (widget.contentType != null) {
      _selectedContentType = widget.contentType;
    }
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

 // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {

  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootBackHeaderBar(
        title: Localization().getStringEx('panel.research_projects.home.header_bar.title', 'Research Projects'),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    return Column(children: [
      _buildContentTypeDropdownButton(),
      Expanded(child:
        Stack(children: [
          Column(children: [
            Expanded(child:
              Container(color: Styles().colors?.white,)
            )
          ],),
          _buildContentTypesDropdownContainer()
        ],)
      ),
    ],);
  }

  // Content type dropdown

  Widget _buildContentTypeDropdownButton() {
    return Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
      RibbonButton(
        textColor: Styles().colors?.fillColorSecondary,
        backgroundColor: Styles().colors?.white,
        borderRadius: BorderRadius.all(Radius.circular(5)),
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: (_contentTypesDropdownExpanded ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
        label: _getContentTypeName(_selectedContentType),
        onTap: _onTapContentTypeDropdownButton
      )
    );
  }

  Widget _buildContentTypesDropdownContainer() {
    return Visibility(visible: _contentTypesDropdownExpanded, child:
      Stack(children: [
        GestureDetector(onTap: _onTapContentTypeBackgroundContainer, child:
          Container(color: _dimmedBackgroundColor)),
        _buildContentTypesDropdownList()
    ]));
  }

  Widget _buildContentTypesDropdownList() {
    
    List<Widget> contentList = <Widget>[];
    contentList.add(Container(color: Styles().colors?.fillColorSecondary, height: 2));
    for (ResearchProjectsContentType contentType in ResearchProjectsContentType.values) {
      if ((_selectedContentType != contentType)) {
        contentList.add(_buildContentTypeDropdownItem(contentType));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: contentList)
      )
    );
  }

  Widget _buildContentTypeDropdownItem(ResearchProjectsContentType contentType) {
    return RibbonButton(
        backgroundColor: Styles().colors?.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        label: _getContentTypeName(contentType),
        onTap: () => _onTapContentTypeDropdownItem(contentType));
  }

  void _onTapContentTypeDropdownButton() {
    setState(() {
      _contentTypesDropdownExpanded = !_contentTypesDropdownExpanded;
    });
  }

  void _onTapContentTypeBackgroundContainer() {
    setState(() {
      _contentTypesDropdownExpanded = false;
    });
  }

  void _onTapContentTypeDropdownItem(ResearchProjectsContentType contentType) {
    Analytics().logSelect(target: _getContentTypeName(contentType, languageCode: 'en'));
    setState(() {
      _selectedContentType = contentType;
      _contentTypesDropdownExpanded = false;
    });
  }


  static String _getContentTypeName(ResearchProjectsContentType? contentType, {String? languageCode} )  {
    switch (contentType) {
      case ResearchProjectsContentType.open: return Localization().getStringEx('panel.research_projects.home.content_type.open.title', 'Open Research Projects');
      case ResearchProjectsContentType.my: return Localization().getStringEx('panel.research_projects.home.content_type.my.title', 'My Research Projects');
      default: return '';
    }
  }

}