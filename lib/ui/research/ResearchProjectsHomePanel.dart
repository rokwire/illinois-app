import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/groups/GroupCreatePanel.dart';
import 'package:illinois/ui/groups/GroupSearchPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ResearchProjectsHomePanel extends StatefulWidget with AnalyticsInfo {

  final ResearchProjectsContentType? contentType;

  ResearchProjectsHomePanel({Key? key, this.contentType}) : super(key: key);
  
  @override
  AnalyticsFeature? get analyticsFeature => contentType?.analyticsFeature ?? AnalyticsFeature.ResearchProject;

  @override
  State<ResearchProjectsHomePanel> createState() => _ResearchProjectsHomePanelState();
}

enum _FilterType { category, tags }
enum _TagFilter { all, my }

class _ResearchProjectsHomePanelState extends State<ResearchProjectsHomePanel> with NotificationsListener {
  
  static Color _dimmedBackgroundColor = Color(0x99000000);
  static String _allCategories = Localization().getStringEx("panel.groups_home.label.all_categories", "All Categories");
  static ResearchProjectsContentType get _defaultContentType => Auth2().isLoggedIn ? ResearchProjectsContentType.my : ResearchProjectsContentType.open;

  late List<ResearchProjectsContentType> _contentTypes;
  ResearchProjectsContentType? _selectedContentType;
  bool _contentTypesDropdownExpanded = false;

  List<Group>? _researchProjects;
  bool _loadingResearchProjects = false;
  bool _researchProjectsBusy = false;

  List<String> _categories = <String>[ _allCategories ];
  String _selectedCategoryFilter = _allCategories;

  _TagFilter _selectedTagFilter = _TagFilter.all;
  _FilterType? _activeFilterType;

