
/*MIT License

Copyright (c) 2021 MindInventory

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:path/path.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:image_cropping/image_cropping.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:mime_type/mime_type.dart';

class ImageEditPanel extends StatefulWidget {
  final String? storagePath;
  final int? width;
  final bool isUserPic;

  final String? preloadImageUrl;

  const ImageEditPanel({Key? key, this.storagePath, this.width = 1080, this.isUserPic = false, this.preloadImageUrl}) : super(key: key);

  _ImageEditState createState() => _ImageEditState();
}

class _ImageEditState extends State<ImageEditPanel> with WidgetsBindingObserver{
  Uint8List? _imageBytes;
  String? _imageName;
  String? _contentType;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
   _preloadImageFromUrl().then((_){
     WidgetsBinding.instance.addPostFrameCallback((_) async {
       if(_imageBytes == null){
         showImagePickerDialog();
       }
     });
   });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHeaderBar(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
      body: buildContent()
    );
  }

  PreferredSizeWidget _buildHeaderBar(){
    return AppBar(
        leading: Semantics(
          label: Localization().getStringEx('headerbar.back.title', 'Back'),
          hint: Localization().getStringEx('headerbar.back.hint', ''),
          button: true,
          excludeSemantics: true,
          child: IconButton(
              icon: Styles().images?.getImage('chevron-left-white', excludeFromSemantics: true) ?? Container(),
              onPressed: _onBack),
        ),
        title: Text(
          Localization()
              .getStringEx('panel.image_edit.header.title', 'Select Image'),
          style: Styles().textStyles?.getTextStyle("widget.title.light.regular.extra_fat.spaced")
        ),
        centerTitle: false);
  }

  Widget buildContent(){
    return
    Stack( children:[
    Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child:
        Column(
          children:[
            Expanded(
              child: SingleChildScrollView(child: Column(children: [
              Container(height: 8,),
              _imageBytes == null ? Container():
              InkWell(
                    child: Image.memory(_imageBytes!),
                    onTap: () {
                      showImagePickerDialog();
                    },),
              Container(height: 10,),
              Row(
                children: [
                  Expanded(
                  child:
                    RoundedButton(label: "Ok", onTap: _onFinish),
                  ),
                  Container(width: 16,),
                  Expanded(
                  child:
                    RoundedButton(label: "Cancel", onTap: _onBack),
                  )
                ],
              ),
              Container(height: 8,),
              RoundedButton(label: "Choose Image", onTap: showImagePickerDialog),
              Container(height: 10,),
              _imageName!=null?
                RoundedButton(label: "Edit", onTap: _onEdit)
              : Container()
        ],)))])),
          _loading?
              Center(child:
                Container(
                  child: Align(alignment: Alignment.center,
                    child: SizedBox(height: 24, width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
                    ),
                  ),
                ),
              )
          : Container()
    ]);
  }

  /// Image Picker dialog with Open Camera, Open Gallery and cancel button.
  Future<void> showImagePickerDialog() async {
    Dialog dialog = Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      //this right here
      child: Container(
        height: 200.0,
        width: 200.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                "Image Source",
                style: Styles().textStyles?.getTextStyle("widget.title.small"),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 50.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AppDialogButton(
                  buttonTitle: "Camera",
                  onPressed: () {
                    _closeDialog();
                    _openImagePicker(ImageSource.camera);
                  },
                ),
                AppDialogButton(
                  buttonTitle: "Gallery",
                  onPressed: () {
                    _closeDialog();
                    _openImagePicker(ImageSource.gallery);
                  },
                ),
                AppDialogButton(
                  buttonTitle: "Cancel",
                  onPressed: () {
                    _closeDialog();
                    _closeDialog();// close panel
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );

    /// To display a dialog
    showDialog(
      context: this.context,
      builder: (BuildContext context) => dialog,
      barrierDismissible: false,
    );
  }

  /// Open image picker
  void _openImagePicker(source) async {
    _showLoader();
    XFile? pickedFile = await ImagePicker().pickImage(source: source, maxWidth: 1920, maxHeight: 1920);
    if(pickedFile != null){
      _imageBytes = await pickedFile.readAsBytes();
      _imageName = basename(pickedFile.path);
      _contentType = mime(_imageName);
      _openEditTools();
    } else {
      //No image selected

    }
    _hideLoader();
  }

  void _openEditTools(){
    if (_imageBytes != null) {
      ImageCropping.cropImage(
        context: this.context,
        imageBytes: _imageBytes!,
        onImageDoneListener: (data) {
          setState(
                () {
              _imageBytes = data;
            },
          );
        },
        onImageStartLoading: _showLoader,
        onImageEndLoading: _hideLoader,
        visibleOtherAspectRatios: true,
        squareBorderWidth: 2,
        squareCircleColor: Styles().colors!.fillColorPrimary!,
        defaultTextColor: Styles().colors!.fillColorPrimary!,
        selectedTextColor: Styles().colors!.fillColorSecondary!,
        colorForWhiteSpace: Styles().colors!.white!,
      );
    }
  }

  /// To display loader with loading text
  void _showLoader() {
    if (_loading!=true){
      if(mounted){
        setState(() {
          _loading = true;
        });
      }
    }
  }

  /// To hide loader
  void _hideLoader() {
    if (_loading!=false){
      if(mounted){
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// to pop from current
  void _closeDialog() {
    Navigator.of(this.context).pop(ImagesResult.cancel());

  }

  void _onEdit(){
    _openEditTools();
  }

  void _onBack(){
    Analytics().logSelect(target: "Back");
    Navigator.pop(this.context, ImagesResult.cancel());
  }

  void _onFinish() async{
    if(widget.storagePath!=null || widget.isUserPic){
      _showLoader();
      Content().uploadImage(imageBytes: _imageBytes, fileName: _imageName, mediaType: _contentType, storagePath: widget.storagePath, width: widget.width, isUserPic: widget.isUserPic)
          .then((value) {
            _hideLoader();
            Navigator.pop(this.context, value);
      });
    } else {
      _hideLoader();
      ImagesResult result = (_imageBytes != null) ?  ImagesResult.succeed(_imageBytes) : ImagesResult.error(ImagesErrorType.contentNotSupplied, "'No file bytes.'");
      Navigator.pop(this.context,result);
    }
  }

  Future<void> _preloadImageFromUrl() async {
    _showLoader();
    if(widget.preloadImageUrl != null){
      _imageBytes = await readNetworkImage(widget.preloadImageUrl!);
      if(_imageBytes != null) {
        _imageName = basename(widget.preloadImageUrl!);
        _contentType = mime(_imageName);
      }
    }
    _hideLoader();
  }

  //Utils: TBD move to Utils file if we keeps it
  // Reading bytes from a network image
  static Future<Uint8List?> readNetworkImage(String imageUrl) async {
    try {
      final ByteData data = await NetworkAssetBundle(Uri.parse(imageUrl))
          .load(imageUrl);
      final Uint8List bytes = data.buffer.asUint8List();
      return bytes;
    } catch (e){
      return null;
    }
  }
}

/// class for dialog button
class AppDialogButton extends StatefulWidget {
  final String buttonTitle;
  final VoidCallback onPressed;

  const AppDialogButton(
      {Key? key, required this.buttonTitle, required this.onPressed})
      : super(key: key);

  @override
  State<AppDialogButton> createState() => AppDialogButtonState();
}

class AppDialogButtonState extends State<AppDialogButton> {
  Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: widget.onPressed,
      child: Text(
        widget.buttonTitle,
        style: Styles().textStyles?.getTextStyle("widget.button.title.regular.thin")
      ),
    );
  }
}