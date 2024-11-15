
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/model/Directory.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Directory.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileDirectoryConnectionsPage extends StatefulWidget {
  final DirectoryConnections contentType;
  ProfileDirectoryConnectionsPage({super.key, required this.contentType});

  @override
  State<StatefulWidget> createState() => _ProfileDirectoryConnectionsPageState();
}

class _ProfileDirectoryConnectionsPageState extends State<ProfileDirectoryConnectionsPage>  {

  bool _loading = false;
  Map<String, List<DirectoryMember>>? _members;
  String? _expandedMemberId;


  @override
  void initState() {
    _loading = true;
    Directory().loadMembers().then((List<DirectoryMember>? members){
      setStateIfMounted(() {
        _loading = false;
        _members = (members != null) ? _buildMembers(members) : null;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _loadingContent;
    }
    else if (_members == null) {
      return _messageContent(_failedText);
    }
    else if (_members?.isEmpty == true) {
      return _messageContent(_emptyText);
    }
    else {
      return _membersContent;
    }
  }

  Widget get _membersContent {
    List<Widget> sections = <Widget>[];
    int? firstCharCode, lastCharCode;
    _members?.forEach((key, value){
      int charCode = key.codeUnits.first;
      if ((firstCharCode == null) || (charCode < firstCharCode!)) {
        firstCharCode = charCode;
      }
      if ((lastCharCode == null) || (lastCharCode! < charCode)) {
        lastCharCode = charCode;
      }
    });
    if ((firstCharCode != null) && (lastCharCode != null)) {
      for (int charCode = firstCharCode!; charCode <= lastCharCode!; charCode++) {
        String dirEntry = String.fromCharCode(charCode);
        List<DirectoryMember>? members = _members?[dirEntry];
        if (members != null) {
          sections.addAll(_membersSection(dirEntry, members));
        }
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections);
  }

  List<Widget> _membersSection(String dirEntry, List<DirectoryMember> members) {
    List<Widget> result = <Widget>[
      _sectionHeading(dirEntry)
    ];
    for (DirectoryMember member in members) {
      result.add(_sectionSplitter);
      result.add(DirectoryConnectionMemberCard(member, expanded: (_expandedMemberId != null) && (member.id == _expandedMemberId), onToggleExpanded: () => _onToggleMemberExpanded(member),));
    }
    if (members.isNotEmpty) {
      result.add(Padding(padding: EdgeInsets.only(bottom: 16), child: _sectionSplitter));
    }
    return result;
  }

  void _onToggleMemberExpanded(DirectoryMember member) {
    Analytics().logSelect(target: 'Expand', source: member.id);
    setState(() {
      _expandedMemberId = (_expandedMemberId != member.id) ? member.id : null;
    });
  }

  Widget _sectionHeading(String dirEntry) =>
    Padding(padding: EdgeInsets.zero, child:
      Text(dirEntry, style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'),)
    );

  Widget get _sectionSplitter => Container(height: 1, color: Styles().colors.dividerLineAccent,);

  Widget get _loadingContent => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64,), child:
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
      )
    )
  );

  Widget _messageContent(String message) => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64,), child:
    Center(child:
      Text(message, style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), textAlign: TextAlign.center,)
    )
  );

  String get _emptyText {
    switch (widget.contentType) {
      case DirectoryConnections.myConnections: return AppTextUtils.appTitleString('panel.profile.directory.connections.connections.empty.text', 'You do not have any ${AppTextUtils.appTitleMacro} Connections. Your connections will appear after you swap info with another ${AppTextUtils.universityLongNameMacro} student or employee.').replaceAll(AppTextUtils.universityLongNameMacro, AppTextUtils.universityLongName);
      case DirectoryConnections.appDirectory: return AppTextUtils.appTitleString('panel.profile.directory.connections.directory.empty.text', 'The ${AppTextUtils.appTitleMacro} App Directory is empty.');
    }
  }

  String get _failedText {
    switch (widget.contentType) {
      case DirectoryConnections.myConnections: return AppTextUtils.appTitleString('panel.profile.directory.connections.connections.failed.text', 'Failed to load ${AppTextUtils.appTitleMacro} Connections content.');
      case DirectoryConnections.appDirectory: return AppTextUtils.appTitleString('panel.profile.directory.connections.directory.failed.text', 'Failed to load ${AppTextUtils.appTitleMacro} App Directory content.');
    }
  }

  Map<String, List<DirectoryMember>> _buildMembers(List<DirectoryMember> members) {
    Map<String, List<DirectoryMember>> result = <String, List<DirectoryMember>>{};
    for (DirectoryMember member in members) {
      String mapKey = ((member.lastName?.isNotEmpty == true) ? member.lastName?.substring(0, 1).toUpperCase() : null) ?? ' ';
      List<DirectoryMember> mapValue = (result[mapKey] ??= <DirectoryMember>[]);
      mapValue.add(member);
    }
    for (List<DirectoryMember> mapValue in result.values) {
      mapValue.sort((DirectoryMember member1, DirectoryMember member2) {
        int result = SortUtils.compare(member1.lastName?.toUpperCase(), member2.lastName?.toUpperCase());
        if (result == 0) {
          result = SortUtils.compare(member1.firstName?.toUpperCase(), member2.firstName?.toUpperCase());
        }
        if (result == 0) {
          result = SortUtils.compare(member1.middleName?.toUpperCase(), member2.middleName?.toUpperCase());
        }
        return result;
      });
    }
    return result;
  }

}

