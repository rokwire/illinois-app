//
//  AppKeys.h
//  Runner
//
//  Created by Mihail Varbanov on 4/25/19.
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
#import <CoreLocation/CoreLocation.h>

extern NSString * const kFlutterMetodChannelName;

extern CLLocationCoordinate2D const kInitialCameraLocation;
extern float const kInitialCameraZoom;
extern float const kMarkerThresold1Zoom;
extern float const kMarkerThresold2Zoom;
extern float const kMarker2Thresold1Zoom;
extern float const kMarker2Thresold2Zoom;
extern float const kNoPoiThresoldZoom;

extern float const kThresoldZoomUpdateStep;
