import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Guide.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/utils/AppUtils.dart';

class DebugGuidePanel extends StatefulWidget {
  DebugGuidePanel();

  _DebugGuidePanelState createState() => _DebugGuidePanelState();
}

class _DebugGuidePanelState extends State<DebugGuidePanel> {

  String? _contentString;
  GuideContentSource? _contentSource;
  bool? _processingContent;
  bool? _contentModified;
  TextEditingController? _contentTextController;

  @override
  void initState() {
    super.initState();
    _contentTextController = TextEditingController();
    _contentSource = Guide().contentSource;
    _contentModified = false;
    _processingContent = true;
    Guide().getContentString().then((String? jsonContent) {
      setState(() {
        _processingContent = false;
      });
      _contentTextController!.text = _contentString = jsonContent ?? '';
    });
  }

  @override
  void dispose() {
    super.dispose();
    _contentTextController!.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: "Campus Guide", ),
      body: SafeArea(child:
        Column(children: <Widget>[
          Expanded(child: 
            Padding(padding: EdgeInsets.all(16), child:
              _buildContent()
            ,),
          ),
        ],),
      ),
      backgroundColor: Styles().colors!.background,
    );
  }

  Widget _buildContent() {
    String? contentSource = (((_contentSource != null) && (_contentModified != true)) ? guideContentSourceToString(_contentSource) : 'Custom');
    String contentLabel = (_processingContent != true) ? '$contentSource Content:' : '';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(bottom: 4),
        child: Text(contentLabel, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 12, color: Styles().colors!.fillColorPrimary),),
      ),
      Expanded(child:
        Stack(children: <Widget>[
          TextField(
            maxLines: 256,
            controller: _contentTextController,
            onChanged: _onTextContentChanged,
            decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
            style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground,),
          ),
          Visibility(visible: (_processingContent == true),
            child: Align(alignment: Alignment.center,
              child: SizedBox(height: 32, width: 32,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
              ),
            ),
          ),
          Align(alignment: Alignment.topRight, child:
            _buildToolbar()
          ),
        ]),
      ),
      Padding(padding: EdgeInsets.only(top: 16), child: _buildButtons()),
    ],);
  }

  Widget _buildToolbar() {
    return Wrap(children: [
      Visibility(visible: false, child:
        GestureDetector(onTap: _nop,
          child: Container(width: 36, height: 36,
            child: Align(alignment: Alignment.center,
              child: Image.asset('images/icon-share.png', excludeFromSemantics: true),
            ),
          ),
        ),
      ),
      Visibility(visible: false, child:
        GestureDetector(onTap: _nop,
          child: Container(width: 36, height: 36,
            child: Align(alignment: Alignment.center,
              child: Text('X', style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.fillColorPrimary,),), // Image.asset('images/icon-refresh.png'),
            ),
          ),
        ),
      ),
    ],);
  }

  Widget _buildButtons() {
    bool applyEnabled = (_contentSource == null) || (_contentModified == true);
    bool previewEnabled = (_contentSource != null) && (_contentModified != true);

    return Column(children: [
      Row(children: <Widget>[
        Expanded(child: RoundedButton(
          label: "Init From Assets",
          textColor: Styles().colors!.surfaceAccent,
          borderColor: Styles().colors!.surfaceAccent,
          backgroundColor: Styles().colors!.white,
          fontFamily: Styles().fontFamilies!.bold,
          fontSize: 16,
          borderWidth: 2,
          onTap:() { _onInitFromAssets();  }
        ),),
        Container(width: 8,),
        Expanded(child: RoundedButton(
          label: "Init From Net",
          textColor: Styles().colors!.fillColorPrimary, // Styles().colors!.surfaceAccent,
          borderColor: Styles().colors!.fillColorSecondary, // Styles().colors!.surfaceAccent,
          backgroundColor: Styles().colors!.white,
          fontFamily: Styles().fontFamilies!.bold,
          fontSize: 16,
          borderWidth: 2,
          onTap:() { _onInitFromNet();  }
        ),),
      ],),

      Container(height: 8,),

      Row(children: <Widget>[
        Expanded(child: RoundedButton(
          label: "Apply",
          textColor: applyEnabled ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
          borderColor: applyEnabled ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
          backgroundColor: Styles().colors!.white,
          fontFamily: Styles().fontFamilies!.bold,
          fontSize: 16,
          borderWidth: 2,
          onTap:() { _onApply();  }
        ),),
        Container(width: 8,),
        Expanded(child: RoundedButton(
          label: "Preview",
          textColor: previewEnabled ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
          borderColor: previewEnabled ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
          backgroundColor: Styles().colors!.white,
          fontFamily: Styles().fontFamilies!.bold,
          fontSize: 16,
          borderWidth: 2,
          onTap:() { _onPreview();  }
        ),),
      ],),

    ]);
  }

  void _onTextContentChanged(String value) {
    setState(() {
      _contentModified = (_contentString != value);
    });
  }

  void _onInitFromAssets() {
    /*try { 
      setState(() {
        _processingContent = true;
      });
      _contentTextController!.text = '';
      
      AppBundle.loadString('assets/guide.json').then((String? assetsContentString) {
        if (assetsContentString != null) {
          Guide().setDebugContentString(assetsContentString).then((String? contentString) {
            if (contentString != null) {
              setState(() {
                _contentString = contentString;
                _contentSource = Guide().contentSource;
                _contentModified = false;
                _processingContent = false;
                _contentTextController!.text = contentString;
              });
            }
            else {
              setState(() {
                _processingContent = false;
              });
              _contentTextController!.text = _contentString!;
              AppAlert.showDialogResult(context, "Invalid JSON content.");
            }
          });
        }
        else {
          setState(() {
            _processingContent = false;
          });
          _contentTextController!.text = _contentString!;
          AppAlert.showDialogResult(context, "Failed to load assets contnet.");
        }
      });
    }
    catch (e) { print(e.toString()); }*/
  }

  void _onInitFromNet() {
    if (_processingContent != true) {
      setState(() {
        _processingContent = true;
      });
      _contentTextController!.text = '';
      
      Guide().setDebugContentString(null).then((String? contentString) {
        if (contentString != null) {
          setState(() {
            _contentString = contentString;
            _contentSource = Guide().contentSource;
            _contentModified = false;
            _processingContent = false;
            _contentTextController!.text = contentString;
          });
        }
        else {
          setState(() {
            _processingContent = false;
          });
          AppAlert.showDialogResult(context, "Failed to load net content.");
        }
      });
    }
  }

  void _onApply() {
    Guide().setDebugContentString(_contentTextController!.text).then((String? contentString) {
      if (contentString != null) {
        setState(() {
          _contentString = contentString;
          _contentSource = Guide().contentSource;
          _contentModified = false;
          _processingContent = false;
          _contentTextController!.text = contentString;
        });
        AppAlert.showDialogResult(context, "JSON conent applied.");
      }
      else {
        AppAlert.showDialogResult(context, "Invalid JSON content.");
      }
    });
  }

  void _onPreview() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
  }

  void _nop() {
    
  }
}

