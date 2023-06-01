
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Events2ListPanel extends StatefulWidget {
  static final String routeName = 'Events2ListPanel';

  @override
  State<StatefulWidget> createState() => _Events2ListPanelState();

  static void present(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Events2ListPanel.routeName), builder: (context) => Events2ListPanel()));
  }
}

class _Events2ListPanelState extends State<Events2ListPanel> {

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
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.events2_list.header.title", "Events"), leading: RootHeaderBarLeading.Back,),
      body: _buildContent(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildCommandBar(),
      Expanded(child:
        SingleChildScrollView(child:
          _buildListView(),
        )
      )
    ],);
  }

  Widget _buildCommandBar() {
    return Container(decoration: _commandBarDecoration, child:
      Padding(padding: EdgeInsets.only(left: 16, top: 16, bottom: 16), child:
        Row(children: [
          Expanded(flex: 6, child: Wrap(spacing: 8, runSpacing: 8, children: [ //Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Event2FilterCommandButton(
              title: 'Filters',
              leftIconKey: 'filters',
              rightIconKey: 'chevron-right',
              onTap: _onFilters,
            ),
            Event2FilterCommandButton(
              title: 'Sort',
              leftIconKey: 'sort',
              onTap: _onSort,
            ),
          ])),
          Expanded(flex: 4, child: Wrap(alignment: WrapAlignment.end, verticalDirection: VerticalDirection.up, children: [
            LinkButton(
              title: 'Map View',
              hint: 'Tap to view map',
              onTap: _onMapView,
              padding: EdgeInsets.only(left: 0, right: 8, top: 16, bottom: 16),
              textStyle: Styles().textStyles?.getTextStyle('widget.button.title.regular.underline'),
            ),
            Event2ImageCommandButton('plus-circle',
              label: 'Create',
              hint: 'Tap to create event',
              contentPadding: EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 16),
              onTap: _onCreate
            ),
            Event2ImageCommandButton('search',
              label: 'Search',
              hint: 'Tap to search events',
              contentPadding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
              onTap: _onSearch
            ),
          ])),
        ],)
      ),
    );
  }

  Decoration get _commandBarDecoration => BoxDecoration(
    color: Styles().colors?.white,
    border: Border.all(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1)
  );

  Widget _buildListView() {
    return Container();
  }

  void _onFilters() {
    
  }

  void _onSort() {
    
  }

  void _onSearch() {

  }

  void _onCreate() {

  }

  void _onMapView() {

  }
}

class Event2FilterCommandButton extends StatelessWidget {
  final String? title;
  final String? hint;
  final String  titleTextStyleKey;

  final String? leftIconKey;
  final EdgeInsetsGeometry leftIconPadding;

  final String? rightIconKey;
  final EdgeInsetsGeometry rightIconPadding;

  final EdgeInsetsGeometry contentPadding;
  final Decoration? contentDecoration;

  final void Function()? onTap;

  Event2FilterCommandButton({Key? key,
    this.title, this.hint,
    this.titleTextStyleKey = 'widget.button.title.regular',
    this.leftIconKey,
    this.leftIconPadding = const EdgeInsets.only(right: 6),
    
    this.rightIconKey,
    this.rightIconPadding = const EdgeInsets.only(left: 3),

    this.contentPadding = const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    this.contentDecoration,

    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];

    Widget? leftIconWidget = (leftIconKey != null) ? Styles().images?.getImage(leftIconKey) : null;
    if (leftIconWidget != null) {
      contentList.add(
        Padding(padding: leftIconPadding, child: leftIconWidget,)
      );
    }

    if (StringUtils.isNotEmpty(title)) {
      contentList.add(
        Text(title ?? '', style: Styles().textStyles?.getTextStyle(titleTextStyleKey),)
      );
    }

    Widget? rightIconWidget = (rightIconKey != null) ? Styles().images?.getImage(rightIconKey) : null;
    if (rightIconWidget != null) {
      contentList.add(
        Padding(padding: rightIconPadding, child: rightIconWidget,)
      );
    }

    return Semantics(label: title, hint: hint, button: true, child:
      InkWell(onTap: onTap, child: 
        Container(decoration: contentDecoration ?? defaultContentDecoration, child:
          Padding(padding: contentPadding, child:
            //Row(mainAxisSize: MainAxisSize.min, children: contentList,),
            Wrap(children: contentList,)
          ),
        ),
      ),
    );
  }

  Decoration get defaultContentDecoration => BoxDecoration(
    color: Styles().colors?.white,
    border: Border.all(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1),
    borderRadius: BorderRadius.circular(16),
  );

}

class Event2ImageCommandButton extends StatelessWidget {
  final String imageKey;
  final String? label;
  final String? hint;
  final EdgeInsetsGeometry contentPadding;
  final void Function()? onTap;
  Event2ImageCommandButton(this.imageKey, { Key? key,
    this.label, this.hint,
    this.contentPadding = const EdgeInsets.all(16),
    this.onTap,
  }) : super(key: key);

   @override
  Widget build(BuildContext context) =>
    Semantics(label: label, hint: hint, button: true, child:
      InkWell(onTap: onTap, child:
        Padding(padding: contentPadding, child:
          Styles().images?.getImage(imageKey)
        )
      ),
    );
}