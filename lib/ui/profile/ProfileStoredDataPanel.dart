
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileStoredDataPanel extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _ProfileStoredDataPanelState();
}

class _ProfileStoredDataPanelState extends State<ProfileStoredDataPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx("panel.profile.stored_data.header.title", "My Stored Data"),),
    body: _scaffoldContent,
    backgroundColor: Styles().colors.background,
  );

  Widget get _scaffoldContent => SafeArea(child:
    RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
        _panelContent,
      )
    ),
  );

  Widget get _panelContent => Padding(padding: EdgeInsets.all(16), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProfileStoredDataWidget(
        title: Localization().getStringEx('panel.profile.stored_data.core_account.title', "Core Account"),
        dataProvider: _coreAccountData,
      ),
    ]),
  );

  Future<String?> _coreAccountData() async {
    Response? response = await Auth2().loadAccountEx();
    return (response?.statusCode == 200) ? JsonUtils.encode(JsonUtils.decode(response?.body), prettify: true) : null;
  }

  Future<void> _onRefresh() async {

  }
}

typedef _StoreDataProvider = Future<String?> Function();

class _ProfileStoredDataWidget extends StatefulWidget {
  final String? title;
  final _StoreDataProvider dataProvider;
  final EdgeInsetsGeometry margin;

  // ignore: unused_element
  _ProfileStoredDataWidget({super.key, required this.dataProvider, this.title, this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4) });

  @override
  State<StatefulWidget> createState() => _ProfileStoredDataWidgetState();
}

class _ProfileStoredDataWidgetState extends State<_ProfileStoredDataWidget> {
  TextEditingController _textController = TextEditingController();
  bool _providingData = false;
  String? _providedData;

  @override
  void initState() {
    _providingData = true;

    widget.dataProvider().then((String? data) {
      if (mounted) {
        setState(() {
          _providedData = data;
          _providingData = false;
        });
        _textController.text = data ?? Localization().getStringEx('widget.profile.stored_data.retrieve.failed.message', 'Failed to retrieve data');
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(padding: widget.margin, child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      if (StringUtils.isNotEmpty(widget.title))
        Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text(widget.title ?? '', style: Styles().textStyles.getTextStyle('widget.title.small.fat'),),
        ),
      Stack(children: [
        TextField(
          maxLines: 5,
          readOnly: true,
          controller: _textController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
          ),
          style: (_providedData != null) ? Styles().textStyles.getTextStyle('widget.input_field.text.regular') : Styles().textStyles.getTextStyle('widget.item.small.thin.italic'),
        ),

        Visibility(visible: _providingData, child:
          Positioned.fill(child:
            Align(alignment: Alignment.center, child:
              SizedBox(height: 24, width: 24, child:
                CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3),
              ),
            ),
          ),
        ),

        Visibility(visible: !_providingData && StringUtils.isNotEmpty(_providedData), child:
          Positioned.fill(child:
            Align(alignment: Alignment.topRight, child:
              InkWell(onTap: _onCopy, child:
                Padding(padding: EdgeInsets.all(12), child:
                  Styles().images.getImage('copy', excludeFromSemantics: true),
                ),
              ),
            ),
          ),
        ),

      ],),
    ]),

  );

  void _onCopy() {
      }
}