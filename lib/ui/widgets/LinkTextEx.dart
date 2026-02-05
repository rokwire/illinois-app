import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/utils/AppUtils.dart';

// Copied from https://pub.dev/packages/link_text

/// Easy to use text widget, which converts inlined urls into clickable links.
/// This version checks for a TLD from a Set of known TLDs.
class LinkTextEx extends StatefulWidget {
  /// Text, which may contain inlined urls.
  final String text;

  /// Style of the non-url part of supplied text.
  final TextStyle? textStyle;

  /// Style of the url part of supplied text.
  final TextStyle? linkStyle;

  /// Determines how the text is aligned.
  final TextAlign textAlign;

  /// If true, this will cut off all visible params after '?'
  /// when displaying the link (for readability). The actual link
  /// that gets launched remains the full string (including params).
  final bool shouldTrimParams;

  /// Overrides default behavior when tapping on links.
  /// Provides the url that was tapped.
  final void Function(String url)? onLinkTap;

  const LinkTextEx(
      this.text, {
        Key? key,
        this.textStyle,
        this.linkStyle,
        this.textAlign = TextAlign.start,
        this.shouldTrimParams = false,
        this.onLinkTap,
      }) : super(key: key);

  @override
  State<LinkTextEx> createState() => _LinkTextExState();
}

class _LinkTextExState extends State<LinkTextEx> {

  /// Url regular expression, credits to: https://stackoverflow.com/a/63022807/3759472
  final RegExp _urlRegex = RegExp(r"([\w+]+\:\/\/)?([\w\d-]+\.)*[\w-]+[\.\:]\w+([\/\?\=\&\#\.]?[\w-]+)*\/?");

  /// We hold on to recognizers so we can dispose them properly.
  final Map<String, TapGestureRecognizer> _gestureRecognizers = {};

  List<InlineSpan> _textSpans = [];

  @override
  void initState() {
    _buildTextSpans();
    super.initState();
  }

  @override
  void didUpdateWidget(LinkTextEx oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _buildTextSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _buildTextSpans() {
    _textSpans.clear();
    _disposeRecognizers();

    Iterable<RegExpMatch> urls = _urlRegex.allMatches(widget.text);
    if (urls.isEmpty) {
      // Entire text is Normal
      _textSpans.add(TextSpan(text: widget.text, style: widget.textStyle,),);
    }
    else {
      int textPos = 0;
      for (RegExpMatch urlMatch in urls) {
        if (textPos < urlMatch.start) {
          // Normal word
          String word = widget.text.substring(textPos, urlMatch.start);
          _textSpans.add(TextSpan(text: word, style: widget.textStyle,),);
        }
        if (urlMatch.start < urlMatch.end) {
          // URL link
          String url = widget.text.substring(urlMatch.start, urlMatch.end);
          String displayUrl = url;
          if (widget.shouldTrimParams) {
            int pos1 = url.indexOf('?'), pos2 = url.indexOf('#');
            int pos = (0 < pos1) ? ((0 < pos2) ? min(pos1, pos2) : pos1 ) : pos2;
            if (0 < pos) {
              displayUrl = url.substring(0, pos);
            }
          }
          TapGestureRecognizer recognizer = (_gestureRecognizers[url] ??= (TapGestureRecognizer()..onTap = () => _launchUrl(url)));
          _textSpans.add(TextSpan(text: displayUrl, style: widget.linkStyle, recognizer: recognizer,));
        }
        textPos = urlMatch.end;
      }
      if (textPos < widget.text.length) {
        String word = widget.text.substring(textPos);
        _textSpans.add(TextSpan(text: word, style: widget.textStyle,),);
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
    Text.rich(TextSpan(children: _textSpans), textAlign: widget.textAlign,);

  void _disposeRecognizers() {
    for (final recognizer in _gestureRecognizers.values) {
      recognizer.dispose();
    }
    _gestureRecognizers.clear();
  }

  void _launchUrl(String url) async {
    void Function(String)? onLinkTap = widget.onLinkTap;
    if (onLinkTap != null) {
      onLinkTap(url);
    }
    else {
      AppLaunchUrl.launchExternal(url: url);
    }
  }
}
