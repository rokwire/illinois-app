

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeHandleWidget extends StatefulWidget {
  final String? title;
  final int? position;
  final CrossAxisAlignment crossAxisAlignment;

  final String? favoriteId;
  final HomeDragAndDropHost? dragAndDropHost;

  const HomeHandleWidget({Key? key, this.title, this.position, this.crossAxisAlignment = CrossAxisAlignment.center, this.favoriteId, this.dragAndDropHost}): super(key: key);

  @override
  _HomeHandleWidgetState createState() => _HomeHandleWidgetState();
}

class _HomeHandleWidgetState extends State<HomeHandleWidget> {

  final GlobalKey _contentKey = GlobalKey();
  CrossAxisAlignment? _dropAnchorAlignment;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<HomeFavorite>(
      builder: (BuildContext context, List <HomeFavorite?> candidateData, List<dynamic> rejectedData) {
        HomeFavorite? homeFavorite = candidateData.isNotEmpty ? candidateData.first : null;
        return _buildContent(context, dropTarget: homeFavorite != null);
      },
      onMove: (DragTargetDetails<HomeFavorite> details) {
        _onDragMove(details.offset);
      },
      onLeave: (_) {
        _onDragLeave();
      },
      onAccept: (HomeFavorite favorite) {
        widget.dragAndDropHost?.onDragAndDrop(dragFavoriteId: favorite.favoriteId, dropFavoriteId: widget.favoriteId, dropAnchor: _dropAnchorAlignment);
      },
    );
  }

  Widget _buildContent(BuildContext context, {bool dropTarget = false }) {
    return Column(key: _contentKey, children: <Widget>[
      Container(height: 2, color: (dropTarget && (_dropAnchorAlignment == CrossAxisAlignment.start)) ? Styles().colors?.fillColorSecondary : ((widget.position == 0) ? Styles().colors!.surfaceAccent : Colors.transparent),),

      LongPressDraggable<HomeFavorite>(
        data: HomeFavorite(widget.favoriteId),
        axis: Axis.vertical,
        //affinity: Axis.vertical,
        maxSimultaneousDrags: 1,
        onDragStarted: () { widget.dragAndDropHost?.isDragging = true; },
        onDragEnd: (details) { widget.dragAndDropHost?.isDragging = false; },
        onDragCompleted: () { widget.dragAndDropHost?.isDragging = false; },
        onDraggableCanceled: (velocity, offset) { widget.dragAndDropHost?.isDragging = false; },
        feedback: HomeDragFeedback(title: widget.title),
        child: Row(crossAxisAlignment: widget.crossAxisAlignment, children: <Widget>[

          Semantics(label: 'Drag Handle' /* TBD: Localization */, button: true, child:
            Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
              Image.asset('images/icon-drag-white.png', excludeFromSemantics: true),
            ),
          ),

          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
              Semantics(label: widget.title, header: true, excludeSemantics: true, child:
                Text(widget.title ?? '', style: TextStyle(color: Styles().colors?.fillColorPrimary, fontFamily: Styles().fontFamilies?.bold, fontSize: 18),)
              )
            )
          ),

                
          HomeFavoriteButton(favorite: HomeFavorite(widget.favoriteId), style: HomeFavoriteStyle.SlantHeader, prompt: true),
        ],),
      ),

      Container(height: 2, color: (dropTarget && (_dropAnchorAlignment == CrossAxisAlignment.end)) ? Styles().colors?.fillColorSecondary : Styles().colors!.surfaceAccent,),
    ]);
  }

  void _onDragMove(Offset offset) {
    RenderBox render = _contentKey.currentContext?.findRenderObject() as RenderBox;
    Offset position = render.localToGlobal(Offset.zero);
    double topY = position.dy;  // top position of the widget
    double middleY = topY + render.size.height / 2;
    double eventY = offset.dy + 25; //TBD: handle properly the offset
    
    CrossAxisAlignment dropAnchorAlignment = (eventY < middleY) ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    if ((_dropAnchorAlignment != dropAnchorAlignment) && mounted) {
      setState(() {
        _dropAnchorAlignment = dropAnchorAlignment;
      });
    }
  }

  void _onDragLeave() {
    if ((_dropAnchorAlignment != null) && mounted) {
      setState(() {
        _dropAnchorAlignment = null;
      });
    }
  }
}

class HomeDropTargetWidget extends StatefulWidget {

  final String? favoriteId;
  final HomeDragAndDropHost? dragAndDropHost;
  final CrossAxisAlignment? dropAnchorAlignment;
  final Widget Function(BuildContext context, { bool? dropTarget, CrossAxisAlignment? dropAnchorAlignment }) childBuilder;

  const HomeDropTargetWidget({Key? key, required this.childBuilder, this.dragAndDropHost, this.favoriteId, this.dropAnchorAlignment }): super(key: key);

  @override
  _HomeDropTargetWidgetState createState() => _HomeDropTargetWidgetState();
}

