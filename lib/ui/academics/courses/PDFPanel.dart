import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class PDFPanel extends StatefulWidget {
  final String? resourceKey;
  final String? resourceName;
  PDFPanel({Key? key, this.resourceKey, this.resourceName}) : super(key: key);

  _PDFPanelState createState() => _PDFPanelState();
}

class _PDFPanelState extends State<PDFPanel> with WidgetsBindingObserver {
  Uint8List? _fileContents;
  PDFViewController? _pdfViewController;

  int? _pages;
  int? currentPage;
  bool isReady = false;
  String errorMessage = '';

  @override
  void initState() {
    _loadFileContents();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      appBar: HeaderBar(title: widget.resourceName ?? Localization().getStringEx('panel.essential_skills_coach.pdf_view.header.title', 'PDF View'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: _fileContents != null ? Stack(
        children: <Widget>[
          PDFView(
            pdfData: _fileContents,
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
          errorMessage.isEmpty ? (isReady ? Container() : _loadingIndicator) : Center(child: Text(errorMessage),),
          Column(
            children: [
              Expanded(child: Container()),
              Row(
                children: [
                  Visibility(
                    visible: (currentPage ?? 0) > 0,
                    replacement: SizedBox.square(dimension: 48.0),
                    child: GestureDetector(
                      onTap: () {
                        _pdfViewController?.setPage(0);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Styles().images.getImage('double-chevron-left', excludeFromSemantics: true, color: Styles().colors.fillColorPrimary) ?? Container(),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: (currentPage ?? 0) > 0,
                    replacement: SizedBox.square(dimension: 48.0),
                    child: GestureDetector(
                      onTap: () {
                        int previous = (currentPage ?? 0) - 1;
                        if (previous >= 0) {
                          _pdfViewController?.setPage(previous);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Styles().images.getImage('chevron-left-bold', excludeFromSemantics: true, color: Styles().colors.fillColorPrimary, size: 16.0) ?? Container(),
                      ),
                    ),
                  ),
                  Expanded(child: Container()),
                  if (currentPage != null)
                    Text('${currentPage! + 1}/$_pages', style: Styles().textStyles.getTextStyle('widget.detail.extra_large.fat'), textAlign: TextAlign.center,),
                  Expanded(child: Container()),
                  Visibility(
                    visible: (currentPage ?? 0) + 1 < (_pages ?? 0),
                    replacement: SizedBox.square(dimension: 48.0),
                    child: GestureDetector(
                      onTap: () {
                        int next = (currentPage ?? 0) + 1;
                        if (next < (_pages ?? 0)) {
                          _pdfViewController?.setPage(next);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true, color: Styles().colors.fillColorPrimary, size: 16.0) ?? Container(),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: (currentPage ?? 0) + 1 < (_pages ?? 0),
                    replacement: SizedBox.square(dimension: 48.0),
                    child: GestureDetector(
                      onTap: () {
                        _pdfViewController?.setPage((_pages ?? 1) - 1);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Styles().images.getImage('double-chevron-right', excludeFromSemantics: true, color: Styles().colors.fillColorPrimary) ?? Container(),
                      ),
                    ),
                  ),
                ]
              ),
            ],
          ),
        ],
      ) : _loadingIndicator,
    );
  }

  Widget get _loadingIndicator => const Center(child: CircularProgressIndicator(),);

  Future<void> _loadFileContents() async {
    if (widget.resourceKey != null && Config().essentialSkillsCoachKey != null) {
      //TODO: this content BB API call will not work because resourceKey is a file name
      Map<String, Uint8List> files = await Content().getFileContentItems([widget.resourceKey!], Config().essentialSkillsCoachKey!);
      if (files.isNotEmpty && mounted) {
        setState(() {
          _fileContents = files[widget.resourceKey!];
        });
      }
    } else if (mounted) {
      setState(() {
        errorMessage = Localization().getStringEx('panel.essential_skills_coach.pdf_view.error.message', 'Missing required data to load the requested file. Please try again later.');
      });
    }
  }
}