import 'package:flutter/material.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

typedef void ImageDescriptionChanged(ImageDescriptionData? data);

enum ImageDescriptionInputMode{dialog, layout}
class ImageDescriptionInput extends StatefulWidget {
  final ImageDescriptionInputMode mode;
  final ImageDescriptionData? imageDescriptionData;
  final ImageDescriptionChanged? onChanged;

  const ImageDescriptionInput({super.key, this.imageDescriptionData, this.onChanged, this.mode = ImageDescriptionInputMode.layout});

  static Future<ImageDescriptionData?> showAsDialog({required BuildContext context, ImageDescriptionData? imageDescriptionData , ImageDescriptionChanged? onChanged}) =>
    showDialog(context: context, barrierDismissible: false, builder: (_) =>
      Dialog(child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24), child:
            ImageDescriptionInput(imageDescriptionData: imageDescriptionData, onChanged: onChanged, mode: ImageDescriptionInputMode.dialog)
          )));

  @override
  State<StatefulWidget> createState() => _ImageDescriptionInputState();
}
class _ImageDescriptionInputState extends State<ImageDescriptionInput> {
  EdgeInsetsGeometry _dialogButtonPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  TextEditingController _textController = TextEditingController();
  late ImageDescriptionData _imageDescriptionData;

  @override
  void initState() {
    _imageDescriptionData = widget.imageDescriptionData ?? ImageDescriptionData();
    _textController.text = _imageDescriptionData.description ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
      String label = Localization().getStringEx('', 'Alt Text');
      String hint = Localization().getStringEx('', 'Add a one to two sentence description of the image. Do not include \"Image of . . .\"');
      return Container(
          // padding: EdgeInsets.symmetric(horizontal: 12),
         // decoration: BoxDecoration(
         //    // color: Styles().colors.surface,
         //    borderRadius: BorderRadius.circular(8),
         //    border: Border.all(color: Styles().colors.surfaceAccent, width: 0.5)
         // ),
        child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Styles().textStyles.getTextStyle("widget.title.medium.fat"),),
            Visibility(visible: _imageDescriptionData.decorative == false, child:
                Column(
                  children: [
                    Container(height: 8,),
                    Container(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        decoration: PostInputField.fieldDecoration,
                        child: Semantics(label: label, hint: hint, container: true,
                          child:TextField(
                            controller: _textController,
                            onChanged: (value) {
                              setStateIfMounted((){
                                _imageDescriptionData.description = value;
                                widget.onChanged?.call(widget.imageDescriptionData);
                              });
                            },
                            minLines: 1,
                            maxLines: 2,
                            enabled: _imageDescriptionData.decorative == false,
                            textAlign: TextAlign.start,
                            decoration: InputDecoration(
                              filled: _imageDescriptionData.decorative == false,
                              fillColor: Styles().colors.white,
                              // hintText: hint,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            style: Styles().textStyles.getTextStyle(
                                'widget.input_field.text.regular'),
                          )
                        )
                    ),
                    Container(height: 8,),
                    ExcludeSemantics(child:
                      Text(hint, style: Styles().textStyles.getTextStyle("widget.description.regular"),)),
              ])),
          Container(height: 8),
          _buildSwitch(
              title: Localization().getStringEx("",
                  "This image is decorative and does not convey any information"),
              value: _imageDescriptionData.decorative == true,
              onTap: () =>
                  setStateIfMounted(() {
                    _imageDescriptionData.decorative = !_imageDescriptionData.decorative;
                    widget.onChanged?.call(_imageDescriptionData);
                  })
          ),
          Container(height: 8,),
            Text(Localization().getStringEx('', 'Note: logos, departmental banners, and images used as links are all considered informational.'),
              style: Styles().textStyles.getTextStyle("widget.description.regular"),),
           Container(height: 12,),
           Visibility(visible: widget.mode == ImageDescriptionInputMode.dialog, child:
              Container(child:
                 Row(
                   mainAxisSize: MainAxisSize.max,
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Expanded(child:
                     RoundedButton(label: "Ok",
                       textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
                       backgroundColor: Colors.white,
                       // borderColor: _imageDescriptionData.isValidated == true ? Styles().colors.fillColorSecondary : Styles().colors.disabledTextColor,
                       // enabled: _imageDescriptionData.isValidated == true,
                       rightIcon: Container(),
                       padding: _dialogButtonPadding,
                       onTap: (){
                         // if(StringUtils.isNotEmpty(imageUrl) && imageDescriptionData?.isValidated == true){
                         //   Content().uploadImageMetaData(imageUrl: imageUrl ?? "", imageMetaData: imageDescriptionData.)
                         // }
                         Navigator.pop(context, _imageDescriptionData);
                       },
                       // enabled: _imageInputData.isValidated,
                       // borderColor: _imageInputData.isValidated ? Styles().colors.fillColorSecondary : Styles().colors.disabledTextColor,
                       // )
                     )),
                     Container(width: 18,),
                     // Expanded(child:
                       Expanded(child:
                         RoundedButton(label: "Cancel",
                           padding: _dialogButtonPadding,
                           onTap: (){
                             Navigator.pop(context);
                           },
                           textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
                           backgroundColor: Colors.white,
                           borderColor: Styles().colors.fillColorSecondary,
                           rightIcon: Container(),
                        )
                       ),
                     // )
                   ],
                 ),
                 )
           )
        ],)
    );
  }

  Widget _buildSwitch({String? title, bool? value, void Function()? onTap}){
    String semanticsValue = (value == true) ?  Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked");
    return Semantics(label: title, value: semanticsValue, button: true, child:
    Container(
        decoration: BoxDecoration(
            color: Styles().colors.white,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4))
        ),
        padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child:
            Text(title ?? "", semanticsLabel: "", style: Styles().textStyles.getTextStyle("widget.title.regular.fat"))
            ),
            GestureDetector(
                onTap: ((onTap != null)) ?() {
                  onTap();
                  AppSemantics.announceCheckBoxStateChange(this.context,  /*reversed value*/!(value == true), title);
                } : (){},
                child: Padding(padding: EdgeInsets.only(left: 10), child:
                Styles().images.getImage(value ?? false ? 'toggle-on' : 'toggle-off')
                )
            )
          ])
        ])
    ),
    );
  }
}

class ImageDescriptionData {
    String? description;
    bool decorative;

    ImageDescriptionData({this.description, this.decorative = false});
}

extension ImageDescriptionDataExt on ImageDescriptionData{
  static ImageDescriptionData? fromMetaData(ImageMetaData? data) => data != null ? ImageDescriptionData(
    description: data.altText,
    decorative: data.decorative ?? false,
  ) : null;

  bool get isValidated => (decorative) || StringUtils.isNotEmpty(description);

  ImageMetaData get toMetaData => ImageMetaData(altText: description, decorative: decorative);
}