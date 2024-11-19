
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Directory.dart';
import 'package:illinois/model/Directory.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryMemberCard extends StatefulWidget {
  final DirectoryMember member;
  final bool expanded;
  final void Function()? onToggleExpanded;
  DirectoryMemberCard(this.member, { super.key, this.expanded = false, this.onToggleExpanded });

  @override
  State<StatefulWidget> createState() => _DirectoryMemberCardState();
}

class _DirectoryMemberCardState extends State<DirectoryMemberCard> {

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
                Text(widget.member.fullName, style: Styles().textStyles.getTextStyleEx('widget.title.large.fat', fontHeight: 0.85)),
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
            DirectoryMemberDetails(widget.member),
          ),
        ),
        Expanded(child:
          Padding(padding: EdgeInsets.only(top: 0), child:
            DirectoryMemberPhoto(widget.member, imageSize: _photoImageSize, borderSize: 12,)
          ),
        ),
        //Container(width: 32,),
      ],),
    );

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
}

class DirectoryMemberDetails extends StatelessWidget {
  final DirectoryMember member;
  DirectoryMemberDetails(this.member, { super.key });

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (member.college?.isNotEmpty == true)
          Text(member.college ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (member.department?.isNotEmpty == true)
          Text(member.department ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (member.major?.isNotEmpty == true)
          Text(member.major ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (member.email?.isNotEmpty == true)
          _linkDetail(member.email ?? '', 'mailto:${member.email}'),
        if (member.email2?.isNotEmpty == true)
          _linkDetail(member.email2 ?? '', 'mailto:${member.email2}'),
        if (member.phone?.isNotEmpty == true)
          _linkDetail(member.phone ?? '', 'tel:${member.phone}'),
        if (member.website?.isNotEmpty == true)
          _linkDetail(member.website ?? '', UrlUtils.fixUrl(member.website ?? '', scheme: 'https') ?? member.website ?? ''),
      ],);

  Widget _linkDetail(String text, String url) =>
    InkWell(onTap: () => _onTapLink(url, analyticsTarget: text), child:
      Text(text, style: Styles().textStyles.getTextStyleEx('widget.button.title.small.underline', decorationColor: Styles().colors.fillColorPrimary),),
    );

  void _onTapLink(String url, { String? analyticsTarget }) {
    Analytics().logSelect(target: analyticsTarget ?? url);
    _launchUrl(url);
  }
}

void _launchUrl(String? url) {
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

class DirectoryMemberPhoto extends StatelessWidget {
  final DirectoryMember member;
  final double imageSize;
  final double borderSize;
  final Map<String, String>? headers;

  DirectoryMemberPhoto(this.member, { super.key, required this.imageSize, this.borderSize = 0, this.headers });

  @override
  Widget build(BuildContext context) => (member.photoUrl?.isNotEmpty == true) ?
    Container(
      width: imageSize + borderSize, height: imageSize + borderSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Styles().colors.surfaceAccent,
      ),
      child: Center(
        child: Container(
          width: imageSize, height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Styles().colors.background,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: NetworkImage(member.photoUrl ?? '',
                headers: headers
              )
            ),
          )
        )
      ),
    ) : (Styles().images.getImage('profile-placeholder', excludeFromSemantics: true, size: imageSize + borderSize) ?? Container());
}