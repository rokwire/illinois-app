import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/WellnessRing.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/WellnessRings.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class WellnessRingCreatePanel extends StatefulWidget implements AnalyticsPageAttributes {
  final WellnessRingDefinition? data;
  final String? examplesText;
  final bool initialCreation;

  const WellnessRingCreatePanel({Key? key, this.data, this.initialCreation = true, this.examplesText}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WellnessRingCreatePanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes {
    return {
      Analytics.LogWellnessCategoryName: Analytics.LogWellnessCategoryRings,
      Analytics.LogWellnessTargetName: data?.name,
      Analytics.LogWellnessRingGoalName: data?.goal,
      Analytics.LogWellnessRingUnitName: data?.unit,
    };
  }
}

class _WellnessRingCreatePanelState extends State<WellnessRingCreatePanel> implements NotificationsListener {
  Color? _selectedColor;
  Color? _tmpColor;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();
  TextEditingController _unitController = TextEditingController();

  bool _loadingSave = false;
  bool _loadingDelete = false;

  @override
  void initState() {
    _nameController.text = widget.data!=null ? widget.data!.name??"" : "";
    _quantityController.text = widget.data!=null ? _trimDecimal(widget.data!.goal).toString() : "";
    _unitController.text = widget.data!=null ? widget.data!.unit??"" : "";
    _selectedColor = widget.data != null ? widget.data!.color : null;
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: _headingTitle),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
        Expanded(child:
        SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(children: [
                Container(height: 14,),
                // WellnessWidgetHelper.buildWellnessHeader(),
                _buildCreateDescriptionHeader(),
                _buildNameWidget(),
                _buildColorsRowWidget(),
                _buildDetailsWidget(),
                Container(height: 50,)
        ])))),
        Container(
          padding: EdgeInsets.only(bottom: 50, top: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDeleteButton(),
              _buildSaveButton(),
            ],)
        )
      ],),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildCreateDescriptionHeader() {
    return Padding(
        padding: EdgeInsets.only(top: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(widget.examplesText ?? "",
                  style: Styles().textStyles?.getTextStyle('widget.message.small')))
        ]));
  }

  Widget _buildNameWidget() {
    return Padding(
        padding: EdgeInsets.only(top: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text(Localization().getStringEx('panel.wellness.ring.create.name.field.label', 'RING NAME'),
                  style: Styles().textStyles?.getTextStyle('widget.description.small.fat'))),
          Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
              child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(border: InputBorder.none),
                  style: Styles().textStyles?.getTextStyle('widget.title.medium.fat')))
        ]));
  }

  Widget _buildColorsRowWidget() {
    final List<String> predefinedColors = [
      "#e45434",
      "#f5821e",
      "#54a747",
      "#09fd4",
      "#1d58a7",
      "#662d91"
    ];
    //Custom Color shown in last cell Not used for now. Use if showing custom picker
    // String? initialColorHex = widget.data?.colorHex;
    // String? tmpColorHex = _tmpColor!= null ? ColorUtils.toHex(_tmpColor!) : null;
    String? selectedColorHex = _selectedColor != null ? ColorUtils.toHex(_selectedColor!) : null;
    //
    // //Show initial color if we have changed with default one
    // if(initialColorHex != null && !predefinedColors.contains(initialColorHex)){
    //   predefinedColors.removeLast();
    //   predefinedColors.add(initialColorHex);
    // }
    //
    // //Show selected colour
    // if(selectedColorHex!=null && !predefinedColors.contains(selectedColorHex)){
    //   predefinedColors.removeLast();
    //   predefinedColors.add(selectedColorHex);
    // //Or last custom color
    // } else if(tmpColorHex != null && !predefinedColors.contains(tmpColorHex)){
    //   predefinedColors.removeLast();
    //   predefinedColors.add(tmpColorHex);
    // }

    List<Widget> content = [];
    for(String colorHex in predefinedColors){
      content.add(
        _buildColorEntry(color: ColorUtils.fromHex(colorHex), isSelected: (selectedColorHex == colorHex)),
      );
    }

    //Custom Color Picker
    // content.add(_buildColorEntry(imageAsset: 'images/icon-color-edit.png'),);

    return Center(
        child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: content))));
  }

  Widget _buildColorEntry({Color? color, String? imageAsset, bool isSelected = false}) {
    BoxBorder? border = isSelected ? Border.all(color: Colors.black, width: 2) : null;
    DecorationImage? image = StringUtils.isNotEmpty(imageAsset) ? DecorationImage(image: AssetImage(imageAsset!), fit: BoxFit.fill) : null;
    return Padding(padding: EdgeInsets.only(right: 10), child: GestureDetector(
        onTap: () => _onTapColor(color),
        child: Container(
            width: 50, height: 50, decoration: BoxDecoration(color: color, image: image, border: border, shape: BoxShape.circle))));
  }

  Widget _buildColorPickerDialog() {
    return SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          ColorPicker(pickerColor: Styles().colors!.fillColorSecondary!, onColorChanged: _onColorChanged),
          Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                    RoundedButton(
                        label: Localization().getStringEx('panel.wellness.categories.manage.color.pick.cancel.button', 'Cancel'),
                        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
                        contentWeight: 0,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        onTap: _onTapCancelColorSelection),
                    Container(width: 30),
                    RoundedButton(
                        label: Localization().getStringEx('panel.wellness.categories.manage.color.pick.select.button', 'Select'),
                        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
                        contentWeight: 0,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        onTap: _onTapSelectColor)
                  ])))
        ]));
  }

  Widget _buildDetailsWidget() {
    return Container(
        padding: EdgeInsets.only(top: 20),
        child: Row(children: [
          Expanded(flex: 10,
            child:  Column(crossAxisAlignment: CrossAxisAlignment.start,  mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                      padding: EdgeInsets.only(bottom: 6, left: 7),
                      child: Text(Localization().getStringEx('panel.wellness.ring.create.field.quantity.label', 'QUANTITY'),
                          style: Styles().textStyles?.getTextStyle('widget.description.small.fat'))),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                      child: TextField(
                          controller: _quantityController,
                          decoration: InputDecoration(border: InputBorder.none),
                          style: Styles().textStyles?.getTextStyle('widget.title.medium.fat')))
                ])),
          Container(width: 16,),
          Expanded(flex: 17,
             child: Column(crossAxisAlignment: CrossAxisAlignment.start,  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                        padding: EdgeInsets.only(bottom: 6, left: 7),
                        child: Text(Localization().getStringEx('panel.wellness.ring.create.field.unit.label', 'UNIT'),
                            style: Styles().textStyles?.getTextStyle('widget.description.small.fat'))),
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                        child: TextField(
                            controller: _unitController,
                            decoration: InputDecoration(border: InputBorder.none),
                            style: Styles().textStyles?.getTextStyle('widget.title.medium.fat')))
                  ]))
        ],),
        );
  }

  Widget _buildSaveButton() {
    return Padding(
        padding: EdgeInsets.only(top: 30),
        child: RoundedButton(
            label: _continueButtonTitle,
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
            contentWeight: 0,
            progress: _loadingSave,
            padding: EdgeInsets.symmetric(horizontal: 46, vertical: 6),
            onTap: _onTapSave));
  }

  Widget _buildDeleteButton() {
    if(widget.data == null || WellnessRings().getRingData(widget.data?.id) == null)
      return Container();

    return Padding(
        padding: EdgeInsets.only(top: 30, right: 16),
        child: RoundedButton(
            label: Localization().getStringEx('panel.wellness.categories.delete.button', 'Delete'),
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
            contentWeight: 0,
            progress: _loadingDelete,
            padding: EdgeInsets.symmetric(horizontal: 46, vertical: 8),
            onTap: _onTapDelete));
  }

  void _onColorChanged(Color newColor) {
    _tmpColor = newColor;
  }

  void _onTapCancelColorSelection() {
    Analytics().logSelect(target: "Cancel Color");
    Navigator.of(context).pop();
  }

  void _onTapSelectColor() {
    Analytics().logSelect(target: "Select Color");
    _selectedColor = _tmpColor;
    Navigator.of(context).pop();
    _updateState();
  }

  void _onTapSave() {
    Analytics().logSelect(target: "Save");
    _hideKeyboard();
    String name = _nameController.text;
    double? quantity = StringUtils.isNotEmpty(_quantityController.text)? _toDouble(_quantityController.text) : null;
    String unit = _unitController.text;
    if(StringUtils.isEmpty(name)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.wellness.ring.create.empty.name.msg', 'Please, fill ring name.'));
      return;
    }

    if(quantity == null) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.wellness.ring.create.empty.quantity.msg', 'Please, fill quantity field with valid number.'));
      return;
    }

    if(StringUtils.isEmpty(unit)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.wellness.ring.create.empty.unit.msg', 'Please, fill unit field.'));
      return;
    }
    if(_selectedColor == null) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.wellness.ring.create.empty.color.msg', 'Please, select color.'));
      return;
    }
    _setLoadingSave(true);
    WellnessRingDefinition _ringData = WellnessRingDefinition(name: name, colorHex: ColorUtils.toHex(_selectedColor!), goal: quantity, unit: unit, dateCreatedUtc: DateTime.now().toUtc(), id: "id_${DateTime.now().millisecondsSinceEpoch}");
    if(widget.data?.id != null) {
      _ringData.id = widget.data!.id;
    }
    Analytics().logWellnessRing(
      action: widget.initialCreation ? Analytics.LogWellnessActionCreate : Analytics.LogWellnessActionUpdate,
      item: _ringData
    );
    if(widget.initialCreation) {

      WellnessRings().addRing(_ringData).then((success) {
        late String msg;
        if (success) {
          msg = Localization().getStringEx(
              'panel.wellness.ring.create.create.succeeded.msg',
              'Wellness Ring created successfully.');
        } else {
          msg = Localization().getStringEx(
              'panel.wellness.ring.create.failed.msg',
              'Failed to create Wellness Ring.');
        }
        _setLoadingSave(false);
        AppAlert.showDialogResult(context, msg).then((value){
          Navigator.of(context).pop(success);
        });
      });
    } else {
      WellnessRings().updateRing(_ringData).then((success){
        late String msg;
        if (success) {
          msg = Localization().getStringEx(
              'panel.wellness.ring.create.update.succeeded.msg',
              'Wellness Ring updated successfully.');
        } else {
          msg = Localization().getStringEx(
              'panel.wellness.ring.create.update.failed.msg',
              'Failed to update Wellness Ring.');
        }
        _setLoadingSave(false);
        AppAlert.showDialogResult(context, msg).then((value) {
          Navigator.of(context).pop(success);
        });
      });
    }
  }

  void _onTapDelete(){
    Analytics().logSelect(target: "Delete");
    Analytics().logWellnessRing(
      action: Analytics.LogWellnessActionClear,
      item: widget.data
    );
    _hideKeyboard();
    if(widget.data?.id != null) {
      _setLoadingDelete(true);
      WellnessRings().removeRing(widget.data!).then((success){
        late String msg;
        if (success) {
          msg = Localization().getStringEx(
              'panel.wellness.ring.create.delete.succeeded.msg',
              'Wellness Ring deleted successfully.');
        } else {
          msg = Localization().getStringEx(
              'panel.wellness.ring.create.delete.failed.msg',
              'Failed to delete Wellness Ring.');
        }
        _setLoadingDelete(false);
        AppAlert.showDialogResult(context, msg).then((value) {
          Navigator.of(context).pop(success);
        });
      });
    }
  }

  void _onTapColor(Color? color) async {
    Analytics().logSelect(target: "Color: $color");
    _hideKeyboard();
    if (color == null) {
      AppAlert.showCustomDialog(context: context, contentWidget: _buildColorPickerDialog()).then((_) {
        // _tmpColor = null; do not refresh the tmp colour show it instead
      });
    } else {
      _selectedColor = color;
      _updateState();
    }
  }

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setLoadingDelete(bool loading) {
    _loadingDelete = loading;
    _updateState();

  }

  void _setLoadingSave(bool loading) {
    _loadingSave = loading;
    _updateState();
  }

  String get _continueButtonTitle{
    return widget.initialCreation?
      Localization().getStringEx('panel.wellness.ring,create.create.button', 'Create') :
      Localization().getStringEx('panel.wellness.ring.create.update.button', 'Update');
  }

  String get _headingTitle{
    return widget.initialCreation?
    Localization().getStringEx('panel.wellness.ring.create.create.title', 'Create Wellness Ring'):
    Localization().getStringEx('panel.wellness.ring.create.update.title', 'Update Wellness Ring');
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    //TBD implement if needed
  }

  //Duplicated utils tbd move to shared utils
  num _trimDecimal(double value){
    return value % 1 == 0 ? value.toInt() : value;
  }

  double? _toDouble(String value){
    int? intValue = int.tryParse(value);
    if(intValue != null){
      return intValue.toDouble();
    }

    double? doubleValue = double.tryParse(value);
    if(doubleValue != null){
      return doubleValue;
    }

    return null;
  }
}