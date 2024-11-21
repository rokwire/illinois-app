
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Directory.dart';
import 'package:illinois/model/Directory.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:rokwire_plugin/model/auth2.dart';
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
            DirectoryMemberPhoto(widget.member.photoUrl, imageSize: _photoImageSize, borderSize: 12,)
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

class _DetailsWidget extends StatelessWidget {
  _DetailsWidget({super.key});
  
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
        if (college?.isNotEmpty == true)
          Text(college ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (department?.isNotEmpty == true)
          Text(department ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (major?.isNotEmpty == true)
          Text(major ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (email?.isNotEmpty == true)
          _linkDetail(email ?? '', 'mailto:${email}'),
        if (email2?.isNotEmpty == true)
          _linkDetail(email2 ?? '', 'mailto:${email2}'),
        if (phone?.isNotEmpty == true)
          _linkDetail(phone ?? '', 'tel:${phone}'),
        if (website?.isNotEmpty == true)
          _linkDetail(website ?? '', UrlUtils.fixUrl(website ?? '', scheme: 'https') ?? website ?? ''),
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

class DirectoryMemberDetails extends _DetailsWidget {
  final DirectoryMember member;
  DirectoryMemberDetails(this.member, { super.key });

  @override String? get college => member.college;
  @override String? get department => member.department;
  @override String? get major => member.major;
  
  @override String? get email => member.email;
  @override String? get email2 => member.email2;
  @override String? get phone => member.phone;
  @override String? get website => member.website;
}

class ProfileDetails extends _DetailsWidget {
  final Auth2UserProfile profile;
  ProfileDetails(this.profile, { super.key });

  @override String? get college => profile.college;
  @override String? get department => profile.department;
  @override String? get major => profile.major;
  
  @override String? get email => profile.email;
  @override String? get email2 => profile.email2;
  @override String? get phone => profile.phone;
  @override String? get website => profile.website;
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
  final String? photoUrl;
  final double imageSize;
  final double borderSize;
  final Map<String, String>? headers;

  DirectoryMemberPhoto(this.photoUrl, { super.key, required this.imageSize, this.borderSize = 0, this.headers });

  @override
  Widget build(BuildContext context) => (photoUrl?.isNotEmpty == true) ?
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
              image: NetworkImage(photoUrl ?? '',
                headers: headers
              )
            ),
          )
        )
      ),
    ) : (Styles().images.getImage('profile-placeholder', excludeFromSemantics: true, size: imageSize + borderSize) ?? Container());
}