//
//  MapView.h
//  Runner
//
//  Created by Mihail Varbanov on 5/21/19.
//  Copyright 2020 Board of Trustees of the University of Illinois.
    
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//    http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>

/////////////////////////////////
// MapViewFactory

@interface MapViewFactory : NSObject<FlutterPlatformViewFactory>
- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;
@end

/////////////////////////////////
// MapViewController

@interface MapViewController : NSObject<FlutterPlatformView>
- (instancetype)initWithFrame:(CGRect)frame viewId:(int64_t) viewId args:(id)args binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;
@end

/////////////////////////////////
// MapView

@interface MapView : UIView
@end

