import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/gen/styles.dart';

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
  Color? _mainColor = AppColors.white;
  Color? _trackColor = AppColors.fillColorPrimaryVariant;
  Color? _inactiveTrackColor = AppColors.surfaceAccent;

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
        color: widget.color ?? AppColors.white,
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
                                  color: AppColors.fillColorPrimaryVariant,
                                  border: Border.all(color: AppColors.fillColorPrimaryVariant, width: 1),
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
                            valueIndicatorTextStyle: Styles().textStyles.getTextStyle("widget.title.large.extra_fat")),
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
                          enabledIconKey: "view-dark",
                          disabledIconKey: "view-dark",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: PrivacyIcon(
                          currentPrivacyLevel: _currentLevel,
                          minPrivacyLevel: 2,
                          enabledIconKey: "location-dark",
                          disabledIconKey: "location-disabled-dark",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: PrivacyIcon(
                          currentPrivacyLevel: _currentLevel,
                          minPrivacyLevel: 3,
                          enabledIconKey: "sliders-dark",
                          disabledIconKey: "sliders-disabled-dark",
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PrivacyIcon(
                            currentPrivacyLevel: _currentLevel,
                            minPrivacyLevel: 4,
                            enabledIconKey: "notification-dark",
                            disabledIconKey: "notification-disabled-dark",
                          ),
                          SizedBox(width: 16),
                          PrivacyIcon(
                            currentPrivacyLevel: _currentLevel,
                            minPrivacyLevel: 4,
                            enabledIconKey: "person-dark",
                            disabledIconKey: "person-disabled-dark",
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: PrivacyIcon(
                          currentPrivacyLevel: _currentLevel,
                          minPrivacyLevel: 5,
                          enabledIconKey: "share-dark",
                          disabledIconKey: "share-disabled-dark",
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
  final String? enabledIconKey;
  final String? disabledIconKey;

  const PrivacyIcon({Key? key, this.minPrivacyLevel = 1, this.enabledIconKey, this.disabledIconKey, this.currentPrivacyLevel}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Styles().images.getImage(currentPrivacyLevel! >= minPrivacyLevel ? enabledIconKey : disabledIconKey, excludeFromSemantics: true) ?? Container();
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
      begin: AppColors.white,
      end: AppColors.white,
    );

    final ColorTween colorTween3 = ColorTween(
      begin: AppColors.fillColorSecondary,
      end: AppColors.fillColorSecondary,
    );
    final ColorTween colorTween4 = ColorTween(
      begin: AppColors.fillColorPrimary,
      end: AppColors.fillColorPrimary,
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
