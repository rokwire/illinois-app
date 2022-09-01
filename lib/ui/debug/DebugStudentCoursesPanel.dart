import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DebugStudentCoursesPanel extends StatefulWidget {
  _DebugStudentCoursesPanelState createState() => _DebugStudentCoursesPanelState();
}

class _DebugStudentCoursesPanelState extends State<DebugStudentCoursesPanel> {

  late TextEditingController _rawContentController;
  bool _rawContentModified = false;
  bool _useDebugContent = false;
  bool _processingContent = false;
  bool _validContent = false;

  @override
  void initState() {
    _rawContentController = TextEditingController();
    _useDebugContent = StudentCourses().useDebugCoursesContent;
    _processingContent = true;
    StudentCourses().getDebugCoursesRawContent().then((String? value) {
      if (mounted) {
        setState(() {
          _rawContentController.text = value ?? '';
          _processingContent = false;
          _rawContentModified = false;
          _validContent = ((value != null) && value.isNotEmpty) ? (JsonUtils.decodeList(value) != null) : false;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _rawContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: "Student Courses",
        onLeading: _onHeaderBack,
      ),
      backgroundColor: Styles().colors!.surface,
      body: SafeArea(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ToggleRibbonButton(label: 'Use JSON Contnet:', toggled: _useDebugContent, onTap: _onToggleUseDebugContent),
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
              Stack(children: [
                TextField(
                  maxLines: 1024,
                  controller: _rawContentController,
                  decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
                  style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground,),
                  onChanged: _onRawContentChanged,
                  onEditingComplete: _onRawContentFinished,
                ),
                Visibility(visible: (_processingContent == true), child:
                  Align(alignment: Alignment.center, child:
                    SizedBox(height: 32, width: 32, child:
                      CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
                    ),
                  ),
                ),
                Visibility(visible: !_processingContent, child:
                  Align(alignment: Alignment.bottomRight, child:
                    Padding(padding: EdgeInsets.all(10), child: 
                      _validContent ? Image.asset('images/green-check-mark.png', width: 18, height: 18) : Image.asset('images/close-orange-small.png', width: 18, height: 18),
                    ),
                  ),
                ),
                Visibility(visible: !_processingContent, child:
                  Align(alignment: Alignment.topRight, child:
                    Wrap(children: [
                      InkWell(onTap: _onPaste, child:
                        Padding(padding: EdgeInsets.all(10), child: 
                          Image.asset('images/icon-paste.png', excludeFromSemantics: true),
                        ),
                      ),
                      InkWell(onTap: _onClear, child:
                        Padding(padding: EdgeInsets.only(top: 10, bottom: 10, left: 6, right: 14), child: 
                          Text('X', style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.fillColorPrimary,),), // Image.asset('images/icon-refresh.png'),
                        ),
                      ),
                    ],),
                  ),
                ),
              ],)
            ),
          ),
        ],),
      ),
    );
  }

  void _onToggleUseDebugContent() {
    
    setState(() {
      StudentCourses().useDebugCoursesContent = _useDebugContent = !_useDebugContent;
    });

    if (_useDebugContent && _rawContentModified && !_processingContent) {
      setState(() {
        _processingContent = true;
      });
      StudentCourses().setDebugCoursesRawContent(_rawContentController.text).then((_) {
        if (mounted) {
          setState(() {
            _rawContentModified = false;
            _processingContent = false;
          });
        }
      });
    }
  }

  void _onClear() {
    if (_rawContentController.text.isNotEmpty) {
      setStateIfMounted(() {
        _rawContentController.text = '';
        _rawContentModified = true;
        _validContent = false;
      });
    }
  }

  void _onPaste() {
    Clipboard.getData('text/plain').then((ClipboardData? data) {
      if (data?.text != null) {
        setStateIfMounted(() {
          _rawContentController.text = data!.text!;
          _rawContentModified = true;
          _validContent = JsonUtils.decodeList(data.text) != null;
        });

      }
      else {
        AppAlert.showDialogResult(context, 'Unable to retrieve clipboard content.');
      }
    });
  }
  
  void _onRawContentChanged(String text) {
    _rawContentModified = true;

    bool validContent = JsonUtils.decodeList(text) != null;
    if (validContent != _validContent) {
      setState(() {
        _validContent = validContent;
      });
    }
  }

  void _onRawContentFinished() {
    if (_rawContentModified && !_processingContent) {
      setState(() {
        _processingContent = true;
      });
      StudentCourses().setDebugCoursesRawContent(_rawContentController.text).then((_) {
        if (mounted) {
          setState(() {
            _rawContentModified = false;
            _processingContent = false;
          });
        }
      });
    }
  }

  void _onHeaderBack() {
    if (_rawContentModified && !_processingContent) {
      setState(() {
        _processingContent = true;
      });
      StudentCourses().setDebugCoursesRawContent(_rawContentController.text).then((_) {
        if (mounted) {
          setState(() {
            _rawContentModified = false;
            _processingContent = false;
          });
          Navigator.of(context).pop();    
        }
      });
    }
    else {
      Navigator.of(context).pop();
    }
  }
}