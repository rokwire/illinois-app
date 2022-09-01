//
//  Navigation+Utils.h
//  Runner
//
//  Created by Mihail Varbanov on 8/19/22.
//  Copyright 2022 Board of Trustees of the University of Illinois.
//

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
#import <CoreLocation/CLLocation.h>
@class NavCoord;

// Polyline Utils
bool                    navContainsLocation(NavCoord *point, NSArray *polygon, bool geodesic);
bool                    navIsLocationOnEdge(NavCoord *point, NSArray *polygon, bool geodesic, double tolerance);
bool                    navIsLocationOnPath(NavCoord *point, NSArray *polyline, bool geodesic, double tolerance);
int                     navGetLocationPathIndex(NavCoord *point, NSArray *polyline, bool geodesic, double tolerance);
int                     navIsLocationOnEdgeOrPath(NavCoord *point, NSArray *poly, bool closed, bool geodesic, double toleranceEarth);
int						navGetLocationStepIndex(NavCoord *point, NSArray *steps, double tolerance);

// Spherical Utils
double	                navComputeDistanceBetween(CLLocationCoordinate2D from, CLLocationCoordinate2D to);
double                  navComputeHeading(CLLocationCoordinate2D from, CLLocationCoordinate2D to);
double                  navComputeLength(NSArray *path);
double                  navComputeSignedArea(NSArray *path);
double                  navComputeArea(NSArray *path);
CLLocationCoordinate2D  navComputeOffsetOrigin(CLLocationCoordinate2D to, double distance, double heading);
CLLocationCoordinate2D  navComputeOffset(CLLocationCoordinate2D from, double distance, double heading);
CLLocationCoordinate2D  navInterpolate(CLLocationCoordinate2D from, CLLocationCoordinate2D to, double fraction);

// Encoding Utils
NSMutableArray         *navCreatePolygonFromEncodedString(NSString *encodedString);
