

import 'package:flutter/material.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class HomeDropTargetWidget extends StatefulWidget {

  final String? favoriteId;
  final Widget? child;

  const HomeDropTargetWidget({Key? key, this.child, this.favoriteId, }) : super(key: key);

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

  final double flatHeight;
  final double slantHeight;
  
  final Widget? child;
  final EdgeInsetsGeometry childPadding;
  
  final String? favoriteId;
  final HomeScrollableDragging? scrollableDragging;

  const HomeSlantWidget({Key? key,
    this.title,
    
    this.flatHeight = 40,
    this.slantHeight = 65,

    this.child,
    this.childPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    
    this.favoriteId,
    this.scrollableDragging,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Column(children: [
      
      // Title Row
      Semantics(container: true, header: true,
        child: Container(color: Styles().colors!.fillColorPrimary, child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[

            Semantics(label: 'Drag Handle' /* TBD: Localization */, button: true, child:
              Draggable<HomeFavorite>(
                data: HomeFavorite(id: favoriteId),
                onDragStarted: () { scrollableDragging?.isDragging = true; },
                onDragEnd: (details) { scrollableDragging?.isDragging = false; },
                onDraggableCanceled: (velocity, offset) { scrollableDragging?.isDragging = false; },
                feedback: Container(color: Styles().colors!.fillColorPrimary!.withOpacity(0.8), child:
                  Row(children: <Widget>[
                    dragHandle,
                    Padding(padding: EdgeInsets.only(right: 24), child:
                      Text(title ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20, decoration: TextDecoration.none, shadows: <Shadow>[
                        Shadow(color: Styles().colors!.fillColorPrimary!.withOpacity(0.5), offset: Offset(2, 2), blurRadius: 2, )
                      ] ),),
                    ),
                  ],),
                ),
                childWhenDragging: dragHandle,
                child: dragHandle
              ),
            ),

            Expanded(child:
              Padding(padding: EdgeInsets.only(top: 14), child:
                Semantics(label: title, header: true, excludeSemantics: true, child:
                  Text(title ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20),)
                )
              )
            ),

            Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
                Image.asset('images/icon-star-yellow.png', excludeFromSemantics: true,),
              )
            ),
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

  static Widget get dragHandle => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
    Image.asset('images/icon-drag-white.png', excludeFromSemantics: true),
  );

}

