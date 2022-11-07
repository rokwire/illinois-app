//
//  AppKeys.m
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

#import "AppKeys.h"

////////////////////////////////////////////
// Flutter

NSString * const kFlutterMetodChannelName = @"edu.illinois.rokwire/native_call";

// --------------------------------------------

// Camera: Campus Center
CLLocationCoordinate2D const kInitialCameraLocation = { 40.102116, -88.227129 };
float const kInitialCameraZoom = 17;
float const kMarkerThresold1Zoom = 16.0;
float const kMarkerThresold2Zoom = 16.89f;
float const kMarker2Thresold1Zoom = 17.0;
float const kMarker2Thresold2Zoom = 18.0f;
float const kNoPoiThresoldZoom = 17.0;

// --------------------------------------------

float const kThresoldZoomUpdateStep = 0.3f;
