

import 'package:flutter/material.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeSlantHeader extends StatelessWidget {

  final String? title;
  final String? subTitle;
  final List<Widget>? children;
  final String? favoriteId;
  final HomeScrollableDragging? scrollableDragging;

  const HomeSlantHeader({
    Key? key,

    this.title,
    this.subTitle,

    this.children,

    this.favoriteId,
    this.scrollableDragging,
  }) : super(key: key);

  static Widget get dragHandle => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
    Image.asset('images/icon-drag-white.png', excludeFromSemantics: true),
  );

  @override
  Widget build(BuildContext context) {
    
    // Build Stack layer 1
    List<Widget> layer1List = <Widget>[];
    layer1List.addAll([
      Container(color: Styles().colors?.fillColorPrimary, height: 85,),
      Container(color: Styles().colors?.fillColorPrimary, child:
        CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background, horzDir: TriangleHorzDirection.rightToLeft), child:
          Container(height: 67,),
        ),
      ),
    ]);

    // Build Title Row
    List<Widget> titleList = <Widget>[];
    titleList.add(
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
    );
    
    titleList.add(
      Expanded(child:
        Padding(padding: EdgeInsets.only(top: 14), child:
          Semantics(label: title, header: true, excludeSemantics: true, child:
            Text(title ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20),)
          )
        )
      ),
    );
    
    titleList.add(
      Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
          Image.asset('images/icon-star-yellow.png', excludeFromSemantics: true,),
        )
      ),
    );

    // Build Stack layer 2
    List<Widget> layer2List = <Widget>[
      Padding(padding: EdgeInsets.zero, child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: titleList,),
      ),
    ];

    if (StringUtils.isNotEmpty(subTitle)) {
      layer2List.add(
        Semantics(label: subTitle, header: true, excludeSemantics: true, child:
          Padding(padding: const EdgeInsets.only(left: 50, right: 16), child:
            Row(children: <Widget>[
              Expanded(child:
                Text(subTitle ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.regular, fontSize: 16),),
              ),
            ],),
          ),
        ),
      );
    }

    layer2List.add(
      Padding(padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8), child:
        Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: children ?? [],),
      )
    );

    return Stack(alignment: Alignment.topCenter, children: <Widget>[
      Column(children: layer1List,),
      Column(children: layer2List,),
    ],);

    
  }

}

class HomeRibonHeader extends StatelessWidget {
  final String? title;
  final String? favoriteId;
  final HomeScrollableDragging? scrollableDragging;

  HomeRibonHeader({Key? key, this.favoriteId, this.title, this.scrollableDragging}) : super(key: key);

  static Widget get dragHandle => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
    Image.asset('images/icon-drag-white.png', excludeFromSemantics: true),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(container: true, header: true,
      child: Container(color: Styles().colors!.fillColorPrimary, child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                Text(title ?? '', style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20,),),
              ),
            ),

            Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
                Image.asset('images/icon-star-yellow.png', excludeFromSemantics: true,),
              )
            ),
    ],),),);
  }
  
}