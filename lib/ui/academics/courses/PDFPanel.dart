import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

import '../../widgets/HeaderBar.dart';

class PDFPanel extends StatefulWidget {
  final String? resourceName;
  final String? path;
  PDFPanel({Key? key, this.resourceName, this.path}) : super(key: key);

  _PDFPanelState createState() => _PDFPanelState();
}

class _PDFPanelState extends State<PDFPanel> with WidgetsBindingObserver {
  final Completer<PDFViewController> _viewCompleter = Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      appBar: HeaderBar(title: widget.resourceName ?? Localization().getStringEx('panel.essential_skills_coach.pdf_view.header.title', 'PDF View'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.path,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.BOTH,
            onRender: (_pages) {
              setState(() {
                pages = _pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _viewCompleter.complete(pdfViewController);
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                currentPage = page;
              });
            },
          ),
          errorMessage.isEmpty ? (isReady ? Container() : Center(child: CircularProgressIndicator(),)) : Center(child: Text(errorMessage),),
        ],
      ),
    );
  }
}