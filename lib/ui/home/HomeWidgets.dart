

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class HomeDropTargetWidget extends StatefulWidget {

  final String? favoriteId;
  final HomeDragAndDropHost? dragAndDropHost;
  final Widget? child;

  const HomeDropTargetWidget({Key? key, this.child, this.dragAndDropHost, this.favoriteId, }) : super(key: key);

  @override
  _HomeDropTargetWidgetState createState() => _HomeDropTargetWidgetState();
}

class _HomeDropTargetWidgetState extends State<HomeDropTargetWidget> {

  final GlobalKey _contentKey = GlobalKey();
  Size? _contentSize;
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
        return _buildContent(dropTarget: homeFavorite != null);
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

  Widget _buildContent({bool dropTarget = false }) {

    List<Widget> layers = <Widget>[
      Opacity(opacity: dropTarget ? 0.3 : 1.0, child: 
        widget.child
      ),
    ];

    if (dropTarget) {
      if (_dropAnchorAlignment == CrossAxisAlignment.start) {
        layers.add(Container(height: 3, color: Styles().colors?.fillColorSecondary),);
      }
      else if ((_dropAnchorAlignment == CrossAxisAlignment.end) && (_contentSize != null)) {
        layers.add(Padding(padding: EdgeInsets.only(top: (_contentSize!.height - 3)), child: Container(height: 3, color: Styles().colors?.fillColorSecondary?.withOpacity(0.8)),),);
      }
    }

    return Stack(key: _contentKey, children: layers,);
  }

  void _onDragMove(Offset offset) {
    RenderBox render = _contentKey.currentContext?.findRenderObject() as RenderBox;
    _contentSize = render.size;
    Offset position = render.localToGlobal(Offset.zero);
    double topY = position.dy;  // top position of the widget
    double eventY = offset.dy;
    CrossAxisAlignment? dropAnchorAlignment;
    if ((topY <= eventY) && (eventY < (topY + _contentSize!.height / 2))) {
      dropAnchorAlignment = CrossAxisAlignment.start;
    }
    else if ( ((topY + _contentSize!.height / 2) < eventY) && (eventY < (topY + _contentSize!.height)) ) {
      dropAnchorAlignment = CrossAxisAlignment.end;
    }
    else {
      dropAnchorAlignment = null;
    }

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

class HomeSlantWidget extends StatelessWidget {

  final String? title;
  final CrossAxisAlignment headerAxisAlignment;

  final double flatHeight;
  final double slantHeight;
  
  final Widget? child;
  final EdgeInsetsGeometry childPadding;
  
  final String? favoriteId;
  final HomeDragAndDropHost? dragAndDropHost;

  const HomeSlantWidget({Key? key,
    this.title,
    this.headerAxisAlignment = CrossAxisAlignment.center,
    
    this.flatHeight = 40,
    this.slantHeight = 65,

    this.child,
    this.childPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    
    this.favoriteId,
    this.dragAndDropHost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Column(children: [
      
      // Title Row
      Semantics(container: true, header: true,
        child: Container(color: Styles().colors!.fillColorPrimary, child:
          Row(crossAxisAlignment: headerAxisAlignment, children: <Widget>[

            Semantics(label: 'Drag Handle' /* TBD: Localization */, button: true, child:
              Draggable<HomeFavorite>(
                data: HomeFavorite(favoriteId),
                axis: Axis.vertical,
                affinity: Axis.vertical,
                maxSimultaneousDrags: 1,
                onDragStarted: () { dragAndDropHost?.isDragging = true; },
                onDragEnd: (details) { dragAndDropHost?.isDragging = false; },
                onDragCompleted: () { dragAndDropHost?.isDragging = false; },
                onDraggableCanceled: (velocity, offset) { dragAndDropHost?.isDragging = false; },
                feedback: HomeSlantFeedback(title: title),
                childWhenDragging: HomeDragHandle(),
                child: HomeDragHandle()
              ),
            ),

            Expanded(child:
              Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
                Semantics(label: title, header: true, excludeSemantics: true, child:
                  Text(title ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20),)
                )
              )
            ),

            
            HomeFavoriteButton(favoriteId: favoriteId,),
          ],),
      ),),
      
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
      ]),

    ],);
  }

}

class HomeDragHandle extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
      Image.asset('images/icon-drag-white.png', excludeFromSemantics: true),
    );
  }
}

class HomeFavoriteStar extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
      Image.asset('images/icon-star-yellow.png', excludeFromSemantics: true,),
    );
  }

}

class HomeFavoriteButton extends StatelessWidget {

  final String? favoriteId;

  HomeFavoriteButton({this.favoriteId});

  @override
  Widget build(BuildContext context) {
    return Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
      InkWell(onTap: () => _onFavorite(context), child:
        HomeFavoriteStar()
      ),
    );
  }

  void _onFavorite(BuildContext context) {
    Analytics().logSelect(target: "Favorite: $favoriteId");

    HomeFavorite favorite = HomeFavorite(favoriteId);
    if (Auth2().prefs?.isFavorite(favorite) ?? false) {
      _promptRemoveFavorite(context).then((bool? result) {
        if (result == true) {
          Auth2().prefs?.toggleFavorite(favorite);
        }
      });
    }
    else {
      Auth2().prefs?.toggleFavorite(favorite);
    }
  }

  Future<bool?> _promptRemoveFavorite(BuildContext context) async {
    String message = Localization().getStringEx('widget.home.promot.remove.favorite', 'Are you sure you want to remove this favorite');
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

class HomeSlantFeedback extends StatelessWidget {
  final String? title;
  final CrossAxisAlignment headerAxisAlignment;

  HomeSlantFeedback({
    this.title,
    this.headerAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: MediaQuery.of(context).size.width, color: Styles().colors!.fillColorPrimary!.withOpacity(0.5), child:
        Row(crossAxisAlignment: headerAxisAlignment, children: <Widget>[
          HomeDragHandle(),
          
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
              Text(title ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20, decoration: TextDecoration.none, shadows: <Shadow>[
                Shadow(color: Styles().colors!.fillColorPrimary!.withOpacity(0.5), offset: Offset(2, 2), blurRadius: 2, )
              ] ),),
            ),
          ),

          HomeFavoriteStar(),
        ],),
      ),
      
      CustomPaint(painter: TrianglePainter(painterColor: Styles().colors?.fillColorPrimary?.withOpacity(0.5), horzDir: TriangleHorzDirection.leftToRight, vertDir: TriangleVertDirection.bottomToTop), child:
        Container(width: MediaQuery.of(context).size.width, height: 45,),
      ),

    ],);
  }
}
