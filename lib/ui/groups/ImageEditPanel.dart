
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/ImageDescriptionInput.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:image_cropper/image_cropper.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:path/path.dart';
import 'package:rokwire_plugin/model/content.dart';
import 'package:rokwire_plugin/service/auth2.dart';
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
  bool _saving = false;

  ImageDescriptionData? _imageDescriptionData;

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
      backgroundColor: Styles().colors.background,
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
              icon: Styles().images.getImage('chevron-left-white', excludeFromSemantics: true) ?? Container(),
              onPressed: _onBack),
        ),
        title: Text(
          Localization()
              .getStringEx('panel.image_edit.header.title', 'Select Image'),
          style: Styles().textStyles.getTextStyle("widget.title.light.regular.extra_fat.spaced")
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
              ImageDescriptionInput(
                  imageDescriptionData: _imageDescriptionData,
                  onChanged: (data)=>
                      setStateIfMounted(() =>
                        _imageDescriptionData = data ?? _imageDescriptionData
                  )
              ),
              Container(height: 10,),
                _imageName!=null?
                RoundedButton(label: "Edit Image", onTap: _onEdit)
                    : Container(),
              Container(height: 10,),
              RoundedButton(label: _imageName!=null? "Upload New Image" : "Choose Image", onTap: showImagePickerDialog),
              Container(height: 10),
              Row(
                children: [
                  Expanded(
                  child:
                    RoundedButton(label: "Ok",
                      onTap: _onFinish,
                      progress: _saving,
                      progressSize: 24,)
                      // enabled: _imageDescriptionData?.isValidated == true,
                      // borderColor: _imageDescriptionData?.isValidated == true? Styles().colors.fillColorSecondary : Styles().colors.disabledTextColor,),
                  ),
                  Container(width: 16,),
                  Expanded(
                  child:
                    RoundedButton(label: "Cancel", onTap: _onBack),
                  )
                ],
              ),
              Container(height: 10,),
                //TBD: DDWEB - hide for web because it is not available
                ((_imageName!=null) && !kIsWeb)?
                RoundedButton(label: "Edit", onTap: _onEdit)
              : Container()
        ],)))])),
          _loading ?
          Positioned.fill(child:
            Center(child:
                Container(
                  child: Align(alignment: Alignment.center,
                    child: SizedBox(height: 24, width: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Styles().colors.fillColorSecondary, )
                    ),
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
                style: Styles().textStyles.getTextStyle("widget.title.small"),
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
    if (pickedFile != null) {
      _imageBytes = await pickedFile.readAsBytes();
      _imageName = kIsWeb ? pickedFile.name : basename(pickedFile.path);
      _contentType = kIsWeb ? pickedFile.mimeType : mime(_imageName);
      if (kIsWeb) {
        _showLoader();
        CroppedFile? croppedImage = await _cropImage(pickedFile);
        if (croppedImage != null) {
          _imageBytes = await croppedImage.readAsBytes();
        }
        _hideLoader();
      } else {
        _openEditTools();
      }
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
        useInitialFullCrop: true,
        squareBorderWidth: 2,
        squareCircleColor: Styles().colors.fillColorPrimary,
        defaultTextColor: Styles().colors.fillColorPrimary,
        selectedTextColor: Styles().colors.fillColorSecondary,
        colorForWhiteSpace: Styles().colors.white,
      );
    }
  }

  Future<CroppedFile?> _cropImage(XFile? initialImage) async {
    if (!kIsWeb) {
      // Use it only for web
      return null;
    }
    if (initialImage == null) {
      return null;
    }
    CroppedFile? croppedImage = await ImageCropper().cropImage(sourcePath: initialImage.path, compressFormat: ImageCompressFormat.jpg, compressQuality: 100, uiSettings: [
      WebUiSettings(
          context: this.context,
          presentStyle: WebPresentStyle.page,
          customRouteBuilder: (cropper, initCropper, crop, rotate, scale) {
            return _ImageCropPageRoute(cropper: cropper, initCropper: initCropper, crop: crop, rotate: rotate, scale: scale);
          })
    ]);
    return croppedImage;
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
    if (kIsWeb) {
      //TBD: DDWEB - does not work for web
    }
    _openEditTools();
  }

  void _onBack(){
    Analytics().logSelect(target: "Back");
    Navigator.pop(this.context, ImagesResult.cancel());
  }

  void _onFinish() async{
    if(widget.storagePath!=null || widget.isUserPic){
      if (_saving != true) {
        setState(() {
          _saving = true;
        });
        if (widget.isUserPic) {
          Content().uploadUserPhoto(fileName: _imageName, imageBytes: _imageBytes, mediaType: _contentType).then(_onImageUploaded);
        } else {
          Content().uploadImage(imageBytes: _imageBytes, mediaType: _contentType, storagePath: widget.storagePath!, width: widget.width).then(_onImageUploaded);
        }
      }
    } else {
      _hideLoader();
      ImagesResult result = (_imageBytes != null) ?  ImagesResult.succeed(imageData: _imageBytes) : ImagesResult.error(ImagesErrorType.contentNotSupplied, "'No file bytes.'");
      Navigator.pop(this.context, result);
    }
  }

  void _onImageUploaded(ImagesResult result) {
    if(result.resultType == ImagesResultType.succeeded
        &&  (result.imageUrl != null || widget.isUserPic)
        && _imageDescriptionData != null){
      String? url = result.imageUrl ?? (widget.isUserPic ? Content().getUserPhotoUrl(accountId: Auth2().accountId) : null);
      Content().uploadImageMetaData(
          url: url,
          metaData: _imageDescriptionData?.toMetaData).then((metaDataResult){
        if (mounted) {
          setState(() {
            _saving = false;
          });
          Navigator.pop(this.context, result);
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _saving = false;
        });
        Navigator.pop(this.context, result);
      }
    }
  }

  Future<void> _preloadImageFromUrl() async {
    _showLoader();
    if(widget.preloadImageUrl != null){
      _imageBytes = await readNetworkImage(widget.preloadImageUrl!);
      ImageMetaData? metaData = await _loadImageMetaData(widget.preloadImageUrl!);
      _imageDescriptionData = metaData != null ? ImageDescriptionDataExt.fromMetaData(metaData) : ImageDescriptionData();

      if(_imageBytes != null) {
        _imageName = basename(widget.preloadImageUrl!);
        _contentType = mime(_imageName);
      }
    } else if(widget.isUserPic){
      ImageMetaData? metaData = await _loadImageMetaData(Content().getUserPhotoUrl(accountId: Auth2().accountId));
      _imageDescriptionData = metaData != null ? ImageDescriptionDataExt.fromMetaData(metaData) : ImageDescriptionData();
    }
    _hideLoader();
  }

  Future<ImageMetaData?> _loadImageMetaData(String? imageUrl) async => imageUrl != null ?
    (await Content().loadImageMetaData(url: imageUrl)).imageMetaData :
    null;

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
        style: Styles().textStyles.getTextStyle("widget.button.title.regular.thin")
      ),
    );
  }
}

