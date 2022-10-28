
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ExpandableNetworkImage extends StatelessWidget{
  final String? url, semanticLabel;
  final BoxFit? fit;
  final Map<String, String>? headers;
  final bool excludeFromSemantics;
  final ImageLoadingBuilder? loadingBuilder;
  final double? width, height;
  final AlignmentGeometry alignment;

  final Widget? child;

  const ExpandableNetworkImage(this.url, {Key? key, this.child, this.semanticLabel, this.fit, this.headers, this.excludeFromSemantics = false, this.loadingBuilder, this.width, this.height, this.alignment = Alignment.center}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        _showModalImage(url, context);
      },
      child: child??
          (StringUtils.isNotEmpty(url)? Image.network(url!, semanticLabel: semanticLabel ?? "", fit: fit, headers: headers, excludeFromSemantics: excludeFromSemantics, loadingBuilder: this.loadingBuilder, width: this.width, height: this.height, alignment: this.alignment)
          : Container()),
    );
  }

  //Modal Image Dialog
  void _showModalImage(String? url, BuildContext context){
    Analytics().logSelect(target: "Image");
    if (url != null) {
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(imageUrl: url, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image"))));    }
      // Navigator.push(context, CupertinoPageRoute( builder: (context) => ModalImagePanel(imageUrl: url, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image"))));    }
  }
}