  GestureRecognizer? _loginRecognizer;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupDeleted,
      Auth2.notifyLoginChanged,
    ]);
    _loginRecognizer = TapGestureRecognizer()..onTap = _onTapLogin;
    _contentTypes = _ResearchProjectsContentTypeList.fromContentTypes(ResearchProjectsContentType.values);
    _selectedContentType = widget.contentType?._ensure(availableTypes: _contentTypes) ??
      _defaultContentType._ensure(availableTypes: _contentTypes) ??
      (_contentTypes.isNotEmpty ? _contentTypes.first : null);
    _loadInitialContent();
    _loadFilters();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _loginRecognizer?.dispose();
    super.dispose();
  }

 // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if ((name == Groups.notifyGroupCreated) || (name == Groups.notifyGroupUpdated) || (name == Groups.notifyGroupDeleted)) {
      if (mounted) {
        _updateContent();
      }
    }
    else if (name == Auth2.notifyLoginChanged) {
      if (mounted) {
        _updateContent();
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.research_projects.home.header_bar.title', 'Research Participation'), leading: RootHeaderBarLeading.Back,),
      body: _buildPage(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildPage() {
    return Column(children: [
      _buildContentTypeDropdownButton(),
      Expanded(child:
        Stack(children: [
          Column(children: [
            if ((_selectedContentType != ResearchProjectsContentType.my) || Auth2().isLoggedIn)
              _buildToolBar(),
            Expanded(child: _researchProjectsBusy ?
              _buildLoading() :
              Stack(children: [
                RefreshIndicator(onRefresh: _onPullToRefresh, child:
                  SingleChildScrollView(scrollDirection: Axis.vertical, physics: AlwaysScrollableScrollPhysics(), child:
                    _buildContent()
                  ),
                ),
                _buildFiltersDropdownContainer()
              ],),
            ),
          ],),
          _buildContentTypesDropdownContainer()
        ],)
      ),
    ],);
  }

  // Content Type Dropdown

  Widget _buildContentTypeDropdownButton() {
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8), child:
      RibbonButton(
        textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
        backgroundColor: Styles().colors.white,
        borderRadius: BorderRadius.all(Radius.circular(5)),
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        rightIconKey: _contentTypesDropdownExpanded ? 'chevron-up' : 'chevron-down',
        label: _selectedContentType?.displayTitle ?? '',
        onTap: _onTapContentTypeDropdownButton
      )
    );
  }

  Widget _buildContentTypesDropdownContainer() {
    return Visibility(visible: _contentTypesDropdownExpanded, child:
      Stack(children: [
        GestureDetector(onTap: _onTapContentTypeBackgroundContainer, child:
          Container(color: _dimmedBackgroundColor)),
        Semantics(
          container: true, //Take accessibility access when shown
          child: _dropdownList
        )
    ]));
  }

  Widget get _dropdownList  {
    List<Widget> contentList = <Widget>[];
    contentList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (ResearchProjectsContentType contentType in _contentTypes) {
      if (contentType != _selectedContentType) {
        contentList.add(RibbonButton(
          backgroundColor: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          textStyle: Styles().textStyles.getTextStyle((_selectedContentType == contentType) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
          rightIconKey: (_selectedContentType == contentType) ? 'check-accent' : null,
          label: contentType.displayTitle,
          onTap: () => _onTapContentTypeDropdownItem(contentType)
        ));
      }
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: contentList)
      )
    );
  }

  void _onTapContentTypeDropdownButton() {
    setState(() {
      _contentTypesDropdownExpanded = !_contentTypesDropdownExpanded;
      _activeFilterType = null;
    });
  }

  void _onTapContentTypeBackgroundContainer() {
    setState(() {
      _contentTypesDropdownExpanded = false;
    });
  }

  void _onTapContentTypeDropdownItem(ResearchProjectsContentType contentType) {
    Analytics().logSelect(target: contentType.displayTitleEn);
    if (_selectedContentType != contentType) {
      setState(() {
        _selectedContentType = contentType;
        _contentTypesDropdownExpanded = false;
      });
      _updateContent();
    }
    else {
      setState(() {
        _contentTypesDropdownExpanded = false;
      });
    }
  }


  // ToolBar

  Widget _buildToolBar() {
    String createTitle = Localization().getStringEx("panel.research_projects.home.button.create.title", "Create");
    String searchTitle = Localization().getStringEx("panel.research_projects.home.button.search.title", "Search");
    const double defaultIconPadding = 10;
    const double innerIconPadding = 8;

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Visibility(visible: false /*_selectedContentType == ResearchProjectsContentType.open*/, child:
        FilterSelector(
          padding: EdgeInsets.only(left: 16, top: 12, bottom: 12),
          title: _selectedCategoryFilter,
          active: (_activeFilterType == _FilterType.category),
          onTap: _onTapCategoriesFilter
        ),
      ),
      Visibility(visible: false /*_selectedContentType == ResearchProjectsContentType.open*/, child:
        FilterSelector(
          padding: EdgeInsets.only(left: 8, top: 12, bottom: 12),
          title: _filterTagToDisplayString(_selectedTagFilter),
          active: (_activeFilterType == _FilterType.tags),
          onTap: _onTapTagsFilter
        ),
      ),
      Expanded(child: Container()),
      Visibility(visible: _canCreateResearchProject, child:
        Semantics(label: createTitle, button: true, child:
          IconButton(
            padding: EdgeInsets.only(left: defaultIconPadding, top: defaultIconPadding, bottom: defaultIconPadding, right: innerIconPadding),
            constraints: BoxConstraints(),
            style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            icon: Styles().images.getImage('plus-circle', excludeFromSemantics: true) ?? Container(),
            onPressed: _onTapCreate),
        ),
      ),
      Visibility(visible: true, child:
        Semantics(label: searchTitle, button: true, child:
          IconButton(
            padding: EdgeInsets.only(left: innerIconPadding, top: defaultIconPadding, bottom: defaultIconPadding, right: (defaultIconPadding + innerIconPadding)),
            constraints: BoxConstraints(),
            style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            icon: Styles().images.getImage('search', excludeFromSemantics: true) ?? Container(),
            onPressed: _onTapSearch),
        ),
      ),
    ],);
  }

  static String _filterTagToDisplayString(_TagFilter tagFilter, { String? language }) {
    switch (tagFilter) {
      case _TagFilter.all: return Localization().getStringEx('panel.groups_home.filter.tag.all.label', 'All Tags', language: language);
      case _TagFilter.my: return Localization().getStringEx('panel.groups_home.filter.tag.my.label', 'My Tags', language: language);
    }
  }

  void _onTapCategoriesFilter() {
    Analytics().logSelect(target: "Category Filter");
    setState(() {
      _activeFilterType = (_activeFilterType != _FilterType.category) ? _FilterType.category : null;
    });
  }

  void _onTapTagsFilter() {
    Analytics().logSelect(target: "Tags Filter");
    setState(() {
      _activeFilterType = (_activeFilterType != _FilterType.tags) ? _FilterType.tags : null;
    });
  }

  void _onTapCreate() {
    Analytics().logSelect(target: "Create New Research Project");
    setState(() {
      _contentTypesDropdownExpanded = false;
    });
    Navigator.push(context, MaterialPageRoute(builder: (context) => GroupCreatePanel(group: Group(
      researchProject: true
    ),)));
  }

  void _onTapSearch() {
    Analytics().logSelect(target: "Search Research Projects");
    setState(() {
      _contentTypesDropdownExpanded = false;
    });
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsSearchPanel(researchProject: true,)));
  }

  bool get _canCreateResearchProject {
    return Auth2().isOidcLoggedIn && FlexUI().isSharingAvailable && Auth2().isResearchProjectAdmin;
  }

  // Filters Widget

  Widget _buildFiltersDropdownContainer() {
    return (_activeFilterType != null) ?
      Stack(children: [
        GestureDetector(onTap: _onTapFilterBackgroundContainer, child:
          Container(color: _dimmedBackgroundColor)),
        _buildFiltersDropdownList()
    ]) : Container();
  }

  Widget _buildFiltersDropdownList() {
    List<Widget> filterWidgets = <Widget>[];
    if (_activeFilterType == _FilterType.category) {
      for (String category in _categories) {
        if (filterWidgets.isNotEmpty) {
          filterWidgets.add(Divider(height: 1, color: Styles().colors.fillColorPrimaryTransparent03,));
        }
        filterWidgets.add(FilterListItem(
          title: category,
          selected: _selectedCategoryFilter == category,
          onTap: () => _onTapCategoryFilter(category),
        ));
      }
    }
    else if (_activeFilterType == _FilterType.tags) {
      for (_TagFilter tagFilter in _TagFilter.values) {
        if (filterWidgets.isNotEmpty) {
          filterWidgets.add(Divider(height: 1, color: Styles().colors.fillColorPrimaryTransparent03,));
        }
        filterWidgets.add(FilterListItem(
          title: _filterTagToDisplayString(tagFilter),
          selected: _selectedTagFilter == tagFilter,
          onTap: () => _onTapTagFilter(tagFilter),
        ));
      }
    }

    return Semantics(child:
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 40), child:
        Semantics(child:
          Container(decoration: BoxDecoration(color: Styles().colors.fillColorSecondary, borderRadius: BorderRadius.circular(5.0),), child:
            Padding(padding: EdgeInsets.only(top: 2), child:
              Container(color: Colors.white, child:
                SingleChildScrollView(child:
                  Column(children: filterWidgets,)
                ),
             ),
            ),
          )
        ),
      )
    );
  }

  void _onTapFilterBackgroundContainer() {
    setState(() {
      _activeFilterType = null;
    });
  }

  void _onTapCategoryFilter(String category) {
    Analytics().logSelect(target: "Category Filter: $category");
    if (_selectedCategoryFilter != category) {
      setState(() {
        _selectedCategoryFilter = category;
      });
      _updateContent();
    }
    setState(() {
      _activeFilterType = null;
    });
  }

  void _onTapTagFilter(_TagFilter tagFilter) {
    String tagFilterName = _filterTagToDisplayString(tagFilter, language: 'en');
    Analytics().logSelect(target: "Category Filter: $tagFilterName");

    if (_selectedTagFilter != tagFilter) {
      setState(() {
        _selectedTagFilter = tagFilter;
      });
      _updateContent();
    }
    setState(() {
      _activeFilterType = null;
    });
  }

  // Content Widget

  Widget _buildContent() {
    if ((_selectedContentType == ResearchProjectsContentType.my) && !Auth2().isLoggedIn) {
      return _buildLoggedOutContent();
    }
    else if (_researchProjects == null) {
      return _buildStatus(_errorDisplayStatus);
    }
    else if (_researchProjects!.isEmpty) {
      return _buildStatus(_emptyDisplayStatus);
    }
    else {
      return _buildResearchProjects();
    }
  }

  Widget _buildResearchProjects() {
    List<Widget> widgets = [];
    GroupCardDisplayType cardDisplayType = (_selectedContentType == ResearchProjectsContentType.my) ? GroupCardDisplayType.myGroup : GroupCardDisplayType.allGroups;
    if (CollectionUtils.isNotEmpty(_researchProjects)) {
      for (Group researchProject in _researchProjects!) {
        if (researchProject.isVisible) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: GroupCard(
              group: researchProject,
              displayType: cardDisplayType,
              onImageTap: () => _onTapImage(researchProject)
            ,),
          ));
        }
      }
      widgets.add(Container(height: 8,));
    }
    return Column(children: widgets,);
  }

  Widget _buildLoading() {
    return Align(alignment: Alignment.center, child:
      CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3, ),
    );
  }

  Widget _buildStatus(String status) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Padding(padding: EdgeInsets.only(left: 32, right: 32, top: screenHeight / 5), child:
        Row(children: [
          Expanded(child:
            Text(status ,style:
              Styles().textStyles.getTextStyle("widget.message.large"), textAlign: TextAlign.center,),
          ),
        ],)
    );
  }

  String get _errorDisplayStatus {
    switch(_selectedContentType) {
      case ResearchProjectsContentType.open: return Localization().getStringEx('panel.research_projects.home.status.error.open.text', 'Failed to load open research projects.');
      case ResearchProjectsContentType.my: return Localization().getStringEx('panel.research_projects.home.status.error.my.text', 'Failed to load your research projects.');
      default: return '';
    }
  }

  String get _emptyDisplayStatus {
    switch(_selectedContentType) {
      case ResearchProjectsContentType.open: return Localization().getStringEx('panel.research_projects.home.status.empty.open.text', 'There are no opened research projects at the moment.');
      case ResearchProjectsContentType.my: return Localization().getStringEx('panel.research_projects.home.status.empty.my.text', 'You have not created and do not participate in any research projects.');
      default: return '';
    }
  }

  void _onTapImage(Group? group){
    Analytics().logSelect(target: "Image");
    if (group?.imageURL != null) {
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalPhotoImagePanel(imageUrl: group!.imageURL!, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image"))));
    }
  }

  // Content Data

  Widget _buildLoggedOutContent() {
    final String linkLoginMacro = "{{link.login}}";
    String messageTemplate = Localization().getStringEx("panel.research_projects.home.status.my_projects.logged_out", "You are not logged in. To access your research projects, $linkLoginMacro with your NetID and set your privacy level to 4 or 5 under Settings.");
    List<String> messages = messageTemplate.split(linkLoginMacro);
    List<InlineSpan> spanList = <InlineSpan>[];
    if (0 < messages.length)
      spanList.add(TextSpan(text: messages.first));
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(text: Localization().getStringEx("panel.research_projects.home.status.my_projects.logged_out.link.login", "sign in"), style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
        recognizer: _loginRecognizer, ));
      spanList.add(TextSpan(text: messages[index]));
    }

    return Container(padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), children: spanList)
      )
    );
  }

  void _onTapLogin() {
    Analytics().logSelect(target: "sign in");
    ProfileHomePanel.present(context, contentType: ProfileContentType.login,);
  }

  // Content Data

  void _loadInitialContent() {
    ResearchProjectsContentType contentType = _selectedContentType ?? ResearchProjectsContentType.my;
    if ((_loadingResearchProjects == false) && ((contentType != ResearchProjectsContentType.my) || Auth2().isLoggedIn)) {
      _loadingResearchProjects = _researchProjectsBusy = true;
      
      Groups().loadResearchProjects(contentType: contentType).then((List<Group>? researchProjects) {
        if ((_selectedContentType == null) && (researchProjects != null) && (researchProjects.length == 0)) {
          contentType = ResearchProjectsContentType.open;
          Groups().loadResearchProjects(contentType: contentType).then((List<Group>? researchProjects) {
            if (mounted) {
              setState(() {
                _loadingResearchProjects = _researchProjectsBusy = false;
                _selectedContentType = contentType;
                _researchProjects = researchProjects;
              });
            }
          });
        }
        else if (mounted) {
          setState(() {
            _loadingResearchProjects = _researchProjectsBusy = false;
            _selectedContentType = contentType;
            _researchProjects = researchProjects;
          });
        }
      });

    }
  }

  void _updateContent() {
    if (_loadingResearchProjects == false) {
      setState(() {
        _loadingResearchProjects = _researchProjectsBusy = true;
      });

      Groups().loadResearchProjects(
        contentType: _selectedContentType,
        category: ((_selectedContentType == ResearchProjectsContentType.open) && (_selectedCategoryFilter != _allCategories)) ? _selectedCategoryFilter : null,
        tags: ((_selectedContentType == ResearchProjectsContentType.open) && (_selectedTagFilter == _TagFilter.my)) ? Auth2().prefs?.positiveTags : null,
      ).then((List<Group>? researchProjects) {
        if (mounted) {
          setState(() {
            _loadingResearchProjects = _researchProjectsBusy = false;
            _researchProjects = researchProjects;
          });
        }
      });
    }
  }

  Future<void> _onPullToRefresh() async {
    if (_loadingResearchProjects == false) {

      _loadingResearchProjects = true;
      List<Group>? researchProjects = await Groups().loadResearchProjects(
        contentType: _selectedContentType,
        category: ((_selectedContentType == ResearchProjectsContentType.open) && (_selectedCategoryFilter != _allCategories)) ? _selectedCategoryFilter : null,
        tags: ((_selectedContentType == ResearchProjectsContentType.open) && (_selectedTagFilter == _TagFilter.my)) ? Auth2().prefs?.positiveTags : null,
      );
      _loadingResearchProjects = false;

      if ((researchProjects != null) && mounted) {
        setState(() {
          _researchProjects = researchProjects;
        });
      }
    }
  }

  // Filters

  void _loadFilters() {
    Groups().loadCategories().then((List<String>? groupsCategories) {
      if (mounted) {
        setState(() {
          if (groupsCategories != null) {
            _categories.addAll(groupsCategories);
          }
        });

      }
    });
  }
}

