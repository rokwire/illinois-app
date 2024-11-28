
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/directory.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryProfileCard extends StatefulWidget {
  final Auth2PublicAccount account;
  final bool expanded;
  final void Function()? onToggleExpanded;
  DirectoryProfileCard(this.account, { super.key, this.expanded = false, this.onToggleExpanded });

  @override
  State<StatefulWidget> createState() => _DirectoryProfileCardState();
}

class _DirectoryProfileCardState extends State<DirectoryProfileCard> {

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
                Text(widget.account.profile?.fullName ?? '', style: Styles().textStyles.getTextStyleEx('widget.title.large.fat', fontHeight: 0.85)),
                if (widget.account.profile?.pronouns?.isNotEmpty == true)
                  Text(widget.account.profile?.pronouns ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small')),
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
          DirectoryProfileDetails(widget.account.profile),
          ),
        ),
        Expanded(child:
          Padding(padding: EdgeInsets.only(top: 0), child:
            DirectoryProfilePhoto(widget.account.profile?.photoUrl, imageSize: _photoImageSize, borderSize: 12,)
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
    _addNameSpan(spans, widget.account.profile?.firstName);
    _addNameSpan(spans, widget.account.profile?.middleName);
    _addNameSpan(spans, widget.account.profile?.lastName, style: Styles().textStyles.getTextStyle('widget.title.regular.fat'));
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

class DirectoryProfileDetails extends StatelessWidget {
  final Auth2UserProfile? profile;

  DirectoryProfileDetails(this.profile, { super.key });
  
  String? get college => null;
  String? get department => null;
  String? get major => null;
  
  String? get email => null;
  String? get email2 => null;
  String? get phone => null;
  String? get website => null;
  
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (profile?.college?.isNotEmpty == true)
          Text(profile?.college ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (profile?.department?.isNotEmpty == true)
          Text(profile?.department ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (profile?.major?.isNotEmpty == true)
          Text(profile?.major ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (profile?.email?.isNotEmpty == true)
          _linkDetail(profile?.email ?? '', 'mailto:${email}'),
        if (profile?.email2?.isNotEmpty == true)
          _linkDetail(profile?.email2 ?? '', 'mailto:${email2}'),
        if (profile?.phone?.isNotEmpty == true)
          _linkDetail(profile?.phone ?? '', 'tel:${phone}'),
        if (profile?.website?.isNotEmpty == true)
          _linkDetail(profile?.website ?? '', UrlUtils.fixUrl(profile?.website ?? '', scheme: 'https') ?? profile?.website ?? ''),
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

class DirectoryProfilePhoto extends StatelessWidget {
  final String? photoUrl;
  final double imageSize;
  final double borderSize;
  final Map<String, String>? headers;

  DirectoryProfilePhoto(this.photoUrl, { super.key, required this.imageSize, this.borderSize = 0, this.headers });

  @override
  Widget build(BuildContext context) => (photoUrl?.isNotEmpty == true) ?
    Container(
      width: imageSize + borderSize, height: imageSize + borderSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      ),
      child: Center(
        child: Container(
          width: imageSize, height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Styles().colors.background,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: NetworkImage(photoUrl ?? '',
                headers: headers
              )
            ),
          )
        )
      ),
    ) : (Styles().images.getImage('profile-placeholder', excludeFromSemantics: true, size: imageSize + borderSize) ?? Container());
}