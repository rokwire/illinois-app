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

import 'package:flutter/material.dart';
import 'package:illinois/ui/wallet/WalletPanel.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WalletSheet extends StatelessWidget{

  static const String initialRouteName = "initial";

  final String? ensureVisibleCard;

  WalletSheet({Key? key, this.ensureVisibleCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24),),
        child: Container(
          color: Styles().colors!.surface,
          child: DraggableScrollableSheet(
              maxChildSize: 0.95,
              initialChildSize: 0.95,
              expand: false,
              builder: (context, scrollController){
                return Column(
                  children: <Widget>[

                    Padding(padding: EdgeInsets.only(top: 16), child:
                      Container(height: 2, width: 32, decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(3.5)), color: Styles().colors!.mediumGray,)),
                    ),
                    
                    Expanded(child:
                      WalletPanel(scrollController: scrollController, ensureVisibleCard: ensureVisibleCard),
                    ),

                    TabBarWidget(walletExpanded: true,),
                    //CloseSheetButton(onTap: ()=>Navigator.of(context, rootNavigator: true).pop(),),
                  ],
                );
              }
          ),
        ),
    );
  }
}