class DirectoryConnectionMemberCard extends StatefulWidget {
  final DirectoryMember member;
  final bool expanded;
  final void Function()? onToggleExpanded;
  DirectoryConnectionMemberCard(this.member, { super.key, this.expanded = false, this.onToggleExpanded });

  @override
  State<StatefulWidget> createState() => _DirectoryConnectionMemberCardState();
}

class _DirectoryConnectionMemberCardState extends State<DirectoryConnectionMemberCard> {
  @override
  Widget build(BuildContext context) =>
    widget.expanded ? _expandedContent : _collapsedContent;

  Widget get _expandedContent => Column(children: [
    _expandedHeading,
    _expandedBody,
  ],);

  Widget get _expandedHeading =>
    InkWell(onTap: widget.onToggleExpanded, child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child:
          Padding(padding: EdgeInsets.only(top: 16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(_nameString, style: Styles().textStyles.getTextStyleEx('widget.title.large.fat', fontHeight: 0.85)),
                if (widget.member.pronoun?.isNotEmpty == true)
                  Text(widget.member.pronoun ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small')),
              ],)
          ),
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12), child:
          Styles().images.getImage('chevron2-up',)
        ),
      ],),
    );

  Widget get _expandedBody =>
    Padding(padding: EdgeInsets.only(bottom: 16), child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child:
          Padding(padding: EdgeInsets.only(top: 12), child:
            _expandedDetails
          ),
        ),
        Expanded(child:
          Padding(padding: EdgeInsets.only(top: 0), child:
            _expandedPhotoImage
          ),
        ),
        //Container(width: 32,),
      ],),
    );

  Widget get _expandedDetails =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.member.college?.isNotEmpty == true)
          Text(widget.member.college ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (widget.member.department?.isNotEmpty == true)
          Text(widget.member.department ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (widget.member.major?.isNotEmpty == true)
          Text(widget.member.major ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (widget.member.email?.isNotEmpty == true)
          _linkDetail(widget.member.email ?? '', 'mailto:${widget.member.email}'),
        if (widget.member.email2?.isNotEmpty == true)
          _linkDetail(widget.member.email2 ?? '', 'mailto:${widget.member.email2}'),
        if (widget.member.phone?.isNotEmpty == true)
          _linkDetail(widget.member.phone ?? '', 'tel:${widget.member.phone}'),
        if (widget.member.website?.isNotEmpty == true)
          _linkDetail(widget.member.website ?? '', UrlUtils.fixUrl(widget.member.website ?? '', scheme: 'https') ?? widget.member.website ?? ''),
      ],);

  Widget _linkDetail(String text, String url) =>
    InkWell(onTap: () => _onTapLink(url, analyticsTarget: text), child:
      Text(text, style: Styles().textStyles.getTextStyleEx('widget.button.title.small.underline', decorationColor: Styles().colors.fillColorPrimary),),
    );

  Widget get _expandedPhotoImage => (widget.member.photoUrl?.isNotEmpty == true) ?
    Container(
      width: _photoImageSize, height: _photoImageSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Styles().colors.background,
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(widget.member.photoUrl ?? ''
        )),
      )
    ) : (Styles().images.getImage('profile-placeholder', excludeFromSemantics: true, size: _photoImageSize) ?? Container());

  double get _photoImageSize => MediaQuery.of(context).size.width / 4;

  Widget get _collapsedContent =>
    InkWell(onTap: widget.onToggleExpanded, child:
      Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
        Row(children: [
          Expanded(child:
            RichText(textAlign: TextAlign.left, text:
              TextSpan(style: Styles().textStyles.getTextStyle('widget.title.regular'), children: _nameSpans),
            )
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 6), child:
            Styles().images.getImage('chevron2-down',)
          )
        ],)
     ),
    );

  String get _nameString {
    String string = '';
    string = _addNameString(string, widget.member.firstName);
    string = _addNameString(string, widget.member.middleName);
    string = _addNameString(string, widget.member.lastName);
    return string;
  }

  String _addNameString(String string, String? name) {
    if (name?.isNotEmpty == true) {
      if (string.isNotEmpty) {
        string += ' ';
      }
      string += name ?? '';
    }
    return string;
  }

  List<TextSpan> get _nameSpans {
    List<TextSpan> spans = <TextSpan>[];
    _addNameSpan(spans, widget.member.firstName);
    _addNameSpan(spans, widget.member.middleName);
    _addNameSpan(spans, widget.member.lastName, style: Styles().textStyles.getTextStyle('widget.title.regular.fat'));
    return spans;
  }

  void _addNameSpan(List<TextSpan> spans, String? name, {TextStyle? style}) {
    if (name?.isNotEmpty == true) {
      if (spans.isNotEmpty) {
        spans.add(TextSpan(text: ' '));
      }
      spans.add(TextSpan(text: name ?? '', style: style));
    }
  }

  void _onTapLink(String url, {String? analyticsTarget}) {
    Analytics().logSelect(target: analyticsTarget ?? url);
    _launchUrl(context, url);
  }

  static void _launchUrl(BuildContext context, String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri, mode: (Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault));
        }
      }
    }
  }
}