class _ImageCropPageRoute extends PageRoute<String> {
  final Widget cropper;
  final void Function() initCropper;
  final Future<String?> Function() crop;
  final void Function(RotationAngle angle) rotate;
  final void Function(double) scale;

  _ImageCropPageRoute({required this.cropper, required this.initCropper, required this.crop, required this.rotate, required this.scale});

  @override
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => false;

  @override
  String get barrierLabel => 'Image Crop';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Semantics(scopesRoute: true, explicitChildNodes: true, child:
      _ImageCropPage(cropper: cropper, initCropper: initCropper, crop: crop, rotate: rotate, scale: scale)
    );
  }
}

class _ImageCropPage extends StatefulWidget {
  final Widget cropper;
  final void Function() initCropper;
  final Future<String?> Function() crop;
  final void Function(RotationAngle angle) rotate;
  final void Function(double) scale;

  const _ImageCropPage({required this.cropper, required this.initCropper, required this.crop, required this.rotate, required this.scale});

  @override
  State<_ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<_ImageCropPage> {
  double _scaleValue = 1.0;

  @override
  void initState() {
    super.initState();
    widget.initCropper();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Styles().colors.fillColorPrimaryVariant,
        appBar: AppBar(backgroundColor: Styles().colors.fillColorPrimaryVariant, foregroundColor: Styles().colors.white,
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => _onBack(context)),
          actions: [IconButton(icon: Icon(Icons.done), onPressed: () => _onDone(context))]),
        body: Column(
          children: [
            Expanded(child: Center(child: widget.cropper)),
            SizedBox(height: 16),
            _buildTools(),
            SizedBox(height: 24)
          ]
        ));
  }

  Widget _buildTools() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(icon: const Icon(Icons.rotate_left, color: Colors.white), onPressed: () => _onRotate(RotationAngle.counterClockwise90)),
        Slider(
            value: _scaleValue,
            onChanged: (value) {
              setState(() => _scaleValue = value);
              widget.scale(value);
            },
            min: 1.0,
            max: 3.0,
            divisions: 20,
            activeColor: Styles().colors.fillColorSecondary),
        IconButton(icon: const Icon(Icons.rotate_right, color: Colors.white), onPressed: () => _onRotate(RotationAngle.clockwise90))
      ])
    ]);
  }

  void _onDone(BuildContext context) {
    widget.crop().then((result) {
      if (context.mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  void _onBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onRotate(RotationAngle angle) {
    widget.rotate(angle);
  }
}