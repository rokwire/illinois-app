import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:neom/service/Content.dart';

// Copied from https://pub.dev/packages/link_text

/// Easy to use text widget, which converts inlined urls into clickable links.
/// This version checks for a TLD from a Set of known TLDs.
class CustomLinkText extends StatefulWidget {
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

  const CustomLinkText(
      this.text, {
        Key? key,
        this.textStyle,
        this.linkStyle,
        this.textAlign = TextAlign.start,
        this.shouldTrimParams = false,
        this.onLinkTap,
      }) : super(key: key);

  @override
  State<CustomLinkText> createState() => _CustomLinkTextState();
}

class _CustomLinkTextState extends State<CustomLinkText> {

  /// We hold on to recognizers so we can dispose them properly.
  final Map<String, TapGestureRecognizer> _gestureRecognizers = {};

  List<InlineSpan> _textSpans = [];

  @override
  void initState() {
    _initTextSpans();
    super.initState();
  }

  @override
  void didUpdateWidget(CustomLinkText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _initTextSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _initTextSpans() {
    _textSpans.clear();
    _disposeRecognizers();

    // Split text on whitespace
    final words = widget.text.split(RegExp(r' '));

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (_isPotentialLink(word)) {
        String displayLink = word;
        if (widget.shouldTrimParams) {
          final questionMarkIndex = displayLink.indexOf('?');
          if (questionMarkIndex != -1) {
            displayLink = displayLink.substring(0, questionMarkIndex);
          }
        }

        TapGestureRecognizer recognizer = (_gestureRecognizers[word] ??= (TapGestureRecognizer()..onTap = () => _launchUrl(word)));

        _textSpans.add(
          TextSpan(
            text: displayLink,
            style: widget.linkStyle,
            recognizer: recognizer,
          ),
        );
      } else {
        // Normal text
        _textSpans.add(
          TextSpan(
            text: word,
            style: widget.textStyle,
          ),
        );
      }

      // Add a space after each word unless it's the last one.
      if (i < words.length - 1) {
        _textSpans.add(const TextSpan(text: ' '));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _textSpans),
      textAlign: widget.textAlign,
    );
  }

  /// Checks if a 'word' might be a link by verifying it ends with a known TLD.
  bool _isPotentialLink(String word) {
    final lastDotIndex = word.lastIndexOf('.');
    // Checks if dot doesn't exist or is first char
    if (lastDotIndex < 1 || lastDotIndex == word.length - 1) {
      return false;
    }
    final tldCandidate = word.substring(lastDotIndex + 1).toLowerCase();
    return Content().topLevelDomains.contains(tldCandidate);
  }

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
      return;
    }

    Uri? uri = UrlUtils.fixUri(Uri.parse(url), scheme: 'https');

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $uri');
    }
  }
}
