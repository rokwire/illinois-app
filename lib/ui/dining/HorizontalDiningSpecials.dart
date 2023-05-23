/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


import 'package:flutter/cupertino.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/dining/LocationsWithSpecialPanel.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HorizontalDiningSpecials extends StatelessWidget {
  final String? locationId;
  final List<DiningSpecial>? specials;

  HorizontalDiningSpecials({this.specials, this.locationId});

  @override
  Widget build(BuildContext context) {
    List<Widget> offerWidgets = _createOffers();
    bool hasOffers = offerWidgets.isNotEmpty;

    return hasOffers ? Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Container(height: 10,),
        Text(Localization().getStringEx("panel.explore.label.dining_news.title", "Dining News"), style: Styles().textStyles?.getTextStyle("widget.item.regular.extra_fat")),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child:
          Row(children: offerWidgets,),
        )
      ],),
    ) : Container();
  }

  List<Widget> _createOffers() {
    List<Widget> offers = [];

    List<DiningSpecial>? limitedOffers = specials;
    if (StringUtils.isNotEmpty(locationId) && CollectionUtils.isNotEmpty(specials)) {
      limitedOffers = specials!.where((entry) => entry.locationIds!.contains(locationId)).toList();
    }

    if (CollectionUtils.isNotEmpty(limitedOffers)) {
      for (DiningSpecial offer in limitedOffers!) {
        if (offers.isNotEmpty) {
          offers.add(Container(width: 10,));
        }
        offers.add(_SpecialOffer(special: offer,));
      }
    }
    return offers;
  }
}

class _SpecialOffer extends StatefulWidget {
  final DiningSpecial? special;

  _SpecialOffer({this.special});

  @override
  _SpecialOfferState createState() => _SpecialOfferState();
}

class _SpecialOfferState extends State<_SpecialOffer> {

  GlobalKey _keyHtml = GlobalKey();
  double? _imageHeight;

  final EdgeInsets _textPadding = EdgeInsets.all(16.0);

  @override
  void initState() {
    super.initState();
    
    if (_hasImage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _evalImageHeight();
      });
    }
    
  }

  @override
  Widget build(BuildContext context) {

    double width = MediaQuery.of(context).size.width * 0.6;
    double imageWidth = width / 3;

    //Text text = Text(widget.special.title, style: _textStyle);

    //double textWidth = (width - imageWidth) - _textPadding.left - _textPadding.right;
    //final renderObject = (text.build(context) as RichText).createRenderObject(context);
    //renderObject.layout(BoxConstraints(maxWidth: textWidth));
    //List<TextBox> boxes = renderObject.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: special.title.length));
    //double _imageHeight = (boxes.last.bottom - boxes.first.top) + _textPadding.top + _textPadding.bottom;

    HtmlWidget html = HtmlWidget(StringUtils.ensureNotEmpty(widget.special!.title), key:_keyHtml, );

    return Padding(padding: const EdgeInsets.symmetric(vertical: 0), child:
      ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
        Container(width: width, color: Styles().colors!.white, child:
          Row(/*crossAxisAlignment: CrossAxisAlignment.stretch,*/ children: <Widget>[
            _hasImage ? ModalImageHolder(child:
              Image.network(widget.special!.imageUrl!, excludeFromSemantics: true, width: imageWidth, height: _imageHeight, fit: BoxFit.cover,)
            ) : Container(),
            Expanded(child:
              GestureDetector(onTap: _onOfferTap, child:
                Padding(padding: _textPadding, child: html,),
              )
            )
          ],),
        ),
      ),
    );
  }

  bool get _hasImage {
    return StringUtils.isNotEmpty(widget.special!.imageUrl);
  }

  void _evalImageHeight() {
    try {
      final RenderObject? renderBoxHtml = _keyHtml.currentContext?.findRenderObject();
      if (renderBoxHtml is RenderBox) {
        setState(() {
          _imageHeight = renderBoxHtml.size.height + _textPadding.top + _textPadding.bottom;
        });
      }
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  void _onOfferTap() {
    Analytics().logSelect(target: "Special Offer: ${widget.special!.text}");
    Navigator.push(context, CupertinoPageRoute( builder: (context) => LocationsWithSpecialPanel(special: widget.special,)));
  }
}