class _HomeDropTargetWidgetState extends State<HomeDropTargetWidget> {

  final GlobalKey _contentKey = GlobalKey();
  CrossAxisAlignment? _dropAnchorAlignment;

  @override
  void initState() {
    super.initState();
    _dropAnchorAlignment = widget.dropAnchorAlignment;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<HomeFavorite>(
      builder: (BuildContext context, List <HomeFavorite?> candidateData, List<dynamic> rejectedData) {
        HomeFavorite? homeFavorite = candidateData.isNotEmpty ? candidateData.first : null;
        return Container(key: _contentKey, child:
          widget.childBuilder(context, dropTarget: homeFavorite != null, dropAnchorAlignment: _dropAnchorAlignment)
        );
      },
      onMove: (DragTargetDetails<HomeFavorite> details) {
        _onDragMove(details.offset);
      },
      onLeave: (_) {
        _onDragLeave();
      },
      onAccept: (HomeFavorite favorite) {
        widget.dragAndDropHost?.onDragAndDrop(dragFavoriteId: favorite.favoriteId, dropFavoriteId: widget.favoriteId, dropAnchor: _dropAnchorAlignment);
      },
    );
  }

  void _onDragMove(Offset offset) {
    if (widget.dropAnchorAlignment == null) {
      RenderBox render = _contentKey.currentContext?.findRenderObject() as RenderBox;
      Offset position = render.localToGlobal(Offset.zero);
      double topY = position.dy;  // top position of the widget
      double middleY = topY + render.size.height / 2;
      double eventY = offset.dy; //TBD: handle properly the offset
      
      CrossAxisAlignment dropAnchorAlignment = (eventY < middleY) ? CrossAxisAlignment.start : CrossAxisAlignment.end;

      if ((_dropAnchorAlignment != dropAnchorAlignment) && mounted) {
        setState(() {
          _dropAnchorAlignment = dropAnchorAlignment;
        });
      }
    }
  }

  void _onDragLeave() {
    if ((widget.dropAnchorAlignment == null) && (_dropAnchorAlignment != null) && mounted) {
      setState(() {
        _dropAnchorAlignment = null;
      });
    }
  }
}

class HomeSlantWidget extends StatelessWidget {

  final String? title;
  final Image? titleIcon;
  final CrossAxisAlignment headerAxisAlignment;

  final double flatHeight;
  final double slantHeight;
  
  final Widget? child;
  final EdgeInsetsGeometry childPadding;
  
  final String? favoriteId;

  const HomeSlantWidget({Key? key,
    this.title,
    this.titleIcon,
    this.headerAxisAlignment = CrossAxisAlignment.center,
    
    this.flatHeight = 40,
    this.slantHeight = 65,

    this.child,
    this.childPadding = const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
    
    this.favoriteId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Column(children: [
      
      // Title Row
      Padding(padding: EdgeInsets.zero, child: 
        Semantics(container: true, header: true,
          child: Container(color: Styles().colors!.fillColorPrimary, child:
            Row(crossAxisAlignment: headerAxisAlignment, children: <Widget>[

              HomeTitleIcon(image: titleIcon),

              Expanded(child:
                Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
                  Semantics(label: title, header: true, excludeSemantics: true, child:
                    Text(title ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20),)
                  )
                )
              ),

              
              Opacity(opacity: (favoriteId != null) ? 1 : 0, child:
                HomeFavoriteButton(favorite: HomeFavorite(favoriteId), style: HomeFavoriteStyle.SlantHeader, prompt: true),
              ),
            ],),
        ),),
      ),
      
      Stack(children:<Widget>[
      
        // Slant
        Column(children: <Widget>[
          Container(color: Styles().colors?.fillColorPrimary, height: flatHeight,),
          Container(color: Styles().colors?.fillColorPrimary, child:
            CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background, horzDir: TriangleHorzDirection.rightToLeft), child:
              Container(height: slantHeight,),
            ),
          ),
        ],),
        
        // Content
        Padding(padding: childPadding, child:
          child ?? Container()
        )
      ])

    ],);
  }

}

class HomeTitleIcon extends StatelessWidget {

  final Image? image;
  HomeTitleIcon({Key? key, this.image});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
      image ?? Container(width: 18, height: 18),
    );
  }
}

enum HomeFavoriteStyle { SlantHeader, Button }

class HomeFavoriteStar extends StatelessWidget {

  final bool? selected;
  final HomeFavoriteStyle style;
  final EdgeInsetsGeometry padding;

