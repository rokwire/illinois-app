
import 'package:flutter/material.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

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

class Event2Card extends StatefulWidget {
  final Event2 event;
  final void Function()? onTap;
  
  Event2Card(this.event, { Key? key, this.onTap}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2CardState();
}

class _Event2CardState extends State<Event2Card> {

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
    return Semantics(label: _semanticsLabel, hint: _semanticsHint, button: true, child:
      InkWell(onTap: widget.onTap, child:
        Container(decoration: _contentDecoration, child:
          ClipRRect(borderRadius: _contentBorderRadius, child: 
            Column(mainAxisSize: MainAxisSize.min, children: [
              Visibility(visible: StringUtils.isNotEmpty(widget.event.imageUrl), child:
                Container(decoration: _imageDecoration, child:
                  AspectRatio(aspectRatio: 2.5, child:
                    Image.network(widget.event.imageUrl ?? '', fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true)
                  ),
                )
              ),
              Padding(padding: EdgeInsets.all(16), child:
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.event.name ?? '', style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'), maxLines: 2,)
                ]),
              ),

            ],),
          ),
        ),
      ),
    );
  }

  String get _semanticsLabel => 'TODO Label';
  String get _semanticsHint => 'TODO Hint';
  
  Decoration get _contentDecoration => BoxDecoration(
    color: Styles().colors?.surface,
    borderRadius: _contentBorderRadius,
    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
    boxShadow: [ BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]
  );

  BorderRadiusGeometry get _contentBorderRadius => BorderRadius.all(Radius.circular(8));

  Decoration get _imageDecoration => BoxDecoration(
    border: Border(bottom: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1)),
  );
}
