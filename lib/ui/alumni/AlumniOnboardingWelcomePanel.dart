/*
 * Copyright 2025 Board of Trustees of the University of Illinois.
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/localization.dart';

import 'AlumniOnboardingContactPanel.dart';

/// Alumni Onboarding – Welcome Screen
class AlumniOnboardingWelcomePanel extends StatefulWidget {
  const AlumniOnboardingWelcomePanel({Key? key}) : super(key: key);

  @override
  State<AlumniOnboardingWelcomePanel> createState() => _AlumniOnboardingWelcomePanelState();
}

class _AlumniOnboardingWelcomePanelState extends State<AlumniOnboardingWelcomePanel> with SingleTickerProviderStateMixin {

  late final ConfettiController _confetti;
  bool _confettiVisible = true;

  // ---- Text styles (Proxima Nova via Styles) ----

  // Title: Illini Orange on navy
  TextStyle get _titleStyle => Styles().textStyles
      .getTextStyle('widget.title.light.huge.fat')!
      .merge(TextStyle(fontSize: 40, height: 1.0, color: Styles().colors.fillColorSecondary));

  // Body copy: white, regular
  TextStyle get _bodyStyle => Styles().textStyles
      .getTextStyle('widget.description.regular.highlight')!
      .merge(const TextStyle(fontSize: 24, height: 1.2));

  // CTA text: dark primary variant on white pill
  TextStyle get _buttonTextStyle => Styles().textStyles
      .getTextStyle('widget.button.title.regular')!
      .copyWith(color: Styles().colors.fillColorPrimaryVariant);

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3))
      ..addListener(() {
        if (!mounted) return;
        if (_confetti.state == ConfettiControllerState.stopped) {
          setState(() => _confettiVisible = false);
        }
      })
      ..play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final double bottomSafe = safe.bottom;

    return Scaffold(
      backgroundColor: Styles().colors.fillColorPrimary, // #002855
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: <Widget>[
            // Content (Figma-ish offsets)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(41, 206, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Official Illinois Alumni logo from styles.json
                    _alumniLogo(),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      Localization().getStringEx('', 'Welcome to\nAlumni Mode'),
                      style: _titleStyle,
                      textAlign: TextAlign.left,
                    ),

                    const SizedBox(height: 24),

                    // Body
                    Text(
                      Localization().getStringEx(
                        '',
                        'Congrats! Your Illinois App now has an Alumni view. Keep your info fresh, connect with fellow Illini, and get perks.',
                      ),
                      style: _bodyStyle,
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),

            // Confetti burst (top corners) – auto hides after ~3s
            if (_confettiVisible) ...[
              Align(
                alignment: Alignment.topLeft,
                child: _ConfettiBurst(
                  controller: _confetti,
                  colors: _confettiColors,
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: _ConfettiBurst(
                  controller: _confetti,
                  colors: _confettiColors,
                ),
              ),
            ],

            // Bottom CTA (white pill with orange border)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + bottomSafe,
              child: _ContinueButton(
                label: Localization().getStringEx('', 'Continue'),
                textStyle: _buttonTextStyle,
                onTap: _onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> get _confettiColors => <Color>[
    Styles().colors.fillColorSecondary,           // Illini Orange
    Styles().colors.white,
    Styles().colors.accentColor3,                 // Blue accent
    Styles().colors.accentColor2,                 // Teal accent
  ];

  Widget _alumniLogo() {
    final Widget? logo = Styles().images.getImage('illinois-alumni', excludeFromSemantics: true);
    return SizedBox(
      height: 64,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.contain,
          child: logo ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  void _onContinue() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AlumniOnboardingContactPanel(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation
                .drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.ease))),
            child: child,
          );
        },
      ),
    );
  }

}

/// Confetti settings extracted for reuse (lightweight burst)
class _ConfettiBurst extends StatelessWidget {
  final ConfettiController controller;
  final List<Color> colors;

  const _ConfettiBurst({Key? key, required this.controller, required this.colors}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConfettiWidget(
      confettiController: controller,
      blastDirectionality: BlastDirectionality.explosive,
      emissionFrequency: 0.03,      // light
      numberOfParticles: 12,        // light
      maxBlastForce: 20,
      minBlastForce: 8,
      gravity: 0.25,
      shouldLoop: false,
      colors: colors,
    );
  }
}

/// CTA button – white pill with orange border
class _ContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final TextStyle textStyle;

  const _ContinueButton({
    Key? key,
    required this.label,
    required this.textStyle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Styles().colors;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.fillColorSecondary, width: 2),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 2),
                color: Colors.black.withOpacity(0.10),
              ),
            ],
          ),
          child: Text(label, style: textStyle),
        ),
      ),
    );
  }
}