// ResearchProjectsContentType

extension ResearchProjectsContentTypeImpl on ResearchProjectsContentType {
  String get displayTitle => displayTitleLng();
  String get displayTitleEn => displayTitleLng('en');

  String displayTitleLng([ String? language ]) {
    switch (this) {
      case ResearchProjectsContentType.open: return Localization().getStringEx('panel.research_projects.home.content_type.open.title', 'Open Research Projects', language: language);
      case ResearchProjectsContentType.my: return Localization().getStringEx('panel.research_projects.home.content_type.my.title', 'My Research Projects', language: language);
    }
  }

  String get jsonString {
    switch (this) {
      case ResearchProjectsContentType.open: return 'open';
      case ResearchProjectsContentType.my: return 'my';
    }
  }

  static ResearchProjectsContentType? fromJsonString(String? value) {
    switch(value) {
      case 'open': return ResearchProjectsContentType.open;
      case 'my': return ResearchProjectsContentType.my;
      default: return null;
    }
  }

  AnalyticsFeature? get analyticsFeature {
    switch (this) {
      case ResearchProjectsContentType.my:   return AnalyticsFeature.ResearchProjectMy;
      case ResearchProjectsContentType.open: return AnalyticsFeature.ResearchProjectOpen;
    }
  }

  ResearchProjectsContentType? _ensure({List<ResearchProjectsContentType>? availableTypes}) =>
      (availableTypes?.contains(this) != false) ? this : null;
}

extension _ResearchProjectsContentTypeList on List<ResearchProjectsContentType> {
  void sortAlphabetical() => sort((ResearchProjectsContentType t1, ResearchProjectsContentType t2) => t1.displayTitle.compareTo(t2.displayTitle));

  static List<ResearchProjectsContentType> fromContentTypes(Iterable<ResearchProjectsContentType> contentTypes) {
    List<ResearchProjectsContentType> contentTypesList = List<ResearchProjectsContentType>.from(contentTypes);
    contentTypesList.sortAlphabetical();
    return contentTypesList;
  }
}
