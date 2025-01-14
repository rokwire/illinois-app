import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum WebEmbedType {
  youtube,
  vimeo,
  kaltura,
  other,
}

class WebEmbed extends StatefulWidget {
  final String? body;

  const WebEmbed({Key? key, this.body}) : super(key: key);

  @override
  State<WebEmbed> createState() => _WebEmbedState();
}

class _WebEmbedState extends State<WebEmbed> {
  late final WebViewController _controller;
  String? _embedUrl;
  double _aspectRatio = 1;

  @override
  void initState() {
    super.initState();
    // Parse out a recognized link from body:
    final link = _findEmbedLink(widget.body);
    if (link != null) {
      // Determine embed type & build final embed URL:
      final type = _determinePlatform(link);
      _embedUrl = _buildEmbedUrl(link, type) ?? link;
      // Aspect ratio 16:9 for recognized, else 1:1
      if (type != WebEmbedType.other) {
        _aspectRatio = 16 / 9;
      }
      // Setup controller to load the URL
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(_embedUrl!));
    } else {
      // No recognized link => no controller
      _controller = WebViewController();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_embedUrl == null) {
      // No recognized embed => return empty
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

  // -------------------------------
  //      Link detection
  // -------------------------------

  String? _findEmbedLink(String? text) {
    if (text == null) return null;
    final lower = text.toLowerCase();
    // naive detection
    if (lower.contains("youtube.com/") || lower.contains("youtu.be/")) {
      return _extractLink(text, ["youtube.com/", "youtu.be/"]);
    }
    if (lower.contains("vimeo.com/")) {
      return _extractLink(text, ["vimeo.com/"]);
    }
    if (lower.contains("kaltura.com/")) {
      return _extractLink(text, ["kaltura.com/"]);
    }
    return null;
  }

  String? _extractLink(String text, List<String> markers) {
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

  bool _isWhitespaceOrSeparator(String ch) {
    return ch.trim().isEmpty || ch == '"' || ch == "'" || ch == "<" || ch == ">";
  }

  // -------------------------------
  //      Platform & URLs
  // -------------------------------

  WebEmbedType _determinePlatform(String urlStr) {
    final lower = urlStr.toLowerCase();
    if (lower.contains('youtu.be') || lower.contains('youtube.com')) {
      return WebEmbedType.youtube;
    } else if (lower.contains('vimeo.com')) {
      return WebEmbedType.vimeo;
    } else if (lower.contains('kaltura.com')) {
      return WebEmbedType.kaltura;
    } else {
      return WebEmbedType.other;
    }
  }

  String? _buildEmbedUrl(String originalUrl, WebEmbedType type) {
    switch (type) {
      case WebEmbedType.youtube:
        return _getYouTubeEmbedUrl(originalUrl);
      case WebEmbedType.vimeo:
        return _getVimeoEmbedUrl(originalUrl);
      case WebEmbedType.kaltura:
        return _getKalturaEmbedUrl(originalUrl);
      default:
        return null;
    }
  }

  String? _getYouTubeEmbedUrl(String urlStr) {
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

  String? _getVimeoEmbedUrl(String urlStr) {
    final uri = Uri.tryParse(urlStr);
    if (uri == null || uri.pathSegments.isEmpty) return null;
    final videoId = uri.pathSegments.last;
    return 'https://player.vimeo.com/video/$videoId';
  }

  String? _getKalturaEmbedUrl(String urlStr) {
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return null;
    String? entryId;
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'id') {
      entryId = uri.pathSegments[1];
    } else {
      entryId = uri.queryParameters['entry_id'];
    }
    if (entryId == null) {
      return null;
    }
    const partnerId = '<YOUR_PARTNER_ID>';
    const uiconfId = '<YOUR_UICONF_ID>';
    return 'https://cdnapisec.kaltura.com/p/$partnerId/sp/${partnerId}00'
        '/embedIframeJs/uiconf_id/$uiconfId/partner_id/$partnerId'
        '?entry_id=$entryId'
        '&iframeembed=true';
  }
}
