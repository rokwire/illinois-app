
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/guide/GuideCategoriesPanel.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

import '../widgets/HeaderBar.dart';

class DebugGuideBrowsePanel extends StatefulWidget {
  DebugGuideBrowsePanel();

  _DebugGuideBrowsePanelState createState() => _DebugGuideBrowsePanelState();
}

class _DebugGuideBrowsePanelState extends State<DebugGuideBrowsePanel> {

  LinkedHashSet<String> _guides = LinkedHashSet<String>();
  String? _selectedGuide;

  LinkedHashSet<String> _contentTypes = LinkedHashSet<String>();
  String? _selectedContentType;


  @override
  void initState() {
    List<Map<String, dynamic>>? guideList = Guide().getContentList();
    if (guideList != null) {
      for (Map<String, dynamic> guideEntry in guideList) {
        String? guide = Guide().entryGuide(guideEntry);
        if ((guide != null) && guide.isNotEmpty && !_guides.contains(guide)) {
          _guides.add(guide);
        }
        String? contentType = Guide().entryContentType(guideEntry);
        if ((contentType != null) && contentType.isNotEmpty && !_contentTypes.contains(contentType)) {
          _contentTypes.add(contentType);
        }
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: "Browse Guide", ),
      body: SafeArea(child:
        SingleChildScrollView(child:
          Padding(padding: EdgeInsets.all(16), child:
            Column(children: <Widget>[
              Padding(padding: EdgeInsets.only(bottom: 8), child:
                _buildDropdown(title: 'Guides: ', items: _guides, selectedItem: _selectedGuide, onChanged: _onSelectedGuideChanged),
              ),
              Padding(padding: EdgeInsets.only(bottom: 8), child:
                _buildDropdown(title: 'Content Types: ', items: _contentTypes, selectedItem: _selectedContentType, onChanged: _onSelectedContentTypeChanged),
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 24, horizontal: 64), child:
                _browseButton,
              )
            ],),
          )
        )
      ),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildDropdown({String? title, required Iterable<String> items, String? selectedItem, required void Function(String?) onChanged }) =>
    Row(children: <Widget>[
      Expanded(flex: 1, child:
        Padding(padding: EdgeInsets.only(right: 12), child:
          Event2CreatePanel.buildSectionTitleWidget(title ?? ''),
        ),
      ),
      Expanded(flex: 2, child:
        Container(decoration: Event2CreatePanel.dropdownButtonDecoration, child:
          Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
            DropdownButtonHideUnderline(child:
              DropdownButton<String>(
                dropdownColor: Styles().colors.surface,
                icon: Styles().images.getImage('chevron-down'),
                isExpanded: true,
                style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                value: selectedItem,
                hint: Text(selectedItem ?? '---------',),
                items: _buildDropDownItems(items),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      )
    ],);

  List<DropdownMenuItem<String>> _buildDropDownItems(Iterable<String> items) {
    List<DropdownMenuItem<String>> menuItems = <DropdownMenuItem<String>>[];
    for (String item in items) {
      menuItems.add(DropdownMenuItem<String>(
        value: item,
        child: Text(item),
      ));
    }
    menuItems.add(DropdownMenuItem<String>(
      value: null,
      child: Text('---------'),
    ));

    return menuItems;
  }

  Widget get _browseButton => RoundedButton(
    label: "Browse",
    textColor: Styles().colors.fillColorPrimary,
    borderColor: Styles().colors.fillColorSecondary,
    backgroundColor: Styles().colors.surface,
    fontFamily: Styles().fontFamilies.bold,
    fontSize: 16,
    borderWidth: 2,
    onTap: _onBrowse
  );

  void _onSelectedGuideChanged(String? value) {
    Event2CreatePanel.hideKeyboard(context);
    setState(() {
      _selectedGuide = value;
    });
  }

  void _onSelectedContentTypeChanged(String? value) {
    Event2CreatePanel.hideKeyboard(context);
    setState(() {
      _selectedContentType = value;
    });
  }

  void _onBrowse() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideCategoriesPanel(guide: _selectedGuide, contentType: _selectedContentType,)));
  }

}
