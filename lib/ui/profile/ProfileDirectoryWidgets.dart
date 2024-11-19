
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
