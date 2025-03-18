
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ui/widgets/LinkButton.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Event2SetupGroups extends StatefulWidget {
  final List<Group> selection;

  Event2SetupGroups({super.key, required this.selection});

  @override
  State<StatefulWidget> createState() => _Event2SetupGroupsState();
}

class _Event2SetupGroupsState extends State<Event2SetupGroups> {
  List<Group>? _groups;
  bool _loadingGroups = false;
  bool _refreshingGroups = false;

  late LinkedHashSet<String> _initialSelectedGroupIds;
  late LinkedHashSet<String> _selectedGroupIds;

  @override
  void initState() {
    _initialSelectedGroupIds = LinkedHashSet.from(widget.selection.map((Group group) => group.id));
    _selectedGroupIds = LinkedHashSet.from(_initialSelectedGroupIds);
    _loadGroups();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx('panel.event2.setup.groups.header.title', 'Select Groups'), actions: _barActions,),
    body: _scaffoldContent,
    backgroundColor: Styles().colors.background,
  );

  Widget get _scaffoldContent =>
    RefreshIndicator(onRefresh: _onRefresh, child:
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child:
        SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
          _panelContent
        )
      )
    );

  Widget get _panelContent {
    if (_loadingGroups) {
      return _loadingContent;
    }
    else if (_groups == null) {
      return _buildMessageContent(Localization().getStringEx('panel.event2.setup.groups.content.failed', 'Failed to load user\'s groups'),);
    }
    else if (_groups?.isEmpty == true) {
      return _buildMessageContent(Localization().getStringEx('panel.event2.setup.groups.content.empty', 'There are no groups user\'s groups'),);
    }
    else {
      return _groupsContent;
    }
  }

  Widget get _groupsContent {
    List<Widget> cardsList = <Widget>[_groupsToolBar];
    for (Group group in _groups!) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        ToggleRibbonButton(
          label: group.title ?? '',
          toggled: _selectedGroupIds.contains(group.id),
          onTap: () => _onGroupToggled(group.id),
          textStyle: Styles().textStyles.getTextStyle('widget.item.light.regular.fat'),
          backgroundColor: Styles().colors.background,
        ),
      ),);
    }
    return Padding(padding: const EdgeInsets.only(bottom: 32), child:
      Column(children:  cardsList,)
    );
  }

  Widget get _groupsToolBar => Row(children: [
    Expanded(child: Align(alignment: Alignment.centerLeft, child: _toolbarButton(title: Localization().getStringEx("headerbar.select.all.title", "Select All"), onTap: _onSelectAll,))),
    Expanded(child: Align(alignment: Alignment.centerRight, child: _toolbarButton(title: Localization().getStringEx("headerbar.deselect.all.title", "Deselect All"), onTap: _onDeselectAll,))),
  ],);

  LinkButton _toolbarButton({String? title, void Function()? onTap}) =>
    LinkButton(
      title: title ?? '',
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12),
      textStyle: Styles().textStyles.getTextStyle('widget.button.title.medium.fat.underline'),
    );

  Widget get _loadingContent => Center(child:
    Padding(padding: EdgeInsets.symmetric(vertical: _screenHeight / 4), child:
     SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
      ),
      )
    );

  Widget _buildMessageContent(String message, { String? title }) => Center(child:
    Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 4), child:
      Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
    ),
  );

  List<Widget>? get _barActions => _canApply ? <Widget>[
    HeaderBarActionTextButton(title:  Localization().getStringEx('dialog.apply.title', 'Apply'), onTap: _onApply),
  ] : null;

  double get _screenHeight => MediaQuery.of(context).size.height;

  void _loadGroups() {
    if (!_loadingGroups && mounted) {
      setState(() {
        _loadingGroups = true;
        _refreshingGroups = false;
      });
      Groups().loadAdminUserGroups().then((List<Group>? result) {
        if (mounted) {
          setState(() {
            _loadingGroups = false;
            _groups = (result != null) ? List.from(result) : null;
          });
        }
      });
    }
  }

  Future<void> _refreshGroups() async {
    if (!_loadingGroups && !_refreshingGroups && mounted) {
      setState(() {
        _refreshingGroups = true;
      });
      List<Group>? result = await Groups().loadAdminUserGroups();
      if (mounted && _refreshingGroups) {
        setState(() {
          _refreshingGroups = false;
          if (result != null) {
            _groups = List.from(result);
          }
        });
      }
    }
  }

  Future<void> _onRefresh() {
    Analytics().logSelect(target: 'Refresh');
    return _refreshGroups();
  }

  void _onGroupToggled(String? groupId) {
    if (groupId != null) {
      setState(() {
        if (_selectedGroupIds.contains(groupId)) {
          _selectedGroupIds.remove(groupId);
        }
        else {
          _selectedGroupIds.add(groupId);
        }
      });
    }
  }

  void _onSelectAll() {
    setState(() {
      _selectedGroupIds = LinkedHashSet.from(_groups?.map((Group group) => group.id) ?? <String>[]);
    });
  }

  void _onDeselectAll() {
    setState(() {
      _selectedGroupIds.clear();
    });
  }

  bool get _canApply => !DeepCollectionEquality().equals(_initialSelectedGroupIds, _selectedGroupIds);

  void _onApply() {

    Map<String, Group> groupsMap = <String, Group>{};
    _groups?.forEach((Group group) {
      groupsMap[group.id ?? ''] = group;
    });

    List<Group> selection = <Group>[];
    for (String groupId in _selectedGroupIds) {
      Group? group = groupsMap[groupId];
      if (group != null) {
        selection.add(group);
      }
    }

    Navigator.of(context).pop(selection);
  }
}