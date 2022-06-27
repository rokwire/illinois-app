
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';

enum FavoriteIconStyle { SlantHeader, Handle, Button }

class FavoriteStarIcon extends StatelessWidget {

  final bool? selected;
  final FavoriteIconStyle style;
  final EdgeInsetsGeometry padding;

  FavoriteStarIcon({Key? key, this.selected, required this.style, this.padding = const EdgeInsets.all(16) }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, child:
      _starImage,
    );
  }

  Widget get _starImage {
    if (style == FavoriteIconStyle.SlantHeader) {
      return (selected == true) ?
        Image.asset('images/icon-star-orange.png', excludeFromSemantics: true) :
        Image.asset('images/icon-star-white-frame-thin.png', excludeFromSemantics: true,);
    }
    else if (style == FavoriteIconStyle.Handle) {
      return (selected == true) ?
        Image.asset('images/icon-star-orange.png', excludeFromSemantics: true) :
        Image.asset('images/icon-star-gray-frame-thin.png', excludeFromSemantics: true,);
    }
    else if (style == FavoriteIconStyle.Button) {
      if (selected == null) {
        return Image.asset('images/icon-star-gray.png', excludeFromSemantics: true);
      }
      else if (selected == true) {
        return Image.asset('images/icon-star-orange.png', excludeFromSemantics: true);
      }
      else if (selected == false) {
        return Image.asset('images/icon-star-white.png', excludeFromSemantics: true);
      }
    }
    
    return Image.asset('images/icon-star-gray-frame-thin.png', excludeFromSemantics: true);
  }
}

class FavoriteButton extends StatelessWidget {

  final Favorite? favorite;
  final FavoriteIconStyle style;
  final EdgeInsetsGeometry padding;

  FavoriteButton({Key? key, this.favorite, required this.style, this.padding = const EdgeInsets.all(16)}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
      InkWell(onTap: () => onFavorite(context), child:
        FavoriteStarIcon(selected: isFavorite, style: style, padding: padding,)
      ),
    );
  }

  bool get isFavorite => Auth2().prefs?.isFavorite(favorite) ?? false;
  void toggleFavorite() => Auth2().prefs?.toggleFavorite(favorite);

  void onFavorite(BuildContext context) {
    Analytics().logSelect(target: "Favorite: $favorite");
    toggleFavorite();
  }
}