  HomeFavoriteStar({Key? key, this.selected, required this.style, this.padding = const EdgeInsets.all(16) }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, child:
      _starImage,
    );
  }

  Widget get _starImage {
    if (style == HomeFavoriteStyle.SlantHeader) {
      return (selected == true) ?
        Image.asset('images/icon-star-orange.png', excludeFromSemantics: true) :
        Image.asset('images/icon-star-gray-frame-thin.png', excludeFromSemantics: true,);
    }
    else if (style == HomeFavoriteStyle.Button) {
      if (selected == null) {
        return Image.asset('images/icon-star-gray.png', excludeFromSemantics: true);
      }
      else if (selected == true) {
        return Image.asset('images/icon-star-blue.png', excludeFromSemantics: true);
      }
      else if (selected == false) {
        return Image.asset('images/icon-star-gray-frame-thin.png', excludeFromSemantics: true);
      }
    }
    
    return Image.asset('images/icon-star-gray-frame-thin.png', excludeFromSemantics: true);
  }

}

class HomeFavoriteButton extends StatelessWidget {

  final Favorite? favorite;
  final HomeFavoriteStyle style;
  final EdgeInsetsGeometry padding;
  final bool prompt;

  HomeFavoriteButton({this.favorite, required this.style, this.padding = const EdgeInsets.all(16), this.prompt = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
      InkWell(onTap: () => _onFavorite(context), child:
        HomeFavoriteStar(selected: _isFavorite, style: style, padding: padding,)
      ),
    );
  }

  bool get _isFavorite => Auth2().prefs?.isFavorite(favorite) ?? false;

  void _onFavorite(BuildContext context) {
    Analytics().logSelect(target: "Favorite: $favorite");

    if (prompt) {
      promptFavorite(context, favorite).then((bool? result) {
        if (result == true) {
          Auth2().prefs?.toggleFavorite(favorite);
        }
      });
    }
    else {
      Auth2().prefs?.toggleFavorite(favorite);
    }
  }

  static Future<bool?> promptFavorite(BuildContext context, Favorite? favorite) async {
    String message = (Auth2().prefs?.isFavorite(favorite) ?? false) ?
      Localization().getStringEx('widget.home.prompt.remove.favorite', 'Are you sure you want to REMOVE this item from your favorites?') :
      Localization().getStringEx('widget.home.prompt.add.favorite', 'Are you sure you want to ADD this favorite?');
    return await showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        content: Text(message),
        actions: <Widget>[
          TextButton(child: Text(Localization().getStringEx("dialog.yes.title", "Yes")),
            onPressed:(){
              Analytics().logAlert(text: message, selection: "Yes");
              Navigator.pop(context, true);
            }),
          TextButton(child: Text(Localization().getStringEx("dialog.no.title", "No")),
            onPressed:(){
              Analytics().logAlert(text: message, selection: "No");
              Navigator.pop(context, false);
            }),
        ]
      );
    });
  }
}

class HomeDragFeedback extends StatelessWidget {
  final String? title;
  final CrossAxisAlignment headerAxisAlignment;

  HomeDragFeedback({
    this.title,
    this.headerAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: MediaQuery.of(context).size.width, color: Styles().colors!.accentColor3!.withOpacity(0.25), child:
        Row(crossAxisAlignment: headerAxisAlignment, children: <Widget>[

          Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Image.asset('images/icon-drag-white.png', excludeFromSemantics: true),
          ),
          
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
              Text(title ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20, decoration: TextDecoration.none, shadows: <Shadow>[
                Shadow(color: Styles().colors!.fillColorPrimary!.withOpacity(0.5), offset: Offset(2, 2), blurRadius: 2, )
              ] ),),
            ),
          ),

          //HomeFavoriteStar(selected: true,),
        ],),
      ),
    ],);
  }
}

class HomeCommandButton extends StatelessWidget {
  final Favorite? favorite;
  final String? title;
  final String? description;
  final bool? loading;
  final Function()? onTap;


  HomeCommandButton({Key? key, this.favorite, this.title, this.description, this.loading, this.onTap}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Semantics(label: title, hint: description, button: true, child:
      InkWell(onTap: onTap, child: Container(
          padding: EdgeInsets.only(left: 16, bottom: 16),
          decoration: BoxDecoration(color: Styles().colors!.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Row(children: <Widget>[
              Expanded(child:
                Padding(padding: EdgeInsets.only(top: 16), child:
                  Text(title ?? '', style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary), semanticsLabel: "",),
                )
              ),
              // Image.asset('images/chevron-right.png', excludeFromSemantics: true)
              ((loading == true)
                ? Padding(padding: EdgeInsets.all(16), child:
                    SizedBox(height: 16, width: 16, child:
                      CircularProgressIndicator(color: Styles().colors!.fillColorSecondary, strokeWidth: 2),
                    )
                )
                : HomeFavoriteButton(favorite: favorite, style: HomeFavoriteStyle.Button, prompt: true)
              )
            ],),
            StringUtils.isNotEmpty(description)
              ? Padding(padding: EdgeInsets.only(top: 5, right: 16), child:
                  Text(description ?? '', style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textSurface), semanticsLabel: "",),
                )
              : Container(),
        ],),),),
      );
  }

}