
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Event2FiltersPanel extends StatefulWidget {
  final Map<String, dynamic> attributes;
  Event2FiltersPanel(this.attributes, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2FiltersPanelState();
}

class _Event2FiltersPanelState extends State<Event2FiltersPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.background,
    );
  }

  Widget _buildPanelContent() {
    return Container();
  }
}