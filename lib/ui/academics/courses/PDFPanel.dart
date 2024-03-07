import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/gen/styles.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class PDFPanel extends StatefulWidget {
  final String? resourceName;
  final Uint8List? pdfData;
  PDFPanel({Key? key, this.resourceName, this.pdfData}) : super(key: key);

  _PDFPanelState createState() => _PDFPanelState();
}

class _PDFPanelState extends State<PDFPanel> with WidgetsBindingObserver {
  PDFViewController? _pdfViewController;

  int? _pages;
  int? currentPage;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HeaderBar(title: widget.resourceName ?? Localization().getStringEx('panel.essential_skills_coach.pdf_view.header.title', 'PDF View'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: Stack(
        children: <Widget>[
          PDFView(
            pdfData: widget.pdfData,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage ?? 0,
            fitPolicy: FitPolicy.BOTH,
            onRender: (pages) {
              setState(() {
                _pages = pages;
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
              _pdfViewController = pdfViewController;
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                currentPage = page;
              });
            },
          ),
          errorMessage.isEmpty ? (isReady ? Container() : Center(child: CircularProgressIndicator(),)) : Center(child: Text(errorMessage),),
          Column(
            children: [
              Expanded(child: Container()),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      int previous = (currentPage ?? 0) - 1;
                      if (previous >= 0) {
                        _pdfViewController?.setPage(previous);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                          height: 64.0,
                          child: Visibility(
                            visible: (currentPage ?? 0) > 0,
                            child: Styles().images.getImage('chevron-left-bold', excludeFromSemantics: true, color: AppColors.fillColorPrimary) ?? Container()
                          )
                      ),
                    ),
                  ),
                  Expanded(child: Container()),
                  if (currentPage != null)
                    Text('${currentPage! + 1}/$_pages', style: Styles().textStyles.getTextStyle('widget.detail.extra_large.fat'), textAlign: TextAlign.center,),
                  Expanded(child: Container()),
                  GestureDetector(
                    onTap: () {
                      int next = (currentPage ?? 0) + 1;
                      if (next < (_pages ?? 0)) {
                        _pdfViewController?.setPage(next);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                          height: 64.0,
                          child: Visibility(
                            visible: (currentPage ?? 0) + 1 < (_pages ?? 0),
                            child: Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true, color: AppColors.fillColorPrimary) ?? Container()
                          )
                      ),
                    ),
                  )
                ]
              ),
            ],
          ),
        ],
      ),
    );
  }
}