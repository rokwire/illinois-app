import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum WebEmbedType {
  youtube,
  vimeo,
  mediaspace,
  other,
}

class WebEmbed extends StatelessWidget {
  final _WebEmbedData? _data;
  final EdgeInsetsGeometry padding;

  WebEmbed(String? body, {super.key, this.padding = const EdgeInsets.symmetric(vertical: 8.0) }) :
    _data = _WebEmbedData.fromBody(body);

  @override
  Widget build(BuildContext context) => (_data != null) ?
    Padding(padding: padding, child:
      AspectRatio(aspectRatio: _data!.aspectRatio, child:
        WebViewWidget(controller: _data!.controller),
      ),
    ) : Container();
}

class _WebEmbedData {
  final double aspectRatio;
  final WebViewController controller;

  _WebEmbedData({
    required this.controller,
    required this.aspectRatio
  });

  static _WebEmbedData? fromBody(String? body) {
    String? link = _findEmbedLink(body);
    if (link != null) {
      // Determine embed type & build final embed URL:
      WebEmbedType type = _determinePlatform(link);
      String embedUrl = _buildEmbedUrl(link, type) ?? link;
      Uri? embedUri = Uri.tryParse(embedUrl);
      if (embedUri != null) {}
      return (embedUri != null) ? _WebEmbedData(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(embedUri),
        aspectRatio: (type != WebEmbedType.other) ? (16 / 9) : 1,
      ) : null;
    } else {
      return null;
    }
  }


  // -------------------------------
  //      Link detection
  // -------------------------------

  static String? _findEmbedLink(String? text) {
    if (text == null) return null;
    final lower = text.toLowerCase();
    // naive detection
    if (lower.contains("youtube.com/") || lower.contains("youtu.be/")) {
      return _extractLink(text, ["youtube.com/", "youtu.be/"]);
    }
    if (lower.contains("vimeo.com/")) {
      return _extractLink(text, ["vimeo.com/"]);
    }
    if (lower.contains("mediaspace.illinois.edu")) {
      return _extractLink(text, ["mediaspace.illinois.edu"]);
    }
    return null;
  }

  static String? _extractLink(String text, List<String> markers) {
    final lower = text.toLowerCase();
    for (String marker in markers) {
      int index = lower.indexOf(marker);
      if (index >= 0) {
        int startIndex = index;
        while (startIndex > 0 && !_isWhitespaceOrSeparator(text[startIndex - 1])) {
          startIndex--;
        }
        int endIndex = index + marker.length;
        while (endIndex < text.length && !_isWhitespaceOrSeparator(text[endIndex])) {
          endIndex++;
        }
        return text.substring(startIndex, endIndex).trim();
      }
    }
    return null;
  }

  static bool _isWhitespaceOrSeparator(String ch) {
    return ch.trim().isEmpty || ch == '"' || ch == "'" || ch == "<" || ch == ">";
  }

  // -------------------------------
  //      Platform & URLs
  // -------------------------------

  static WebEmbedType _determinePlatform(String urlStr) {
    final lower = urlStr.toLowerCase();
    if (lower.contains('youtu.be') || lower.contains('youtube.com')) {
      return WebEmbedType.youtube;
    } else if (lower.contains('vimeo.com')) {
      return WebEmbedType.vimeo;
    } else if (lower.contains('mediaspace.illinois.edu')) {
      return WebEmbedType.mediaspace;
    } else {
      return WebEmbedType.other;
    }
  }

  static String? _buildEmbedUrl(String originalUrl, WebEmbedType type) {
    switch (type) {
      case WebEmbedType.youtube:
        return _getYouTubeEmbedUrl(originalUrl);
      case WebEmbedType.vimeo:
        return _getVimeoEmbedUrl(originalUrl);
      case WebEmbedType.mediaspace:
        return _getKalturaEmbedUrl(originalUrl);
      default:
        return null;
    }
  }

  static String? _getYouTubeEmbedUrl(String urlStr) {
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      final videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
      return 'https://www.youtube.com/embed/$videoId';
    }
    if (uri.host.contains('youtube.com')) {
      final videoId = uri.queryParameters['v'];
      if (videoId != null) {
        return 'https://www.youtube.com/embed/$videoId';
      }
    }
    return null;
  }

  static String? _getVimeoEmbedUrl(String urlStr) {
    final uri = Uri.tryParse(urlStr);
    if (uri == null || uri.pathSegments.isEmpty) return null;
    final videoId = uri.pathSegments.last;
    return 'https://player.vimeo.com/video/$videoId';
  }

  static String? _getKalturaEmbedUrl(String urlStr) {
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return null;
    if (uri.host.contains('mediaspace.illinois.edu')) {
      if (uri.pathSegments.length >= 3) {
        final entryId = uri.pathSegments[2];
        return 'https://mediaspace.illinois.edu/embed/secure/iframe/entryId/$entryId';
      }
      return null;
    }
    return null;
  }
}