import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class PrivacyLevelSlider extends StatefulWidget {
  final double? initialValue;
  final Function? onValueChanged;
  final Color? color;
  final bool readOnly;

  const PrivacyLevelSlider({Key? key, this.onValueChanged, this.initialValue, this.color, this.readOnly = false}) : super(key: key);

  @override
  _PrivacyLevelSliderState createState() => _PrivacyLevelSliderState();
}

class _PrivacyLevelSliderState extends State<PrivacyLevelSlider> {
  double? _discreteValue;
  Color? _mainColor = Styles().colors!.white;
  Color? _trackColor = Styles().colors!.fillColorPrimaryVariant;
  Color? _inactiveTrackColor = Styles().colors!.surfaceAccent;

  @override
  void initState() {
    super.initState();
    _discreteValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    int roundedValue = _discreteValue?.round() ?? 0;
    final ThemeData theme = Theme.of(context);
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 18),
        color: widget.color ?? Styles().colors!.white,
        child: Column(
            children: <Widget>[
              Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Styles().colors!.fillColorPrimaryVariant,
                                  border: Border.all(color: Styles().colors!.fillColorPrimaryVariant!, width: 1),
                                  borderRadius: BorderRadius.circular(24.0),
                                )),
                          )),
                    ),
                    SliderTheme(
                        data: theme.sliderTheme.copyWith(
                            activeTrackColor: _trackColor,
                            inactiveTrackColor: _inactiveTrackColor,
                            activeTickMarkColor: _mainColor,
                            thumbColor: _mainColor,
                            thumbShape: _CustomThumbShape(),
                            tickMarkShape: _CustomTickMarkShape(),
                            trackHeight: 10,
                            inactiveTickMarkColor: _inactiveTrackColor,
                            showValueIndicator: ShowValueIndicator.never,
                            valueIndicatorTextStyle: TextStyle(fontSize: 20, fontFamily: Styles().fontFamilies!.extraBold, color: Styles().colors!.fillColorPrimary)),
                        child: MergeSemantics(
                            child: Semantics(
                                label: Localization().getStringEx("panel.settings.privacy.privacy.button.set_privacy.slider.hint", "Privacy Level"),
                                enabled: true,
                                increasedValue: Localization().getStringEx("panel.settings.privacy.privacy.button.set_privacy.slider.increase", "increased to") +
                                    (roundedValue + 1).toString(),
                                decreasedValue: Localization().getStringEx("panel.settings.privacy.privacy.button.set_privacy.slider.decrease", "decreased to") +
                                    (roundedValue - 1).toString(),
                                child:
                                Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2), //Fix cut off circle
                                    child:
                                    Slider(
                                      value: _discreteValue!,
                                      min: 1.0,
                                      max: 5.0,
                                      divisions: 4,
                                      semanticFormatterCallback: (double value) => value.round().toString(),
                                      label: "$roundedValue",
                                      onChanged: (double value) {
                                        if (!widget.readOnly) {
                                          setState(() {
                                          _discreteValue = value;
                                          if (value > 3.3 && value < 4) {
                                            // remove the second 3rd division caused by {max == division}
                                            _discreteValue = value = 4;
                                          }
                                          if (widget.onValueChanged != null) {
                                            widget.onValueChanged!(value);
                                          }
                                          });
                                        }
                                      },
                                    )
                                ))))
                  ]),
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: PrivacyIcon(
                          currentPrivacyLevel: _currentLevel,
                          minPrivacyLevel: 1,
                          enabledIcon: "images/view-only-blue.png",
                          disabledIcon: "images/view-only-blue.png",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: PrivacyIcon(
                          currentPrivacyLevel: _currentLevel,
                          minPrivacyLevel: 2,
                          enabledIcon: "images/location-sharing-blue.png",
                          disabledIcon: "images/location-sharing-blue-off.png",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: PrivacyIcon(
                          currentPrivacyLevel: _currentLevel,
                          minPrivacyLevel: 3,
                          enabledIcon: "images/personalization-blue.png",
                          disabledIcon: "images/personalization-blue-off.png",
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PrivacyIcon(
                            currentPrivacyLevel: _currentLevel,
                            minPrivacyLevel: 4,
                            enabledIcon: "images/notifications-blue.png",
                            disabledIcon: "images/notifications-blue-off.png",
                          ),
                          SizedBox(width: 16),
                          PrivacyIcon(
                            currentPrivacyLevel: _currentLevel,
                            minPrivacyLevel: 4,
                            enabledIcon: "images/identiy-blue.png",
                            disabledIcon: "images/identiy-blue-off.png",
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: PrivacyIcon(
                          currentPrivacyLevel: _currentLevel,
                          minPrivacyLevel: 5,
                          enabledIcon: "images/share-blue.png",
                          disabledIcon: "images/share-blue-off.png",
                        ),
                      ),
                    ],
                  )
              ),
              Container(height: 5,)
            ]
        ));
  }

  int? get _currentLevel{
    return _discreteValue?.round();
  }
}

class PrivacyIcon extends StatelessWidget{
  final int? currentPrivacyLevel;
  final int minPrivacyLevel;
  final enabledIcon;
  final disabledIcon;

  const PrivacyIcon({Key? key, this.minPrivacyLevel = 1, this.enabledIcon, this.disabledIcon, this.currentPrivacyLevel}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Image.asset(currentPrivacyLevel!>=minPrivacyLevel? enabledIcon : (disabledIcon??""), excludeFromSemantics: true,);
  }

}

class _CustomThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size.fromRadius(16);
  }

  @override
  void paint(PaintingContext context, Offset center, {Animation<double>? activationAnimation, required Animation<double> enableAnimation, bool? isDiscrete, required TextPainter labelPainter, RenderBox? parentBox, required SliderThemeData sliderTheme, TextDirection? textDirection, double? value, double? textScaleFactor, Size? sizeWithOverflow}) {
    final Canvas canvas = context.canvas;
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.activeTickMarkColor,
    );

    final ColorTween colorTween2 = ColorTween(
      begin: Styles().colors!.white,
      end: Styles().colors!.white,
    );

    final ColorTween colorTween3 = ColorTween(
      begin: Styles().colors!.fillColorSecondary,
      end: Styles().colors!.fillColorSecondary,
    );
    final ColorTween colorTween4 = ColorTween(
      begin: Styles().colors!.fillColorPrimary,
      end: Styles().colors!.fillColorPrimary,
    );

    canvas.drawCircle(center, 25, Paint()..color = colorTween4.evaluate(enableAnimation)!);
    canvas.drawCircle(center, 23, Paint()..color = colorTween2.evaluate(enableAnimation)!);
    canvas.drawCircle(center, 21, Paint()..color = colorTween3.evaluate(enableAnimation)!);
    canvas.drawCircle(center, 19, Paint()..color = colorTween.evaluate(enableAnimation)!);
    labelPainter.paint(canvas, center + Offset(-labelPainter.width / 2.0, -labelPainter.height / 2.0));
  }
}

class _CustomTickMarkShape extends SliderTickMarkShape {
  @override
  Size getPreferredSize({SliderThemeData? sliderTheme, bool? isEnabled}) {
    return Size.fromRadius(3);
  }

  @override
  void paint(PaintingContext context, Offset center,
      {RenderBox? parentBox, SliderThemeData? sliderTheme, Animation<double>? enableAnimation, Offset? thumbCenter, bool? isEnabled, TextDirection? textDirection}) {
    //Don"t draw - we don"t want to show TickMarkers
  }
}
